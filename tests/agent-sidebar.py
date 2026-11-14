"""Exercise default-on, idempotence and explicit hiding on a private server."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


with tempfile.TemporaryDirectory(prefix="sidebar-test-") as directory:
    root = Path(directory)
    mock = root / "ccmux"
    mock.write_text("#!" + sys.executable + "\n" + '''
import subprocess
def tmux(*args):
    return subprocess.check_output(["tmux", *args], text=True).strip()
windows = set(tmux("list-windows", "-a", "-F", "#{window_id}").splitlines())
sidebars = {}
for row in tmux("list-panes", "-a", "-F", "#{window_id} #{pane_id} #{pane_title}").splitlines():
    window, pane, title = row.split(" ", 2)
    if title == "ccmux-sidebar": sidebars[window] = pane
if windows <= sidebars.keys():
    for pane in sidebars.values(): tmux("kill-pane", "-t", pane)
else:
    for window in windows - sidebars.keys():
        pane = tmux("split-window", "-hbd", "-l", "36", "-t", window, "-P", "-F", "#{pane_id}", "sleep 600")
        tmux("select-pane", "-t", pane, "-T", "ccmux-sidebar")
''')
    mock.chmod(0o755)
    env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
               HOME=str(root), TERM="xterm-256color")
    env.pop("TMUX", None)
    socket = str(root / "s")

    def tmux(*args):
        return subprocess.check_output(["tmux", "-S", socket, *args], env=env, text=True).strip()

    def helper(*args):
        subprocess.run([os.environ["TMUX_AGENT_SIDEBAR"], *args], env=env, check=True, timeout=15)

    def panes():
        return tmux("list-panes", "-a", "-F", "#{pane_id}").splitlines()

    try:
        tmux("-f", "/dev/null", "new-session", "-d", "-s", "first", "-x", "180", "-y", "50", "sleep 600")
        env["TMUX"] = f'{socket},{tmux("display-message", "-p", "#{pid}")},0'
        original = panes()
        helper()
        assert len(panes()) == 2
        helper()
        assert len(panes()) == 2, "Reload must not hide or duplicate the rail"
        helper("--toggle")
        assert panes() == original
        helper()
        assert panes() == original, "Attach/reload must respect explicit hiding"
        helper("--toggle")
        assert len(panes()) == 2
        tmux("new-session", "-d", "-s", "second", "-x", "180", "-y", "50", "sleep 600")
        helper()
        assert len(panes()) == 4, "A new session needs its own rail"
        assert set(original) <= set(panes())
        print("Sidebar defaults, reload, explicit hiding and new sessions passed")
    finally:
        tmux("kill-server")
