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

# ================== Config ==================
DB_HOST = "87.106.214.100"
DB_USER = "happyuser"
DB_PASS = "HappyUser@2025"
DB_NAME = "intervhappy_hours_businesses"   # you used this in your original file

# External services
TEXTBEE_URL = "http://192.168.0.100:8080/sms/send"  # reachable only if on same LAN
TEXTBEE_API_KEY = "1bccf6bf-4e98-4ad6-899d-2ce9f48d5234"

FROM_EMAIL = "no-reply@app.lovehappyhours.com"
SMTP_SERVER = "localhost"
SMTP_PORT = 25

# Optional: verification link under your own domain (update if needed)
VERIFY_LINK_BASE = "https://customercallsapp.com/prod/customercallsapp/verified.php"
# Example if you later move it:
# VERIFY_LINK_BASE = "https://app.lovehappyhours.com/verify"

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

# ================== SMS Sender ==================
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

# ================== Route Function ==================
def business_registration():
    # Accept JSON or form-encoded
    data = request.get_json(silent=True) or (request.form.to_dict() if request.form else {})
    logMessage("POST data: " + str(data))

    # Extract fields
    businessName   = data.get('businessName', '').strip()
    ownerName      = data.get('ownerName', '').strip()
    email          = data.get('email', '').strip()
    phone          = data.get('phone', '').strip()
    address        = data.get('address', '').strip()
    city           = data.get('city', '').strip()
    state          = data.get('state', '').strip()
    country        = data.get('country', '').strip()
    pin            = data.get('pin', '').strip()
    category       = data.get('category', '').strip()
    description    = data.get('description', '').strip()
    openHours      = data.get('open_hours', '').strip()
    happyHourStart = data.get('happy_hour_start', '').strip()
    happyHourEnd   = data.get('happy_hour_end', '').strip()
    happyHourYesNo = data.get('happy_hour_yes_no', 'No').strip()
    remark         = data.get('remark', '').strip()
    latitude       = data.get('latitude', '').strip()
    longitude      = data.get('longitude', '').strip()

    # Basic validation (optional, expand as needed)
    if not businessName or not ownerName or not email:
        return jsonify({"status": "error", "message": "businessName, ownerName, and email are required"}), 400

    token    = secrets.token_hex(16)
    verified = 0
    uniqID   = secrets.token_hex(8)

    try:
        # Connect to DB
        conn = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME, charset='utf8mb4')
        cursor = conn.cursor()

        sql = """
            INSERT INTO happy_hours_global_test
            (happy_hours_id, owner_name, email, Name, Description, Address, business_category, city, country, Open_hours, 
             Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, Telephone, Remark, latitude, longitude, token, verified) 
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """

        cursor.execute(sql, (
            uniqID, ownerName, email, businessName, description, address, category, city, country,
            openHours, happyHourStart, happyHourEnd, happyHourYesNo, phone, remark, latitude, longitude, token, verified
        ))

        conn.commit()
        cursor.close()
        conn.close()

        logMessage(f"Insert successful for email: {email}")

        # Send verification mail
        verifyLink = f"{VERIFY_LINK_BASE}?email={email}&token={token}"
        subject = "Verify Your Business Registration"
        message_body = f"Hi {ownerName},\n\nPlease verify your business registration by clicking:\n{verifyLink}\n\nThank you!"

        try:
            msg = MIMEText(message_body)
            msg["Subject"] = subject
            msg["From"] = FROM_EMAIL
            msg["To"] = email

            with smtplib.SMTP(SMTP_SERVER, SMTP_PORT, timeout=20) as server:
                server.sendmail(FROM_EMAIL, [email], msg.as_string())

            logMessage(f"Mail sent to {email}")

            # Send SMS via TextBee (best effort)
            if phone:
                smsMessage = f"Hi {ownerName}! A verification email has been sent to {email}. Please check your inbox to activate your business registration."
                sendSMS_TextBee(phone, smsMessage)

        except Exception as e:
            logMessage(f"Mail/SMS step failed for {email}: {str(e)}")

        return jsonify({"status": "success", "message": "Business registered successfully. Verification email & SMS sent."})

    except Exception as e:
        logMessage(f"DB insert failed: {str(e)}")
        return jsonify({"status": "error", "message": "DB insert failed."}), 500