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

# ─── Install and configure CloudWatch Agent ───────────────────────────────────

yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWA'
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user_data.log",
            "log_group_name": "/${app_name}/bootstrap",
            "log_stream_name": "{instance_id}/user_data",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          }
        ]
      }
    }
  }
}
CWA

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
echo "CloudWatch agent started"

# ─── Mount EBS volume for PostgreSQL data ────────────────────────────────────
DB_DEVICE="${db_device}"
DB_MOUNT="${db_mount_point}"

for i in {1..12}; do
  [ -b "$DB_DEVICE" ] && break
  echo "Waiting for $DB_DEVICE... ($i/12)"
  sleep 5
done

[ -b "$DB_DEVICE" ] || { echo "ERROR: $DB_DEVICE not found"; exit 1; }

# Format only on first boot (blank EBS volume)
if ! blkid "$DB_DEVICE" > /dev/null 2>&1; then
  echo "First boot — formatting $DB_DEVICE"
  mkfs.ext4 "$DB_DEVICE"
fi

mkdir -p "$DB_MOUNT/postgres"
mount "$DB_DEVICE" "$DB_MOUNT"
mkdir -p "$DB_MOUNT/postgres"

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

  # ── PostgreSQL ──────────────────────────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: always
    environment:
      POSTGRES_DB: "${postgres_db}"
      POSTGRES_USER: "${postgres_user}"
      POSTGRES_PASSWORD: "${postgres_password}"
    volumes:
      - ${db_mount_point}/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${postgres_user} -d ${postgres_db}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s

  # ── pgAdmin ─────────────────────────────────────────────────────────────────
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    restart: always
    ports:
      - "${pgadmin_port}:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: "${pgadmin_email}"
      PGADMIN_DEFAULT_PASSWORD: "${pgadmin_password}"
      PGADMIN_CONFIG_SERVER_MODE: "True"
      PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION: "True"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    depends_on:
      postgres:
        condition: service_healthy

  # ── Flask App ────────────────────────────────────────────────────────────────
  flask_crud_app:
    image: ${docker_image}
    container_name: flask_crud_app
    restart: always
    expose:
      - "5000"
    environment:
      FLASK_ENV: "${flask_env}"
      SECRET_KEY: "${secret_key}"
      DATABASE_URL: "postgresql://${postgres_user}:${postgres_password}@postgres:5432/${postgres_db}"
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:5000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    logging:
      driver: "awslogs"
      options:
        awslogs-region: "${aws_region}"
        awslogs-group: "/${app_name}/app"
        awslogs-stream: "flask_crud_app"

  # ── Nginx ────────────────────────────────────────────────────────────────────
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
      driver: "awslogs"
      options:
        awslogs-region: "${aws_region}"
        awslogs-group: "/${app_name}/nginx"
        awslogs-stream: "nginx"

volumes:
  pgadmin_data:

COMPOSE

echo "docker-compose.yml written"

# ─── Pull all images ──────────────────────────────────────────────────────────
cd /app
/usr/local/bin/docker-compose pull

# ─── Start PostgreSQL first and wait for it to be healthy ────────────────────
/usr/local/bin/docker-compose up -d postgres

echo "Waiting for PostgreSQL to be ready..."
for i in {1..20}; do
  if docker exec postgres pg_isready -U "${postgres_user}" -d "${postgres_db}" > /dev/null 2>&1; then
    echo "PostgreSQL is ready."
    break
  fi
  echo "Waiting for PostgreSQL... ($i/20)"
  sleep 5
done

# ─── Run Flask-Migrate (flask db upgrade) ────────────────────────────────────
echo "Running flask db upgrade..."
docker run --rm \
  --network app_default \
  -e FLASK_ENV="${flask_env}" \
  -e SECRET_KEY="${secret_key}" \
  -e DATABASE_URL="postgresql://${postgres_user}:${postgres_password}@postgres:5432/${postgres_db}" \
  ${docker_image} \
  flask db upgrade \
  && echo "Migrations applied." \
  || echo "WARNING: flask db upgrade failed — check logs"

# ─── Start remaining services ─────────────────────────────────────────────────
/usr/local/bin/docker-compose up -d

# ─── Automatic cleanup ────────────────────────────────────────────────────────

# Limit systemd journal to 50MB
journalctl --vacuum-size=50M
sed -i 's/#SystemMaxUse=/SystemMaxUse=50M/' /etc/systemd/journald.conf || \
  echo "SystemMaxUse=50M" >> /etc/systemd/journald.conf
systemctl restart systemd-journald

# Weekly cron: pull latest image, restart containers, prune old images
# Daily cron: vacuum system journal
cat > /etc/cron.d/docker-cleanup << 'CRON'
# Every Sunday at 2am — pull latest image and prune unused Docker resources
0 2 * * 0 root /usr/local/bin/docker-compose -f /app/docker-compose.yml pull && /usr/local/bin/docker-compose -f /app/docker-compose.yml up -d && docker image prune -f
# Every day at 3am — vacuum system journal
0 3 * * * root journalctl --vacuum-size=50M
CRON

chmod 644 /etc/cron.d/docker-cleanup
echo "Cleanup cron jobs configured"

echo "=== Bootstrap complete ==="
echo "App:     http://$(curl -sf http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "pgAdmin: http://$(curl -sf http://169.254.169.254/latest/meta-data/public-ipv4):${pgadmin_port}"
