# Flask CRUD App — v4: SQLite + Docker + AWS EC2

A modern full-stack CRUD application built with **Flask**, **SQLite**, **SQLAlchemy**, **Flask-Migrate**, **HTMX**, **Alpine.js**, and **Bootstrap 5**. Features inline editing, toast notifications, client-side filtering, database migrations, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                                                      |
|------------|-----------------------------------------------------------------|
| Backend    | Flask 3.0, SQLAlchemy, Flask-Migrate                            |
| Database   | SQLite (file-based, stored on EBS in production)                |
| Frontend   | HTMX 2.0 + Alpine.js 3.14                                       |
| Styling    | Bootstrap 5.3 + Custom CSS overrides                            |
| Proxy      | Nginx Alpine                                                    |
| Deployment | Docker Compose + Terraform (AWS EC2 t4g.nano) + GitHub Actions  |
| Logging    | AWS CloudWatch (3 log groups, 7-day retention)                  |

---

## Branch Overview

| Branch | Database   | Hosting | Notes |
|--------|------------|---------|-------|
| `v2`   | Supabase (PostgreSQL) | AWS EC2 t4g.nano | Realtime websocket, ~$2.68/mo |
| `v4`   | SQLite on EBS | AWS EC2 t4g.nano | Zero DB setup, ~$3.08/mo |
| `v5`   | PostgreSQL on EBS | AWS EC2 t4g.micro | Full PostgreSQL + pgAdmin, ~$9.25/mo |
| `v6`   | SQLite file | PythonAnywhere | Free tier, WSGI deployment |

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
│   └── nginx.conf          # Reverse proxy configuration
└── terraform-aws/          # AWS EC2 Terraform infrastructure
    ├── versions.tf          # Terraform + provider versions
    ├── vpc.tf               # VPC, subnet, IGW, route table
    ├── security_groups.tf   # App SG (HTTP/HTTPS/SSH)
    ├── ec2.tf               # t4g.nano instance, key pair, Elastic IP
    ├── ebs.tf               # EBS volume for SQLite persistence
    ├── cloudwatch.tf        # IAM role, log groups, CloudWatch agent
    ├── variables.tf         # All configurable variables
    ├── outputs.tf           # IP, app URL, SSH command, CloudWatch URLs
    ├── user_data.sh         # Bootstrap: Docker install, EBS mount, compose up, crons
    ├── terraform.tfvars.example  # Copy to terraform.tfvars and fill secrets
    └── .gitignore           # Excludes tfstate and tfvars from git
```

---

## Features

- **Full CRUD** — Create, Read, Update, Delete items
- **HTMX-powered** — Inline editing, partial page swaps, no full reloads
- **Alpine.js** — Toast notifications, flash message auto-dismiss, mobile nav, client-side search/filter
- **Non-HTMX fallback** — Standard form-based routes for full compatibility
- **Database Migrations** — Flask-Migrate (Alembic) for version-controlled schema changes
- **Responsive** — Mobile-first design with sticky navbar
- **Docker ready** — Containerised with Nginx reverse proxy (ARM64)
- **AWS deployable** — Terraform config for EC2 t4g.nano with own VPC and persistent EBS storage
- **CloudWatch logs** — All container logs shipped to AWS CloudWatch (no SSH needed)
- **Auto cleanup** — Weekly Docker prune + daily journal vacuum cron jobs
- **CI/CD** — GitHub Actions auto-deploys on push to `v4`

---

## Environment Variables

Create a `.env` file in the project root:

```env
SECRET_KEY=your-flask-secret-key
DATABASE_URL=sqlite:///flask_crud.db
```

| Variable       | Description                                                        |
|----------------|--------------------------------------------------------------------|
| `SECRET_KEY`   | Flask session secret — set to any random string                    |
| `DATABASE_URL` | SQLite path (omit to use project root default `flask_crud.db`)     |

> In production on EC2, `DATABASE_URL` is set to `sqlite:////data/flask_crud.db` pointing to the EBS volume.

---

## Local Development

### Prerequisites

- Python 3.11+
- Nothing else — SQLite is built into Python

