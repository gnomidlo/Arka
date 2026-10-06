"""Verify exact source commit, current source contents and flat plugin ZIP layout."""
from pathlib import Path
import subprocess
import zipfile


def git(*args):
    return subprocess.check_output(["git", *args])


with zipfile.ZipFile(Path("dist/UNICORN.zip")) as archive:
    revision = archive.comment.decode("ascii")
    assert len(revision) == 40 and all(c in "0123456789abcdef" for c in revision), "Missing source SHA"
    expected = git("ls-tree", "-r", "--name-only", revision, "init.lua", "version.lua", "le").decode().splitlines()
    names = [name for name in archive.namelist() if not name.endswith("/")]
    assert sorted(names) == sorted(expected), "Unexpected archive layout or contents"
    for name in names:
        payload = archive.read(name)
        assert payload == git("show", f"{revision}:{name}"), f"Source SHA mismatch: {name}"
        assert payload == git("show", f"HEAD:{name}"), f"Release does not match current source: {name}"
    assert "le/storage.lua" in names
    print(f"OK: {len(names)} files match source {revision} and HEAD; flat ZIP layout")
