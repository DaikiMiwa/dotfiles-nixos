"""Opt-in auto approval for individual ccmux agent sessions."""

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import time
import urllib.error
import urllib.request


OPTION = "@agent-auto-approve"


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def identity(row):
    # A pane ID alone can be reused by a different conversation or process.
    if not row.get("id") or type(row.get("pid")) is not int or row["pid"] <= 0:
        raise ValueError("Agent process is not identified yet; refresh and try again")
    if not re.fullmatch(r"%\d+", row.get("tmuxPane") or ""):
        raise ValueError("Agent has no live tmux pane")
    return digest([row["id"], row["pid"], row["tmuxPane"], row.get("agentType"), row.get("nativeSessionId")])


class Approver:
    def __init__(self, socket, port=2269):
        self.socket = os.path.realpath(socket)
        self.port = port
        self.server_pid = self.tmux("display-message", "-p", "#{pid}").strip()
        root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
        self.directory = root / "dotfiles/agent-auto-approve" / digest([self.socket, self.server_pid])
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.journal = self.directory / "attempts.json"

    def tmux(self, *args):
        return subprocess.check_output(
            ["tmux", "-S", self.socket, *args], text=True, stderr=subprocess.DEVNULL, timeout=5
        )

    @contextmanager
    def lock(self, name, blocking=True):
        fd = os.open(self.directory / name, os.O_CREAT | os.O_RDWR, 0o600)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB))
            yield
        finally:
            os.close(fd)

    def api(self, route, payload=None):
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.port}{route}",
            data=json.dumps(payload).encode() if payload is not None else None,
            headers={"Content-Type": "application/json"},
        )
        # Local daemon only; never route agent metadata through an HTTP proxy.
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        with opener.open(request, timeout=2) as response:
            return json.load(response)

    def sessions(self):
        info = self.api("/server-info")
        if info.get("socketError") or os.path.realpath(info.get("socketPath") or "") != self.socket:
            raise ValueError("ccmux is tracking a different tmux server")
        rows = self.api("/sessions")["sessions"]
        if not isinstance(rows, list):
            raise ValueError("Unsupported ccmux session response")
        return rows

    def policies(self):
        rows = self.tmux("list-panes", "-a", "-F", "#{pane_id}\t#{@agent-auto-approve}")
        return dict(line.split("\t", 1) for line in rows.splitlines())

    def enabled(self, row, policies):
        try:
            return policies.get(row["tmuxPane"]) == identity(row)
        except (ValueError, KeyError):
            return False

    def set_enabled(self, row, enabled):
        token = identity(row)
        # OFF waits for an in-flight request to finish; none start after it returns.
        with self.lock("policy.lock"):
            if enabled is None:
                enabled = not self.enabled(row, self.policies())
            self.tmux("set-option", "-p", "-t", row["tmuxPane"], OPTION, token if enabled else "")

    def foreground(self, row):
        # The daemon's PID can lag a process replacement by a scan interval.
        # Check the real PTY foreground group before consuming its old state.
        try:
            pane_pid = self.tmux("display-message", "-p", "-t", row["tmuxPane"], "#{pane_pid}").strip()
            # tcgetpgrp on another process's controlling terminal fails on macOS.
            group = int(subprocess.check_output(
                ["ps", "-o", "tpgid=", "-p", pane_pid], text=True, stderr=subprocess.DEVNULL, timeout=3
            ).strip())
            return group > 0 and group == os.getpgid(row["pid"])
        except (OSError, ValueError, subprocess.SubprocessError):
            return False

    def save_attempts(self, attempts):
        # Record before POST: timeout/restart must never replay an uncertain press.
        temp = self.journal.with_suffix(".tmp")
        with temp.open("w") as stream:
            os.chmod(temp, 0o600)
            json.dump(attempts, stream)
            stream.flush()
            os.fsync(stream.fileno())
        temp.replace(self.journal)

    def process_once(self):
        rows = self.sessions()
        with self.lock("policy.lock"):
            policies = self.policies()
            # A new conversation/process in an old pane always starts OFF.
            valid = {r["tmuxPane"] for r in rows if self.enabled(r, policies)}
            for pane, value in policies.items():
                if value and pane not in valid:
                    self.tmux("set-option", "-p", "-t", pane, OPTION, "")
        for row in rows:
            if row.get("status") != "waiting" or row.get("attentionType") not in ("permission", "plan_approval"):
                continue
            generation = row.get("attentionGeneration")
            changed = row.get("statusChangedAt")
            if type(generation) is not int or generation < 1 or not isinstance(changed, str) or not changed:
                continue
            with self.lock("policy.lock"):
                if not self.enabled(row, self.policies()) or not self.foreground(row):
                    continue
                key = digest([identity(row), generation, changed])
                # Corrupt state is an error, never a reason to forget old attempts.
                attempts = json.loads(self.journal.read_text()) if self.journal.exists() else {}
                if key in attempts:
                    continue
                attempts[key] = {"result": "pending", "time": time.time()}
                self.save_attempts(attempts)
                payload = {"sessionId": row["id"], "action": "approve",
                           "statusChangedAt": changed, "attentionGeneration": generation}
                try:
                    result = self.api("/notification-action", payload)
                    outcome = "approved" if result.get("ok") else "declined"
                except urllib.error.HTTPError as error:
                    outcome = f"declined:{error.code}"
                except (OSError, ValueError):
                    outcome = "unknown:no-retry"
                attempts[key]["result"] = outcome
                self.save_attempts(attempts)
                print(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {key[:12]} {outcome}", flush=True)

    def start(self):
        if not any(self.policies().values()):
            return
        log = os.open(self.directory / "worker.log", os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
        try:
            subprocess.Popen(
                [sys.executable, __file__, "--socket", self.socket, "--port", str(self.port), "worker"],
                stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True, close_fds=True,
            )
        finally:
            os.close(log)

    def worker(self):
        try:
            with self.lock("worker.lock", blocking=False):
                last_error = None
                while self.tmux("display-message", "-p", "#{pid}").strip() == self.server_pid:
                    try:
                        if any(self.policies().values()):
                            self.process_once()
                        last_error = None
                    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
                        # Missing daemon or unsupported schema never triggers raw keys.
                        message = f"paused: {type(error).__name__}: {error}"
                        if message != last_error:
                            print(message, flush=True)
                        last_error = message
                    time.sleep(1)
        except (BlockingIOError, subprocess.SubprocessError):
            return

    def menu(self):
        try:
            self.sessions()
        except OSError:
            # ccmux exits 1 for "already running"; trust the following API
            # probe rather than treating that benign CLI status as fatal.
            subprocess.run(["ccmux", "daemon", "start", "-b"], check=False, stdout=subprocess.DEVNULL)
        while True:
            rows = self.sessions()
            policies = self.policies()
            lines = []
            for index, row in enumerate(rows):
                if not row.get("tmuxPane"):
                    continue
                mode = "ON " if self.enabled(row, policies) else "OFF"
                label = f'[{mode}] {row.get("agentType")}  {row.get("tmuxTarget")}  {row.get("project")}  {row.get("status")}'
                label = re.sub(r"[\x00-\x1f\x7f]", " ", label)
                lines.append(f'{index}\t{row["tmuxPane"]}\t{label}')
            selection = subprocess.run(
                ["fzf", "--delimiter=\t", "--with-nth=3..", "--no-multi", "--expect=enter,ctrl-r",
                 "--prompt=Auto approval > ", "--header=Enter: toggle selected agent | Ctrl-R: refresh | Esc: close",
                 "--preview", "tmux -S " + shlex.quote(self.socket) + " capture-pane -p -t {2}",
                 "--preview-window=right,60%,wrap"],
                input="\n".join(lines), text=True, stdout=subprocess.PIPE,
            )
            if selection.returncode in (1, 130):
                return
            selection.check_returncode()
            chosen = selection.stdout.splitlines()
            if chosen and chosen[0] == "ctrl-r":
                continue
            if len(chosen) < 2:
                continue
            row = rows[int(chosen[1].split("\t", 1)[0])]
            # Refresh identity before enabling a row the operator selected earlier.
            fresh = next((r for r in self.sessions() if r["id"] == row["id"] and identity(r) == identity(row)), None)
            if fresh is None:
                continue
            self.set_enabled(fresh, not self.enabled(fresh, self.policies()))
            self.start()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--socket")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--port", type=int, default=int(os.environ.get("CCMUX_PORT", "2269")))
    parser.add_argument("command", nargs="?", default="menu", choices=("menu", "start", "worker", "status", "on", "off", "toggle"))
    parser.add_argument("session", nargs="?")
    args = parser.parse_args()
    socket = args.socket or subprocess.check_output(["tmux", "display-message", "-p", "#{socket_path}"], text=True).strip()
    approver = Approver(socket, args.port)
    if args.command in ("menu", "start", "worker"):
        getattr(approver, args.command)()
    elif args.command == "status":
        policies = approver.policies()
        rows = approver.sessions()
        if args.json:
            print(json.dumps({row["id"]: approver.enabled(row, policies) for row in rows}))
        else:
            for row in rows:
                print("ON" if approver.enabled(row, policies) else "OFF", row["id"], row.get("tmuxTarget"))
    else:
        row = next((r for r in approver.sessions() if r["id"] == args.session), None)
        if row is None:
            raise ValueError("Select a live ccmux session ID")
        approver.set_enabled(row, None if args.command == "toggle" else args.command == "on")
        approver.start()


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"Auto approval: {error}", file=sys.stderr)
        sys.exit(1)
