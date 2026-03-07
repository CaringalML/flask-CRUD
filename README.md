# Flask CRUD App — PostgreSQL + Docker + AWS EC2

A modern full-stack CRUD application built with **Flask**, **PostgreSQL**, **SQLAlchemy**, **Flask-Migrate**, **HTMX**, **Alpine.js**, and **Bootstrap 5**. Features inline editing, toast notifications, client-side filtering, database migrations, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                                                        |
|------------|-------------------------------------------------------------------|
| Backend    | Flask 3.0, SQLAlchemy, Flask-Migrate                              |
| Database   | PostgreSQL 16 (Docker container, data stored on AWS EBS)          |
| Frontend   | HTMX 2.0 + Alpine.js 3.14                                        |
| Styling    | Bootstrap 5.3 + Custom CSS overrides                              |
| Proxy      | Nginx Alpine                                                      |
| Deployment | Docker Compose + Terraform (AWS EC2 t4g.micro) + GitHub Actions   |

---

## Branch Overview

| Branch | Database   | Notes                                                        |
|--------|------------|--------------------------------------------------------------|
| `v3`   | PostgreSQL | Local PostgreSQL + psycopg2                                  |
| `v4`   | SQLite     | Zero setup, file-based, deployed on AWS EC2                  |
| `v5`   | PostgreSQL | Docker Compose + pgAdmin + AWS EC2 with EBS persistent data  |

---

## Project Structure

```
flask_crud/
├── app.py                  # Flask application factory
├── extensions.py           # SQLAlchemy + Flask-Migrate initialisation
├── models.py               # SQLAlchemy ORM models (source of truth for schema)
├── routes.py               # All routes (standard + HTMX endpoints)
├── requirements.txt        # Python dependencies
├── Dockerfile              # App container (Python 3.11 Alpine, ARM64)
├── entrypoint.sh           # Runs flask db upgrade then starts the app
├── docker-compose.yml      # Local dev: postgres + pgadmin + flask + nginx
├── .env                    # Environment variables (DO NOT COMMIT)
├── migrations/             # Alembic database migration files
│   ├── alembic.ini
│   ├── env.py
│   └── versions/           # Auto-generated migration scripts
├── static/
│   └── style.css           # Custom CSS overrides on top of Bootstrap
├── templates/
│   ├── base.html           # Layout with Bootstrap, navbar, toasts, HTMX/Alpine
│   ├── index.html          # Items list page with search/filter
│   ├── form.html           # Create / Edit form page
│   └── partials/
│       ├── item_card.html     # Single item card partial (HTMX swap target)
│       ├── item_edit.html     # Inline edit form partial
│       ├── form_success.html  # Success message partial
│       └── form_error.html    # Error message partial
├── nginx/
│   ├── Dockerfile          # Nginx Alpine container (ARM64)
│   └── nginx.conf          # Reverse proxy config
└── terraform-aws/          # AWS infrastructure (v5)
    ├── versions.tf          # Terraform + provider versions
    ├── vpc.tf               # VPC, subnet, IGW, route table
    ├── security_groups.tf   # App (80/443/22), pgAdmin (5050), postgres (5432)
    ├── ebs.tf               # 10GB EBS volume for PostgreSQL data
    ├── ec2.tf               # t4g.micro instance, key pair, Elastic IP
    ├── variables.tf         # All configurable variables
    ├── outputs.tf           # IP, URLs, SSH command after deploy
    ├── user_data.sh         # Bootstrap: Docker install, EBS mount, compose up
    ├── terraform.tfvars.example  # Copy to terraform.tfvars and fill secrets
    └── .gitignore           # Excludes tfstate and tfvars from git
```

---

## Features

- **Full CRUD** — Create, Read, Update, Delete items
- **HTMX-powered** — Inline editing, partial page swaps, no full reloads
- **Alpine.js** — Toast notifications, flash message auto-dismiss, mobile nav, client-side search filter
- **Non-HTMX fallback** — Standard form-based routes for full compatibility
- **Database Migrations** — Flask-Migrate (Alembic) for version-controlled schema changes
- **Auto-migrate on startup** — `entrypoint.sh` runs `flask db upgrade` every time the container starts
- **Bootstrap 5** — Responsive framework with custom design overrides
- **Docker Compose** — Full local stack: PostgreSQL + pgAdmin + Flask + Nginx
- **AWS deployable** — Terraform config for EC2 with persistent EBS storage
- **CI/CD** — GitHub Actions auto-deploys on push to `v5`

