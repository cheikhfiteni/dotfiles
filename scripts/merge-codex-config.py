# /// script
# requires-python = ">=3.10"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Stage a formatting-preserving merge of only tui.status_line."""
import os
from pathlib import Path
import stat
import sys

import tomlkit


def merge(source, target, output):
    shared = tomlkit.parse(source.read_bytes().decode("utf-8"))
    fields = shared["tui"]["status_line"]
    if not isinstance(fields, list) or not all(isinstance(item, str) for item in fields):
        raise ValueError("tui.status_line must be an array of strings")
    if target.is_symlink() and not target.exists():
        raise ValueError(f"Codex config symlink has no readable target: {target}")
    original = target.read_bytes() if target.exists() else b""
    document = tomlkit.parse(original.decode("utf-8"))
    if "tui" not in document:
        document["tui"] = tomlkit.table()
    if document["tui"].get("status_line") == fields:
        result = original
    else:
        document["tui"]["status_line"] = fields
        result = tomlkit.dumps(document).encode("utf-8")
    # Configs can contain credentials; new files must be private.
    mode = stat.S_IMODE(target.stat().st_mode) if target.exists() else 0o600
    with os.fdopen(os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode), "wb") as file:
        file.write(result)
    output.chmod(mode)


if __name__ == "__main__":
    merge(*(Path(argument) for argument in sys.argv[1:]))
