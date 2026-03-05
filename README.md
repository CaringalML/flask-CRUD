# Flask CRUD App with PostgreSQL, HTMX & Bootstrap

A modern full-stack CRUD application built with **Flask**, **PostgreSQL**, **SQLAlchemy**, **Flask-Migrate**, **HTMX**, **Alpine.js**, and **Bootstrap 5**. Features inline editing, toast notifications, client-side filtering, database migrations, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                              |
|------------|-----------------------------------------|
| Backend    | Flask 3.0, SQLAlchemy, Flask-Migrate    |
| Database   | PostgreSQL 17 (local)                   |
| Frontend   | HTMX 2.0 + Alpine.js 3.14              |
| Styling    | Bootstrap 5.3 + Custom CSS overrides    |
| Deployment | Docker + Nginx + Terraform (AWS ECS)    |

---

## Project Structure

```
flask_crud/
├── app.py                  # Flask application factory
├── extensions.py           # SQLAlchemy + Flask-Migrate initialisation
├── models.py               # SQLAlchemy ORM models (source of truth for schema)
├── routes.py               # All routes (standard + HTMX endpoints)
├── requirements.txt        # Python dependencies
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

### Prerequisites

- **PostgreSQL 17+** installed locally (download from [EDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads))
- **pgAdmin 4** (optional, for visual database management — bundled with PostgreSQL installer or download from [pgadmin.org](https://www.pgadmin.org/download/))

### 1. Create the Database

Using **pgAdmin**:
1. In the left sidebar, right-click **Databases** → **Create** → **Database...**
2. Name: `flask_crud`, Owner: `postgres` → **Save**

Or using **psql** command line:

```bash
psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE flask_crud;"
```

### 2. Run Migrations

Tables are managed by Flask-Migrate. After setting up your `.env` (see below), run:

```bash
python -m flask db upgrade
```

This will create all tables automatically from the migration files in `migrations/versions/`.

> **Note:** The database itself (e.g. `flask_crud`) must be created manually — migrations only handle tables and schema, not database creation.

### 3. pgAdmin Connection (Optional)

To connect pgAdmin to your local database:

| Field              | Value          |
|--------------------|----------------|
| **Server Name**    | Any label (e.g. `Flask CRUD Local`) |
| **Host**           | `localhost`    |
| **Port**           | `5432`         |
| **Database**       | `flask_crud`   |
| **User**           | `postgres`     |
| **Password**       | Your PostgreSQL password |

---

## Environment Variables

Create a `.env` file in the project root:

```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/flask_crud
SECRET_KEY=your-flask-secret-key
```

| Variable        | Description                                      |
|-----------------|--------------------------------------------------|
| `DATABASE_URL`  | PostgreSQL connection string                     |
| `SECRET_KEY`    | Flask session secret — set to any random string  |

The `DATABASE_URL` format is:

```
postgresql://<user>:<password>@<host>:<port>/<database>
```

---

## Setup & Installation

### Prerequisites

- Python 3.11+
- PostgreSQL 17+ with the `flask_crud` database created (see Database Setup above)

### 1. Clone the Repository

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD
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

The pinned dependencies in [requirements.txt](requirements.txt):

```
flask==3.0.0
flask-sqlalchemy==3.1.1
flask-migrate==4.0.7
psycopg2-binary==2.9.9
python-dotenv==1.0.0
```

| Package              | Purpose                                              |
|----------------------|------------------------------------------------------|
| `flask-sqlalchemy`   | SQLAlchemy ORM integration with Flask                |
| `flask-migrate`      | Database migrations (Alembic wrapper)                |
| `psycopg2-binary`    | PostgreSQL driver for Python                         |
| `python-dotenv`      | Loads `.env` variables into the environment          |

### 4. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env with your PostgreSQL credentials
```

### 5. Run Database Migrations

```bash
python -m flask db upgrade
```

This creates all tables in the `flask_crud` database.

### 6. Run the Application

```bash
python app.py
```

The app will be available at **http://localhost:5000**.

---

## Database Migrations

This project uses **Flask-Migrate** (Alembic) for schema management — similar to `php artisan migrate` in Laravel.

### Quick Reference

