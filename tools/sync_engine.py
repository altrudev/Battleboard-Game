from pathlib import Path
import shutil

here = Path(__file__).resolve().parent
source = (here / ".." / ".." / "Battleboard-Engine" / "addons" / "battleboard_engine").resolve()
target = (here / ".." / "addons" / "battleboard_engine").resolve()
if not source.exists():
    raise SystemExit(f"Engine checkout not found at {source}")
if target.exists():
    shutil.rmtree(target)
shutil.copytree(source, target)
print(f"Synced {source} -> {target}")
