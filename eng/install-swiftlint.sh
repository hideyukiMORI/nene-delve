#!/bin/sh
# SwiftLint の静的バイナリを eng/tool-versions.json の URL と SHA-256 で置く。
# 動的バイナリは glibc 2.38 を要求し、この開発機（glibc 2.35）では起動しない。
set -eu
cd "$(dirname "$0")/.."
dest=".tools/swiftlint"
python3 - "$dest" << 'PY'
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

dest = Path(sys.argv[1])
pin = json.loads(Path("eng/tool-versions.json").read_text(encoding="utf-8"))["swiftlint"]
expected = pin["sha256"]
url = pin["url"]
member = pin["binary_in_zip"]

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

stamp = dest.with_suffix(".sha256")
if dest.exists() and stamp.exists() and stamp.read_text(encoding="utf-8").strip() == expected:
    sys.exit(0)

dest.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    archive = Path(tmp) / "swiftlint.zip"
    urllib.request.urlretrieve(url, archive)
    actual = sha256(archive)
    if actual != expected:
        sys.stderr.write(f"QLT-011: swiftlint sha256 mismatch\n  expected {expected}\n  actual   {actual}\n")
        sys.exit(1)
    with zipfile.ZipFile(archive) as zipped:
        zipped.extract(member, tmp)
    shutil.move(str(Path(tmp) / member), dest)
dest.chmod(0o755)
stamp.write_text(expected + "\n", encoding="utf-8")
PY
"$dest" version >/dev/null
