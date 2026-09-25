"""Check release contents and every packaged TOC dependency."""
import sys
import tempfile
from pathlib import Path
from zipfile import ZipFile
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from package import build
with tempfile.TemporaryDirectory() as directory:
    for flavor in ("forever", "classic"):
        target = build("0.1.0", flavor, Path(directory))
        with ZipFile(target) as archive:
            names = archive.namelist()
            assert all(name.startswith("ExtraStats/") for name in names)
            assert not any(part in name for name in names for part in (".git", ".references", "tests/", "__pycache__", "scripts/"))
            toc = archive.read("ExtraStats/ExtraStats.toc").decode()
            assert "@project-version@" not in toc and "0.1.0" in toc
            assert ("16001" in toc) == (flavor == "forever")
            assert ("ExtraStats/forever/StatsUI.lua" in names) == (flavor == "forever")
            assert ("ExtraStats/core/settings.lua" in names) == (flavor == "classic")
print("PASS: isolated Forever/Classic archives, TOC dependencies, versions, development-file exclusion")
