# Flask CRUD App with Supabase & HTMX

A modern full-stack CRUD application built with **Flask**, **Supabase** (PostgreSQL), **HTMX**, and **Alpine.js**. Features inline editing, toast notifications, client-side filtering, and a responsive UI — all with minimal JavaScript.

---

## Tech Stack

| Layer      | Technology                   |
|------------|------------------------------|
| Backend    | Flask 3.0                    |
| Database   | Supabase (PostgreSQL)        |
| Frontend   | HTMX 2.0 + Alpine.js 3.14   |
| Styling    | Custom CSS (no framework)    |
| Deployment | Docker + Nginx + Terraform (AWS ECS) |

---

## Project Structure

```
flask_crud/
├── app.py                  # Flask application factory
├── extensions.py           # Supabase client initialisation
├── models.py               # SQLAlchemy model (reference schema)
├── routes.py               # All routes (standard + HTMX endpoints)
├── requirements.txt        # Python dependencies
├── Dockerfile              # App container (Python 3.11 Alpine)
├── .env                    # Environment variables (DO NOT COMMIT)
├── static/
│   └── style.css           # Complete application styles
├── templates/
│   ├── base.html           # Layout with navbar, toasts, HTMX/Alpine
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
- **Responsive** — Mobile-first design with sticky navbar
- **Docker ready** — Containerised with Nginx reverse proxy
- **AWS deployable** — Terraform config for ECS

---

## Supabase Database Setup

### 1. Create the `items` Table

In your Supabase project dashboard, go to **Table Editor** → **New Table** and create a table named `items` with the following columns:

| Column        | Type        | Default               | Nullable |
|---------------|-------------|-----------------------|----------|
| `id`          | int8        | auto-increment (PK)   | No       |
| `name`        | varchar(100)|                       | No       |
| `description` | text        |                       | Yes      |
| `created_at`  | timestamptz | `now()`               | No       |
| `updated_at`  | timestamptz | `now()`               | No       |

Or run this SQL in the **SQL Editor**:

```sql
CREATE TABLE items (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
```

### 2. Set Row Level Security (RLS) Policies

> **IMPORTANT:** The `items` table must have RLS enabled with **both SELECT and INSERT/UPDATE/DELETE policies set to `true`** (allow all). Without this, Supabase will block all operations even with the service key.

In the Supabase dashboard:

1. Go to **Authentication** → **Policies**
2. Select the `items` table
3. Enable **Row Level Security**
4. Add the following policies:

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

Create a `.env` file in the project root with the following variables:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-service-role-secret-key
SECRET_KEY=your-flask-secret-key
```

**Strict rules for the environment variables:**

1. **DO NOT rename the environment variables.** The variable names **must** remain exactly:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`

   These names are referenced in [extensions.py](extensions.py) and must match exactly. Do not change them to `SUPABASE_SERVICE_KEY`, `SUPABASE_API_KEY`, `DATABASE_URL`, or any other variation.

2. **Use the `service_role` secret key, NOT the `anon` publishable key.** In your Supabase dashboard under **Settings** → **API**, there are two keys:
   - `anon` (public) — **DO NOT USE THIS ONE**
   - `service_role` (secret) — **USE THIS ONE**

   The `anon` key has restricted permissions and will result in empty responses or `401` errors. The `service_role` key bypasses RLS when needed and has full access to perform CRUD operations.

3. The `SECRET_KEY` is Flask's session secret — set it to any random string.

---

## Setup & Installation

### Prerequisites

- Python 3.11+
- A [Supabase](https://supabase.com) project with the `items` table created (see above)

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

> **IMPORTANT:** The correct dependency versions are pinned in [requirements.txt](requirements.txt):
>
> ```
> flask==3.0.0
> supabase==2.28.0
> python-dotenv==1.0.0
> requests>=2.28.0
> ```
>
> **Fixes applied via correct dependencies:**
> - `supabase==2.28.0` — This is the correct version of the Supabase Python client. Earlier or incompatible versions caused import errors (`cannot import name 'create_client'`) or SSL/connection failures. Always use this pinned version.
> - `python-dotenv==1.0.0` — Required for loading `.env` variables. Without it, `SUPABASE_URL` and `SUPABASE_KEY` will be `None` at runtime, causing `TypeError` on client initialisation.
> - `requests>=2.28.0` — Ensures a compatible HTTP library is present for the Supabase client's internal HTTP calls.
>
> **Do not** run `pip install supabase` without specifying the version — it may install an incompatible version.

### 4. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env with your Supabase credentials (see Environment Variables section above)
```

### 5. Run the Application

```bash
python app.py
```

The app will be available at **http://localhost:5000**.

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

All routes in [routes.py](routes.py) import this `supabase` client and interact with the `items` table directly via the Supabase Python SDK — no ORM queries needed.

### Routing

| Endpoint                        | Method | Type   | Description                       |
|---------------------------------|--------|--------|-----------------------------------|
| `/`                             | GET    | Page   | List all items                    |
| `/create`                       | GET/POST | Page | Create item form                  |
| `/edit/<id>`                    | GET/POST | Page | Edit item form (fallback)         |
| `/delete/<id>`                  | POST   | Page   | Delete item (fallback)            |
| `/htmx/create`                  | POST   | HTMX   | Create item via HTMX              |
| `/htmx/items/<id>`              | PUT    | HTMX   | Inline update item                |
| `/htmx/items/<id>`              | DELETE | HTMX   | Delete item (removes card)        |
| `/htmx/items/<id>/edit`         | GET    | HTMX   | Get inline edit form              |
| `/htmx/items/<id>/card`         | GET    | HTMX   | Get single item card              |
| `/htmx/edit/<id>`               | POST   | HTMX   | Edit from dedicated form page     |

---

## Docker Deployment

See [DOCKER_README.md](DOCKER_README.md) for full Docker and Docker Compose instructions, including Nginx reverse proxy setup.

Quick start:

```bash
docker build -t flask-crud .
docker run -p 5000:5000 \
  -e SUPABASE_URL=https://your-project.supabase.co \
  -e SUPABASE_KEY=your-service-role-secret-key \
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

### Empty item list / no data returned
- Verify RLS policies are set to `true` for all operations on the `items` table (see Supabase Database Setup above).
- Confirm you're using the **service_role secret key**, not the anon public key.

### `TypeError: expected str, got NoneType` on startup
- Your `.env` file is missing or the variable names are wrong. Ensure `SUPABASE_URL` and `SUPABASE_KEY` are set exactly as specified — do not rename them.

### `ImportError: cannot import name 'create_client'`
- You have an incompatible version of the `supabase` package. Run:
  ```bash
  pip install supabase==2.28.0
  ```

### Connection timeout / SSL errors
- Ensure `requests>=2.28.0` is installed.
- Verify your Supabase project URL is correct and the project is active.

### `401 Unauthorized` from Supabase
- You're using the `anon` (publishable) key instead of the `service_role` (secret) key. Switch to the secret key.

---

## License

MIT