---

## Local Development (Docker Compose)

The easiest way to run v5 locally is with Docker Compose. It spins up all four services automatically.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Git

### 1. Clone and switch to v5

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD
git checkout v5
```

### 2. Create your `.env` file

```bash
cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL=postgresql://rence_caringal:your_password@postgres:5432/flask_crud
SECRET_KEY=your-flask-secret-key
```

> **Note:** The host is `postgres` (the Docker service name), not `localhost`.

### 3. Start the stack

```powershell
# Windows — disable BuildKit if you hit cancellation errors
$env:DOCKER_BUILDKIT=0
docker-compose up -d --build
```

```bash
# macOS / Linux
docker-compose up -d --build
```

### 4. Access the services

| Service   | URL                    |
|-----------|------------------------|
| Flask app | http://localhost       |
| pgAdmin   | http://localhost:5050  |

### 5. Connect pgAdmin to PostgreSQL

After logging into pgAdmin, click **Add New Server**:

| Field    | Value            |
|----------|------------------|
| Name     | `flask_crud`     |
| Host     | `postgres`       |
| Port     | `5432`           |
| Database | `flask_crud`     |
| Username | `rence_caringal` |
| Password | your postgres password |

> **Note:** Use `postgres` as the host — pgAdmin runs inside Docker and reaches the postgres container via the Docker network, not via `localhost`.

### 6. Stop the stack

```bash
docker-compose down        # keep data
docker-compose down -v     # wipe all volumes (fresh start)
```

---

## Auto-Migration on Container Start

The `entrypoint.sh` script runs automatically every time the Flask container starts:

```bash
#!/bin/sh
set -e
echo "Running database migrations..."
flask db upgrade
echo "Starting Flask app..."
exec python app.py
```

This means:
- Fresh deploy → tables are created automatically ✅
- New migration added → applied on next container restart ✅
- Already up to date → Alembic skips silently ✅

No need to manually run `flask db upgrade` after deploying.

---

## Database Migrations

This project uses **Flask-Migrate** (Alembic) for schema management.

### Quick Reference

| Command                                      | Description                           |
|----------------------------------------------|---------------------------------------|
| `python -m flask db init`                    | One-time setup (already done)         |
| `python -m flask db migrate -m "message"`    | Generate migration from model changes |
| `python -m flask db upgrade`                 | Apply pending migrations              |
| `python -m flask db downgrade`               | Rollback last migration               |
| `python -m flask db history`                 | Show all migrations                   |
| `python -m flask db current`                 | Show current migration version        |

### Workflow

1. Edit the model in [models.py](models.py)
2. Generate the migration: `python -m flask db migrate -m "describe change"`
3. Apply it: `python -m flask db upgrade`

> **Important:** Always start from [models.py](models.py). The model is the source of truth.

---

## Environment Variables

| Variable       | Description                                      |
|----------------|--------------------------------------------------|
| `DATABASE_URL` | PostgreSQL connection string                     |
| `SECRET_KEY`   | Flask session secret — set to any random string  |

Generate a secure secret key:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

---

## AWS EC2 Deployment (v5 — Terraform)

The `terraform-aws/` directory deploys the full stack on a **t4g.micro** (AWS Graviton2, ARM64) in Mumbai (`ap-south-1`).

### Architecture

```
Internet → Elastic IP (static) → EC2 t4g.micro (ap-south-1)
                                        ├── nginx:alpine        (port 80)
                                        ├── flask_crud_app      (port 5000)
                                        ├── postgres:16-alpine  (port 5432)
                                        └── pgadmin4            (port 5050)
                                                 ↓
                                        EBS Volume /dev/xvdf
                                        mounted at /data
                                        PostgreSQL data → /data/postgres
```

### Monthly Cost (~USD)

| Resource           | Cost       |
|--------------------|------------|
| t4g.micro Mumbai   | ~$6.05     |
| EBS 10 GiB gp3     | ~$0.80     |
| EBS 30 GiB root    | ~$2.40     |
| Elastic IP         | $0.00      |
| **Total**          | **~$9.25** |

---

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured (`aws configure`)
- An SSH key pair (see below)

---

### Generating an SSH Key Pair

You need an SSH key pair to access the EC2 instance. Terraform reads your **public key** and uploads it to AWS automatically. You keep the **private key** and use it to SSH in.

#### Windows (PowerShell)

```powershell
# Create the .ssh directory if it doesn't exist
mkdir "$env:USERPROFILE\.ssh"

