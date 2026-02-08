import os
import sys
import time
import requests

from utils import get_savedvars_path, lua_table_to_json

# .env is loaded by utils on import; SERVER_URL comes from there
SERVER_URL = os.environ.get("SERVER_URL", "http://localhost:8000")
POLL_INTERVAL = 3

def send_save_data(json_str: str) -> dict:
    if not SERVER_URL:
        raise ValueError("SERVER_URL is not set. Set it in .env.")
    resp = requests.post(
        f"{SERVER_URL}/save-data",
        json={"data": json_str},
        headers={"Content-Type": "application/json"},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()


def send_savedvars_as_json(path: str | None = None) -> dict:
    json_str = lua_table_to_json(path=path, indent=None)
    return send_save_data(json_str)


def watch_and_send():
    path = get_savedvars_path()
    last_mtime: float | None = None

    print(f"Watching: {path}")
    print(f"Server: {SERVER_URL} (check every {POLL_INTERVAL}s). Ctrl+C to stop.")
    print()

    while True:
        try:
            if not os.path.isfile(path):
                time.sleep(POLL_INTERVAL)
                continue

            mtime = os.path.getmtime(path)
            if last_mtime is not None and mtime <= last_mtime:
                time.sleep(POLL_INTERVAL)
                continue

            last_mtime = mtime
            result = send_savedvars_as_json(path=path)
            print(f"[{time.strftime('%H:%M:%S')}] Saved ({result.get('length', 0)} chars). ok={result.get('ok')}")
        except KeyboardInterrupt:
            print("\nStopped.")
            sys.exit(0)
        except Exception as e:
            print(f"[{time.strftime('%H:%M:%S')}] Error: {e}")
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    watch_and_send()
