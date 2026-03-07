# Flask CRUD App — v2: Supabase + Docker + AWS EC2

A modern full-stack CRUD application built with **Flask**, **Supabase** (PostgreSQL), **HTMX**, and **Alpine.js**. Features inline editing, toast notifications, Supabase Realtime live updates, client-side filtering, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                                                      |
|------------|-----------------------------------------------------------------|
| Backend    | Flask 3.0                                                       |
| Database   | Supabase (hosted PostgreSQL — no local DB container needed)     |
| Frontend   | HTMX 2.0 + Alpine.js 3.14                                       |
| Styling    | Bootstrap 5.3 + Custom CSS overrides                            |
| Proxy      | Nginx Alpine                                                    |
| Deployment | Docker Compose + Terraform (AWS EC2 t4g.nano) + GitHub Actions  |
| Logging    | AWS CloudWatch (3 log groups, 7-day retention)                  |

---

## Project Structure

```
flask_crud/
├── app.py                  # Flask application factory
├── extensions.py           # Supabase client initialisation
├── models.py               # SQLAlchemy model (reference schema)
├── routes.py               # All routes (standard + HTMX endpoints)
├── requirements.txt        # Python dependencies
├── Dockerfile              # App container (Python 3.11 Alpine, ARM64)
├── entrypoint.sh           # Runs flask db upgrade then starts the app
├── .env                    # Environment variables (DO NOT COMMIT)
├── static/
│   └── style.css           # Complete application styles
├── templates/
│   ├── base.html           # Layout with navbar, toasts, HTMX/Alpine
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
    ├── cloudwatch.tf        # IAM role, log groups, CloudWatch agent
    ├── variables.tf         # All configurable variables
    ├── outputs.tf           # IP, app URL, SSH command, CloudWatch URLs
    ├── user_data.sh         # Bootstrap: Docker install, compose up, cleanup cron
    ├── terraform.tfvars.example  # Copy to terraform.tfvars and fill secrets
    └── .gitignore           # Excludes tfstate and tfvars from git
```

---

## Features

- **Full CRUD** — Create, Read, Update, Delete items
- **HTMX-powered** — Inline editing, partial page swaps, no full reloads
- **Alpine.js** — Toast notifications, flash message auto-dismiss, mobile nav, client-side search filter
- **Supabase Realtime** — Live badge via websocket, auto-updates without page refresh
- **Non-HTMX fallback** — Standard form-based routes for full compatibility
- **Responsive** — Mobile-first design with sticky navbar
- **Docker ready** — Containerised with Nginx reverse proxy (ARM64)
- **AWS deployable** — Terraform config for EC2 t4g.nano with Elastic IP and own VPC
- **CloudWatch logs** — All container logs shipped to AWS CloudWatch (no SSH needed to debug)
- **Auto cleanup** — Weekly Docker prune + daily journal vacuum cron jobs
- **CI/CD** — GitHub Actions auto-deploys on push to `v2`

---

## Supabase Database Setup

### 1. Create the `items` Table

In your Supabase project dashboard go to **Table Editor** → **New Table**, or run this SQL in the **SQL Editor**:

```sql
CREATE TABLE items (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
```

### 2. Set Row Level Security (RLS) Policies

> **IMPORTANT:** The `items` table must have RLS enabled with policies set to `true`. Without this, Supabase will block all operations even with the service key.

```sql
CREATE POLICY "Allow all select" ON items FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON items FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Allow all delete" ON items FOR DELETE USING (true);
```

> If RLS is enabled without these policies, you will get empty responses or permission errors.

### 3. Enable Realtime

Supabase Dashboard → **Database** → **Replication** → toggle the `items` table on.

---

## Environment Variables

### ⚠️ CRITICAL — Read Before Configuring

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-service-role-secret-key
SUPABASE_ANON_KEY=your-supabase-anon-public-key
DATABASE_URL=postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres
SECRET_KEY=your-flask-secret-key
```

**Rules:**

1. **DO NOT rename the environment variables.** They must be exactly `SUPABASE_URL`, `SUPABASE_KEY`, `SUPABASE_ANON_KEY`.

2. **Two different Supabase keys serve different purposes:**

   | Key | Where used | Why |
   |-----|-----------|-----|
   | `SUPABASE_KEY` (service_role) | Flask backend only | Full DB access, bypasses RLS — never exposed to browser |
   | `SUPABASE_ANON_KEY` (anon) | Browser (Realtime websocket) | Public key, safe to expose — required for Realtime Live badge |

   Find both in: Supabase Dashboard → **Project Settings** → **API**

3. `SECRET_KEY` is Flask's session secret — generate one with:
   ```bash
   python -c "import secrets; print(secrets.token_hex(32))"
   ```

---

## Local Development

### Prerequisites

- Python 3.11+
- A [Supabase](https://supabase.com) project with the `items` table and RLS policies created

### 1. Clone and switch to v2

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD
git checkout v2
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

> Pinned versions in `requirements.txt`:
> ```
> flask==3.0.0
> supabase==2.28.0
> flask-sqlalchemy==3.1.1
> flask-migrate==4.0.7
> psycopg2-binary==2.9.9
> python-dotenv==1.0.0
> requests>=2.28.0
> ```
> - Always use `supabase==2.28.0` — other versions may cause import errors or SSL failures.
> - `psycopg2-binary` is required for Flask-Migrate/SQLAlchemy to connect to Supabase via `DATABASE_URL`.

### 4. Configure environment variables

```bash
cp .env.example .env
# Edit .env with your Supabase credentials
```

### 5. Run the application

```bash
python app.py
```

App available at **http://localhost:5000**.

---

## How It Works

### Database Connection

The app uses **two separate database integrations** that serve different purposes:

| Integration | Used for | File |
|---|---|---|
| Supabase Python SDK | All CRUD routes | `extensions.py` + `routes.py` |
| SQLAlchemy + Flask-Migrate | Schema migrations only | `extensions.py` + `models.py` |

```python
# extensions.py — Supabase SDK (CRUD operations, uses service_role key)
supabase: Client = create_client(
    os.environ.get("SUPABASE_URL"),
    os.environ.get("SUPABASE_KEY")
)

