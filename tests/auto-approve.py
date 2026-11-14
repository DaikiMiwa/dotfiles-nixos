"""Private tmux + loopback daemon stub: scope, state changes, replay and OFF."""

import copy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
from unittest.mock import patch


sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("auto_approve", "home/tmux/auto-approve.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


with tempfile.TemporaryDirectory(prefix="approve-test-") as directory:
    socket = str(Path(directory) / "s")
    env = dict(os.environ, HOME=directory, TERM="xterm-256color")
    env.pop("TMUX", None)

    def tmux(*args):
        return subprocess.check_output(["tmux", "-S", socket, *args], env=env, text=True).strip()

    state = {"rows": [], "requests": [], "code": 200, "socket": socket}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            data = {"socketPath": state["socket"], "socketError": None}
            if self.path == "/sessions":
                data = {"sessions": copy.deepcopy(state["rows"])}
            self.send_response(200)
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())

        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            state["requests"].append((self.path, body))
            if state["code"] == 0:
                self.connection.close()
                return
            self.send_response(state["code"])
            self.end_headers()
            self.wfile.write(json.dumps({"ok": state["code"] == 200}).encode())

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        pane1 = tmux("-f", "/dev/null", "new-session", "-d", "-s", "agents", "-P", "-F", "#{pane_id}", "exec sleep 600")
        pane2 = tmux("split-window", "-d", "-P", "-F", "#{pane_id}", "exec sleep 600")
        original_pid = int(tmux("display-message", "-p", "-t", pane1, "#{pane_pid}"))
        row = {"id": "codex-test", "pid": original_pid, "agentType": "codex", "tmuxPane": pane1,
               "status": "waiting", "attentionType": "permission", "attentionGeneration": 1,
               "statusChangedAt": "2026-11-14T00:00:00Z", "nativeSessionId": "conversation-1"}
        other = dict(row, id="claude-test", pid=int(tmux("display-message", "-p", "-t", pane2, "#{pane_pid}")), agentType="claude", tmuxPane=pane2)
        state["rows"] = [row, other]
        with patch.dict(os.environ, {"XDG_STATE_HOME": directory}):
            approver = module.Approver(socket, server.server_port)
            for _ in range(40):
                if approver.foreground(row) and approver.foreground(other):
                    break
                time.sleep(0.05)
            assert approver.foreground(row), "Mock agent is not foreground on its PTY"
            approver.process_once()
            assert not state["requests"], "Every session starts OFF"
            approver.set_enabled(row, None)
            assert approver.enabled(row, approver.policies()), "Atomic toggle turns ON"
            approver.set_enabled(row, None)
            assert not approver.enabled(row, approver.policies()), "Atomic toggle turns OFF"
            approver.set_enabled(row, True)
            approver.process_once()
            assert state["requests"] == [("/notification-action", {
                "sessionId": "codex-test", "action": "approve",
                "statusChangedAt": row["statusChangedAt"], "attentionGeneration": 1,
            })], "Only the enabled agent in this shared tmux session is approved"
            approver.process_once()
            # A restarted worker also retains the attempt, including failed POSTs.
            module.Approver(socket, server.server_port).process_once()
            assert len(state["requests"]) == 1
            row["attentionGeneration"] = 2
            approver.process_once()
            assert len(state["requests"]) == 2, "A new wait is a new action"
            row["attentionGeneration"] = 3
            row["attentionType"] = "question"
            approver.process_once()
            assert len(state["requests"]) == 2, "Questions are never auto-answered"
            row["attentionType"] = "permission"
            row["status"] = "idle"
            approver.process_once()
            assert len(state["requests"]) == 2, "No input at the ordinary composer"
            row["status"] = "waiting"
            approver.set_enabled(row, False)
            approver.process_once()
            assert len(state["requests"]) == 2, "OFF stops the next pending approval"
            approver.set_enabled(row, True)
            row["nativeSessionId"] = "conversation-2"
            approver.process_once()
            assert not approver.enabled(row, approver.policies()), "New conversation starts OFF"
            approver.set_enabled(row, True)
            row["pid"] = 200
            approver.process_once()
            assert not approver.enabled(row, approver.policies()), "New process starts OFF"
            row["pid"] = original_pid
            approver.set_enabled(row, True)
            row["attentionGeneration"] = None
            approver.process_once()
            assert len(state["requests"]) == 2, "Unknown generation cannot be approved"
            row["attentionGeneration"] = 4
            state["code"] = 409
            approver.process_once()
            approver.process_once()
            assert len(state["requests"]) == 3, "Rejected/stale waits never fall back to raw keys"
            assert not approver.enabled(other, approver.policies())
            row["attentionGeneration"] = 5
            state["code"] = 0
            approver.process_once()
            module.Approver(socket, server.server_port).process_once()
            assert len(state["requests"]) == 4, "Lost responses never replay a possibly sent key"
            row["attentionGeneration"] = 6
            state["socket"] = "/wrong/socket"
            try:
                approver.process_once()
                raise AssertionError("Different server accepted")
            except ValueError:
                pass
            assert len(state["requests"]) == 4
            # A damaged replay journal must not be treated as empty history.
            state["socket"] = socket
            approver.journal.write_text("broken")
            try:
                approver.process_once()
                raise AssertionError("Corrupt journal accepted")
            except ValueError:
                pass
            assert len(state["requests"]) == 4
        print("Per-agent opt-in, OFF, questions, generation changes, replay and server isolation passed")
    finally:
        server.shutdown()
        server.server_close()
        tmux("kill-server")
