import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from contextlib import suppress
from dataclasses import dataclass
from pathlib import Path


DEFAULT_CT_ARTIFACT_PYTHON = r"D:\develop\Anaconda\envs\py3106\python.exe"
CT_ARTIFACT_STARTUP_TIMEOUT_SECONDS = 60.0
CT_ARTIFACT_MAX_RESTART_ATTEMPTS = 3
CT_ARTIFACT_RESTART_DELAY_SECONDS = 3.0


@dataclass(frozen=True)
class ServiceSpec:
    name: str
    module: str
    port: int
    host: str = "0.0.0.0"
    python_executable: str | None = None
    critical: bool = True
    health_url: str | None = None

    @property
    def interpreter(self) -> str:
        return self.python_executable or sys.executable

    @property
    def log_path(self) -> Path:
        return Path("logs") / f"{self.name.lower()}.log"


@dataclass
class ManagedProcess:
    name: str
    process: subprocess.Popen
    critical: bool
    log_path: Path


def build_services(environment: dict[str, str] | None = None) -> list[ServiceSpec]:
    env = os.environ if environment is None else environment
    ct_artifact_python = env.get("CT_ARTIFACT_PYTHON", DEFAULT_CT_ARTIFACT_PYTHON)
    return [
        ServiceSpec(
            name="CTArtifact",
            module="model_services.ct_artifact.service:app",
            host="127.0.0.1",
            port=8013,
            python_executable=ct_artifact_python,
            critical=False,
            health_url="http://127.0.0.1:8013/health",
        ),
        ServiceSpec("Auth", "app.microservices.auth.main:app", 8001),
        ServiceSpec("Patient", "app.microservices.patient.main:app", 8002),
        ServiceSpec("Medical", "app.microservices.medical.main:app", 8003),
        ServiceSpec("Pharmacy", "app.microservices.pharmacy.main:app", 8004),
        ServiceSpec("Billing", "app.microservices.billing.main:app", 8005),
        ServiceSpec("Gateway", "app.main:app", 8000),
    ]


DAEMON_SCRIPTS = [
    ("AIEvaluator", "cron_ai_evaluate.py"),
    ("DisruptionAutoResolver", "cron_disruptions.py"),
]


def build_service_command(service: ServiceSpec) -> list[str]:
    return [
        service.interpreter,
        "-m",
        "uvicorn",
        service.module,
        "--host",
        service.host,
        "--port",
        str(service.port),
    ]


def interpreter_exists(interpreter: str) -> bool:
    candidate = Path(interpreter)
    return candidate.is_file() if candidate.is_absolute() else shutil.which(interpreter) is not None


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


def stop_processes(processes: list[ManagedProcess]) -> None:
    for managed in processes:
        terminate_process(managed.process)


def close_log_files(log_files: dict[str, object]) -> None:
    for handle in log_files.values():
        with suppress(Exception):
            handle.close()


def print_log_tail(name: str, log_path: Path | None = None) -> None:
    destination = log_path or Path("logs") / f"{name.lower()}.log"
    print(f"--- {name} Logs ({destination}) ---")
    with suppress(FileNotFoundError):
        with destination.open("r", encoding="utf-8", errors="ignore") as handle:
            print(handle.read()[-4000:])


def wait_for_health(url: str, timeout_seconds: float) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=3) as response:
                if response.status == 200:
                    return True
        except (OSError, urllib.error.URLError):
            pass
        time.sleep(1)
    return False


def start_service(
    service: ServiceSpec,
    processes: list[ManagedProcess],
    log_files: dict[str, object],
) -> ManagedProcess:
    print(f"Starting {service.name} on port {service.port}...")
    handle = service.log_path.open("w", encoding="utf-8")
    log_files[service.name] = handle
    proc = subprocess.Popen(
        build_service_command(service),
        stdout=handle,
        stderr=subprocess.STDOUT,
        text=True,
    )
    managed = ManagedProcess(service.name, proc, service.critical, service.log_path)
    processes.append(managed)
    return managed


