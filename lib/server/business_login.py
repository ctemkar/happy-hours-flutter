from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql

app = Flask(__name__)
CORS(app)

# --- Database Config ---
DB_HOST = "87.106.214.100"
DB_USER = "happyuser"
DB_PASSWORD = "HappyUser@2025"
DB_NAME = "happy_hours_businesses"

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )

def handle_business_login():
    if request.method == "OPTIONS":
        return ("", 204)
    if request.method == "GET":
        return jsonify({"ok": True, "message": "business_login endpoint is alive. Use POST with JSON."}), 200

    data = request.get_json(silent=True) or {}
    email = data.get("email")
    if not email:
        return jsonify({"success": False, "message": "Email required"}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT `Name` FROM `happy_hours_global_test` WHERE `email`=%s LIMIT 1",
                (email,)
            )
            business = cursor.fetchone()
        conn.close()

        if business:
            return jsonify({
                "success": True,
                "message": "Login successful",
                "business_name": business["Name"]
            }), 200
        else:
            return jsonify({"success": False, "message": "Email not found"}), 404

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

# Expose BOTH routes to be safe
@app.route("/happy-hours-api/business_login", methods=["GET", "POST", "OPTIONS"])
def business_login_prefixed():
    return handle_business_login()

@app.route("/business_login", methods=["GET", "POST", "OPTIONS"])
def business_login_unprefixed():
    return handle_business_login()

if __name__ == "__main__":
    # Make sure this is the script actually being run by your process
    app.run(host="0.0.0.0", port=5000, debug=True)