"""Stdio MCP proxy that starts a craft app on the first call that needs it.

Usage: craft-mcp CONFIG_JSON, with keys name, port, launch (the app),
live (an MCP server for the running app) and catalog (one that answers
list requests while the app is down; null when live starts without it).
"""

import json
import socket
import subprocess
import sys
import threading
import time

SETSID = "@setsid@"
NEEDS_APP = {"tools/call", "resources/read"}
INIT_ID = "craft-mcp-initialize"
START_SECONDS = 60

cfg = json.loads(sys.argv[1])
out_lock = threading.Lock()


def emit(msg):
    line = msg if isinstance(msg, str) else json.dumps(msg)
    with out_lock:
        sys.stdout.write(line + "\n")
        sys.stdout.flush()


def app_up():
    try:
        socket.create_connection(("127.0.0.1", cfg["port"]), timeout=0.5).close()
        return True
    except OSError:
        return False


class Server:
    def __init__(self, argv, patch_init_id=None):
        self.patch_init_id = patch_init_id
        self.init_reply = threading.Event()
        self.init_ok = False
        self.proc = subprocess.Popen(
            argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE, encoding="utf-8"
        )
        threading.Thread(target=self.pump, daemon=True).start()

    def pump(self):
        for line in self.proc.stdout:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except ValueError:
                msg = None
            if not isinstance(msg, dict):
                emit(line)
            elif msg.get("id") == INIT_ID:
                self.init_ok = "result" in msg
                self.init_reply.set()
            elif self.patch_init_id is not None and msg.get("id") == self.patch_init_id:
                # The tools may change once the live server takes over.
                tools = msg.get("result", {}).get("capabilities", {}).get("tools")
                if isinstance(tools, dict):
                    tools["listChanged"] = True
                emit(msg)
            else:
                emit(line)
        self.init_reply.set()

    def alive(self):
        return self.proc.poll() is None

    def send(self, msg):
        line = msg if isinstance(msg, str) else json.dumps(msg)
        self.proc.stdin.write(line + "\n")
        self.proc.stdin.flush()

    def close(self):
        try:
            self.proc.stdin.close()
        except OSError:
            pass


class Proxy:
    def __init__(self):
        self.server = None
        self.live = False
        self.init_params = {}

    def start_live(self):
        # Retries cover an app that opens its port just before its token file.
        for _ in range(10):
            server = Server(cfg["live"])
            server.send({"jsonrpc": "2.0", "id": INIT_ID, "method": "initialize", "params": self.init_params})
            if server.init_reply.wait(15) and server.init_ok:
                server.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
                return server
            server.close()
            time.sleep(0.5)
        return None

    def ensure_app(self):
        launched = False
        if not app_up():
            subprocess.run(
                [SETSID, "-f", *cfg["launch"]],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            launched = True
            deadline = time.monotonic() + START_SECONDS
            while not app_up():
                if time.monotonic() > deadline:
                    return f"{cfg['name']} did not open port {cfg['port']} within {START_SECONDS}s"
                time.sleep(0.25)
        # A connect-mode server needs the app at startup and holds its token.
        restart = launched and cfg.get("catalog") is not None
        if not self.live or restart or not self.server.alive():
            server = self.start_live()
            if server is None:
                return f"could not connect to {cfg['name']} on port {cfg['port']}"
            old, self.server = self.server, server
            old.close()
            if not self.live:
                self.live = True
                emit({"jsonrpc": "2.0", "method": "notifications/tools/list_changed"})
        return None

    def handle(self, line):
        try:
            msg = json.loads(line)
        except ValueError:
            msg = None
        method = msg.get("method") if isinstance(msg, dict) else None
        if method == "initialize":
            self.init_params = msg.get("params", {})
            self.live = cfg.get("catalog") is None or app_up()
            if self.live:
                self.server = Server(cfg["live"])
            else:
                self.server = Server(cfg["catalog"], patch_init_id=msg.get("id"))
        elif self.server is None:
            self.live = True
            self.server = Server(cfg["live"])
        elif method in NEEDS_APP:
            error = self.ensure_app()
            if error is not None:
                emit({"jsonrpc": "2.0", "id": msg.get("id"), "error": {"code": -32603, "message": error}})
                return
        try:
            self.server.send(line)
        except OSError as e:
            if isinstance(msg, dict) and "id" in msg and method is not None:
                emit({"jsonrpc": "2.0", "id": msg["id"], "error": {"code": -32603, "message": f"{cfg['name']} MCP server: {e}"}})


def main():
    proxy = Proxy()
    for line in sys.stdin:
        line = line.strip()
        if line:
            proxy.handle(line)
    if proxy.server is not None:
        proxy.server.close()
        try:
            proxy.server.proc.wait(5)
        except subprocess.TimeoutExpired:
            proxy.server.proc.terminate()


if __name__ == "__main__":
    main()
