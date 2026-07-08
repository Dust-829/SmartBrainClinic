import os
import subprocess
import sys
import time
from contextlib import suppress


SERVICES = [
    ("Auth", "app.microservices.auth.main:app", 8001),
    ("Patient", "app.microservices.patient.main:app", 8002),
    ("Medical", "app.microservices.medical.main:app", 8003),
    ("Pharmacy", "app.microservices.pharmacy.main:app", 8004),
    ("Billing", "app.microservices.billing.main:app", 8005),
    ("Gateway", "app.main:app", 8000),
]

DAEMON_SCRIPTS = [
    ("AIEvaluator", "cron_ai_evaluate.py"),
    ("DisruptionAutoResolver", "cron_disruptions.py"),
]


def get_listening_ports(ports: set[int]) -> list[dict[str, str | int]]:
    if os.name != "nt":
        return []

    result = subprocess.run(
        ["netstat", "-ano", "-p", "tcp"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
        check=True,
    )

    listeners: dict[tuple[int, int], dict[str, str | int]] = {}
    for raw_line in result.stdout.splitlines():
        line = raw_line.strip()
        if not line.startswith("TCP"):
            continue

        parts = line.split()
        if len(parts) < 5 or parts[3].upper() != "LISTENING":
            continue

        local_address = parts[1]
        pid = int(parts[4])
        host, _, port_text = local_address.rpartition(":")
        with suppress(ValueError):
            port = int(port_text)
            if port in ports:
                listeners[(port, pid)] = {
                    "port": port,
                    "pid": pid,
                    "local_address": host or "0.0.0.0",
                }

    return sorted(listeners.values(), key=lambda item: (item["port"], item["pid"]))


def print_port_conflicts(conflicts: list[dict[str, str | int]]) -> None:
    print("ERROR: Startup aborted because required ports are already in use:")
    for item in conflicts:
        print(f"  - port {item['port']} is already listening on PID {item['pid']} ({item['local_address']})")
    print("Close the existing microservice processes first, then rerun this script.")


def terminate_process(proc: subprocess.Popen) -> None:
    if proc.poll() is not None:
        return

    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/PID", str(proc.pid), "/T", "/F"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return

    with suppress(ProcessLookupError):
        proc.terminate()
    with suppress(subprocess.TimeoutExpired):
        proc.wait(timeout=5)
        return
    with suppress(ProcessLookupError):
        proc.kill()


def stop_processes(processes: list[tuple[str, subprocess.Popen]]) -> None:
    for _, proc in processes:
        terminate_process(proc)


def close_log_files(log_files: dict[str, object]) -> None:
    for handle in log_files.values():
        with suppress(Exception):
            handle.close()


def print_log_tail(name: str) -> None:
    log_path = f"logs/{name.lower()}.log"
    print(f"--- {name} Logs ---")
    with open(log_path, "r", encoding="utf-8", errors="ignore") as handle:
        print(handle.read()[-4000:])


def main() -> int:
    processes: list[tuple[str, subprocess.Popen]] = []
    log_files: dict[str, object] = {}

    os.makedirs("logs", exist_ok=True)

    conflicts = get_listening_ports({port for _, _, port in SERVICES})
    if conflicts:
        print_port_conflicts(conflicts)
        return 1

    print("Starting Microservices...")

    try:
        for name, module, port in SERVICES:
            print(f"Starting {name} on port {port}...")
            log_path = f"logs/{name.lower()}.log"
            handle = open(log_path, "w", encoding="utf-8")
            log_files[name] = handle

            proc = subprocess.Popen(
                [sys.executable, "-m", "uvicorn", module, "--host", "0.0.0.0", "--port", str(port)],
                stdout=handle,
                stderr=subprocess.STDOUT,
                text=True,
            )
            processes.append((name, proc))
            time.sleep(1)

        for name, script in DAEMON_SCRIPTS:
            print(f"Starting Daemon {name}...")
            log_path = f"logs/{name.lower()}.log"
            handle = open(log_path, "w", encoding="utf-8")
            log_files[name] = handle

            proc = subprocess.Popen(
                [sys.executable, script],
                stdout=handle,
                stderr=subprocess.STDOUT,
                text=True,
            )
            processes.append((name, proc))
            time.sleep(1)

        print("All services started. Logs are written to backend/logs/*.log. Press Ctrl+C to stop.")

        while True:
            for name, proc in processes:
                if proc.poll() is None:
                    continue

                print(f"ERROR: {name} service stopped unexpectedly!")
                stop_processes(processes)
                close_log_files(log_files)
                print_log_tail(name)
                return proc.returncode or 1

            time.sleep(1)

    except KeyboardInterrupt:
        print("\nStopping all services...")
        stop_processes(processes)
        print("Closing log files...")
        close_log_files(log_files)
        print("Done.")
        return 0

    finally:
        close_log_files(log_files)


if __name__ == "__main__":
    raise SystemExit(main())
