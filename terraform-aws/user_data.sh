#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user_data.log | logger -t user_data) 2>&1

echo "=== Bootstrap started ==="

# ─── System update ────────────────────────────────────────────────────────────
yum update -y

# ─── Install Docker ───────────────────────────────────────────────────────────
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ─── Install Docker Compose ───────────────────────────────────────────────────
COMPOSE_VERSION=$(curl -sf https://api.github.com/repos/docker/compose/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)

curl -SL "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-linux-aarch64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
echo "Docker Compose: $(/usr/local/bin/docker-compose --version)"

# ─── Install CloudWatch Agent ─────────────────────────────────────────────────
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CW
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user_data.log",
            "log_group_name": "/${app_name}/bootstrap",
            "log_stream_name": "{instance_id}/user_data",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
CW

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "CloudWatch agent started"

# ─── Mount EBS volume (persistent SQLite storage) ────────────────────────────
DB_DEVICE="${db_device}"
DB_MOUNT="${db_mount_point}"

# Wait up to 60s for EBS device to appear after attach
for i in {1..12}; do
  [ -b "$DB_DEVICE" ] && break
  echo "Waiting for $DB_DEVICE... ($i/12)"
  sleep 5
done

[ -b "$DB_DEVICE" ] || { echo "ERROR: $DB_DEVICE not found"; exit 1; }

# Format only on very first boot (blank volume)
if ! blkid "$DB_DEVICE" > /dev/null 2>&1; then
  echo "First boot — formatting $DB_DEVICE"
  mkfs.ext4 "$DB_DEVICE"
fi

mkdir -p "$DB_MOUNT"
mount "$DB_DEVICE" "$DB_MOUNT"

# Persist across reboots
grep -q "$DB_DEVICE" /etc/fstab \
  || echo "$DB_DEVICE $DB_MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab

echo "EBS mounted at $DB_MOUNT"

# ─── Write nginx config ───────────────────────────────────────────────────────
mkdir -p /app/nginx

cat > /app/nginx/nginx.conf <<'NGINX'
upstream flask_app {
    server flask_crud_app:5000;
}

server {
    listen 80;
    server_name _;
    client_max_body_size 20M;

    gzip on;
    gzip_types text/plain text/css text/javascript application/json application/javascript;
    gzip_min_length 1000;

    location / {
        proxy_pass http://flask_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /static/ {
        proxy_pass http://flask_app;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }

    location /health {
        access_log off;
        proxy_pass http://flask_app;
    }
}
NGINX

# ─── Write docker-compose.yml ─────────────────────────────────────────────────
cat > /app/docker-compose.yml <<COMPOSE
version: '3.8'

services:
  flask_crud_app:
    image: ${docker_image}
    container_name: flask_crud_app
    restart: always
    expose:
      - "5000"
    environment:
      FLASK_ENV: "${flask_env}"
      SECRET_KEY: "${secret_key}"
      DATABASE_URL: "sqlite:////data/flask_crud.db"
    volumes:
      - ${db_mount_point}:/data
    logging:
      driver: awslogs
      options:
        awslogs-region: "${aws_region}"
        awslogs-group: "/${app_name}/app"
        awslogs-stream: "flask_crud_app"
        awslogs-create-group: "false"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:5000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: always
    ports:
      - "80:80"
    volumes:
      - /app/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - flask_crud_app
    logging:
      driver: awslogs
      options:
        awslogs-region: "${aws_region}"
        awslogs-group: "/${app_name}/nginx"
        awslogs-stream: "nginx"
        awslogs-create-group: "false"

COMPOSE

echo "docker-compose.yml written"

# ─── Pull image ───────────────────────────────────────────────────────────────
cd /app
/usr/local/bin/docker-compose pull

# ─── Run Flask-Migrate (flask db upgrade) ────────────────────────────────────
echo "Running flask db upgrade..."
docker run --rm \
  -e FLASK_ENV="${flask_env}" \
  -e SECRET_KEY="${secret_key}" \
  -e DATABASE_URL="sqlite:////data/flask_crud.db" \
  -v "${db_mount_point}:/data" \
  ${docker_image} \
  flask db upgrade \
  && echo "Migrations applied." \
  || echo "WARNING: flask db upgrade failed — check logs"

# ─── Start all services ───────────────────────────────────────────────────────
/usr/local/bin/docker-compose up -d

# ─── Cleanup cron jobs ────────────────────────────────────────────────────────
# Weekly Docker image prune — every Sunday at 2am
# Daily journal vacuum — every day at 3am
cat > /etc/cron.d/app-cleanup <<'CRON'
0 2 * * 0 root /usr/local/bin/docker-compose -f /app/docker-compose.yml pull --quiet && /usr/bin/docker image prune -f >> /var/log/docker-cleanup.log 2>&1
0 3 * * * root journalctl --vacuum-size=50M >> /var/log/journal-vacuum.log 2>&1
CRON

chmod 644 /etc/cron.d/app-cleanup
echo "Cleanup cron jobs configured"

echo "=== Bootstrap complete ==="
echo "App running at http://$(curl -sf http://169.254.169.254/latest/meta-data/public-ipv4)"