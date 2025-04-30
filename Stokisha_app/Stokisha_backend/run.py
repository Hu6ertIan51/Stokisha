from app import create_app
from app.db import get_db_connection  
from migrations.migrations import apply_migrations

app = create_app()

def setup_database():  
    with app.app_context():
        try:
            db = get_db_connection()
            if db:
                apply_migrations(db) 
                print("Database migrations applied successfully.")
            else:
                print("Failed to connect to the database.")
        except Exception as e:
            print(f"Error during database setup: {e}")

if __name__ == '__main__':
    setup_database()  # Set up the database before running the app
    app.run(debug=True, host='0.0.0.0', port=5000)  # Start the Flask app 
