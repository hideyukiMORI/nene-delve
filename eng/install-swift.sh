#!/bin/sh
# CI が Swift を入れる経路。版の入力は .swift-version だけ。
# 既に一致する swift が見えていれば何もしない（開発機）。
set -eu
cd "$(dirname "$0")/.."
wanted="$(tr -d '[:space:]' < .swift-version)"
if command -v swift >/dev/null 2>&1; then
  current="$(swift --version 2>/dev/null || true)"
  case "$current" in
    *"Swift version ${wanted}"*)
      exit 0
      ;;
  esac
fi

python3 - << 'PY'
import hashlib
import json
import os
import stat
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path

pin = json.loads(Path("eng/tool-versions.json").read_text(encoding="utf-8"))["swiftly"]
archive_path = Path(tempfile.mkdtemp()) / "swiftly.tar.gz"
urllib.request.urlretrieve(pin["url"], archive_path)
digest = hashlib.sha256(archive_path.read_bytes()).hexdigest()
if digest != pin["sha256"]:
    raise SystemExit(
        f"QLT-011: swiftly sha256 mismatch\n  expected {pin['sha256']}\n  actual   {digest}"
    )
extract = archive_path.parent / "extract"
extract.mkdir()
with tarfile.open(archive_path) as archive:
    archive.extractall(extract)
binary = next(extract.rglob("swiftly"))
binary.chmod(binary.stat().st_mode | stat.S_IEXEC)
home = Path.home() / ".local" / "share" / "swiftly"
env = os.environ.copy()
env["SWIFTLY_HOME_DIR"] = str(home)
subprocess.run(
    [str(binary), "init", "--assume-yes", "--skip-install", "--quiet-shell-followup"],
    check=True,
    env=env,
)
print(home / "env.sh")
PY

# shellcheck disable=SC1091
# 上の Python が最後に env.sh のパスを出す。init が既にある開発機ではここまで来ない。
env_sh="${HOME}/.local/share/swiftly/env.sh"
if [ -f "$env_sh" ]; then
  # shellcheck disable=SC1090
  . "$env_sh"
fi
hash -r
swiftly install --assume-yes --use "$wanted"
hash -r
swift --version
