# Flask CRUD App with SQLite / PostgreSQL, HTMX & Bootstrap

A modern full-stack CRUD application built with **Flask**, **SQLite** (default) or **PostgreSQL**, **SQLAlchemy**, **Flask-Migrate**, **HTMX**, **Alpine.js**, and **Bootstrap 5**. Features inline editing, toast notifications, client-side filtering, database migrations, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                              |
|------------|-----------------------------------------|
| Backend    | Flask 3.0, SQLAlchemy, Flask-Migrate    |
| Database   | SQLite (default) / PostgreSQL 17        |
| Frontend   | HTMX 2.0 + Alpine.js 3.14              |
| Styling    | Bootstrap 5.3 + Custom CSS overrides    |
| Deployment | PythonAnywhere / Docker + Nginx + Terraform (AWS ECS) |

---

## Branch Overview

| Branch | Database   | Notes                              |
|--------|------------|------------------------------------|
| `v3`   | PostgreSQL | Requires local PostgreSQL + psycopg2 |
| `v4`   | SQLite     | Zero setup, file-based, free-tier friendly |

---

## Project Structure

```
flask_crud/
├── app.py                  # Flask application factory
├── extensions.py           # SQLAlchemy + Flask-Migrate initialisation
├── models.py               # SQLAlchemy ORM models (source of truth for schema)
├── routes.py               # All routes (standard + HTMX endpoints)
├── requirements.txt        # Python dependencies
├── flask_crud.db           # SQLite database file (v4 only, auto-created)
├── Dockerfile              # App container (Python 3.11 Alpine)
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
│       ├── item_card.html  # Single item card partial (HTMX swap target)
│       ├── item_edit.html  # Inline edit form partial
│       ├── form_success.html  # Success message partial
│       └── form_error.html    # Error message partial
├── nginx/
│   ├── Dockerfile          # Nginx container
│   └── nginx.conf          # Reverse proxy configuration
└── terraform-aws/          # AWS ECS Terraform infrastructure
```

---

## Features

- **Full CRUD** — Create, Read, Update, Delete items
- **HTMX-powered** — Inline editing, partial page swaps, no full reloads
- **Alpine.js** — Toast notifications, flash message auto-dismiss, mobile nav, client-side search/filter
- **Non-HTMX fallback** — Standard form-based routes for full compatibility
- **Database Migrations** — Flask-Migrate (Alembic) for version-controlled schema changes
- **Bootstrap 5** — Responsive framework with custom design overrides
- **Responsive** — Mobile-first design with sticky navbar
- **Docker ready** — Containerised with Nginx reverse proxy
- **AWS deployable** — Terraform config for ECS

---

## Database Setup

### SQLite (v4 — default, zero setup)

SQLite requires no installation. The database is a single file (`flask_crud.db`) automatically created in the project root when you run migrations.

**Environment variables** — simply omit `DATABASE_URL`:

```env
SECRET_KEY=your-flask-secret-key
```

The app will fall back to SQLite automatically.

**Run migrations:**

```bash
python -m flask db upgrade
```

That's it. `flask_crud.db` will be created with all tables.

> **Note:** Add `flask_crud.db` to `.gitignore` so the database file is not committed to version control.

---

### PostgreSQL (v3)

#### Prerequisites

