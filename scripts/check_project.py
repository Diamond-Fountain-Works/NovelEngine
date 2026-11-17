#!/usr/bin/env python3
"""Check documentation links and enforce the established module boundaries."""
import json
import pathlib
import plistlib
import re
import sys
from urllib.parse import unquote, urlsplit

root = pathlib.Path(__file__).resolve().parents[1]
errors = []
documents = [*sorted(root.glob("*.md")), *sorted((root / "docs").rglob("*.md")), *sorted((root / "protocol").rglob("*.md"))]
for document in documents:
    content = document.read_text()
    links = re.findall(r"(?<!!)\[[^\]]+\]\(([^)]+)\)", content)
    links += re.findall(r'(?:src|srcset)="([^"]+)"', content)
    for link in links:
        target = urlsplit(link)
        if not target.scheme and target.path and not (document.parent / unquote(target.path)).exists():
            errors.append(f"{document.relative_to(root)}: missing {link}")
for source in (root / "packages/novel-core-swift/Sources").rglob("*.swift"):
    forbidden = re.findall(r"^import (SwiftUI|AppKit|UIKit|SwiftData|Network)\b", source.read_text(), re.M)
    if forbidden:
        errors.append(f"{source.relative_to(root)}: platform imports {forbidden}")
info = plistlib.loads((root / "apps/apple/macOS/Configuration/Info.plist").read_bytes())
if info["CFBundleIdentifier"] != "com.diamondfountain.novelengine.dev":
    errors.append("development bundle ID changed")
if any(info.get(key) != "Novel Engine" for key in ("CFBundleName", "CFBundleDisplayName")):
    errors.append("product display name must be Novel Engine")
if info["LSMinimumSystemVersion"] != "13.0":
    errors.append("deployment target and docs require review")
for required in ("CFBundleDocumentTypes", "UTExportedTypeDeclarations"):
    if not info.get(required):
        errors.append(f"missing {required}")
for manifest in root.glob("**/Package.swift"):
    if "build" in manifest.relative_to(root).parts:
        continue
    for relative in re.findall(r'\.package\(path: "([^"]+)"\)', manifest.read_text()):
        if not (manifest.parent / relative / "Package.swift").is_file():
            errors.append(f"{manifest.relative_to(root)}: invalid dependency {relative}")
print(json.dumps({"status": "FAIL" if errors else "PASS", "documents": len(documents), "errors": errors}, ensure_ascii=False, indent=2))
sys.exit(bool(errors))