# Generate a 4096-bit RSA key pair
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N '""'

# Verify both files exist
ls ~/.ssh
# Should show: id_rsa   and   id_rsa.pub
```

#### macOS / Linux

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Verify
ls ~/.ssh
# Should show: id_rsa   and   id_rsa.pub
```

| File         | Description                                         |
|--------------|-----------------------------------------------------|
| `id_rsa`     | **Private key** — keep this safe, never share it    |
| `id_rsa.pub` | **Public key** — Terraform uploads this to AWS      |

How it works:
```
Your machine holds: id_rsa  (private key — the lock key)
AWS EC2 stores:     id_rsa.pub  (public key — the lock itself)

When you SSH:
ssh -i ~/.ssh/id_rsa ec2-user@<ip>
→ Your private key matches the public key on EC2
→ Access granted, no password needed
```

> **Important:** If you lose your private key you cannot SSH into the instance. You would need to recreate it with `terraform destroy` + `terraform apply`.

---

### Configure terraform.tfvars

```powershell
cd terraform-aws
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region          = "ap-south-1"
instance_type       = "t4g.micro"
flask_secret_key    = "your-generated-secret-key"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
ssh_allowed_cidr    = "0.0.0.0/0"
db_volume_size_gb   = 10

postgres_db         = "flask_crud"
postgres_user       = "rence_caringal"
postgres_password   = "your-postgres-password"

pgadmin_email       = "your@email.com"
pgadmin_password    = "your-pgadmin-password"
pgadmin_port        = 5050
```

---

### Deploy

```powershell
cd terraform-aws

terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. After apply, Terraform outputs:

```
app_url        = "http://<elastic-ip>"
pgadmin_url    = "http://<elastic-ip>:5050"
public_ip      = "<elastic-ip>"
ssh_command    = "ssh -i ~/.ssh/id_rsa ec2-user@<elastic-ip>"
bootstrap_log  = "sudo cat /var/log/user_data.log"
view_logs      = "cd /app && docker-compose logs -f"
```

> **First boot takes 3–5 minutes.** The instance installs Docker, pulls all images, and starts all containers. Wait before visiting `app_url`.

---

### How Data Persists (EBS Volume Explained)

PostgreSQL data is stored on a dedicated **EBS (Elastic Block Store) volume** — completely separate from the EC2 root disk. Think of it exactly like a USB drive attached to the server: you can destroy and recreate the server, but the USB drive and all its data remains untouched.

#### The two volumes in your AWS Console

| Volume             | Size   | What it is                                             |
|--------------------|--------|--------------------------------------------------------|
| `salon-booking-db` | 10 GiB | Your custom EBS — PostgreSQL data, survives forever    |
| (root volume)      | 30 GiB | EC2 OS disk — auto-created, deleted on termination     |

```
30 GiB root volume  =  internal hard drive (OS, Docker, app code)
10 GiB EBS volume   =  USB drive (only your database)

Instance dies  →  internal hard drive gone, USB drive safe ✅
New instance   →  plug USB drive back in, data restored ✅
```

#### Step-by-step: how the EBS gets connected

**Step 1 — Terraform creates and attaches EBS (`ebs.tf`):**

```hcl
resource "aws_ebs_volume" "postgres" {
  size = 10      # 10GB dedicated disk
  type = "gp3"

  lifecycle {
    prevent_destroy = true   # refuses terraform destroy — data protected
  }
}

resource "aws_volume_attachment" "postgres" {
  device_name = "/dev/xvdf"   # EBS visible to EC2 at this device name
  volume_id   = aws_ebs_volume.postgres.id
  instance_id = aws_instance.app.id
}
```

At this point EBS is physically attached as `/dev/xvdf` — like plugging in a USB drive. But it's not accessible yet.

**Step 2 — `user_data.sh` formats and mounts it:**

```bash
# Format only on first boot (blank disk)
if ! blkid /dev/xvdf > /dev/null 2>&1; then
  mkfs.ext4 /dev/xvdf        # format the disk (like formatting a new USB)
fi

