import os
import requests

# Server base URL (override with SERVER_URL env var)
SERVER_URL = os.environ.get("SERVER_URL", "http://localhost:8000")


def post_message(message: str) -> dict:
    """POST a message to the server. Returns the JSON response or raises on error."""
    resp = requests.post(
        f"{SERVER_URL}/message",
        json={"message": message},
        headers={"Content-Type": "application/json"},
        timeout=10,
    )
    resp.raise_for_status()
    return resp.json()


if __name__ == "__main__":
    import sys
    text = sys.argv[1] if len(sys.argv) > 1 else "Hello from PhLib client"
    result = post_message(text)
    print(result)
