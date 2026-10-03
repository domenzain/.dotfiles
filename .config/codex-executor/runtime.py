"""Private configuration and launch validation for the optional dot executor."""
import json
import os
from pathlib import Path
import stat
import subprocess
from urllib.parse import urlsplit


def config_path():
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "codex-executor/service.local.json"


def load_config(path=None):
    path = Path(path) if path is not None else config_path()
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
        raise ValueError("private configuration must be an owned regular file with mode 0600")
    data = json.loads(path.read_text())
    required = {"codex_bin", "codex_home", "remote_url", "environment_id", "working_directory"}
    if not isinstance(data, dict) or set(data) != required:
        raise ValueError("private configuration has missing or unexpected fields")
    if any(not isinstance(v, str) or not v or any(ord(c) < 32 for c in v) for v in data.values()):
        raise ValueError("configuration values must be nonempty strings without control characters")
    for key in ("codex_bin", "codex_home", "working_directory"):
        if not Path(data[key]).is_absolute():
            raise ValueError(key + " must be an absolute path")
    url = urlsplit(data["remote_url"])
    if url.scheme != "https" or not url.hostname or url.username or url.password or url.query or url.fragment:
        raise ValueError("remote_url must be an HTTPS registry URL without credentials, query, or fragment")
    if not os.access(data["codex_bin"], os.X_OK):
        raise ValueError("configured Codex executable is unavailable")
    if not Path(data["codex_home"]).is_dir() or not Path(data["working_directory"]).is_dir():
        raise ValueError("configured profile and working directory must already exist")
    return data


def command(data):
    return [data["codex_bin"], "exec-server", "--remote", data["remote_url"],
            "--environment-id", data["environment_id"]]


def environment(data):
    env = os.environ.copy()
    for key in ("CODEX_EXEC_SERVER_EXIT_ON_STDIN_CLOSE", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN",
                "OPENAI_API_KEY", "OPENAI_ACCESS_TOKEN", "DISPLAY", "WAYLAND_DISPLAY",
                "XAUTHORITY", "CODEX_ELECTRON_USER_DATA_PATH"):
        env.pop(key, None)
    env["CODEX_HOME"] = data["codex_home"]
    env["PATH"] = os.environ.get("CODEX_SERVICE_PATH", str(Path.home() / ".local/bin") + ":/usr/local/bin:/usr/bin:/bin")
    return env


def require_login(data):
    result = subprocess.run([data["codex_bin"], "login", "status"], env=environment(data),
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    if result.returncode:
        raise ValueError("existing profile is not signed in; complete normal Codex login separately")


def state_path():
    return Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "codex-executor/runtime.json"
