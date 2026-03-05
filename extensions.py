import os
from supabase import create_client, Client
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from dotenv import load_dotenv

load_dotenv()

# Supabase SDK client (used for CRUD operations in routes)
supabase: Client = create_client(
    os.environ.get("SUPABASE_URL"),
    os.environ.get("SUPABASE_KEY")
)

# SQLAlchemy + Flask-Migrate (used for database migrations)
db = SQLAlchemy()
migrate = Migrate()
