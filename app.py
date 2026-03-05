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

    from routes import main
    app.register_blueprint(main)

    # Import models so Alembic can detect them
    from models import Item

    print("Successfully connected to PostgreSQL database!")
            
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)