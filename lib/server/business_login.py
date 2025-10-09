from flask import Flask, request, jsonify
import pymysql

app = Flask(__name__)

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

@app.route("/business_login", methods=["POST"])
def business_login():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({"success": False, "message": "Email and Password required"}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT  * FROM business_owners WHERE email=%s AND password=%s",
                (email, password)
            )
            user = cursor.fetchone()
        conn.close()

        if user:
            return jsonify({
                "success": True,
                "message": "Login successful",
                "business_id": user["id"],   # include details you need
                "business_name": user["name"]
            })
        else:
            return jsonify({"success": False, "message": "Invalid credentials"}), 401

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
