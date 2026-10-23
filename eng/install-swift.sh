#!/bin/bash
# CI が Swift を入れる経路。版の入力は .swift-version だけ。
# 既に一致する swift が見えていれば何もしない（開発機）。
# swiftly の env.sh は bash の ${PATH//} を使う。/bin/sh（dash）で読むと
# Bad substitution で落ちる。導入した PATH は、このプロセスだけでは次の
# ステップに残らないので、GITHUB_PATH と GITHUB_ENV があるときだけ渡す。
set -eu
cd "$(dirname "$0")/.."
wanted="$(tr -d '[:space:]' < .swift-version)"

publish_swiftly_env() {
  if [ -z "${SWIFTLY_BIN_DIR:-}" ]; then
    return 0
  fi
  if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${SWIFTLY_BIN_DIR}" >> "${GITHUB_PATH}"
  fi
  if [ -n "${GITHUB_ENV:-}" ]; then
    printf 'SWIFTLY_HOME_DIR=%s\nSWIFTLY_BIN_DIR=%s\nSWIFTLY_TOOLCHAINS_DIR=%s\n' \
      "${SWIFTLY_HOME_DIR}" "${SWIFTLY_BIN_DIR}" "${SWIFTLY_TOOLCHAINS_DIR}" \
      >> "${GITHUB_ENV}"
  fi
}

if command -v swift >/dev/null 2>&1; then
  current="$(swift --version 2>/dev/null || true)"
  case "$current" in
    *"Swift version ${wanted}"*)
      publish_swiftly_env
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
# run 39971963866 で swiftly が終了 1 とともに要求したパッケージ。
# run 39972237751 では索引が古く libcurl4-openssl-dev が 404 で終了 100 だった。
# 一致する swift が既にある開発機は、上の早期 return でここへ来ない。
if command -v apt-get >/dev/null 2>&1; then
  packages=(libcurl4-openssl-dev pkg-config python3-lldb-13)
  if [ "$(id -u)" -eq 0 ]; then
    apt_root() { "$@"; }
  elif command -v sudo >/dev/null 2>&1; then
    apt_root() { sudo "$@"; }
  else
    echo "apt-get needs root for the Swift toolchain dependencies" >&2
    exit 1
  fi
  apt_root env DEBIAN_FRONTEND=noninteractive apt-get update
  apt_root env DEBIAN_FRONTEND=noninteractive apt-get -y install "${packages[@]}"
fi
swiftly install --assume-yes --use "$wanted"
hash -r
swift --version
publish_swiftly_env
