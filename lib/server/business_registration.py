# business_registration.py
from flask import request, jsonify
import pymysql
import requests
import smtplib
from email.mime.text import MIMEText
import os
import datetime
import secrets
import logging
import hashlib

# ================== Config ==================
DB_HOST = "87.106.214.100"
DB_USER = "happyuser"
DB_PASS = "HappyUser@2025"
DB_NAME = "happy_hours_businesses"

# External services (best-effort)
TEXTBEE_URL = "http://192.168.0.100:8080/sms/send"  # reachable only if same LAN
TEXTBEE_API_KEY = "1bccf6bf-4e98-4ad6-899d-2ce9f48d5234"

FROM_EMAIL = "no-reply@app.lovehappyhours.com"
SMTP_SERVER = "localhost"
SMTP_PORT = 25

VERIFY_LINK_BASE = "https://customercallsapp.com/prod/customercallsapp/verified.php"

# ================== Logger ==================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("business_registration")

def logMessage(message: str):
    try:
        logFile = os.path.join(os.path.dirname(__file__), "debug_log.txt")
        with open(logFile, "a") as f:
            f.write(f"{datetime.datetime.now()} | {message}\n")
    except Exception:
        logger.info(message)

# ================== Helpers ==================
def as_text(v, default=""):
    if v is None:
        return default
    return str(v).strip()

def none_if_empty(v):
    s = as_text(v, "")
    return None if s == "" else s

def to_int_yes_no(value):
    if value is None:
        return None
    v = as_text(value).lower()
    if v in ("yes", "y", "true", "1"):
        return 1
    if v in ("no", "n", "false", "0"):
        return 0
    # numeric fallback
    try:
        return 1 if int(float(v)) != 0 else 0
    except Exception:
        return 0

def md5_hash(password: str) -> str:
    """Generate MD5 hash of password"""
    return hashlib.md5(password.encode('utf-8')).hexdigest()

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        charset="utf8mb4",
        autocommit=False,
    )

# ================== SMS Sender (best-effort) ==================
def sendSMS_TextBee(toPhone: str, textMessage: str) -> bool:
    try:
        payload = {"apikey": TEXTBEE_API_KEY, "to": toPhone, "message": textMessage}
        response = requests.post(TEXTBEE_URL, json=payload, timeout=20)
        if response.status_code == 200:
            logMessage(f"✅ SMS sent to {toPhone}: {response.text}")
            return True
        else:
            logMessage(f"❌ SMS send failed {response.status_code} {response.text}")
            return False
    except Exception as e:
        logMessage(f"❌ SMS send exception: {str(e)}")
        return False

# ================== Main Route Function ==================
def business_registration():
    # Accept JSON or form-encoded
    data = request.get_json(silent=True) or (request.form.to_dict() if request.form else {})
    logMessage("POST data: " + str({k: v for k, v in data.items() if k != 'password'}))  # Don't log password

    # Extract and normalize inputs (safe for any type)
    businessName     = as_text(data.get("businessName"))
    ownerName        = as_text(data.get("ownerName"))
    email            = as_text(data.get("email"))
    phone            = as_text(data.get("phone"))
    password         = as_text(data.get("password"))
    address          = as_text(data.get("address"))
    city             = as_text(data.get("city"))
    # Optional fields
    state            = as_text(data.get("state"))
    pin              = as_text(data.get("pin"))
    country          = as_text(data.get("country"))
    category         = as_text(data.get("category"))
    description      = as_text(data.get("description"))
    openHours        = as_text(data.get("open_hours"))
    happyHourStart   = as_text(data.get("happy_hour_start"))
    happyHourEnd     = as_text(data.get("happy_hour_end"))
    happyHourYesNo   = to_int_yes_no(data.get("happy_hour_yes_no", "No"))  # -> 1/0/None
    remark           = as_text(data.get("remark"))

    # Numeric/nullable fields
    latitude_raw     = data.get("latitude")
    longitude_raw    = data.get("longitude")
    latitude         = none_if_empty(latitude_raw)
    longitude        = none_if_empty(longitude_raw)

    # Basic validation
    required = {
        "businessName": businessName,
        "ownerName": ownerName,
        "email": email,
        "password": password,
        "city": city,
        "category": category,
    }
    missing = [k for k, v in required.items() if not v]
    if missing:
        return jsonify({"status": "error", "message": f"Missing required fields: {', '.join(missing)}"}), 400

    # Validate password length
    if len(password) < 6:
        return jsonify({"status": "error", "message": "Password must be at least 6 characters"}), 400

    # Hash the password using MD5
    password_hash = md5_hash(password)

    # IDs and flags
    happy_hours_id = secrets.token_hex(8)  # VARCHAR PK/ID
    token          = secrets.token_hex(16)
    verified       = 0

    # SQL with password field
    sql = """
        INSERT INTO happy_hours_global_test
        (happy_hours_id, owner_name, email, password, Name, Description, Address, business_category, city, country, Open_hours,
         Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, Telephone, Remark, latitude, longitude, token, verified)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """

    params = (
        happy_hours_id,     # VARCHAR id
        ownerName,
        email,
        password_hash,      # MD5 hashed password
        businessName,
        description,
        address,
        category,           # business_category (lowercase)
        city,
        country,
        openHours,
        happyHourStart,
        happyHourEnd,
        happyHourYesNo,     # int 1/0/None
        phone,
        remark,
        latitude,           # None if empty
        longitude,          # None if empty
        token,
        verified
    )

    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cursor:
                # Check if email already exists
                cursor.execute("SELECT email FROM happy_hours_global_test WHERE email = %s", (email,))
                if cursor.fetchone():
                    return jsonify({"status": "error", "message": "Email already registered"}), 400
                
                cursor.execute(sql, params)
            conn.commit()

        logMessage(f"Insert successful for email: {email} (id={happy_hours_id})")

        # Send verification email (best-effort)
        try:
            verifyLink = f"{VERIFY_LINK_BASE}?email={email}&token={token}"
            subject = "Verify Your Business Registration"
            message_body = f"Hi {ownerName},\n\nPlease verify your business registration by clicking:\n{verifyLink}\n\nThank you!"

            msg = MIMEText(message_body)
            msg["Subject"] = subject
            msg["From"] = FROM_EMAIL
            msg["To"] = email

            with smtplib.SMTP(SMTP_SERVER, SMTP_PORT, timeout=20) as server:
                server.sendmail(FROM_EMAIL, [email], msg.as_string())

            logMessage(f"Mail sent to {email}")

            # Send SMS via TextBee (best-effort)
            if phone:
                smsMessage = f"Hi {ownerName}! A verification email has been sent to {email}. Please check your inbox to activate your business registration."
                sendSMS_TextBee(phone, smsMessage)

        except Exception as e:
            logMessage(f"Mail/SMS step failed for {email}: {str(e)}")

        return jsonify({"status": "success", "message": "Business registered successfully. Verification email & SMS sent.", "id": happy_hours_id}), 200

    except Exception as e:
        logMessage(f"DB insert failed: {repr(e)}")
        return jsonify({"status": "error", "message": f"DB insert failed: {str(e)}"}), 500