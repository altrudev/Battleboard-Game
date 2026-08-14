from pathlib import Path
import hashlib, json, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / 'dist'
VERSION = '0.4.3'
NAME = f'Battleboard-Game-v{VERSION}-chapter-one-demo-GODOT-SAFE.zip'


def run(*args):
    result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True)
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise SystemExit(result.returncode)
    return result.stdout.strip()


def main():
    if run('git', 'status', '--porcelain'):
        raise SystemExit('Refusing to package a dirty working tree.')
    head = run('git', 'rev-parse', 'HEAD')
    for command in [
        [sys.executable, 'tools/validate_project.py'],
        [sys.executable, 'tests/test_qualification_contracts.py'],
        [sys.executable, 'tests/test_demo_contracts.py'],
        [sys.executable, 'tools/ddc_gate.py'],
    ]:
        run(*command)

    tracked = [line for line in run('git', 'ls-files').splitlines() if line and not line.startswith('dist/')]
    hashes = {}
    for rel in tracked:
        data = (ROOT / rel).read_bytes()
        hashes[rel] = hashlib.sha256(data).hexdigest()

    provenance = {
        'schema': 1,
        'version': VERSION,
        'source_commit': head,
        'packaging_policy': 'clean tracked Git files only; validation required before archive creation',
        'files': hashes,
    }

    DIST.mkdir(exist_ok=True)
    out = DIST / NAME
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as archive:
        dirs = sorted({str(Path(rel).parent).replace('\\', '/') for rel in tracked if str(Path(rel).parent) != '.'})
        for directory in dirs:
            info = zipfile.ZipInfo(directory.rstrip('/') + '/')
            info.external_attr = (0o40755 << 16) | 0x10
            archive.writestr(info, b'')
        for rel in tracked:
            archive.write(ROOT / rel, rel)
        archive.writestr('BUILD_PROVENANCE.json', json.dumps(provenance, indent=2) + '\n')

    with zipfile.ZipFile(out, 'r') as archive:
        bad = archive.testzip()
        if bad:
            raise SystemExit(f'Archive integrity failed at {bad}')
        if 'project.godot' not in archive.namelist():
            raise SystemExit('project.godot missing from archive root')

    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    (DIST / f'{NAME}.sha256').write_text(f'{digest}  {NAME}\n')
    print(json.dumps({'archive': str(out), 'source_commit': head, 'sha256': digest}, indent=2))


if __name__ == '__main__':
    main()