mkdir -p /data/postgres
mount /dev/xvdf /data         # /data is now the EBS disk
```

`/data` is not a folder that copies data to EBS — `/data` **IS** the EBS disk. Writing to `/data` writes directly onto the physical EBS volume. `/data` is just the door Linux uses to access it.

**Step 3 — Persist the mount across reboots (`/etc/fstab`):**

```bash
echo "/dev/xvdf /data ext4 defaults,nofail 0 2" >> /etc/fstab
```

Without this, the mount would be lost after every reboot and `/data` would be empty.

**Step 4 — `docker-compose.yml` maps the EBS path into the PostgreSQL container:**

```yaml
postgres:
  volumes:
    - /data/postgres:/var/lib/postgresql/data
    #   ↑ path on EC2 (on EBS)    ↑ PostgreSQL's data directory inside container
```

Docker maps `/data/postgres` (which lives on EBS) into the container as its data directory. PostgreSQL thinks it's writing to `/var/lib/postgresql/data` but it's actually writing to EBS.

#### The complete chain

```
PostgreSQL writes to /var/lib/postgresql/data  (inside container)
                ↕  Docker bind mount  (docker-compose volumes:)
           /data/postgres             (folder on EC2)
                ↕  Linux mount point  (mount /dev/xvdf /data)
           /dev/xvdf                  (physical EBS device)
                ↕  AWS attachment     (aws_volume_attachment)
           EBS Volume                 (10GB, persists forever)
```

#### /data is just a bridge

```
/dev/xvdf  =  the physical EBS disk (the hardware)
/data      =  the mount point Linux uses to reach it

"mount /dev/xvdf /data" means:
→ When anyone accesses /data, they are talking directly to /dev/xvdf
→ No copy, no transfer — same thing
```

Analogy:
```
USB drive  =  /dev/xvdf    (the actual hardware)
E:\ drive  =  /data        (Windows label to access it)

Write to E:\file.txt  →  goes directly onto the USB
Write to /data/file   →  goes directly onto EBS
```

#### What survives what

| Event                        | Root Disk | EBS (PostgreSQL data)  |
|------------------------------|-----------|------------------------|
| Container restart            | ✅ Safe   | ✅ Safe                |
| New image deploy             | ✅ Safe   | ✅ Safe                |
| EC2 instance terminated      | ❌ Lost   | ✅ Safe                |
| `terraform destroy`          | ❌ Lost   | ✅ Safe*               |

*`prevent_destroy = true` means Terraform refuses to delete it even during `terraform destroy`.

#### What happens when you terminate and recreate

```
terraform apply  (new instance)
        │
        ├── EBS volume already exists → skip creation
        ├── Attach SAME EBS to new EC2 as /dev/xvdf
        │
        └── user_data.sh runs on new instance
                │
                ├── blkid /dev/xvdf → already formatted → SKIP mkfs
                ├── mount /dev/xvdf /data → /data/postgres has all old data
                └── docker-compose up → PostgreSQL reads existing data ✅
```

---

### Useful Commands After Deploy

```bash
# SSH into the instance
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>

# Check bootstrap log (runs on first boot)
sudo cat /var/log/user_data.log

# View running containers
docker ps

# View all logs
cd /app && docker-compose logs -f

# View just Flask logs
cd /app && docker-compose logs -f flask_crud_app

# View just PostgreSQL logs
docker logs -f postgres

# Restart all containers
cd /app && docker-compose restart

# Pull latest image and redeploy
cd /app && docker-compose pull && docker-compose up -d
```

---

### Destroying Infrastructure

```bash
terraform destroy
```

> ⚠️ The EBS volume has `prevent_destroy = true` — Terraform will **refuse** to delete it.
> To fully destroy including the EBS volume, first remove the `lifecycle` block from `ebs.tf`, then run `terraform destroy`.

> 💡 Back up the database before destroying:
> ```bash
> ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
> docker exec postgres pg_dump -U rence_caringal flask_crud > backup.sql
> ```

---

## CI/CD — GitHub Actions

On every push to `v5`, GitHub Actions automatically:

1. Installs `libpq-dev` and Python dependencies
2. Runs Python syntax checks
3. Builds ARM64 Docker image
4. Pushes to Docker Hub
5. SSHes into EC2 and redeploys with the new image

### Required GitHub Secrets

Go to **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**:

| Secret               | Value                                             |
|----------------------|---------------------------------------------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username                          |
| `DOCKERHUB_TOKEN`    | Your Docker Hub access token                      |
| `EC2_HOST`           | Your Elastic IP e.g. `52.66.112.103`              |
| `EC2_SSH_KEY`        | Full contents of `~/.ssh/id_rsa` (private key)    |

To get your private key contents:

```powershell
cat ~/.ssh/id_rsa
```

Copy the entire output including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`.