### 1. Clone and switch to v4

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD
git checkout v4
```

### 2. Create a virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

> `requirements.txt`:
> ```
> flask==3.0.0
> flask-sqlalchemy==3.1.1
> flask-migrate==4.0.7
> psycopg2-binary==2.9.9
> python-dotenv==1.0.0
> ```
> `psycopg2-binary` is included for GitHub Actions compatibility — not needed for local SQLite use.

### 4. Configure environment variables

```bash
cp .env.example .env
# Edit .env — SECRET_KEY is the only required value
```

### 5. Run migrations

```bash
flask db upgrade
```

### 6. Run the application

```bash
python app.py
```

App available at **http://localhost:5000**.

---

## Database Migrations

This project uses **Flask-Migrate** (Alembic) for schema management.

### Quick Reference

| Command | Description |
|---|---|
| `flask db init` | One-time setup (already done) |
| `flask db migrate -m "message"` | Generate migration from model changes |
| `flask db upgrade` | Apply pending migrations |
| `flask db downgrade` | Rollback last migration |
| `flask db history` | Show all migrations |
| `flask db current` | Show current migration version |

### Workflow

1. Edit the model in [models.py](models.py)
2. Generate: `flask db migrate -m "describe change"`
3. Apply: `flask db upgrade`

> **Important:** Always edit [models.py](models.py) first — it's the source of truth. Never create migration files manually without updating the model.

### Regenerating Migrations from Scratch

If migrations get out of sync (e.g. switching from Supabase/PostgreSQL to SQLite):

```powershell
# Windows
Remove-Item -Recurse -Force migrations
Remove-Item -Force flask_crud.db

# macOS / Linux
rm -rf migrations/
rm -f flask_crud.db
```

Then reinitialise:

```bash
flask db init
flask db migrate -m "initial sqlite schema"
flask db upgrade
```

---

## How It Works

### Database Connection

SQLAlchemy and Flask-Migrate are initialised in [extensions.py](extensions.py):

```python
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()
```

The app factory in [app.py](app.py) falls back to SQLite when `DATABASE_URL` is not set:

```python
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
    'DATABASE_URL',
    'sqlite:///' + os.path.join(basedir, 'flask_crud.db')
)
```

### Architecture

```
Internet → Elastic IP (static) → EC2 t4g.nano (ap-south-1, own VPC)
                                        ├── nginx:alpine   (port 80)
                                        └── flask_crud_app (port 5000)
                                                  └── SQLite on EBS (/data/flask_crud.db)
```

### How Data Persists

The SQLite database lives on a separate **EBS volume**, not inside the container or EC2 root disk:

```
Flask writes → /data/flask_crud.db (inside container)
                    ↓ Docker volume mount
               /data on EC2 instance
                    ↓ Linux mount
               EBS volume /dev/xvdf
```

| Event | Container | EBS Data |
|---|---|---|
| Container restart | Reset | ✅ Safe |
| New image deploy | Reset | ✅ Safe |
| EC2 instance terminated | Lost | ✅ Safe |
| `terraform destroy` | Lost | ⚠️ Destroyed (`prevent_destroy = false`) |

> Set `prevent_destroy = true` in `ebs.tf` once you have real data to protect.

### Routing

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

## AWS EC2 Deployment (Terraform)

The `terraform-aws/` directory deploys the app on a **t4g.nano** (AWS Graviton2, ARM64) in Mumbai (`ap-south-1`) inside its own dedicated VPC with a separate EBS volume for SQLite persistence.

### Monthly Cost (~USD)

| Resource           | Cost      |
|--------------------|-----------|
| t4g.nano Mumbai    | ~$2.04    |
| EBS 8 GiB root     | ~$0.64    |
| EBS 5 GiB data     | ~$0.40    |
| Elastic IP         | $0.00     |
| CloudWatch logs    | ~$0.00    |
| **Total**          | **~$3.08** |

> Root volume is 8 GiB (shrunk from AWS default 30 GiB) — saves ~$1.76/mo.

---

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured (`aws configure`)
- An SSH key pair (see below)

---

### Generating an SSH Key Pair

#### Windows (PowerShell)

```powershell
mkdir "$env:USERPROFILE\.ssh"
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N '""'
ls ~/.ssh
# Should show: id_rsa   and   id_rsa.pub
```

#### macOS / Linux

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
ls ~/.ssh
```

| File | Description |
|---|---|
| `id_rsa` | Private key — keep safe, never share |
| `id_rsa.pub` | Public key — Terraform uploads this to AWS |

---

### Configure terraform.tfvars

```powershell
cd terraform-aws
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region          = "ap-south-1"
app_name            = "salon-booking"
instance_type       = "t4g.nano"
docker_image        = "your-dockerhub-username/flask-crud:latest"
flask_env           = "production"
flask_secret_key    = "replace-with-a-long-random-string"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
ssh_allowed_cidr    = "0.0.0.0/0"
db_volume_size_gb   = 5
```

---

### Deploy

```powershell
cd terraform-aws
terraform init
terraform plan
terraform apply
```

After apply, Terraform outputs:

```
app_url                   = "http://<elastic-ip>"
public_ip                 = "<elastic-ip>"
ssh_command               = "ssh -i ~/.ssh/id_rsa ec2-user@<elastic-ip>"
cloudwatch_app_logs       = "https://ap-south-1.console.aws.amazon.com/cloudwatch/..."
cloudwatch_nginx_logs     = "https://ap-south-1.console.aws.amazon.com/cloudwatch/..."
cloudwatch_bootstrap_logs = "https://ap-south-1.console.aws.amazon.com/cloudwatch/..."
```

