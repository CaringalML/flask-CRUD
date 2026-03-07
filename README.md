# Flask CRUD App — Supabase + Docker + AWS EC2

A modern full-stack CRUD application built with **Flask**, **Supabase** (PostgreSQL), **HTMX**, and **Alpine.js**. Features inline editing, toast notifications, client-side filtering, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                                                      |
|------------|-----------------------------------------------------------------|
| Backend    | Flask 3.0                                                       |
| Database   | Supabase (hosted PostgreSQL — no local DB container needed)     |
| Frontend   | HTMX 2.0 + Alpine.js 3.14                                      |
| Styling    | Bootstrap 5.3 + Custom CSS overrides                            |
| Proxy      | Nginx Alpine                                                    |
| Deployment | Docker Compose + Terraform (AWS EC2 t4g.nano) + GitHub Actions  |

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
    ├── security_groups.tf   # App SG (HTTP/HTTPS/SSH only)
    ├── ec2.tf               # t4g.nano instance, key pair, Elastic IP
    ├── variables.tf         # All configurable variables
    ├── outputs.tf           # IP, app URL, SSH command after deploy
    ├── user_data.sh         # Bootstrap: Docker install, compose up
    ├── terraform.tfvars.example  # Copy to terraform.tfvars and fill secrets
    └── .gitignore           # Excludes tfstate and tfvars from git
```

---

## Features

- **Full CRUD** — Create, Read, Update, Delete items
- **HTMX-powered** — Inline editing, partial page swaps, no full reloads
- **Alpine.js** — Toast notifications, flash message auto-dismiss, mobile nav, client-side search filter
- **Non-HTMX fallback** — Standard form-based routes for full compatibility
- **Responsive** — Mobile-first design with sticky navbar
- **Docker ready** — Containerised with Nginx reverse proxy (ARM64)
- **AWS deployable** — Terraform config for EC2 t4g.nano with Elastic IP
- **CI/CD** — GitHub Actions auto-deploys on push to `v2`

---

## Supabase Database Setup

### 1. Create the `items` Table

In your Supabase project dashboard, go to **Table Editor** → **New Table** and create a table named `items`, or run this SQL in the **SQL Editor**:

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
-- Allow all read access
CREATE POLICY "Allow all select" ON items FOR SELECT USING (true);

-- Allow all insert access
CREATE POLICY "Allow all insert" ON items FOR INSERT WITH CHECK (true);

-- Allow all update access
CREATE POLICY "Allow all update" ON items FOR UPDATE USING (true) WITH CHECK (true);

-- Allow all delete access
CREATE POLICY "Allow all delete" ON items FOR DELETE USING (true);
```

> If RLS is enabled without these policies, you will get empty responses or permission errors.

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

1. **DO NOT rename the environment variables.** They must be exactly:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `SUPABASE_ANON_KEY`

2. **Two different keys serve different purposes:**

   | Key | Where used | Why |
   |-----|-----------|-----|
   | `SUPABASE_KEY` (service_role) | Flask backend only | Full DB access, bypasses RLS — never exposed to browser |
   | `SUPABASE_ANON_KEY` (anon) | Browser (Realtime websocket) | Public key, safe to expose — required for Realtime Live status |

   Find both in: Supabase Dashboard → **Project Settings** → **API**

3. `SECRET_KEY` is Flask's session secret — set it to any random string:
   ```bash
   python -c "import secrets; print(secrets.token_hex(32))"
   ```

---

## Local Development

### Prerequisites

