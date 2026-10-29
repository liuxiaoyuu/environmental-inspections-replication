"""Fetch and verify two pinned author inputs. Python standard library only."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "data/sources.json"


def verify(path, record):
    md5, sha256 = hashlib.md5(), hashlib.sha256()
    size = 0
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            size += len(chunk)
            md5.update(chunk)
            sha256.update(chunk)
    if (size, md5.hexdigest(), sha256.hexdigest()) != (
        record["bytes"], record["md5"], record["sha256"]
    ):
        raise ValueError(f"Integrity check failed: {path.name}; expected the pinned original DTA")
    return sha256.hexdigest()


def fetch(record, offline=False):
    destination = ROOT / "data/raw" / record["filename"]
    if destination.exists():
        verify(destination, record)  # Never silently replace changed input.
    elif offline:
        raise FileNotFoundError(f"Missing {destination.name}; run without --verify to download")
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        for attempt in range(3):
            fd, name = tempfile.mkstemp(prefix=destination.name + ".", suffix=".part", dir=destination.parent)
            temporary = Path(name)
            try:
                request = urllib.request.Request(record["url"], headers={"User-Agent": "environmental-inspections-reproduction/0.1"})
                with os.fdopen(fd, "wb") as output, urllib.request.urlopen(request, timeout=120) as response:
                    while chunk := response.read(1024 * 1024):
                        output.write(chunk)
                verify(temporary, record)
                temporary.replace(destination)
                break
            except (urllib.error.URLError, TimeoutError, ConnectionError):
                if attempt == 2:
                    raise
                time.sleep(2 ** attempt)
            finally:
                temporary.unlink(missing_ok=True)
    print(f"Verified {record['filename']}: {record['bytes']:,} bytes; SHA256 {record['sha256']}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="Verify existing files without network access")
    args = parser.parse_args()
    for record in json.loads(SOURCES.read_text())["files"]:
        fetch(record, offline=args.verify)


if __name__ == "__main__":
    main()
