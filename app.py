import os
from flask import Flask
from extensions import db
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    # Ensure this variable is exactly what is in your .env
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL') 
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'fallback-secret')
    
    db.init_app(app)
    
    from routes import main
    app.register_blueprint(main)
    
    with app.app_context():
        try:
            db.create_all()
            print("Successfully connected to MySQL!")
        except Exception as e:
            print(f"Connection failed: {e}")
            
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)