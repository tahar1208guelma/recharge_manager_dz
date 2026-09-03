#!/usr/bin/env python3
"""
Recharge Manager DZ - SaaS License Server & Web Admin Dashboard
Provides:
- REST API for License Activation, Online Verification, Device Management
- Web Admin Dashboard with responsive UI & analytics
- Cryptographic HMAC-SHA256 Token Generation & Device Binding
"""

import sys
import os
import json
import time
import hmac
import hashlib
import sqlite3
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime, timedelta

PORT = 8088
SECRET_KEY = "DZ_LICENSE_SECRET_KEY_SIGNING_2026"
DB_PATH = os.path.join(os.path.dirname(__file__), "database.sqlite")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS licenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            license_id TEXT UNIQUE NOT NULL,
            customer_id TEXT NOT NULL,
            customer_name TEXT,
            plan TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            start_date TEXT NOT NULL,
            expiry_date TEXT,
            max_devices INTEGER DEFAULT 1,
            device_id TEXT,
            features TEXT NOT NULL,
            last_check TEXT NOT NULL,
            offline_grace_period INTEGER DEFAULT 7,
            token TEXT
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            license_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            activated_at TEXT NOT NULL,
            last_seen TEXT NOT NULL,
            ip_address TEXT,
            UNIQUE(license_id, device_id)
        )
    ''')

    # Seed sample licenses if empty
    cursor.execute("SELECT COUNT(*) FROM licenses")
    if cursor.fetchone()[0] == 0:
        now = datetime.utcnow()
        # 1. Yearly Pro License
        yearly_exp = now + timedelta(days=365)
        cursor.execute('''
            INSERT INTO licenses (license_id, customer_id, customer_name, plan, status, created_at, start_date, expiry_date, max_devices, device_id, features, last_check, offline_grace_period)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            "DZ-YEARLY-2026-ABCD-1234",
            "CUST-001",
            "نقطة بيع البريد السريع - الجزائر",
            "YEARLY",
            "ACTIVE",
            now.isoformat(),
            now.isoformat(),
            yearly_exp.isoformat(),
            3,
            "",
            json.dumps(["RECHARGE", "HISTORY", "CUSTOMERS", "PRINT", "EXPORT", "REPORTS"]),
            now.isoformat(),
            7
        ))

        # 2. Monthly Starter License
        monthly_exp = now + timedelta(days=30)
        cursor.execute('''
            INSERT INTO licenses (license_id, customer_id, customer_name, plan, status, created_at, start_date, expiry_date, max_devices, device_id, features, last_check, offline_grace_period)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            "DZ-MONTHLY-2026-XYZ-9999",
            "CUST-002",
            "محل الهواتف وخدمات الشحن - وهران",
            "MONTHLY",
            "ACTIVE",
            now.isoformat(),
            now.isoformat(),
            monthly_exp.isoformat(),
            1,
            "",
            json.dumps(["RECHARGE", "HISTORY", "CUSTOMERS", "PRINT", "EXPORT"]),
            now.isoformat(),
            7
        ))

        # 3. Lifetime VIP License
        cursor.execute('''
            INSERT INTO licenses (license_id, customer_id, customer_name, plan, status, created_at, start_date, expiry_date, max_devices, device_id, features, last_check, offline_grace_period)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            "DZ-LIFETIME-2026-VIP-GOLD",
            "CUST-003",
            "موزع خدمات الاتصالات المركزي - قسنطينة",
            "LIFETIME",
            "ACTIVE",
            now.isoformat(),
            now.isoformat(),
            None,
            5,
            "",
            json.dumps(["RECHARGE", "HISTORY", "CUSTOMERS", "PRINT", "EXPORT", "REPORTS", "MULTI_USER"]),
            now.isoformat(),
            14
        ))
        conn.commit()
    conn.close()

def generate_token(license_id, device_id, plan, expiry_date_str):
    payload = f"{license_id}|{device_id}|{plan}|{expiry_date_str or 'LIFETIME'}"
    sig = hmac.new(SECRET_KEY.encode('utf-8'), payload.encode('utf-8'), hashlib.sha256).hexdigest()
    return sig

class LicenseRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith("/api/admin/licenses"):
            self.handle_list_licenses()
        elif parsed.path.startswith("/api/admin/stats"):
            self.handle_stats()
        elif parsed.path == "/" or parsed.path.startswith("/static/"):
            # Serve Static Admin Dashboard
            if parsed.path == "/":
                self.path = "/server/static/index.html"
            else:
                self.path = "/server" + parsed.path
            return super().do_GET()
        else:
            self.send_error(404, "Endpoint not found")

    def do_POST(self):
        parsed = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b'{}'
        try:
            data = json.loads(body.decode('utf-8'))
        except Exception:
            data = {}

        if parsed.path == "/api/license/activate":
            self.handle_activate(data)
        elif parsed.path == "/api/license/verify":
            self.handle_verify(data)
        elif parsed.path == "/api/license/deactivate":
            self.handle_deactivate(data)
        elif parsed.path == "/api/admin/licenses":
            self.handle_create_license(data)
        else:
            self.send_error(404, "Unknown POST endpoint")

    def handle_activate(self, data):
        license_key = data.get("license_key", "").strip()
        device_id = data.get("device_id", "").strip()
        customer_name = data.get("customer_name", "").strip()

        if not license_key or not device_id:
            return self.send_json(400, {"success": False, "message": "Missing license_key or device_id"})

        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM licenses WHERE license_id = ?", (license_key,))
        row = cursor.fetchone()

        if not row:
            conn.close()
            return self.send_json(404, {"success": False, "message": "License key not found"})

        # row: (id, license_id, customer_id, customer_name, plan, status, created_at, start_date, expiry_date, max_devices, device_id, features, last_check, offline_grace_period, token)
        status = row[5]
        max_devices = row[9]
        plan = row[4]
        expiry_date = row[8]
        features = row[11]
        offline_grace = row[13]

        if status != "ACTIVE" and status != "TRIAL":
            conn.close()
            return self.send_json(403, {"success": False, "message": f"License is {status}"})

        # Check device count
        cursor.execute("SELECT COUNT(*) FROM devices WHERE license_id = ?", (license_key,))
        device_count = cursor.fetchone()[0]

        cursor.execute("SELECT * FROM devices WHERE license_id = ? AND device_id = ?", (license_key, device_id))
        existing_device = cursor.fetchone()

        now_str = datetime.utcnow().isoformat()

        if not existing_device:
            if device_count >= max_devices:
                conn.close()
                return self.send_json(400, {
                    "success": False,
                    "message": f"Maximum devices limit ({max_devices}) reached for this license"
                })
            cursor.execute('''
                INSERT INTO devices (license_id, device_id, activated_at, last_seen, ip_address)
                VALUES (?, ?, ?, ?, ?)
            ''', (license_key, device_id, now_str, now_str, self.client_address[0]))

        token = generate_token(license_key, device_id, plan, expiry_date)
        cursor.execute('''
            UPDATE licenses 
            SET device_id = ?, last_check = ?, token = ?, customer_name = COALESCE(NULLIF(?, ''), customer_name)
            WHERE license_id = ?
        ''', (device_id, now_str, token, customer_name, license_key))
        conn.commit()

        # Fetch updated
        cursor.execute("SELECT * FROM licenses WHERE license_id = ?", (license_key,))
        updated = cursor.fetchone()
        conn.close()

        res_data = {
            "license_id": updated[1],
            "customer_id": updated[2],
            "customer_name": updated[3],
            "plan": updated[4],
            "status": updated[5],
            "created_at": updated[6],
            "start_date": updated[7],
            "expiry_date": updated[8],
            "max_devices": updated[9],
            "device_id": device_id,
            "features": json.loads(updated[11]) if updated[11] else [],
            "last_check": updated[12],
            "offline_grace_period": updated[13],
            "token": token
        }
        return self.send_json(200, {"success": True, "data": res_data})

    def handle_verify(self, data):
        license_key = data.get("license_key", "").strip()
        device_id = data.get("device_id", "").strip()

        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM licenses WHERE license_id = ?", (license_key,))
        row = cursor.fetchone()

        if not row:
            conn.close()
            return self.send_json(404, {"success": False, "message": "License not found"})

        now_str = datetime.utcnow().isoformat()
        token = generate_token(row[1], device_id, row[4], row[8])

        cursor.execute('''
            UPDATE devices SET last_seen = ?, ip_address = ? WHERE license_id = ? AND device_id = ?
        ''', (now_str, self.client_address[0], license_key, device_id))
        cursor.execute('''
            UPDATE licenses SET last_check = ?, token = ? WHERE license_id = ?
        ''', (now_str, token, license_key))
        conn.commit()

        cursor.execute("SELECT * FROM licenses WHERE license_id = ?", (license_key,))
        updated = cursor.fetchone()
        conn.close()

        res_data = {
            "license_id": updated[1],
            "customer_id": updated[2],
            "customer_name": updated[3],
            "plan": updated[4],
            "status": updated[5],
            "created_at": updated[6],
            "start_date": updated[7],
            "expiry_date": updated[8],
            "max_devices": updated[9],
            "device_id": device_id,
            "features": json.loads(updated[11]) if updated[11] else [],
            "last_check": updated[12],
            "offline_grace_period": updated[13],
            "token": token
        }
        return self.send_json(200, {"success": True, "data": res_data})

    def handle_deactivate(self, data):
        license_key = data.get("license_key", "").strip()
        device_id = data.get("device_id", "").strip()

        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM devices WHERE license_id = ? AND device_id = ?", (license_key, device_id))
        conn.commit()
        conn.close()
        return self.send_json(200, {"success": True, "message": "Device unbound successfully"})

    def handle_create_license(self, data):
        plan = data.get("plan", "YEARLY").upper()
        customer_name = data.get("customer_name", "New Customer")
        max_devices = int(data.get("max_devices", 1))
        days = int(data.get("days", 365))

        now = datetime.utcnow()
        expiry = (now + timedelta(days=days)).isoformat() if plan != "LIFETIME" else None
        rand_id = f"DZ-{plan}-{now.year}-{os.urandom(2).hex().upper()}-{os.urandom(2).hex().upper()}"

        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO licenses (license_id, customer_id, customer_name, plan, status, created_at, start_date, expiry_date, max_devices, device_id, features, last_check, offline_grace_period)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            rand_id,
            f"CUST-{os.urandom(3).hex().upper()}",
            customer_name,
            plan,
            "ACTIVE",
            now.isoformat(),
            now.isoformat(),
            expiry,
            max_devices,
            "",
            json.dumps(["RECHARGE", "HISTORY", "CUSTOMERS", "PRINT", "EXPORT", "REPORTS"]),
            now.isoformat(),
            7
        ))
        conn.commit()
        conn.close()
        return self.send_json(201, {"success": True, "license_id": rand_id, "plan": plan, "expiry_date": expiry})

    def handle_list_licenses(self):
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM licenses ORDER BY id DESC")
        rows = cursor.fetchall()
        licenses = []
        for r in rows:
            cursor.execute("SELECT COUNT(*) FROM devices WHERE license_id = ?", (r[1],))
            dev_count = cursor.fetchone()[0]
            licenses.append({
                "id": r[0],
                "license_id": r[1],
                "customer_id": r[2],
                "customer_name": r[3],
                "plan": r[4],
                "status": r[5],
                "created_at": r[6],
                "start_date": r[7],
                "expiry_date": r[8],
                "max_devices": r[9],
                "active_devices": dev_count,
                "device_id": r[10],
                "last_check": r[12],
                "offline_grace_period": r[13]
            })
        conn.close()
        return self.send_json(200, {"success": True, "licenses": licenses})

    def handle_stats(self):
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM licenses")
        total = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM licenses WHERE status = 'ACTIVE'")
        active = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM devices")
        devices = cursor.fetchone()[0]
        conn.close()
        return self.send_json(200, {
            "success": True,
            "total_licenses": total,
            "active_licenses": active,
            "bound_devices": devices
        })

    def send_json(self, status, payload):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode('utf-8'))

def run_server():
    init_db()
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, LicenseRequestHandler)
    print(f"🚀 Recharge Manager DZ - License Server listening on http://127.0.0.1:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 License Server stopped.")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        init_db()
        print("Database initialized and verified successfully.")
        sys.exit(0)
    run_server()