def start_optional_ct_artifact(
    service: ServiceSpec,
    processes: list[ManagedProcess],
    log_files: dict[str, object],
) -> None:
    if not interpreter_exists(service.interpreter):
        print(
            "CTArtifact is unavailable: interpreter was not found at "
            f"{service.interpreter}. Set CT_ARTIFACT_PYTHON to the py3106 Python executable."
        )
        return

    managed = start_service(service, processes, log_files)
    print(f"Waiting up to {int(CT_ARTIFACT_STARTUP_TIMEOUT_SECONDS)} seconds for CTArtifact health check...")
    if service.health_url and wait_for_health(service.health_url, CT_ARTIFACT_STARTUP_TIMEOUT_SECONDS):
        print("CTArtifact is healthy and ready for CT image analysis.")
        return

    print("CTArtifact did not become healthy; core microservices will continue without CT image analysis.")
    terminate_process(managed.process)
    processes.remove(managed)
    handle = log_files.pop(service.name, None)
    if handle is not None:
        with suppress(Exception):
            handle.close()
    print_log_tail(service.name, service.log_path)


def main() -> int:
    processes: list[ManagedProcess] = []
    log_files: dict[str, object] = {}
    services = build_services()
    optional_services = [service for service in services if not service.critical]
    core_services = [service for service in services if service.critical]
    optional_service_by_name = {service.name: service for service in optional_services}
    optional_restart_attempts = {service.name: 0 for service in optional_services}

    os.makedirs("logs", exist_ok=True)

    conflicts = get_listening_ports({service.port for service in services})
    core_conflicts = [item for item in conflicts if item["port"] in {service.port for service in core_services}]
    optional_conflicts = [item for item in conflicts if item["port"] in {service.port for service in optional_services}]
    if core_conflicts:
        print_port_conflicts(core_conflicts)
        return 1
    if optional_conflicts:
        print("CTArtifact will not start because port 8013 is already in use; core services will continue.")
        for item in optional_conflicts:
            print(f"  - port {item['port']} is already listening on PID {item['pid']} ({item['local_address']})")
        optional_services = []

    print("Starting Microservices...")

    try:
        for service in optional_services:
            start_optional_ct_artifact(service, processes, log_files)

        for service in core_services:
            start_service(service, processes, log_files)
            time.sleep(1)

        for name, script in DAEMON_SCRIPTS:
            print(f"Starting Daemon {name}...")
            log_path = Path("logs") / f"{name.lower()}.log"
            handle = log_path.open("w", encoding="utf-8")
            log_files[name] = handle
            proc = subprocess.Popen(
                [sys.executable, script],
                stdout=handle,
                stderr=subprocess.STDOUT,
                text=True,
            )
            processes.append(ManagedProcess(name, proc, True, log_path))
            time.sleep(1)

        print("All core services started. Logs are written to backend/logs/*.log. Press Ctrl+C to stop.")

        while True:
            for managed in list(processes):
                if managed.process.poll() is None:
                    continue

                if not managed.critical:
                    print(f"CTArtifact stopped unexpectedly; CT image analysis is unavailable. See {managed.log_path}.")
                    processes.remove(managed)
                    handle = log_files.pop(managed.name, None)
                    if handle is not None:
                        with suppress(Exception):
                            handle.close()
                    print_log_tail(managed.name, managed.log_path)
                    service = optional_service_by_name.get(managed.name)
                    attempts = optional_restart_attempts.get(managed.name, 0)
                    if service and attempts < CT_ARTIFACT_MAX_RESTART_ATTEMPTS:
                        optional_restart_attempts[managed.name] = attempts + 1
                        print(
                            f"Restarting CTArtifact in {int(CT_ARTIFACT_RESTART_DELAY_SECONDS)} seconds "
                            f"(attempt {attempts + 1}/{CT_ARTIFACT_MAX_RESTART_ATTEMPTS})..."
                        )
                        time.sleep(CT_ARTIFACT_RESTART_DELAY_SECONDS)
                        start_optional_ct_artifact(service, processes, log_files)
                    elif service:
                        print("CTArtifact restart limit reached; core microservices will continue without CT image analysis.")
                    continue

                print(f"ERROR: {managed.name} service stopped unexpectedly!")
                stop_processes(processes)
                close_log_files(log_files)
                print_log_tail(managed.name, managed.log_path)
                return managed.process.returncode or 1

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
