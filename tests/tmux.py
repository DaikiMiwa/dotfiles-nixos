"""Use a private tmux socket and PTY; never attach to a user's server."""

import base64
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import subprocess
import tempfile
import termios
import time


with tempfile.TemporaryDirectory(prefix="tmux-test-") as directory:
    socket = str(Path(directory) / "s")
    env = dict(os.environ, TERM="xterm-256color")
    env.pop("TMUX", None)
    config = os.environ["TMUX_CONFIG"]
    manager = os.environ["TMUX_SESSION_MANAGER"]
    shell = os.environ.get("TEST_SHELL", "/bin/sh")
    client = None
    master = None

    def tmux(*args, check=True):
        return subprocess.run(
            ["tmux", "-S", socket, *args], env=env,
            text=True, capture_output=True, check=check,
        )

    def manager_run(selection, answer="", exit_code=0):
        script_env = dict(env)
        server_pid = tmux("display-message", "-p", "#{pid}").stdout.strip()
        script_env["TMUX"] = f"{socket},{server_pid},0"
        script_env["BASH_FUNC_fzf%%"] = (
            "() { cat >/dev/null; printf '%s' "
            + "'" + selection + "'; return " + str(exit_code) + "; }"
        )
        return subprocess.run(
            [manager], input=answer, env=script_env,
            text=True, capture_output=True, timeout=10,
        )

    data = b""
    pattern = re.compile(rb"\x1b\]1337;SetUserVar=TMUX_MODE=([^\x07]+)\x07")

    def expect_mode(expected, trigger):
        previous_count = len(pattern.findall(data))
        trigger()
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            read_output()
            modes = [base64.b64decode(item).decode() for item in pattern.findall(data)]
            if expected in modes[previous_count:]:
                return
        raise AssertionError(
            f"Expected {expected!r}, got {modes[previous_count:]!r}; "
            f"screen={data[-1000:]!r}"
        )

    def read_output():
        global data
        if select.select([master], [], [], 0.1)[0]:
            try:
                data += os.read(master, 65536)
            except OSError:
                pass  # A detached client's PTY can return EIO after its output.

    try:
        tmux("-f", config, "new-session", "-d", "-s", "work", shell)
        # Reloading must migrate a server that still has the previous prefix.
        tmux("set-option", "-g", "prefix", "M-b")
        assert not tmux("source-file", config).stderr
        assert tmux("show-option", "-gv", "prefix").stdout.strip() == "C-b"
        assert tmux("show-window-option", "-gv", "mode-keys").stdout.strip() == "vi"
        pane = tmux("display-message", "-p", "-t", "work", "#{pane_id}").stdout.strip()
        master, slave = pty.openpty()

        def controlling_tty():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        def attach():
            global client
            client = subprocess.Popen(
                ["tmux", "-S", socket, "attach-session", "-t", "work"],
                env=env, stdin=slave, stdout=slave, stderr=slave,
                preexec_fn=controlling_tty,
            )

        expect_mode("normal", attach)
        os.close(slave)
        expect_mode(f"copy:{pane}", lambda: tmux("copy-mode", "-t", pane))
        expect_mode("prompt", lambda: os.write(master, b"/"))
        # A search accepts UTF-8 text, then returns to navigation.
        expect_mode(f"copy:{pane}", lambda: os.write(master, "日本語\r".encode()))
        expect_mode("prompt", lambda: os.write(master, b"?"))
        expect_mode(f"copy:{pane}", lambda: os.write(master, b"\x03"))
        expect_mode("normal", lambda: tmux("split-window", "-t", "work", shell))
        expect_mode(f"copy:{pane}", lambda: tmux("select-pane", "-t", pane))
        expect_mode("normal", lambda: os.write(master, b"q"))
        expect_mode(f"copy:{pane}", lambda: tmux("copy-mode", "-t", pane))

        def select_and_copy():
            # Distinct key presses avoid tmux's paste-burst detection.
            os.write(master, b"v")
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if tmux("display-message", "-p", "-t", pane, "#{selection_active}").stdout.strip() == "1":
                    tmux("send-keys", "-t", pane, "-X", "cursor-left")
                    os.write(master, b"y")
                    return
            raise AssertionError("Vim selection did not start")

        expect_mode("normal", select_and_copy)
        expect_mode(f"copy:{pane}", lambda: tmux("copy-mode", "-t", pane))
        tty = tmux("list-clients", "-F", "#{client_tty}").stdout.strip()
        expect_mode("normal", lambda: tmux("detach-client", "-t", tty))
        client.wait(timeout=10)
        os.close(master)
        master, slave = pty.openpty()
        data = b""
        expect_mode(f"copy:{pane}", attach)
        os.close(slave)
        expect_mode("normal", lambda: os.write(master, b"q"))

        for status in (1, 130, 2):
            result = manager_run("", exit_code=status)
            assert result.returncode == (0 if status in (1, 130) else 2), result.stderr

        # Removing the current session with another available must switch first.
        tmux("new-session", "-d", "-s", "other", shell)
        result = manager_run("ctrl-q\nwork\n", "y\n")
        assert result.returncode == 0, result.stderr
        assert tmux("list-sessions", "-F", "#{session_name}").stdout.strip() == "other"
        # The last session must also be removable, despite having no successor.
        result = manager_run("ctrl-q\nother\n", "y\n")
        assert result.returncode == 0, result.stderr
        assert tmux("has-session", check=False).returncode != 0
        print("tmux mode notifications, searches, pane changes and session deletion passed")
    finally:
        tmux("kill-server", check=False)
        if client is not None:
            client.wait(timeout=10)
        if master is not None:
            os.close(master)
