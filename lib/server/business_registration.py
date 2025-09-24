# business_registration.py
from flask import Flask, request, jsonify
from flask_cors import CORS  # Enable CORS
import pymysql
import requests
import smtplib
from email.mime.text import MIMEText
import os
import datetime
import secrets

app = Flask(__name__)
CORS(app)  # Enable CORS for all origins

# ================== Config ==================
DB_HOST = "mysql2-p2.ezhostingserver.com"
DB_USER = "sanjay"
DB_PASS = "BU@R9gr2971{"
DB_NAME = "interview_helper"

TEXTBEE_URL = "http://192.168.0.100:8080/sms/send"
TEXTBEE_API_KEY = "1bccf6bf-4e98-4ad6-899d-2ce9f48d5234"

FROM_EMAIL = "no-reply@customercallsapp.com"
SMTP_SERVER = "localhost"  # Change if using Gmail/other
SMTP_PORT = 25             # Change if needed

# ================== Logger ==================
def logMessage(message):
    logFile = os.path.join(os.path.dirname(__file__), "debug_log.txt")
    with open(logFile, "a") as f:
        f.write(f"{datetime.datetime.now()} | {message}\n")

# ================== SMS Sender ==================
def sendSMS_TextBee(toPhone, textMessage):
    try:
        payload = {
            "apikey": TEXTBEE_API_KEY,
            "to": toPhone,
            "message": textMessage
        }
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

# ================== API Endpoint ==================
@app.route("/business_registration", methods=["POST"])
def business_registration():
    data = request.form if request.form else request.json
    logMessage("POST data: " + str(data))

    # Get POST data
    businessName   = data.get('businessName', '')
    ownerName      = data.get('ownerName', '')
    email          = data.get('email', '')
    phone          = data.get('phone', '')
    address        = data.get('address', '')
    city           = data.get('city', '')
    country        = data.get('country', '')
    pin            = data.get('pin', '')
    category       = data.get('category', '')
    description    = data.get('description', '')
    openHours      = data.get('open_hours', '')
    happyHourStart = data.get('happy_hour_start', '')
    happyHourEnd   = data.get('happy_hour_end', '')
    happyHourYesNo = data.get('happy_hour_yes_no', 'No')
    remark         = data.get('remark', '')
    latitude       = data.get('latitude', '')
    longitude      = data.get('longitude', '')

    token    = secrets.token_hex(16)
    verified = 0
    uniqID   = secrets.token_hex(8)

    try:
        # Connect to DB
        conn = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME)
        cursor = conn.cursor()

        sql = """INSERT INTO happy_hours_global_test
            (happy_hours_id, owner_name, email, Name, Description, Address, business_category, city, country, Open_hours, 
            Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, Telephone, Remark, latitude, longitude, token, verified) 
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"""

        cursor.execute(sql, (
            uniqID, ownerName, email, businessName, description, address, category, city, country,
            openHours, happyHourStart, happyHourEnd, happyHourYesNo, phone, remark, latitude, longitude, token, verified
        ))

        conn.commit()
        cursor.close()
        conn.close()

        logMessage(f"Insert successful for email: {email}")

        # Send verification mail
        verifyLink = f"https://customercallsapp.com/prod/customercallsapp/verify.php?email={email}&token={token}"
        subject = "Verify Your Business Registration"
        message_body = f"Hi {ownerName},\n\nPlease verify your business registration by clicking:\n{verifyLink}\n\nThank you!"

        try:
            msg = MIMEText(message_body)
            msg["Subject"] = subject
            msg["From"] = FROM_EMAIL
            msg["To"] = email

            with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
                server.sendmail(FROM_EMAIL, [email], msg.as_string())

            logMessage(f"Mail sent to {email}")

            # Send SMS via TextBee
            smsMessage = f"Hi {ownerName}! A verification email has been sent to {email}. Please check your inbox to activate your business registration."
            sendSMS_TextBee(phone, smsMessage)

        except Exception as e:
            logMessage(f"Mail failed to {email}: {str(e)}")

        return jsonify({"status": "success", "message": "Business registered successfully. Verification email & SMS sent."})

    except Exception as e:
        logMessage(f"DB insert failed: {str(e)}")
        return jsonify({"status": "error", "message": "DB insert failed."})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
