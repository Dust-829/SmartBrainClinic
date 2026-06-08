import urllib.request
import json
import time

services = [
    ("Auth Service", "http://localhost:8001/health"),
    ("Patient Service", "http://localhost:8002/health"),
    ("Medical Service", "http://localhost:8003/health"),
    ("Pharmacy Service", "http://localhost:8004/health"),
    ("Billing Service", "http://localhost:8005/health"),
    ("Gateway Service", "http://localhost:8000/health")
]

print("🕒 Waiting 3 seconds for services to fully initialize...")
time.sleep(3)

print("\n🔍 Checking microservice health states:")
print("=" * 60)

all_ok = True
for name, url in services:
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=3) as response:
            status = response.getcode()
            body = response.read().decode('utf-8')
            try:
                data = json.loads(body)
                print(f"✅ {name:<16} | Status: {status} | Health: {data}")
            except Exception:
                print(f"✅ {name:<16} | Status: {status} | Output: {body[:60]}")
    except Exception as e:
        print(f"❌ {name:<16} | Failed to connect | Error: {e}")
        all_ok = False

print("=" * 60)
if all_ok:
    print("🎉 All microservices are started and running successfully!")
else:
    print("⚠️ Some microservices failed to respond or initialize. Please check logs.")
