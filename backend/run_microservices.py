import subprocess
import time
import sys
import os

services = [
    ("Auth", "app.microservices.auth.main:app", 8001),
    ("Patient", "app.microservices.patient.main:app", 8002),
    ("Medical", "app.microservices.medical.main:app", 8003),
    ("Pharmacy", "app.microservices.pharmacy.main:app", 8004),
    ("Billing", "app.microservices.billing.main:app", 8005),
    ("Gateway", "app.main:app", 8000),
]

daemon_scripts = [
    ("AIEvaluator", "cron_ai_evaluate.py"),
    ("DisruptionAutoResolver", "cron_disruptions.py")
]

processes = []
log_files = {}

# Ensure logs directory exists
os.makedirs("logs", exist_ok=True)

print("🚀 Starting Microservices...")

try:
    for name, module, port in services:
        print(f"📦 Starting {name} on port {port}...")
        log_path = f"logs/{name.lower()}.log"
        f = open(log_path, "w", encoding="utf-8")
        log_files[name] = f
        
        proc = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", module, "--host", "0.0.0.0", "--port", str(port)],
            stdout=f,
            stderr=subprocess.STDOUT,
            text=True
        )
        processes.append((name, proc))
        time.sleep(1) # Wait a bit for each to start

    for name, script in daemon_scripts:
        print(f"🤖 Starting Daemon {name}...")
        log_path = f"logs/{name.lower()}.log"
        f = open(log_path, "w", encoding="utf-8")
        log_files[name] = f
        
        proc = subprocess.Popen(
            [sys.executable, script],
            stdout=f,
            stderr=subprocess.STDOUT,
            text=True
        )
        processes.append((name, proc))
        time.sleep(1)

    print("✅ All services started. Logs are written to backend/logs/*.log. Press Ctrl+C to stop.")
    
    while True:
        for name, proc in processes:
            if proc.poll() is not None:
                print(f"❌ {name} service stopped unexpectedly!")
                log_files[name].close()
                with open(f"logs/{name.lower()}.log", "r", encoding="utf-8") as f_read:
                    print(f"--- {name} Logs ---")
                    print(f_read.read()[-2000:]) # Show last 2000 chars of logs
                sys.exit(1)
        time.sleep(1)

except KeyboardInterrupt:
    print("\n🛑 Stopping all services...")
    for name, proc in processes:
        proc.terminate()
    print("💾 Closing log files...")
    for f in log_files.values():
        f.close()
    print("👋 Done.")

