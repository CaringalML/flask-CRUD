import os
from flask import Flask
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'fallback-secret')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    from extensions import db, migrate
    db.init_app(app)
    migrate.init_app(app, db)

    # Import model so Alembic can detect schema changes
    from models import Item

    from routes import main
    app.register_blueprint(main)

    print("Successfully initialized Supabase connection!")
    print("SQLAlchemy connected for migrations!")

    return app

if __name__ == '__main__':
    app = create_app()
    debug_mode = os.getenv('FLASK_ENV') != 'production'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)