| Command                                      | Description                          |
|----------------------------------------------|--------------------------------------|
| `python -m flask db init`                    | One-time setup (already done)        |
| `python -m flask db migrate -m "message"`    | Generate migration from model changes |
| `python -m flask db upgrade`                 | Apply pending migrations             |
| `python -m flask db downgrade`               | Rollback last migration              |
| `python -m flask db history`                 | Show all migrations                  |
| `python -m flask db current`                 | Show current migration version       |

### Workflow

1. Edit the model in [models.py](models.py) (add/remove/change columns)
2. Generate the migration: `python -m flask db migrate -m "describe change"`
3. Apply it: `python -m flask db upgrade`

> **Important:** Always start from [models.py](models.py). The model is the source of truth. Alembic compares the model to the database and auto-generates the migration diff. Do not create migration files manually without updating the model — they will go out of sync.

### Deploying to a New Environment

On a fresh database, just run:

```bash
python -m flask db upgrade
```

All migration files in `migrations/versions/` will replay in order and create the full schema.

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

The app factory in [app.py](app.py) configures the database URI from the `DATABASE_URL` environment variable and binds both extensions:

```python
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
db.init_app(app)
migrate.init_app(app, db)
```

All routes in [routes.py](routes.py) use SQLAlchemy ORM queries (e.g. `Item.query`, `db.session.add()`, `db.session.commit()`).

### Frontend Stack

- **Bootstrap 5.3** — Base CSS framework (loaded via CDN)
- **Custom CSS** — [static/style.css](static/style.css) overrides Bootstrap defaults with custom colors, shadows, and animations
- **HTMX 2.0** — Partial page swaps, inline editing without JavaScript
- **Alpine.js 3.14** — Toast notifications, mobile nav toggle, client-side search filter

### Routing

| Endpoint                        | Method   | Type   | Description                       |
|---------------------------------|----------|--------|-----------------------------------|
| `/`                             | GET      | Page   | List all items                    |
| `/create`                       | GET/POST | Page   | Create item form                  |
| `/edit/<id>`                    | GET/POST | Page   | Edit item form (fallback)         |
| `/delete/<id>`                  | POST     | Page   | Delete item (fallback)            |
| `/htmx/create`                  | POST     | HTMX   | Create item via HTMX              |
| `/htmx/items/<id>`              | PUT      | HTMX   | Inline update item                |
| `/htmx/items/<id>`              | DELETE   | HTMX   | Delete item (removes card)        |
| `/htmx/items/<id>/edit`         | GET      | HTMX   | Get inline edit form              |
| `/htmx/items/<id>/card`         | GET      | HTMX   | Get single item card              |
| `/htmx/edit/<id>`               | POST     | HTMX   | Edit from dedicated form page     |

---

## Docker Deployment

See [DOCKER_README.md](DOCKER_README.md) for full Docker and Docker Compose instructions, including Nginx reverse proxy setup.

Quick start:

```bash
docker build -t flask-crud .
docker run -p 5000:5000 \
  -e DATABASE_URL=postgresql://postgres:password@host.docker.internal:5432/flask_crud \
  -e SECRET_KEY=your-flask-secret \
  flask-crud
```

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

## Troubleshooting

### `OperationalError: could not connect to server`
- Ensure PostgreSQL is running: check the `postgresql-x64-17` service in Windows Services
- Verify `DATABASE_URL` in `.env` has the correct host, port, user, and password

### `ProgrammingError: relation "items" does not exist`
- You haven't run migrations yet. Run:
  ```bash
  python -m flask db upgrade
  ```

### `ModuleNotFoundError: No module named 'psycopg2'`
- Install the PostgreSQL driver:
  ```bash
  pip install psycopg2-binary==2.9.9
  ```

### `TypeError: expected str, got NoneType` on startup
- Your `.env` file is missing or `DATABASE_URL` is not set

### Migration says "No changes detected"
- You ran `flask db migrate` without modifying [models.py](models.py) first. Make your model changes, then run migrate.

### `NotNullViolation` when running a migration
- You added a `NOT NULL` column to a table with existing data. Add `server_default` to the column in the migration file before running `upgrade`.

---

## License

MIT
