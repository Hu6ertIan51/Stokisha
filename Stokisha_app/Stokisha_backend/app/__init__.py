from flask import Flask
# Register Blueprints
from .routes import main
from .routes import products 
from .routes import inbounds 
from .routes import sales
from .routes import summary
from .routes import goals
from .routes import graph

from flask_cors import CORS
import os
from .db import get_db_connection
from migrations.migrations import run_migration

def create_app(): 
    app = Flask(__name__)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # Session handling
    app.secret_key = os.getenv('SECRET_KEY', 'thisproject')  

    # Load configurations from environment variables
    app.config['DB_HOST'] = os.getenv('DB_HOST', 'localhost')
    app.config['DB_USER'] = os.getenv('DB_USER', 'root')
    app.config['DB_PASSWORD'] = os.getenv('DB_PASSWORD', '')
    app.config['DB_NAME'] = os.getenv('DB_NAME', 'stokisha')

    app.register_blueprint(main)
    app.register_blueprint(products, url_prefix='/api')
    app.register_blueprint(inbounds, url_prefix='/api')
    app.register_blueprint(sales, url_prefix='/api')
    app.register_blueprint(goals, url_prefix='/api')
    app.register_blueprint(summary, url_prefix='/api')
    app.register_blueprint(graph, url_prefix='/api')

   
    # Run migrations within the app context
    with app.app_context():
        db_connection = get_db_connection()
        if db_connection:
            run_migration(db_connection, 'migrations/create_tables.sql')
        else:
            print("Failed to establish a database connection.")

    return app
