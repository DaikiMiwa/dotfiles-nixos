import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile

spec = importlib.util.spec_from_file_location("advisor", "home/shell-advisor.py")
advisor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(advisor)

data = advisor.summarize(": 123:0;cd /secret/path\nls --token=secret\ngit status\nunknown secret\n")
assert data == {"counts": {"cd": 1, "ls": 1, "git status": 1}, "transitions": {"cd -> ls": 1}}
assert "secret" not in str(data)

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    fake = root / "claude"
    fake.write_text('#!/bin/sh\ncat > "$TEST_PROMPT"\nprintf "z を試しましょう。\\n"\n')
    fake.chmod(0o755)
    notification = root / "osascript"
    notification.write_text("#!/bin/sh\nexit 0\n")
    notification.chmod(0o755)
    history = root / "history"
    history.write_text("cd /secret/path\nls\n" * 10)
    env = dict(os.environ, HOME=str(root), PATH=str(root) + ":" + os.environ["PATH"], HISTFILE=str(history),
               XDG_STATE_HOME=str(root / "state"), TEST_PROMPT=str(root / "prompt"))
    command = [sys.executable, "home/shell-advisor.py"]
    subprocess.run(command + ["run"], env=env, check=True)
    assert "secret" not in (root / "prompt").read_text()
    shown = subprocess.check_output(command + ["show"], env=env, text=True)
    assert "z を試しましょう" in shown
    assert not subprocess.check_output(command + ["show"], env=env, text=True)
    subprocess.run(command + ["run"], env=env, check=True)
    assert not subprocess.check_output(command + ["show"], env=env, text=True), "Cooldown failed"
    subprocess.run(command + ["off"], env=env, check=True)
    assert "off" in subprocess.check_output(command + ["status"], env=env, text=True)
    subprocess.run(command + ["on"], env=env, check=True)
    assert "on" in subprocess.check_output(command + ["status"], env=env, text=True)
print("Shell advisor tests passed")
