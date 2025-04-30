from flask import Blueprint, jsonify, request
from .db import get_db_connection
from mysql.connector import Error
from app.db import fetch_all
from datetime import datetime, timedelta

main = Blueprint('main', __name__)
products = Blueprint('product', __name__)
inbounds = Blueprint('inbound', __name__)
sales = Blueprint('sale', __name__)
goals = Blueprint('goal', __name__)
summary = Blueprint('summary', __name__)
graph = Blueprint('graph', __name__)

"""Fetch all from db"""
def fetch_all(query, params=None):
    """
    Executes a SELECT query and fetches all results.
    
    :param query: SQL query string
    :param params: Optional tuple of parameters for the query
    :return: List of results (each row as a dictionary) or an empty list if no records are found
    """
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(query, params or ())
        results = cursor.fetchall()

        return results
    except Exception as e:
        print(f"Database error: {e}")
        return []
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
 
 
@main.route('/api/test-connection', methods=['GET'])
def test_connection():
    print("App connected to backend!")
    return jsonify({"message": "App connected to backend!"}), 200

products = Blueprint('products', __name__)

@products.route('/products', methods=['POST'])
def add_product():
    data = request.get_json()

    if data is None:  
        print("No JSON payload received - returning 400")
        return jsonify({"error": "Invalid or missing JSON data"}), 400

    # Extract data from the request
    product_name = data.get('product_name')
    product_category = data.get('product_category')
    description = data.get('description')
    cost_price = data.get('cost_price')
    selling_price = data.get('selling_price')
    supplier_name = data.get('supplier_name')
    phone_number = data.get('phone_number')

    # Validate required fields
    if not all([product_name, product_category, description, cost_price, selling_price, supplier_name, phone_number]):
        print("Missing fields - All fields are required")
        return jsonify({"error": "All fields are required"}), 400

    try:
        connection = get_db_connection()

        if connection is None:
            print("Database connection failed")
            return jsonify({"error": "Failed to connect to database"}), 500

        print("Database connection established")

        cursor = connection.cursor()

        # Insert data into the products table
        sql = """
        INSERT INTO products (product_name, product_category, descriptions, cost_price, selling_price, supplier_name, phone_number)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (product_name, product_category, description, cost_price, selling_price, supplier_name, phone_number))
        connection.commit()

        print("Product added successfully")
        return jsonify({"message": "Product added successfully"}), 201
 
    except Exception as e:
        print(f"Database Error: {e}")
        return jsonify({"error": "Database error", "details": str(e)}), 500

    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'connection' in locals():
            connection.close()
    

@products.route('/fetch-products', methods=['GET'])
def fetch_products():
    try:
        # Modify query to select both product_name and product_id
        query = "SELECT id, product_name FROM products"
        products = fetch_all(query)

        print("Fetched products:", products)  # Debugging

        if products:
            # Create a dictionary mapping product_name to product_id
            product_dict = {product['product_name']: product['id'] for product in products}
            
            # Return the product dictionary as JSON
            return jsonify(product_dict), 200
        else:
            return jsonify({"message": "No products found"}), 404
    except Exception as e:
        print(f"Error fetching products: {e}")
        return jsonify({"error": "Failed to fetch products"}), 500
    
  
@inbounds.route('/inbounds', methods=['POST'])
def add_new_inbound():
    try:
        data = request.json
        product_id = data['product_id']
        stock_unit = data['stock_unit']
        quantity = data['quantity']

        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                # Insert inbound
                cursor.execute("""
                    INSERT INTO inbounds (product_id, stock_unit, quantity)
                    VALUES (%s, %s, %s)
                """, (product_id, stock_unit, quantity))

                # Update current_inbounds in one operation
                cursor.execute("""
                    INSERT INTO current_inbounds (product_id, product_name, total_quantity)
                    SELECT %s, p.product_name, %s
                    FROM products p WHERE p.id = %s
                    ON DUPLICATE KEY UPDATE
                        total_quantity = total_quantity + VALUES(total_quantity),
                        last_updated = CURRENT_TIMESTAMP
                """, (product_id, quantity, product_id))

                connection.commit()

        return jsonify({'message': 'Inbound added successfully'}), 201

    except KeyError:
        return jsonify({'error': 'Missing required fields'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500  
     
@inbounds.route('/recent-inbounds', methods=['GET'])
def get_recent_inbounds():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        query = """
        SELECT 
            p.product_name, 
            i.quantity,
            i.created_at
        FROM inbounds i
        JOIN products p ON i.product_id = p.id
        ORDER BY i.created_at DESC
        LIMIT 3
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Format dates to strings
        for result in results:
            if 'created_at' in result and result['created_at']:
                result['created_at'] = result['created_at'].isoformat()
        
        return jsonify(results)
    
    except Exception as e:
        print(f"Error fetching inbounds: {str(e)}")
        return jsonify({"error": "Failed to fetch inbounds"}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@inbounds.route('/total-inbounds', methods=['GET'])
def get_total_inbounds():
    connection = None
    cursor = None
    
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500
            
        cursor = connection.cursor(dictionary=True)
        
        # Get current inventory levels from current_inbounds table
        query = """
        SELECT 
            COALESCE(SUM(total_quantity), 0) AS total_inventory,
            COUNT(DISTINCT product_id) AS product_count
        FROM current_inbounds
        """
        cursor.execute(query)
        result = cursor.fetchone()
        
        print(f"Current inventory result: {result}")
        
        return jsonify({
            "total_inbounds": int(result['total_inventory']),
            "unique_products": result['product_count']
        })
         
    except Exception as e:
        print(f"Error fetching current inventory: {e}")
        return jsonify({"error": str(e)}), 500
        
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

#Fetch Product by id and the quantity
@inbounds.route('/product-stock/<int:product_id>', methods=['GET'])
def get_product_stock(product_id):
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        query = """
            SELECT 
                p.product_name,
                COALESCE(ci.total_quantity, 0) as remaining_quantity
            FROM products p
            LEFT JOIN current_inbounds ci ON p.id = ci.product_id
            WHERE p.id = %s
        """
        cursor.execute(query, (product_id,))
        result = cursor.fetchone()
        
        if result:
            return jsonify({
                "product_name": result['product_name'],
                "remaining_quantity": result['remaining_quantity']
            }), 200
        else:
            return jsonify({"error": "Product not found"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@sales.route('/sales', methods=['POST'])
def add_sale():
    try:
        data = request.json
        product_id = data['product_id']
        quantity_sold = float(data['quantity_sold'])  # Ensure numeric value
        metric = data['metric']

        with get_db_connection() as connection:
            with connection.cursor(dictionary=True) as cursor:
                # 1. Verify product exists
                cursor.execute("SELECT id, product_name FROM products WHERE id = %s", (product_id,))
                product = cursor.fetchone()
                if not product:
                    return jsonify({"error": "Product not found"}), 404

                # 2. Check current stock with locking
                cursor.execute("""
                    SELECT total_quantity 
                    FROM current_inbounds 
                    WHERE product_id = %s
                    FOR UPDATE
                """, (product_id,))
                stock = cursor.fetchone()

                if not stock:
                    # Initialize stock if doesn't exist
                    cursor.execute("""
                        INSERT INTO current_inbounds (product_id, product_name, total_quantity)
                        VALUES (%s, %s, 0)
                    """, (product_id, product['product_name']))
                    stock = {'total_quantity': 0}

                # 3. Validate sufficient stock
                if stock['total_quantity'] < quantity_sold:
                    return jsonify({
                        "error": "Insufficient stock",
                        "available": stock['total_quantity']
                    }), 400

                # 4. Record the sale
                cursor.execute(""" 
                    INSERT INTO sales (product_id, quantity_sold, metric, sale_date)
                    VALUES (%s, %s, %s, NOW())
                """, (product_id, quantity_sold, metric))

                # 5. Update inventory
                cursor.execute("""
                    UPDATE current_inbounds
                    SET 
                        total_quantity = total_quantity - %s,
                        last_updated = NOW()
                    WHERE product_id = %s
                """, (quantity_sold, product_id))

                # 6. Update sales summary
                cursor.execute("""
                    INSERT INTO product_sales_summary (product_id, product_name, total_quantity_sold)
                    VALUES (%s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        total_quantity_sold = total_quantity_sold + VALUES(total_quantity_sold),
                        last_updated = NOW()
                """, (product_id, product['product_name'], quantity_sold))

                connection.commit()

                # Return complete sale details
                return jsonify({
                    'message': 'Sale recorded successfully',
                    'sale': {
                        'product_id': product_id,
                        'product_name': product['product_name'],
                        'quantity_sold': quantity_sold,
                        'metric': metric,
                        'remaining_stock': stock['total_quantity'] - quantity_sold
                    }
                }), 201

    except KeyError as e:
        return jsonify({'error': f'Missing required field: {str(e)}'}), 400
    except ValueError:
        return jsonify({'error': 'Invalid quantity value'}), 400
    except Exception as e:
        return jsonify({'error': f'Failed to record sale: {str(e)}'}), 500
     
@sales.route('/recent-sales', methods=['GET'])
def get_recent_sales():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        query = """
        SELECT 
            p.product_name, 
            s.quantity_sold, 
            s.metric,
            s.sale_date
        FROM sales s
        JOIN products p ON s.product_id = p.id
        ORDER BY s.sale_date DESC
        LIMIT 3
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Format dates to strings
        for result in results:
            if 'sale_date' in result and result['sale_date']:
                result['sale_date'] = result['sale_date'].isoformat()
        
        return jsonify(results)
    
    except Exception as e:
        print(f"Error fetching sales: {str(e)}")
        return jsonify({"error": "Failed to fetch sales"}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@sales.route('/all-sales', methods=['GET'])
def get_all_sales():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        query = """
        SELECT 
            p.product_name as product_name, 
            CAST(s.quantity_sold AS SIGNED) as quantity_sold,  # Ensure numeric type
            s.metric as metric,
            DATE_FORMAT(s.sale_date, '%Y-%m-%dT%H:%i:%s') as sale_date
        FROM sales s
        JOIN products p ON s.product_id = p.id
        ORDER BY s.sale_date DESC
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        return jsonify({
            "success": True,
            "data": results
        })
        
    except Exception as e:
        print(f"Error fetching sales: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@sales.route('/total-sales', methods=['GET'])
def get_total_sales():
    connection = None
    cursor = None
    
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        # Get total quantity sold across all products
        query = """
        SELECT 
            COALESCE(SUM(quantity_sold), 0) AS total_sales,
            COUNT(DISTINCT product_id) AS products_sold
        FROM sales
        """
        cursor.execute(query)
        result = cursor.fetchone()
        
        return jsonify({
            "total_sales": float(result['total_sales']),
            "products_sold": result['products_sold']
        })
        
    except Exception as e:
        print(f"Error fetching total sales: {str(e)}")
        return jsonify({"error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@graph.route('/salesanalytics', methods=['GET'])
def get_sales_analytics():
    try:
        print("✅ /salesanalytics route hit")

        period = request.args.get('period', 'week')
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        end_date = datetime.now()
        if period == 'day':
            start_date = end_date - timedelta(days=1)
            group_format = "%H:00"
            label_format = "%H:%M"
        elif period == 'week':
            start_date = end_date - timedelta(weeks=1)
            group_format = "%Y-%m-%d"
            label_format = "%a"
        elif period == 'month':
            start_date = end_date - timedelta(days=30)
            group_format = "%Y-%m-%d"
            label_format = "%d"
        elif period == 'six_months':
            start_date = end_date - timedelta(days=180)
            group_format = "%Y-%m"
            label_format = "%b"
        elif period == 'year':
            start_date = end_date - timedelta(days=365)
            group_format = "%Y-%m"
            label_format = "%b"
        else:
            return jsonify({"success": False, "error": "Invalid period parameter"}), 400

        query = f"""
        SELECT 
            DATE_FORMAT(s.sale_date, %s) as time_group,
            SUM(s.quantity_sold) as total_quantity,
            DATE_FORMAT(MIN(s.sale_date), %s) as time_label
        FROM sales s
        WHERE s.sale_date BETWEEN %s AND %s
        GROUP BY time_group
        ORDER BY s.sale_date ASC
        """
        
        cursor.execute(query, (
            group_format,
            label_format,
            start_date,
            end_date
        ))
        
        results = cursor.fetchall()
        formatted_results = [
            {
                "label": row['time_label'],
                "value": float(row['total_quantity'])
            }
            for row in results
        ]
        
        return jsonify({
            "success": True,
            "period": period,
            "data": formatted_results
        })

    except Exception as e:
        print(f"Error fetching sales analytics: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close() 


@inbounds.route('/fetchallinbounds', methods=['GET'])
def get_all_inbounds():
    try:
            connection = get_db_connection()
            cursor = connection.cursor(dictionary=True)
            
            query = """
            SELECT 
                p.product_name, 
                i.quantity,
                i.created_at
            FROM inbounds i
            JOIN products p ON i.product_id = p.id
            ORDER BY i.created_at DESC
            """
            cursor.execute(query)
            results = cursor.fetchall()
            
            # Format dates to strings
            for result in results:
                if 'created_at' in result and result['created_at']:
                    result['created_at'] = result['created_at'].isoformat()
            
            return jsonify(results)
        
    except Exception as e:
        print(f"Error fetching inbounds: {str(e)}")
        return jsonify({"error": "Failed to fetch inbounds"}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@goals.route('/goals', methods=['GET', 'POST'])
def handle_goals():
    if request.method == 'POST':
        try:
            print("\n=== NEW GOAL REQUEST RECEIVED ===")
            
            # Check if a goal already exists for today
            with get_db_connection() as connection:
                with connection.cursor(dictionary=True) as cursor:
                    cursor.execute("""
                        SELECT goal_id 
                        FROM goal 
                        WHERE DATE(last_updated) = CURRENT_DATE()
                        LIMIT 1
                    """)
                    existing_goal = cursor.fetchone()
                    
                    if existing_goal:
                        return jsonify({
                            'error': 'A goal already exists for today',
                            'code': 'GOAL_EXISTS'
                        }), 400

            # Rest of your POST handling code...
            data = request.get_json(force=True)
            goal_quantity = float(data.get('goal_quantity', 0))

            with get_db_connection() as connection:
                with connection.cursor(dictionary=True) as cursor:
                    cursor.execute("""
                        SELECT COALESCE(SUM(total_quantity_sold), 0) AS daily_sales 
                        FROM product_sales_summary 
                        WHERE DATE(last_updated) = CURRENT_DATE()
                    """)
                    result = cursor.fetchone()
                    daily_sales = float(result['daily_sales'])

                    cursor.execute("""
                        INSERT INTO goal (goal_quantity, current_sales)
                        VALUES (%s, %s)
                    """, (goal_quantity, daily_sales))

                    goal_id = cursor.lastrowid
                    progress = round((daily_sales / goal_quantity) * 100, 2) if goal_quantity else 0
                    connection.commit()

                    return jsonify({
                        'message': 'New daily goal created successfully',
                        'goal': {
                            'goal_id': goal_id,
                            'target': goal_quantity,
                            'today_sales': daily_sales,
                            'progress': progress,
                        }
                    }), 201

        except ValueError as e:
            return jsonify({'error': f"Invalid number format: {str(e)}"}), 400
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    else:  # GET request
        try:
            with get_db_connection() as connection:
                with connection.cursor(dictionary=True) as cursor:
                    # Get today's goal if it exists
                    cursor.execute("""
                        SELECT 
                            goal_id,
                            goal_quantity,
                            current_sales,
                            last_updated
                        FROM goal
                        WHERE DATE(last_updated) = CURRENT_DATE()
                        LIMIT 1
                    """)
                    goal = cursor.fetchone()

                    if not goal:
                        return jsonify({'message': 'No goal set for today'}), 404

                    # Get today's sales
                    cursor.execute("""
                        SELECT COALESCE(SUM(total_quantity_sold), 0) AS today_sales
                        FROM product_sales_summary
                        WHERE DATE(last_updated) = CURRENT_DATE()
                    """)
                    result = cursor.fetchone()
                    today_sales = float(result['today_sales'])
                    
                    goal_quantity = float(goal['goal_quantity'])
                    current_progress = round((today_sales / goal_quantity) * 100, 2) if goal_quantity else 0

                    return jsonify({
                        'goal': {
                            'target': goal_quantity,
                            'current_sales': today_sales,
                            'progress': current_progress,
                            'last_updated': goal['last_updated'].isoformat()
                        }
                    }), 200

        except Exception as e:
            return jsonify({'error': str(e)}), 500

@goals.route('/today-goal', methods=['GET'])
def get_today_goal():
    try:
        with get_db_connection() as connection:
            with connection.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT goal_quantity 
                    FROM goal 
                    WHERE DATE(last_updated) = CURRENT_DATE()
                    LIMIT 1
                """)
                goal = cursor.fetchone()
                
                return jsonify({
                    'exists': goal is not None,
                    'goal': goal['goal_quantity'] if goal else None
                }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@goals.route('/current-sales', methods=['GET'])
def get_today_sales():
    try:
        with get_db_connection() as connection:
            with connection.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT COALESCE(SUM(total_quantity_sold), 0) AS sales
                    FROM product_sales_summary
                    WHERE DATE(last_updated) = CURRENT_DATE()
                """)
                result = cursor.fetchone()
                # Convert Decimal to float before JSON serialization
                sales = float(result['sales'])
                return jsonify({'sales': sales}), 200
    except Exception as e:
        return jsonify({'sales': 0.0}), 200
        
@summary.route('/summary', methods=['GET'])
def get_summary():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # Get total sales (convert to float to ensure compatibility)
        cursor.execute("SELECT SUM(CAST(amount_sold AS DECIMAL(10,2))) AS total_sales FROM sales")
        total_sales = cursor.fetchone()["total_sales"]
        total_sales = float(total_sales) if total_sales is not None else 0.0  # Ensure it's a float

        # Get total inbounds (convert to int) 
        cursor.execute("SELECT SUM(quantity) AS total_inbounds FROM inbounds")
        total_inbounds = cursor.fetchone()["total_inbounds"]
        total_inbounds = int(total_inbounds) if total_inbounds is not None else 0  # Ensure it's an int

        cursor.close()
        conn.close()

        print(f"Total Sales Retrieved: {total_sales}")  # Debugging
        print(f"Total Inbounds Retrieved: {total_inbounds}")  # Debugging

        return jsonify({
            "total_sales": total_sales,
            "total_inbounds": total_inbounds
        })

    except Exception as e:
        print(f"Error in get_summary: {str(e)}")
        return jsonify({"error": str(e)}), 500
