#!/usr/bin/env python3
"""Offer occasional shell workflow advice from coarse, allowlisted history statistics."""

import collections
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

INTERVAL = 3600
COMMANDS = {"cd", "z", "zi", "ls", "ll", "lt", "gqcd", "pwd", "clear", "nvim", "vim"}
GIT = {"status", "diff", "log", "add", "commit", "push", "pull"}


def summarize(text):
    counts = collections.Counter()
    transitions = collections.Counter()
    previous = None
    for line in text.splitlines()[-2000:]:
        line = re.sub(r"^: \d+:\d+;", "", line).strip()
        # Only the command and a known Git subcommand leave this machine.
        words = line.split()
        if not words:
            continue
        name = words[0] if words[0] in COMMANDS else None
        if words[0] == "git" and len(words) > 1 and words[1] in GIT:
            name = "git " + words[1]
        if name:
            counts[name] += 1
        if previous and name and (previous, name) in {("cd", "ls"), ("ls", "cd")}:
            transitions[previous + " -> " + name] += 1
        previous = name
    return {"counts": dict(counts), "transitions": dict(transitions)}


def state_dir():
    path = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "shell-advisor"
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    return path


def main():
    state = state_dir()
    mode = sys.argv[1] if len(sys.argv) > 1 else "run"
    if mode == "off":
        (state / "disabled").touch(mode=0o600)
        print("Shell advisor: off")
        return
    if mode == "on":
        (state / "disabled").unlink(missing_ok=True)
        print("Shell advisor: on")
        return
    if mode == "status":
        print("Shell advisor: " + ("off" if (state / "disabled").exists() else "on"))
        if (state / "last-error").exists():
            print((state / "last-error").read_text().strip())
        return
    if mode == "show":
        if (state / "disabled").exists():
            return
        try:
            message = (state / "pending").read_text().strip()
            (state / "pending").unlink(missing_ok=True)
            if message:
                print("\n💡 シェル操作のヒント: " + message + "\n")
        except FileNotFoundError:
            pass
        return
    if mode != "run" or (state / "disabled").exists():
        return
    claude = shutil.which("claude")
    history = Path(os.environ.get("HISTFILE") or str(Path.home() / ".zsh_history"))
    if not claude or not history.is_file():
        return
    with (state / "lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        marker = state / "last-run"
        if marker.exists() and time.time() - marker.stat().st_mtime < INTERVAL:
            return
        marker.touch(mode=0o600)
        data = summarize(history.read_text(errors="replace"))
        if sum(data["counts"].values()) < 15:
            return
        prompt = (
            "以下はシェル履歴の匿名化した集計です。頻度に基づき、実用的な改善を日本語で1件、"
            "80文字以内で提案してください。断定せず、具体的なコマンドを示してください。"
            "利用可能: z, zi, gqcd, gs=git status, gd=git diff, gl=git log, ll, lt, Ctrl-L。"
            "統計に根拠がない提案はしないでください。挨拶や見出しは不要です。\n"
            + json.dumps(data, ensure_ascii=False)
        )
        try:
            result = subprocess.run(
                [claude, "--print", "--restricted", "--tools", "", "--strict-mcp-config", "--no-session-persistence"],
                input=prompt, text=True, capture_output=True, timeout=90, check=True, cwd=str(Path.home()),
            )
        except (OSError, subprocess.SubprocessError):
            (state / "last-error").write_text("Claude analysis failed; check Claude login and connectivity. Retry after one hour.\n")
            return
        advice = " ".join(result.stdout.split())[:500]
        if advice:
            pending = state / "pending.tmp"
            pending.write_text(advice + "\n")
            pending.chmod(0o600)
            pending.replace(state / "pending")
            (state / "last-error").unlink(missing_ok=True)
            if sys.platform == "darwin" and shutil.which("osascript"):
                try:
                    subprocess.run(
                        ["osascript", "-e", "on run argv", "-e", 'display notification (item 1 of argv) with title "シェル操作のヒント"', "-e", "end run", advice],
                        timeout=5, capture_output=True, check=False,
                    )
                except (OSError, subprocess.SubprocessError):
                    pass


if __name__ == "__main__":
    main()
