#!/usr/bin/env python3
"""Check the exact Git candidate set. Never print a matched credential value."""
import json
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[1]
repository = pathlib.Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], cwd=root, text=True).strip())
if repository != root:
    sys.exit("FAIL: publication checks require the project repository root")
paths = set(subprocess.check_output(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=root).decode().split("\0")) - {""}
patterns = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "GitHub credential": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,})\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "credential assignment": re.compile(r'''(?im)^\s*(?:CLOUDFLARE_API_TOKEN|CF_API_TOKEN|OPENAI_API_KEY|GITHUB_TOKEN|PAIRING_SECRET)\s*[:=]\s*["']?[A-Za-z0-9_/-]{16,}'''),
    "private home path": re.compile(r"/Users/[A-Za-z0-9_.-]+/"),
}
blocked_extensions = {".p12", ".p8", ".pem", ".key", ".db", ".sqlite", ".sqlite3", ".keystore", ".jks", ".dmg", ".ne"}
errors = []
for name in sorted(paths):
    path = pathlib.Path(name)
    if any(part in {"build", ".build", "DerivedData", "xcuserdata"} or part.endswith((".novelengine", ".ne", ".app", ".xcresult")) for part in path.parts) or path.suffix in blocked_extensions or path.name.startswith((".env", ".dev.vars")):
        errors.append({"file": name, "issue": "private data or generated artifact path"})
        continue
    full = root / path
    if full.is_symlink():
        errors.append({"file": name, "issue": "symbolic link requires review"})
        continue
    if not full.is_file():
        continue
    data = full.read_bytes()
    try:
        content = data.decode("utf-8")
    except UnicodeDecodeError:
        if path.suffix.lower() not in {".png", ".ttf", ".woff2"}:
            errors.append({"file": name, "issue": "unreviewed binary file type"})
        continue
    for label, pattern in patterns.items():
        if pattern.search(content):
            errors.append({"file": name, "issue": label})
print(json.dumps({"status": "FAIL" if errors else "PASS", "files": len(paths), "errors": errors}, ensure_ascii=False, indent=2))
sys.exit(bool(errors))