# app.py — SQLAlchemy (migrations only, uses DATABASE_URL)
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
```

### Architecture

```
Internet → Elastic IP (static) → EC2 t4g.nano (ap-south-1, own VPC)
                                        ├── nginx:alpine   (port 80)
                                        └── flask_crud_app (port 5000)
                                                  ↓ HTTPS API calls (service_role key)
                                         Supabase (hosted PostgreSQL)
                                                  ↑ Realtime websocket (anon key)
                                         Browser ─┘
```

No local PostgreSQL container. No EBS data volume. The database lives entirely on Supabase's infrastructure.

**Two keys, two purposes:**
```
SUPABASE_KEY (service_role) → Flask backend → full DB access, never touches browser
SUPABASE_ANON_KEY (anon)    → Browser JS   → Realtime websocket subscription only
```

### Realtime (Live badge)

The **"Live"** badge in the UI is a Supabase Realtime websocket connection maintained directly from the browser using the **anon key** — never the service_role key.

```
Browser → Supabase Realtime websocket (SUPABASE_ANON_KEY)
→ Subscribes to INSERT/UPDATE/DELETE events on the items table
→ UI updates automatically without page refresh
```

The `SUPABASE_ANON_KEY` is passed Flask → template → browser JS:

```python
# routes.py
return render_template('index.html',
    supabase_url=os.getenv('SUPABASE_URL'),
    supabase_anon_key=os.getenv('SUPABASE_ANON_KEY')  # anon key only, safe to expose
)
```

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

The `terraform-aws/` directory deploys the app on a **t4g.nano** (AWS Graviton2, ARM64) in Mumbai (`ap-south-1`) inside its own dedicated VPC. Since the database is on Supabase, no local PostgreSQL container or EBS data volume is needed.

### Monthly Cost (~USD)

| Resource           | Cost      |
|--------------------|-----------|
| t4g.nano Mumbai    | ~$2.04    |
| EBS 8 GiB root     | ~$0.64    |
| Elastic IP         | $0.00     |
| Supabase Free tier | $0.00     |
| CloudWatch logs    | ~$0.00    |
| **Total**          | **~$2.68** |

> Root volume is 8 GiB (shrunk from the AWS default 30 GiB) — saves ~$1.76/mo.
> CloudWatch costs are negligible at 7-day retention within the free tier.

---

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured (`aws configure`)
- An SSH key pair (see below)
- A Supabase project with the `items` table and RLS policies set up

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
# Should show: id_rsa   and   id_rsa.pub
```

| File         | Description                                      |
|--------------|--------------------------------------------------|
| `id_rsa`     | **Private key** — keep safe, never share         |
| `id_rsa.pub` | **Public key** — Terraform uploads this to AWS   |

---

### Configure terraform.tfvars

```powershell
cd terraform-aws
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# ── General ────────────────────────────────────────────────────────────────────
aws_region = "ap-south-1"
app_name   = "mlcaringal"

# ── EC2 Instance ───────────────────────────────────────────────────────────────
instance_type = "t4g.nano"

# ── Docker ─────────────────────────────────────────────────────────────────────
docker_image = "rencecaringal000/flask-crud:latest"

# ── Flask ──────────────────────────────────────────────────────────────────────
flask_env        = "production"
flask_secret_key = "your-generated-secret-key"

# ── SSH Access ─────────────────────────────────────────────────────────────────
ssh_public_key_path = "~/.ssh/id_rsa.pub"
ssh_allowed_cidr    = "0.0.0.0/0"

# ── Supabase ───────────────────────────────────────────────────────────────────
supabase_url      = "https://your-project-id.supabase.co"
supabase_key      = "your-service-role-secret-key"
supabase_anon_key = "your-supabase-anon-public-key"
database_url      = "postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres"
```

> Find `database_url` in: Supabase Dashboard → **Project Settings** → **Database** → **Connection string** → **URI**

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

