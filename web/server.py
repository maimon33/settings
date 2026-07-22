#!/usr/bin/env python3
"""A localhost-only dashboard for the settings manager."""
import json
import os
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "settings-manager"
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "settings-manager"
TARGETS = CONFIG / "backup-paths.conf"
LOG = STATE / "activity.log"

def targets():
    if not TARGETS.exists(): return []
    return [line.split("#", 1)[0].strip() for line in TARGETS.read_text().splitlines()
            if line.split("#", 1)[0].strip()]

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(REPO / "web"), **kwargs)

    def send_json(self, payload, status=HTTPStatus.OK):
        body = json.dumps(payload).encode()
        self.send_response(status); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)

    def do_GET(self):
        if self.path == "/api/status":
            self.send_json({"targets": targets(), "log": LOG.read_text().splitlines()[-100:] if LOG.exists() else [],
                            "target_file": str(TARGETS), "state_dir": str(STATE)})
        else: super().do_GET()

    def do_POST(self):
        if self.path != "/api/targets": self.send_error(HTTPStatus.NOT_FOUND); return
        size = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(size)); values = data["targets"]
            if not isinstance(values, list) or any(not isinstance(x, str) or not x.startswith("/") or "\n" in x for x in values): raise ValueError
        except (ValueError, KeyError, json.JSONDecodeError):
            self.send_json({"error": "Targets must be a list of absolute paths."}, HTTPStatus.BAD_REQUEST); return
        CONFIG.mkdir(parents=True, exist_ok=True)
        os.chmod(CONFIG, 0o700)
        TARGETS.write_text("# Managed by settings dashboard. One absolute path per line.\n" + "\n".join(values) + "\n")
        os.chmod(TARGETS, 0o600)
        self.send_json({"targets": targets()})

if __name__ == "__main__":
    print("Settings dashboard: http://127.0.0.1:8765")
    ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