> **First boot takes 2–3 minutes.** The instance installs Docker, CloudWatch agent, mounts EBS, runs migrations, and starts containers.

---

## CloudWatch Logs

All container logs are shipped to AWS CloudWatch automatically — no SSH needed for day-to-day debugging.

| Log Group | Stream | Contains |
|---|---|---|
| `/<app_name>/app` | `flask_crud_app` | Flask app logs, HTTP request logs |
| `/<app_name>/nginx` | `nginx` | HTTP access logs, 502 errors |
| `/<app_name>/bootstrap` | `{instance_id}/user_data` | First-boot log, Docker install output |

All log groups have **7-day retention**.

**View logs:** AWS Console → **CloudWatch** → **Log groups** → click the group → click the stream.

> The bootstrap log only runs **once on first boot** — subsequent deploys are handled by GitHub Actions.

---

## Auto Cleanup

| Schedule | Job |
|---|---|
| Every Sunday 2am | `docker image prune -f` — removes old layers after deploys |
| Every day 3am | `journalctl --vacuum-size=50M` — trims system journal |

---

### Useful Commands After Deploy

```bash
# SSH into the instance
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>

# View running containers
docker ps

# View logs (or use CloudWatch instead)
cd /app && docker-compose logs -f

# Pull latest image and redeploy manually
cd /app && docker-compose pull && docker-compose up -d

# Backup SQLite database before destroying
scp -i ~/.ssh/id_rsa ec2-user@<public_ip>:/data/flask_crud.db ./backup.db
```

---

### Destroying Infrastructure

```powershell
terraform destroy
```

> ⚠️ `prevent_destroy = false` on the EBS volume — the SQLite database **will be deleted**. Back it up first:
> ```bash
> scp -i ~/.ssh/id_rsa ec2-user@<public_ip>:/data/flask_crud.db ./backup.db
> ```

---

## CI/CD — GitHub Actions

On every push to `v4`, GitHub Actions automatically:

1. Runs `apt-get update && apt-get install -y libpq-dev` (required for psycopg2)
2. Installs Python dependencies and runs syntax checks
3. Builds ARM64 Docker image
4. Pushes to Docker Hub
5. SSHes into EC2 and redeploys with `docker-compose pull && docker-compose up -d`

### Required GitHub Secrets

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Your Docker Hub access token |
| `EC2_HOST_V4` | Your v4 Elastic IP |
| `EC2_SSH_KEY` | Full contents of `~/.ssh/id_rsa` (private key) |

> Note: v4 uses `EC2_HOST_V4` (not `EC2_HOST`) to avoid conflicting with v2's secret.

---

## Data Export & Import

### Export from SQLite

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

### Import into PostgreSQL (when migrating to v5)

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

## PythonAnywhere Deployment (Free Tier)

SQLite works on PythonAnywhere's free Beginner plan. See the [v6 branch](https://github.com/CaringalML/flask-CRUD/tree/v6) which is purpose-built for PythonAnywhere deployment.

---

## Troubleshooting

### `supabase_url is required` on startup
`extensions.py` still has the Supabase SDK from v2. Replace with:
```python
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()
```

### `Can't locate revision` during migration
Old migration files reference a different database revision. Delete and regenerate:
```powershell
Remove-Item -Recurse -Force migrations
Remove-Item -Force flask_crud.db
flask db init
flask db migrate -m "initial sqlite schema"
flask db upgrade
```

### `unknown log opt 'max-size' for awslogs log driver`
`max-size` and `max-file` are only valid for the `json-file` log driver, not `awslogs`. Remove them from the logging section in `docker-compose.yml` / `user_data.sh`.

### No containers running after bootstrap
Check bootstrap log for errors:
```
CloudWatch → Log groups → /<app_name>/bootstrap
```
Or via SSH:
```bash
sudo cat /var/log/user_data.log
```

### `502 Bad Gateway` after terraform apply
Instance is still bootstrapping — wait 2–3 minutes. The EBS mount + migration + image pull takes time on first boot.

### `WARNING: This is a development server`
`app.py` is running with `debug=True`. Use:
```python
debug_mode = os.getenv('FLASK_ENV') != 'production'
app.run(host='0.0.0.0', port=5000, debug=debug_mode)
```

### `404 Not Found` when installing `libpq-dev` in GitHub Actions
Package list is stale. Add `apt-get update` before install:
```yaml
sudo apt-get update
sudo apt-get install -y libpq-dev
```

### EC2 instance not accessible after deploy
- Check CloudWatch bootstrap logs for errors
- Verify security group allows port 80 inbound
- Check containers: SSH in and run `docker ps`

### `ModuleNotFoundError: No module named 'psycopg2'`
Ensure `requirements.txt` includes `psycopg2-binary==2.9.9` and that GitHub Actions installs `libpq-dev` before `pip install`.

---

## License

MIT