# Flask CRUD App — PythonAnywhere Deployment (v6)

A Flask CRUD application deployed on **PythonAnywhere** (free tier) using **SQLite** as the database. No Docker, no cloud infrastructure, no cost.

---

## Tech Stack

| Layer      | Technology                                      |
|------------|-------------------------------------------------|
| Backend    | Flask 3.0                                       |
| Database   | SQLite (file-based, stored on PythonAnywhere)   |
| Migrations | Flask-Migrate (Alembic)                         |
| Frontend   | HTMX 2.0 + Alpine.js 3.14                      |
| Styling    | Bootstrap 5.3 + Custom CSS                     |
| Hosting    | PythonAnywhere (free tier)                      |
| URL        | `https://nginxcaringal.pythonanywhere.com`      |

---

## Cost

| Resource             | Cost   |
|----------------------|--------|
| PythonAnywhere Free  | $0.00  |
| SQLite (file on disk)| $0.00  |
| **Total**            | **$0** |

> ⚠️ Free tier requires you to log in at least once per month and click **"Run until 1 month from today"** to keep the site alive. PythonAnywhere emails you a week before it expires.

---

## Prerequisites

- A [PythonAnywhere](https://www.pythonanywhere.com) free account
- Your code pushed to GitHub on the `v6` branch

---

## Deployment Steps

### Step 1 — Create a PythonAnywhere account

Go to [pythonanywhere.com](https://www.pythonanywhere.com) → Sign up for free.

Your app will be available at:
```
https://your-username.pythonanywhere.com
```

---

### Step 2 — Open a Bash console

Dashboard → **Consoles** → click **Bash**

---

### Step 3 — Clone the repository

```bash
git clone https://github.com/CaringalML/flask-CRUD.git
cd flask-CRUD
git checkout v6
```

---

### Step 4 — Create a virtual environment

```bash
mkvirtualenv --python=python3.11 flask-crud-env
```

Your prompt will change to:
```
(flask-crud-env) $
```

---

### Step 5 — Install dependencies

```bash
cd ~/flask-CRUD
pip install -r requirements.txt
```

---

### Step 6 — Create the .env file

```bash
nano .env
```

Paste this (replace `your-username` with your actual PythonAnywhere username):

```env
SECRET_KEY=dc1b1d111b3a7aa9454c5ac107ae174b291e99a58efd8749f81d086963e65aba
DATABASE_URL=sqlite:////home/your-username/flask-CRUD/flask_crud.db
```

> ⚠️ The 4 slashes in `sqlite:////` are correct — 3 for the absolute path prefix + 1 for the leading `/` of the path.

Save: `Ctrl+O` → `Enter` → `Ctrl+X`

---

### Step 7 — Run Flask-Migrate

```bash
flask db upgrade
```

Expected output:
```
Successfully connected to SQLite database!
INFO  [alembic.runtime.migration] Running upgrade -> xxxxxxxx, initial sqlite schema
```

This creates `flask_crud.db` on disk at `/home/your-username/flask-CRUD/flask_crud.db`.

---

### Step 8 — Create the Web App

1. Dashboard → **Web** tab → **Add a new web app**
2. Click **Next**
3. Select **Python 3.11**
4. Select **Manual configuration** (NOT Flask quickstart — that would overwrite your app.py)
5. Click **Next**

---

### Step 9 — Configure the WSGI file

In the Web tab, click the WSGI configuration file link:
```
/var/www/your-username_pythonanywhere_com_wsgi.py
```

Select all (`Ctrl+A`), delete everything, and paste:

```python
import sys
import os
from dotenv import load_dotenv

path = '/home/your-username/flask-CRUD'
if path not in sys.path:
    sys.path.insert(0, path)

load_dotenv(os.path.join(path, '.env'))

from app import create_app
application = create_app()
```

> ⚠️ Replace `your-username` with your actual PythonAnywhere username.

Click **Save**.

---

### Step 10 — Set the Virtualenv path

In the Web tab → **Virtualenv** section → click **"Enter path to a virtualenv, if desired"** and enter:

```
/home/your-username/.virtualenvs/flask-crud-env
```

Click the checkmark to save.

---

### Step 11 — Reload and visit

Scroll to the top of the Web tab → click **Reload your-username.pythonanywhere.com**

Then visit:
```
https://your-username.pythonanywhere.com
```

---

## Updating the App

When you push new code to the `v6` branch:

```bash
# In PythonAnywhere Bash console
cd ~/flask-CRUD
git pull origin v6
flask db upgrade    # only needed if you added new migrations
```

Then Web tab → **Reload**.

---

## File Structure on PythonAnywhere

```
/home/your-username/
├── flask-CRUD/                  ← your project root
│   ├── app.py
│   ├── extensions.py
│   ├── models.py
│   ├── routes.py
│   ├── requirements.txt
│   ├── .env                     ← created manually (not in git)
│   ├── flask_crud.db            ← SQLite database (created by flask db upgrade)
│   ├── migrations/
│   ├── static/
│   └── templates/
└── .virtualenvs/
    └── flask-crud-env/          ← virtual environment

/var/www/
└── your-username_pythonanywhere_com_wsgi.py  ← WSGI entry point
```

---

## How It Works

PythonAnywhere uses **WSGI** (Web Server Gateway Interface) to serve your Flask app — no Docker, no Nginx config needed. PythonAnywhere handles the web server layer internally.

```
Browser request
      ↓
PythonAnywhere web server
      ↓
WSGI file (/var/www/..._wsgi.py)
      ↓
create_app() → Flask app
      ↓
SQLite file (flask_crud.db on disk)
```

---

## Troubleshooting

### 500 error after reload
Check the error log: Web tab → **Error log** → `your-username.pythonanywhere.com.error.log`

### `ModuleNotFoundError`
Virtual environment not set or wrong path. Verify:
```
/home/your-username/.virtualenvs/flask-crud-env
```
Then reload.

### `OperationalError: no such table`
Migrations haven't run. In Bash console:
```bash
cd ~/flask-CRUD
flask db upgrade
```
Then reload.

### `sqlite3.OperationalError: unable to open database file`
Wrong path in `.env`. Check that `DATABASE_URL` uses your exact username and has 4 slashes:
```env
DATABASE_URL=sqlite:////home/your-username/flask-CRUD/flask_crud.db
```

### Site disabled / "Best before date" expired
Log in to PythonAnywhere → Web tab → click **"Run until 1 month from today"** → Reload.

### Changes not showing after git pull
You must reload after every code change:
Web tab → **Reload your-username.pythonanywhere.com**

---

## License

MIT