import subprocess
import os
import signal

def main():
    try:
        output = subprocess.check_output("ps aux | grep uvicorn | grep -v grep", shell=True, text=True)
        for line in output.strip().split('\n'):
            if line:
                parts = line.split()
                pid = int(parts[1])
                print(f"Killing PID {pid}")
                try:
                    os.kill(pid, signal.SIGKILL)
                except Exception as e:
                    print(f"Failed: {e}")
    except subprocess.CalledProcessError:
        print("No uvicorn processes found.")

if __name__ == "__main__":
    main()
