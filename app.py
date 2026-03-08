import os
from flask import Flask
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'fallback-secret')

    # PostgreSQL — required, no SQLite fallback
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        raise RuntimeError(
            "DATABASE_URL environment variable is not set. "
            "A PostgreSQL connection string is required."
        )

    # Enforce PostgreSQL — reject SQLite or other backends
    if not database_url.startswith('postgresql://'):
        raise RuntimeError(
            f"Invalid DATABASE_URL: must be a PostgreSQL connection string "
            f"starting with 'postgresql://'. Got: {database_url[:20]}..."
        )

    app.config['SQLALCHEMY_DATABASE_URI'] = database_url
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # PostgreSQL connection pool settings
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_size': 5,
        'pool_recycle': 300,
        'pool_pre_ping': True,  # verify connections are alive before using
    }

    from extensions import db, migrate
    db.init_app(app)
    migrate.init_app(app, db)

    from routes import main
    app.register_blueprint(main)

    from models import Item

    print("Successfully connected to PostgreSQL database!")
    print("SQLAlchemy connected for migrations!")

    return app

if __name__ == '__main__':
    app = create_app()
    debug_mode = os.getenv('FLASK_ENV') != 'production'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)
