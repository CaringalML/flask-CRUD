# Flask CRUD Docker Setup Guide

## Architecture

```
Client Request
    ↓
Nginx (Port 80) - Reverse Proxy
    ↓
Flask App (Port 5000) - Internal
    ↓
MySQL (Port 3306) - Internal
```

## Quick Start with Docker Compose

The easiest way to run the entire application (Nginx + Flask + MySQL) with Docker:

```bash
docker-compose up --build
```

This will:
- Build the Flask application image
- Start a MySQL 8.0 database container
- Start an Nginx reverse proxy
- All services automatically connected
- Expose on `http://localhost` (port 80)

## Standard Docker Commands

### Build the image:
```bash
docker build -t flask-crud .
```

### Run the container:
```bash
docker run -p 5000:5000 --env DATABASE_URL="mysql+pymysql://root:password@host.docker.internal:3306/flask_crud" flask-crud
```

## Using Docker Compose

### Start the application:
```bash
docker-compose up
```

### Run in background:
```bash
docker-compose up -d
```

### View logs:
```bash
docker-compose logs -f web
docker-compose logs -f nginx
docker-compose logs -f db
```

### View specific service logs:
```bash
# Flask logs
docker-compose logs -f web

# Nginx logs
docker-compose logs -f nginx

# MySQL logs
docker-compose logs -f db
```

### Stop the application:
```bash
docker-compose down
```

### Stop and remove volumes:
```bash
docker-compose down -v
```

## Environment Variables

When using Docker Compose, the following are automatically set:
- `DATABASE_URL=mysql+pymysql://root:root@db:3306/flask_crud`
- `FLASK_ENV=development`

## Accessing the Application

- **Web Application**: http://localhost (via Nginx)
- **Direct Flask**: localhost:5000 (only internal, not exposed)
- **phpMyAdmin**: http://localhost:8080
  - Username: `root`
  - Password: `root`
- **MySQL Database**: localhost:3306
  - Username: `root`
  - Password: `root`
  - Database: `flask_crud`

## Nginx Features

- ✅ Reverse proxy to Flask app
- ✅ Gzip compression for static files
- ✅ Static file caching (1 day)
- ✅ X-Forwarded headers for proper client IP
- ✅ WebSocket support
- ✅ Health check endpoint
- ✅ Request timeouts configured

## Docker Services

### Nginx (80)
- Reverse proxy
- Static file serving
- Compression
- Health checks

### Flask App (internal)
- WSGI application
- Database connection
- Business logic

### MySQL (3306)
- Data persistence
- Health monitoring

### phpMyAdmin (8080)
- Database management UI
- Query builder
- Data import/export
- User management

## Troubleshooting

### Database connection errors
Wait a few seconds for MySQL to fully start:
```bash
docker-compose logs db
```

### Nginx can't connect to Flask
Check if Flask container is running:
```bash
docker-compose ps
```

### Rebuild containers after code changes
```bash
docker-compose up --build
```

### Access MySQL from host machine
```bash
mysql -h 127.0.0.1 -u root -proot flask_crud
```

### Check container network
```bash
docker network ls
docker network inspect flask_crud_flask_network
```

## Production Deployment

For production, modify configurations:

1. **Update Nginx** (`nginx/nginx.conf`):
   - Add SSL/TLS certificates
   - Configure domain name
   - Add rate limiting
   - Configure security headers

2. **Update Flask** (`app.py`):
   - Set `FLASK_ENV=production`
   - Use Gunicorn instead of Flask dev server

3. **Update docker-compose.yml**:
   - Remove ports for internal services
   - Add volume for SSL certificates
   - Configure environment variables

Example Gunicorn command:
```bash
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--timeout", "60", "app:create_app()"]
```

## Useful Commands

```bash
# View running containers
docker-compose ps

# Execute command in container
docker-compose exec web python shell

# View container details
docker-compose logs nginx

# Restart a service
docker-compose restart web

# Scale service (development only)
docker-compose up --scale web=3

# Remove everything
docker-compose down -v --remove-orphans
```
