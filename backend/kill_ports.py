import os
import signal
import subprocess
from contextlib import suppress


TARGET_PORTS = {8000, 8001, 8002, 8003, 8004, 8005}


def get_listening_pids() -> set[int]:
    if os.name == "nt":
        result = subprocess.run(
            ["netstat", "-ano", "-p", "tcp"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            check=True,
        )
        pids: set[int] = set()
        for raw_line in result.stdout.splitlines():
            line = raw_line.strip()
            if not line.startswith("TCP"):
                continue

            parts = line.split()
            if len(parts) < 5 or parts[3].upper() != "LISTENING":
                continue

            _, _, port_text = parts[1].rpartition(":")
            with suppress(ValueError):
                port = int(port_text)
                if port in TARGET_PORTS:
                    pids.add(int(parts[4]))
        return pids

    output = subprocess.check_output("ps aux | grep uvicorn | grep -v grep", shell=True, text=True)
    pids = set()
    for line in output.strip().splitlines():
        if not line:
            continue
        parts = line.split()
        with suppress(ValueError):
            pids.add(int(parts[1]))
    return pids


def kill_pid(pid: int) -> None:
    print(f"Killing PID {pid}")
    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/PID", str(pid), "/T", "/F"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return

    with suppress(Exception):
        os.kill(pid, signal.SIGKILL)


def main() -> None:
    try:
        pids = get_listening_pids()
    except subprocess.CalledProcessError:
        pids = set()

    if not pids:
        print("No matching microservice listener processes found.")
        return

    for pid in sorted(pids):
        kill_pid(pid)


if __name__ == "__main__":
    main()