- Python 3.11+
- A [Supabase](https://supabase.com) project with the `items` table created

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
> python-dotenv==1.0.0
> requests>=2.28.0
> ```
> Always use `supabase==2.28.0` — other versions may cause import errors or SSL failures.

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

The Supabase client is initialised in [extensions.py](extensions.py):

```python
import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

supabase: Client = create_client(
    os.environ.get("SUPABASE_URL"),
    os.environ.get("SUPABASE_KEY")
)
```

All routes in [routes.py](routes.py) use this `supabase` client to interact with the `items` table via the Supabase Python SDK — no ORM needed, no local database.

### Architecture

```
Internet → Elastic IP (static) → EC2 t4g.nano (ap-south-1)
                                        ├── nginx:alpine   (port 80)
                                        └── flask_crud_app (port 5000)
                                                  ↓ HTTPS API calls (service_role key)
                                         Supabase (hosted PostgreSQL)
                                                  ↑ Realtime websocket (anon key)
                                         Browser ─┘
```

No local PostgreSQL container. No EBS volume. The database lives entirely on Supabase's infrastructure.

**Two keys, two purposes:**
```
SUPABASE_KEY (service_role) → Flask backend → full DB access, never touches browser
SUPABASE_ANON_KEY (anon)    → Browser JS   → Realtime websocket subscription only
```

### Realtime (Live status)

The **"Live"** badge in the UI is a Supabase Realtime websocket connection maintained directly from the browser. It uses the **anon key** (safe to expose publicly) — never the service_role key.

```
Browser → Supabase Realtime websocket (SUPABASE_ANON_KEY)
→ Subscribes to INSERT/UPDATE/DELETE events on the items table
→ UI updates automatically without page refresh
```

The `SUPABASE_ANON_KEY` is passed from Flask → HTML template → browser JavaScript:

```python
# routes.py
return render_template('index.html',
    supabase_url=os.getenv('SUPABASE_URL'),
    supabase_anon_key=os.getenv('SUPABASE_ANON_KEY')  # anon key only
)
```

For Realtime to work, enable it in Supabase Dashboard → **Database** → **Replication** → toggle `items` table on.

---

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

The `terraform-aws/` directory deploys the app on a **t4g.nano** (AWS Graviton2, ARM64) in Mumbai (`ap-south-1`) — the cheapest Graviton option. Since the database is on Supabase, no local PostgreSQL or EBS volume is needed.

### Architecture vs v5

| | v2 (Supabase) | v5 (PostgreSQL) |
|---|---|---|
| Instance | t4g.nano | t4g.micro |
| Database | Supabase (external) | PostgreSQL (local container) |
| EBS volume | ❌ Not needed | ✅ 10GB for PostgreSQL data |
| pgAdmin | ❌ Not needed | ✅ http://ip:5050 |
| Monthly cost | ~$4/mo | ~$9.25/mo |

### Monthly Cost (~USD)

| Resource           | Cost      |
|--------------------|-----------|
| t4g.nano Mumbai    | ~$2.04    |
| EBS 30 GiB root    | ~$2.40    |
| Elastic IP         | $0.00     |
| **Total**          | **~$4.44** |

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
aws_region          = "ap-south-1"
app_name            = "salon-booking"
instance_type       = "t4g.nano"
docker_image        = "rencecaringal000/flask-crud:latest"
flask_env           = "production"
flask_secret_key    = "your-generated-secret-key"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
ssh_allowed_cidr    = "0.0.0.0/0"

supabase_url        = "https://your-project-id.supabase.co"
supabase_key        = "your-service-role-secret-key"
supabase_anon_key   = "your-supabase-anon-public-key"
database_url        = "postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres"
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
app_url       = "http://<elastic-ip>"
public_ip     = "<elastic-ip>"
ssh_command   = "ssh -i ~/.ssh/id_rsa ec2-user@<elastic-ip>"
bootstrap_log = "sudo cat /var/log/user_data.log"
view_logs     = "cd /app && docker-compose logs -f"
```

> **First boot takes 2–3 minutes.** The instance installs Docker, pulls images, and starts containers. Wait before visiting `app_url`.

---

### Useful Commands After Deploy

```bash
# SSH into the instance
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>

# Check bootstrap log
sudo cat /var/log/user_data.log

# View running containers
docker ps

# View all logs
cd /app && docker-compose logs -f

# Pull latest image and redeploy
cd /app && docker-compose pull && docker-compose up -d
```

---

### Destroying Infrastructure

```bash
terraform destroy
```

> No EBS volume to worry about — all data is in Supabase. `terraform destroy` cleanly removes everything.

---

## CI/CD — GitHub Actions

On every push to `v2`, GitHub Actions automatically:

1. Runs Python syntax checks
2. Builds ARM64 Docker image
3. Pushes to Docker Hub
4. SSHes into EC2 and redeploys

### Required GitHub Secrets

| Secret               | Value                                           |
|----------------------|-------------------------------------------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username                        |
| `DOCKERHUB_TOKEN`    | Your Docker Hub access token                    |
| `EC2_HOST`           | Your Elastic IP                                 |
| `EC2_SSH_KEY`        | Full contents of `~/.ssh/id_rsa` (private key)  |

---

## Troubleshooting

### `Unexpected attribute: secret_key` in terraform.tfvars
The variable is named `flask_secret_key`, not `secret_key`. Fix:
```hcl
flask_secret_key = "your-secret"
```

### `var.database_url` prompt during terraform apply
`database_url` is missing from `terraform.tfvars`. Add it:
```hcl
database_url = "postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres"
```

### `502 Bad Gateway` after terraform apply
Instance is still bootstrapping. Wait 2–3 minutes then refresh. Check:
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
sudo cat /var/log/user_data.log
```

### Empty item list / no data returned
- Verify RLS policies are set to `true` for all operations on the `items` table.
- Confirm you're using the **service_role secret key**, not the anon key.

### `TypeError: expected str, got NoneType` on startup
`.env` is missing or variable names are wrong. Ensure `SUPABASE_URL` and `SUPABASE_KEY` are set exactly as specified.

### `ImportError: cannot import name 'create_client'`
Incompatible supabase package version. Run:
```bash
pip install supabase==2.28.0
```

### `401 Unauthorized` from Supabase
You're using the `anon` key instead of the `service_role` key. Switch to the secret key in Supabase Dashboard → **Settings** → **API**.

### `context canceled` when building on Windows Docker Desktop
BuildKit bug. Disable it:
```powershell
$env:DOCKER_BUILDKIT=0
docker build -t flask-crud-test .
```

---

## License

MIT