### Deploy Flow

```
git push origin v5
        ↓
GitHub Actions (ubuntu ARM64 runner)
        ↓
Install libpq-dev → pip install → syntax check
        ↓
Build ARM64 Docker image → Push to Docker Hub
        ↓
SSH into EC2 → docker-compose pull → docker-compose up -d
        ↓
Live in ~2–3 minutes
```

---

## Routing

| Endpoint                  | Method   | Type | Description                   |
|---------------------------|----------|------|-------------------------------|
| `/`                       | GET      | Page | List all items                |
| `/create`                 | GET/POST | Page | Create item form              |
| `/edit/<id>`              | GET/POST | Page | Edit item form (fallback)     |
| `/delete/<id>`            | POST     | Page | Delete item (fallback)        |
| `/htmx/create`            | POST     | HTMX | Create item via HTMX          |
| `/htmx/items/<id>`        | PUT      | HTMX | Inline update item            |
| `/htmx/items/<id>`        | DELETE   | HTMX | Delete item (removes card)    |
| `/htmx/items/<id>/edit`   | GET      | HTMX | Get inline edit form          |
| `/htmx/items/<id>/card`   | GET      | HTMX | Get single item card          |
| `/htmx/edit/<id>`         | POST     | HTMX | Edit from dedicated form page |

---

## Troubleshooting

### `ModuleNotFoundError: No module named 'psycopg2'`
The Docker image on Docker Hub is outdated. Rebuild and push:
```powershell
$env:DOCKER_BUILDKIT=0
docker build -t rencecaringal000/flask-crud:latest .
docker push rencecaringal000/flask-crud:latest
```

### `502 Bad Gateway` after terraform apply
Instance is still bootstrapping. Wait 3–5 minutes then refresh. Check progress:
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
sudo cat /var/log/user_data.log
```

### `Error loading items: relation "items" does not exist`
Migrations haven't run yet. Rebuild with the entrypoint (auto-runs migrations):
```bash
docker-compose down && docker-compose up -d --build
```

### `context canceled` when building on Windows Docker Desktop
BuildKit bug. Disable it:
```powershell
$env:DOCKER_BUILDKIT=0
docker build -t flask-crud-test .
```

### `error checking context: open venv\lib64`
The `venv` folder is in the build context. Delete it:
```powershell
Remove-Item -Recurse -Force venv
docker build -t flask-crud-test .
```
Recreate after building:
```powershell
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### `OperationalError: could not connect to server`
- Check `DATABASE_URL` in `.env` is correct
- Running locally (not Docker): use `localhost` as host
- Running inside Docker: use `postgres` as host

### `Can't locate revision` error during migration
Reinitialise migrations:
```powershell
Remove-Item -Recurse -Force migrations   # Windows
# rm -rf migrations/                     # macOS/Linux
```
Then: `flask db init` → `flask db migrate` → `flask db upgrade`

### EC2 instance not accessible after deploy
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
sudo cat /var/log/user_data.log    # check bootstrap
docker ps                          # check containers
cd /app && docker-compose logs -f  # check app logs
```

---

## Data Export & Import (SQLite → PostgreSQL)

If migrating from v4 (SQLite) to v5 (PostgreSQL):

### Export from SQLite (v4)

```bash
python -m flask shell
```

```python
from models import Item
import json

items = [item.to_dict() for item in Item.query.all()]
with open('export.json', 'w') as f:
    json.dump(items, f, indent=2, default=str)
print(f"Exported {len(items)} items")
exit()
```

### Import into PostgreSQL (v5)

```bash
python -m flask shell
```

```python
from models import Item
from extensions import db
import json

with open('export.json') as f:
    items = json.load(f)

for i in items:
    item = Item(name=i['name'], description=i['description'], status=i['status'])
    db.session.add(item)

db.session.commit()
print(f"Imported {len(items)} items")
exit()
```

---

## License

MIT