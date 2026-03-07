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

  # ── Flask App ────────────────────────────────────────────────────────────────
  # Database is Supabase (external) — no local postgres container needed
  flask_crud_app:
    image: ${docker_image}
    container_name: flask_crud_app
    restart: always
    expose:
      - "5000"
    environment:
      FLASK_ENV: "${flask_env}"
      SECRET_KEY: "${secret_key}"
      SUPABASE_URL: "${supabase_url}"
      SUPABASE_KEY: "${supabase_key}"
      DATABASE_URL: "${database_url}"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:5000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

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

COMPOSE

echo "docker-compose.yml written"

# ─── Pull images and start ────────────────────────────────────────────────────
cd /app
/usr/local/bin/docker-compose pull
/usr/local/bin/docker-compose up -d

echo "=== Bootstrap complete ==="
echo "App: http://$(curl -sf http://169.254.169.254/latest/meta-data/public-ipv4)"