> **First boot takes 2–3 minutes.** The instance installs Docker, installs the CloudWatch agent, pulls images, and starts containers. Wait before visiting `app_url`.

---

## CloudWatch Logs

All container logs are shipped to AWS CloudWatch automatically — no SSH needed for day-to-day debugging.

| Log Group                   | Stream                      | Contains                              |
|-----------------------------|-----------------------------|---------------------------------------|
| `/mlcaringal/app`           | `flask_crud_app`            | Flask app logs, all HTTP request logs |
| `/mlcaringal/nginx`         | `nginx`                     | HTTP access logs, 502 errors          |
| `/mlcaringal/bootstrap`     | `{instance_id}/user_data`   | First-boot log, Docker install output |

All log groups have **7-day retention** — logs older than a week are deleted automatically.

**View logs:** AWS Console → **CloudWatch** → **Log groups** → click the group → click the stream.

Or use the direct URLs from `terraform output` after deploying.

> The bootstrap log only runs **once on first boot**. It will not update on subsequent deploys — those are handled by GitHub Actions SSH deploy.

---

## Auto Cleanup

The following jobs run automatically on the EC2 instance to keep disk usage low on the 8 GiB root volume:

| Schedule          | Job                                                       |
|-------------------|-----------------------------------------------------------|
| Every Sunday 2am  | `docker image prune -f` — removes old layers after deploy |
| Every day 3am     | `journalctl --vacuum-size=50M` — trims system journal     |

Container log sizes are also capped via Docker logging config:
- Flask container: max 10 MB × 3 files
- Nginx container: max 5 MB × 2 files

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
```

---

### Destroying Infrastructure

```bash
terraform destroy
```

> No EBS data volume to worry about — all data is in Supabase. `terraform destroy` cleanly removes everything including the VPC, IAM role, and CloudWatch log groups.

---

## CI/CD — GitHub Actions

On every push to `v2`, GitHub Actions automatically:

1. Runs `apt-get update && apt-get install -y libpq-dev` (required to install psycopg2)
2. Installs Python dependencies and runs syntax checks
3. Builds ARM64 Docker image
4. Pushes to Docker Hub
5. SSHes into EC2 and redeploys with `docker-compose pull && docker-compose up -d`

### Required GitHub Secrets

| Secret               | Value                                           |
|----------------------|-------------------------------------------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username                        |
| `DOCKERHUB_TOKEN`    | Your Docker Hub access token                    |
| `EC2_HOST`           | Your Elastic IP                                 |
| `EC2_SSH_KEY`        | Full contents of `~/.ssh/id_rsa` (private key)  |

---

## Troubleshooting

### `ModuleNotFoundError: No module named 'psycopg2'`
The Docker image is missing `psycopg2-binary`. Ensure `requirements.txt` includes `psycopg2-binary==2.9.9`, then push a new commit to trigger a rebuild. The GitHub Actions workflow installs `libpq-dev` before pip install — this is required for psycopg2 to compile on ARM64.

### `WARNING: This is a development server`
`app.py` is running with `debug=True`. Use an env-aware flag instead:
```python
debug_mode = os.getenv('FLASK_ENV') != 'production'
app.run(host='0.0.0.0', port=5000, debug=debug_mode)
```
With `flask_env = "production"` set in `terraform.tfvars`, this evaluates to `False` automatically.

### `404 Not Found` when installing `libpq-dev` in GitHub Actions
The package list is stale. The workflow must run `apt-get update` before install:
```yaml
sudo apt-get update
sudo apt-get install -y libpq-dev
```

### `Unexpected attribute: secret_key` in terraform.tfvars
The variable is `flask_secret_key`, not `secret_key`:
```hcl
flask_secret_key = "your-secret"
```

### `var.database_url` prompt during terraform apply
`database_url` is missing from `terraform.tfvars`. Add:
```hcl
database_url = "postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres"
```

### `502 Bad Gateway` after terraform apply
Instance is still bootstrapping — wait 2–3 minutes. Check the bootstrap log:
```
CloudWatch → Log groups → /mlcaringal/bootstrap
```
Or via SSH:
```bash
sudo cat /var/log/user_data.log
```

### Empty item list / no data returned
- Verify RLS policies are set to `true` for all operations on the `items` table.
- Confirm `SUPABASE_KEY` is the **service_role secret key**, not the anon key.

### `TypeError: expected str, got NoneType` on startup
`.env` is missing or a variable name is wrong. Ensure `SUPABASE_URL` and `SUPABASE_KEY` are set exactly as specified.

### `ImportError: cannot import name 'create_client'`
Incompatible supabase package version. Run:
```bash
pip install supabase==2.28.0
```

### `401 Unauthorized` from Supabase
You are using the anon key instead of the service_role key for backend calls. Switch to the secret key found in Supabase Dashboard → **Settings** → **API**.

### `context canceled` when building on Windows Docker Desktop
BuildKit bug on Windows. Disable it:
```powershell
$env:DOCKER_BUILDKIT=0
docker build -t flask-crud-test .
```

---

## License

MIT