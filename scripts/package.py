"""Build an allowlisted CurseForge archive; no checkout files are modified."""
import argparse
import re
import sys
import posixpath
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]

def build(version, flavor, output):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", version):
        raise ValueError("Version must be a filename-safe release tag")
    if flavor == "forever":
        sys.path.insert(0, str(ROOT / "tools"))
        from package_forever import build_package
        return build_package(ROOT, output, version)[0]
    files = {"LICENSE": ROOT / "LICENSE", "CHANGELOG.md": ROOT / "CHANGELOG.md"}
    files["ExtraStats.toc"] = ROOT / "packaging/ExtraStats_Classic.toc"
    for name in ("README.md", "ExtraStats.lua", "embeds.xml", "ExtraStats_Tbc.toc", "ExtraStats_Vanilla.toc"):
        files[name] = ROOT / name
    for directory in ("core", "libraries", "locales", "modules", "plugins", "resources", "xml"):
        for path in (ROOT / directory).rglob("*"):
            if path.is_file():
                files[path.relative_to(ROOT).as_posix()] = path
    output.mkdir(parents=True, exist_ok=True)
    target = output / ("ExtraStats-" + version + ".zip")
    with ZipFile(target, "w", ZIP_DEFLATED) as archive:
        for name, path in sorted(files.items()):
            data = path.read_bytes()
            if path.suffix == ".toc":
                data = data.replace(b"@project-version@", version.encode())
            archive.writestr("ExtraStats/" + name, data)
    with ZipFile(target) as archive:
        names = set(archive.namelist())
        for name in names:
            if not name.endswith(".toc"):
                continue
            for line in archive.read(name).decode().splitlines():
                line = line.strip()
                if line and not line.startswith("#"):
                    entry = posixpath.normpath(posixpath.dirname(name) + "/" + line.replace(chr(92), "/"))
                    if entry not in names:
                        raise ValueError("Missing TOC dependency: " + entry)
    return target

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--flavor", choices=("forever", "classic"), default="forever")
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    print(build(args.version, args.flavor, args.output))
