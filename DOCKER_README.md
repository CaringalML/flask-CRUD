# Flask CRUD — Docker Setup Guide

## Architecture

```
Client Request
    ↓
Nginx (Port 80) — Reverse Proxy
    ↓
Flask App (Port 5000) — Internal
    ↓
PostgreSQL (Port 5432) — Internal
```

## Quick Start with Docker Compose

Spins up all four services (Nginx + Flask + PostgreSQL + pgAdmin):

```bash
docker-compose up -d --build
```

This will:
- Build the Flask application image
- Start a PostgreSQL 16 database container
- Start pgAdmin 4 (database management UI)
- Start an Nginx reverse proxy
- All services automatically connected via Docker network
- Expose app on `http://localhost` (port 80)

## Standard Docker Commands

### Build the image:
```bash
docker build -t flask-crud .
```

### Run the container standalone:
```bash
docker run -p 5000:5000 \
  -e DATABASE_URL="postgresql://user:password@host.docker.internal:5432/flask_crud" \
  -e SECRET_KEY="your-secret-key" \
  flask-crud
```

## Using Docker Compose

### Start the stack:
```bash
docker-compose up -d
```

### Start with rebuild:
```bash
docker-compose up -d --build
```

### View logs:
```bash
# All services
docker-compose logs -f

# Flask only
docker-compose logs -f flask_crud_app

# Nginx only
docker-compose logs -f nginx

# PostgreSQL only
docker-compose logs -f postgres
```

### Stop the stack:
```bash
docker-compose down        # keep volumes (data preserved)
docker-compose down -v     # wipe volumes (fresh database)
```

### Rebuild containers after code changes:
```bash
docker-compose up -d --build
```

## Environment Variables

| Variable       | Description                              |
|----------------|------------------------------------------|
| `DATABASE_URL` | PostgreSQL connection string             |
| `SECRET_KEY`   | Flask session secret key                 |
| `FLASK_ENV`    | `production` or `development`            |

When using Docker Compose locally, set these in your `.env` file (never commit it):

```env
DATABASE_URL=postgresql://rence_caringal:your_password@postgres:5432/flask_crud
SECRET_KEY=your-flask-secret-key
```

> The host in `DATABASE_URL` must be `postgres` (the Docker service name) when running inside Docker, not `localhost`.

## Accessing the Services

| Service    | URL                    | Notes                          |
|------------|------------------------|--------------------------------|
| Flask App  | http://localhost       | Via Nginx reverse proxy        |
| pgAdmin 4  | http://localhost:5050  | PostgreSQL management UI       |

### pgAdmin login

Use the credentials from `docker-compose.yml` (or your `.env` overrides).

After login, click **Add New Server**:

| Field    | Value            |
|----------|------------------|
| Host     | `postgres`       |
| Port     | `5432`           |
| Database | `flask_crud`     |
| Username | `rence_caringal` |
| Password | your postgres password |

## Docker Services

### Nginx (port 80)
- Reverse proxy to Flask
- Gzip compression
- Static file caching (1 day)
- X-Forwarded headers for client IP
- WebSocket support
- Health check endpoint at `/health`
- Configurable via `nginx/nginx.conf`

### Flask App (internal, port 5000)
- Application container (Python 3.11 Alpine)
- Runs `flask db upgrade` automatically on start via `entrypoint.sh`
- ARM64 image (built for AWS Graviton2 t4g.micro)

### PostgreSQL 16 (internal, port 5432)
- Data persisted in Docker volume `postgres_data`
- Health check via `pg_isready`

### pgAdmin 4 (port 5050)
- Web-based PostgreSQL management UI
- Data persisted in Docker volume `pgadmin_data`

## Troubleshooting

### Database connection errors
Wait a few seconds for PostgreSQL to finish starting:
```bash
docker-compose logs postgres
```

### Nginx can't reach Flask (`502 Bad Gateway`)
Check if the Flask container is running and healthy:
```bash
docker-compose ps
docker-compose logs flask_crud_app
```

### `error checking context: open venv\lib64` on Windows
The `venv` folder is in the build context. Delete it before building:
```powershell
Remove-Item -Recurse -Force venv
docker-compose up -d --build
```

### `context canceled` on Windows Docker Desktop
BuildKit bug. Disable it:
```powershell
$env:DOCKER_BUILDKIT=0
docker-compose up -d --build
```

### Migrations not applied
The entrypoint runs `flask db upgrade` automatically. If it failed, check:
```bash
docker-compose logs flask_crud_app | grep -i migrat
```

## Useful Commands

```bash
# View running containers and health status
docker-compose ps

# Open a shell inside the Flask container
docker-compose exec flask_crud_app sh

# Run Flask shell (for debugging models)
docker-compose exec flask_crud_app python -m flask shell

# Restart a single service
docker-compose restart flask_crud_app

# Remove everything including volumes (full reset)
docker-compose down -v --remove-orphans
```
