"""Check the Forever release contents and packaged load chain."""
import sys
import tempfile
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from package import build

source_toc = (ROOT / "ExtraStats.toc").read_bytes()
with tempfile.TemporaryDirectory() as directory:
    target = build("0.1.0", Path(directory))
    with ZipFile(target) as archive:
        names = set(archive.namelist())
        expected = {"ExtraStats/" + name for name in (
            "ExtraStats.toc", "LICENSE", "CHANGELOG.md", "forever/README.md",
            "forever/Frames.xml", "forever/ExtraStats.lua", "forever/StatsUI.lua",
            "forever/EquipmentSets.lua", "forever/Header.lua",
            "forever/Controller.lua", "forever/SettingsUI.lua",
        )}
        assert names == expected, (names - expected, expected - names)
        toc = archive.read("ExtraStats/ExtraStats.toc").decode()
        assert "@project-version@" not in toc and "## Version: 0.1.0" in toc
        assert "## Interface: 16001" in toc
        assert "## AllowLoadGameType: camelot" in toc
assert (ROOT / "ExtraStats.toc").read_bytes() == source_toc
print("PASS: Forever-only archive, validated load chain, version substitution, source TOC unchanged")