- **PostgreSQL 17+** installed locally (download from [EDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads))
- **pgAdmin 4** (optional — bundled with PostgreSQL installer or download from [pgadmin.org](https://www.pgadmin.org/download/))

#### 1. Create the Database

Using **pgAdmin**:
1. In the left sidebar, right-click **Databases** → **Create** → **Database...**
2. Name: `flask_crud`, Owner: `postgres` → **Save**

Or using **psql**:

```bash
psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE flask_crud;"
```

#### 2. Run Migrations

```bash
python -m flask db upgrade
```

#### 3. pgAdmin Connection (Optional)

| Field           | Value                          |
|-----------------|--------------------------------|
| **Server Name** | Any label (e.g. `Flask CRUD Local`) |
| **Host**        | `localhost`                    |
| **Port**        | `5432`                         |
| **Database**    | `flask_crud`                   |
| **User**        | `postgres`                     |
| **Password**    | Your PostgreSQL password       |

---

## Environment Variables

Create a `.env` file in the project root.

### SQLite (v4)

```env
SECRET_KEY=your-flask-secret-key
```

### PostgreSQL (v3)

```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/flask_crud
SECRET_KEY=your-flask-secret-key
```

| Variable       | Description                                     |
|----------------|-------------------------------------------------|
| `DATABASE_URL` | PostgreSQL connection string (omit for SQLite)  |
| `SECRET_KEY`   | Flask session secret — set to any random string |

---

## Setup & Installation

### Prerequisites

- Python 3.11+
- For SQLite (v4): nothing else needed
- For PostgreSQL (v3): PostgreSQL 17+ with the `flask_crud` database created

### 1. Clone the Repository

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD

# For SQLite
git checkout v4

# For PostgreSQL
git checkout v3
```

### 2. Create a Virtual Environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

**v4 (SQLite) dependencies:**

```
flask==3.0.0
flask-sqlalchemy==3.1.1
flask-migrate==4.0.7
python-dotenv==1.0.0
```

**v3 (PostgreSQL) adds:**

```
psycopg2-binary==2.9.9
```

### 4. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env as needed
```

### 5. Run Database Migrations

```bash
python -m flask db upgrade
```

### 6. Run the Application

```bash
python app.py
```

The app will be available at **http://localhost:5000**.

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

> **Important:** Always start from [models.py](models.py). The model is the source of truth. Do not create migration files manually without updating the model — they will go out of sync.

---

## Data Export & Import

This section covers how to export data from SQLite and import it into PostgreSQL when migrating between database backends.

### Export Data from SQLite

Make sure your app is running on SQLite (v4), then open a Flask shell:

```bash
python -m flask shell
```

Run the following to export all items to a JSON file:

```python
from models import Item
import json

items = [item.to_dict() for item in Item.query.all()]

with open('export.json', 'w') as f:
    json.dump(items, f, indent=2, default=str)

print(f"Exported {len(items)} items")
exit()
```

This creates `export.json` in your project root. Keep this file safe — it contains all your data.

> **Note:** `default=str` ensures datetime fields are serialised correctly as strings.

---

### Import Data into PostgreSQL

#### Step 1: Set up PostgreSQL

Create the `flask_crud` database (see [PostgreSQL setup](#postgresql-v3) above).

#### Step 2: Switch `.env` to PostgreSQL

```env
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/flask_crud
SECRET_KEY=your-flask-secret-key
```

#### Step 3: Reinstall psycopg2

```bash
pip install psycopg2-binary==2.9.9
```

#### Step 4: Reset migrations for PostgreSQL

```bash
# Windows PowerShell
Remove-Item -Recurse -Force migrations

# macOS / Linux
rm -rf migrations/
```

Then reinitialise:

```bash
python -m flask db init
python -m flask db migrate -m "initial postgres schema"
python -m flask db upgrade
```

#### Step 5: Import the data

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
    item = Item(
        name=i['name'],
        description=i['description'],
        status=i['status']
    )
    db.session.add(item)

db.session.commit()
print(f"Imported {len(items)} items")
exit()
```

#### Step 6: Verify

```bash
python -m flask shell
```

```python
from models import Item
print(f"Total items in PostgreSQL: {len(Item.query.all())}")
exit()
```

---

### Export/Import Notes

| Detail | Info |
|--------|------|
| `created_at` / `updated_at` | Reset to current time on import — add these fields to the Item constructor if preservation is needed |
| Large datasets | Use `pgloader` for automated SQLite → PostgreSQL migration with full type mapping |
| Backup before switching | Always keep `export.json` until the import is verified |

---

### pgloader (Alternative for Large Datasets)

For large datasets, [pgloader](https://pgloader.io/) handles the full migration automatically including type conversion:

```bash
pgloader sqlite:///flask_crud.db postgresql://postgres:yourpassword@localhost/flask_crud
```

---

## PythonAnywhere Deployment (SQLite — Free Tier)

SQLite works on PythonAnywhere's **free Beginner plan** — no database setup required.

### 1. Open a Bash console and clone the repo

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD
git checkout v4
```

### 2. Create a virtual environment

```bash
mkvirtualenv --python=/usr/bin/python3.11 flask-crud-venv
pip install -r requirements.txt
```

### 3. Create your `.env` file

```bash
nano .env
```

```env
SECRET_KEY=your-flask-secret-key
```

### 4. Run migrations

```bash
python -m flask db upgrade
```

### 5. Configure the Web App

Go to **Web tab** → **Add a new web app** → **Manual configuration** → **Python 3.11**.

| Field             | Value                                          |
|-------------------|------------------------------------------------|
| Source code       | `/home/yourusername/flask-CRUD`                |
| Working directory | `/home/yourusername/flask-CRUD`                |
| Virtualenv        | `/home/yourusername/.virtualenvs/flask-crud-venv` |

### 6. Edit the WSGI file

Replace all content with:

```python
import sys
import os
from dotenv import load_dotenv

path = '/home/yourusername/flask-CRUD'
if path not in sys.path:
    sys.path.insert(0, path)

load_dotenv(os.path.join(path, '.env'))

from app import create_app
application = create_app()
```

### 7. Configure Static Files

| URL       | Directory                                    |
|-----------|----------------------------------------------|
| `/static/` | `/home/yourusername/flask-CRUD/static`      |

### 8. Reload

Hit the green **Reload** button. Your app is live at `https://yourusername.pythonanywhere.com`.

### Redeploying after changes

```bash
cd ~/flask-CRUD
git pull origin v4
# If models changed:
python -m flask db upgrade
```

Then hit **Reload** in the Web tab.

---

## Docker Deployment

```bash
docker build -t flask-crud .
docker run -p 5000:5000 \
  -e SECRET_KEY=your-flask-secret \
  flask-crud
```

For PostgreSQL:

```bash
docker run -p 5000:5000 \
  -e DATABASE_URL=postgresql://postgres:password@host.docker.internal:5432/flask_crud \
  -e SECRET_KEY=your-flask-secret \
  flask-crud
```

See [DOCKER_README.md](DOCKER_README.md) for full Docker Compose and Nginx instructions.

---

## AWS Deployment (Terraform)

The `terraform-aws/` directory contains Terraform configuration for deploying to **AWS ECS** with:

- VPC with public subnets
- ECS cluster (self-managed EC2 instances)
- Task definition & service
- Security groups
- IAM roles
- CloudWatch logging

See [terraform-aws/variables.tf](terraform-aws/variables.tf) and [terraform-aws/terraform.tfvars.example](terraform-aws/terraform.tfvars.example) for configuration.

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

### Frontend Stack

- **Bootstrap 5.3** — Base CSS framework (loaded via CDN)
- **Custom CSS** — [static/style.css](static/style.css) overrides Bootstrap defaults
- **HTMX 2.0** — Partial page swaps, inline editing without JavaScript
- **Alpine.js 3.14** — Toast notifications, mobile nav toggle, client-side search filter

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

## Troubleshooting

### `OperationalError: could not connect to server`
- Ensure PostgreSQL is running: check the `postgresql-x64-17` service in Windows Services
- Verify `DATABASE_URL` in `.env` is correct

### `ProgrammingError: relation "items" does not exist`
- Run migrations: `python -m flask db upgrade`

### `ModuleNotFoundError: No module named 'psycopg2'`
- Install: `pip install psycopg2-binary==2.9.9`

### `TypeError: expected str, got NoneType` on startup
- Your `.env` is missing or `DATABASE_URL` is not set (PostgreSQL only)

### App still connects to PostgreSQL after switching to SQLite
- Check that `DATABASE_URL` is fully commented out or removed from `.env`
- Verify no system-level environment variable is overriding it:
  ```bash
  python -c "import os; from dotenv import load_dotenv; load_dotenv(); print(os.getenv('DATABASE_URL'))"
  ```
  Should print `None`.

### Migration says "No changes detected"
- You ran `flask db migrate` without modifying [models.py](models.py) first

### `Can't locate revision` error during migration
- Old migration files reference a different database. Delete and reinitialise:
  ```bash
  # Windows
  Remove-Item -Recurse -Force migrations
  # macOS / Linux
  rm -rf migrations/
  ```
  Then: `flask db init` → `flask db migrate` → `flask db upgrade`

### `NotNullViolation` when running a migration
- You added a `NOT NULL` column to a table with existing data. Add `server_default` to the column in the migration file before running `upgrade`.

---

## License

MIT