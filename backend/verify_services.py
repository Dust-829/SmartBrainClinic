import json
import time
import urllib.error
import urllib.request


CORE_SERVICES = [
    ("Auth Service", "http://localhost:8001/health"),
    ("Patient Service", "http://localhost:8002/health"),
    ("Medical Service", "http://localhost:8003/health"),
    ("Pharmacy Service", "http://localhost:8004/health"),
    ("Billing Service", "http://localhost:8005/health"),
    ("Gateway Service", "http://localhost:8000/health"),
]

OPTIONAL_SERVICES = [
    ("CT Artifact Service", "http://127.0.0.1:8013/health"),
]


def check_service(name: str, url: str) -> bool:
    try:
        request = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(request, timeout=3) as response:
            status = response.getcode()
            body = response.read().decode("utf-8")
            try:
                detail = json.loads(body)
            except json.JSONDecodeError:
                detail = body[:60]
            print(f"OK   {name:<20} | Status: {status} | Health: {detail}")
            return True
    except (OSError, urllib.error.URLError) as exc:
        print(f"FAIL {name:<20} | Failed to connect | Error: {exc}")
        return False


def main() -> int:
    print("Waiting 3 seconds for core services to initialize...")
    time.sleep(3)
    print("\nChecking microservice health states:")
    print("=" * 60)

    core_results = [check_service(name, url) for name, url in CORE_SERVICES]
    core_ok = all(core_results)
    for name, url in OPTIONAL_SERVICES:
        if not check_service(name, url):
            print("INFO CT image analysis is unavailable; core outpatient workflows are unaffected.")

    print("=" * 60)
    if core_ok:
        print("All core microservices are healthy.")
        return 0

    print("One or more core microservices failed to respond. Please check backend/logs.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
