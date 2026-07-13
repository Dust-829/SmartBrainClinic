import json
import subprocess
import sys
import textwrap
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def run_isolated_python(code: str) -> dict:
    result = subprocess.run(
        [sys.executable, "-c", textwrap.dedent(code)],
        cwd=BACKEND_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def test_ct_artifact_uses_dedicated_interpreter_and_remains_optional():
    data = run_isolated_python(
        """
        import json
        from run_microservices import build_service_command, build_services

        services = build_services({"CT_ARTIFACT_PYTHON": r"C:\\custom\\py3106\\python.exe"})
        artifact = next(service for service in services if service.name == "CTArtifact")
        medical = next(service for service in services if service.name == "Medical")
        print(json.dumps({
            "artifact_command": build_service_command(artifact),
            "artifact_critical": artifact.critical,
            "artifact_health_url": artifact.health_url,
            "medical_uses_current_interpreter": medical.python_executable is None,
        }))
        """
    )

    assert data["artifact_command"] == [
        r"C:\custom\py3106\python.exe",
        "-m",
        "uvicorn",
        "model_services.ct_artifact.service:app",
        "--host",
        "127.0.0.1",
        "--port",
        "8013",
    ]
    assert data["artifact_critical"] is False
    assert data["artifact_health_url"] == "http://127.0.0.1:8013/health"
    assert data["medical_uses_current_interpreter"] is True


def test_ct_artifact_defaults_to_project_py3106_path():
    data = run_isolated_python(
        """
        import json
        from run_microservices import DEFAULT_CT_ARTIFACT_PYTHON, build_services

        artifact = next(service for service in build_services({}) if service.name == "CTArtifact")
        print(json.dumps({"configured": artifact.python_executable, "default": DEFAULT_CT_ARTIFACT_PYTHON}))
        """
    )

    assert data["configured"] == data["default"]
