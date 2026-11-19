"""Build deterministic addon ZIPs from the reviewed source manifest only."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--source-root', type=Path, default=Path('.'))
parser.add_argument('--manifest', type=Path, default=Path('scripts/release-manifest.json'))
parser.add_argument('--output', type=Path, default=Path('dist'))
args = parser.parse_args()
manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
assert len(manifest) == 23
args.output.mkdir(parents=True, exist_ok=True)
content = {}
for name, expected in manifest.items():
    path = Path(name)
    assert not path.is_absolute() and '..' not in path.parts
    assert path.parts[0] in ('WinxGuild', 'TankAlertsForever')
    data = (args.source_root / path).read_bytes()
    if path.suffix in ('.lua', '.md', '.toc'):
        data = data.replace(b'\r\n', b'\n')
    sha = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    assert sha == expected, 'Source differs from reviewed manifest: ' + name
    assert not re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\bsk-proj-[A-Za-z0-9_-]{20,}|\bgh[pousr]_[A-Za-z0-9]{20,}|\bgithub_pat_[A-Za-z0-9_]{20,}', data)
    assert not re.search(rb'(?i)[A-Z]:[\\/]Users[\\/]', data)
    content[name] = data

for addon, version, filename, count in (
    ('WinxGuild', '0.3.41', 'WinxGuild-0.3.41.zip', 8),
    ('TankAlertsForever', '1.0.0', 'TankAlertsForever-1.0.0.zip', 15),
):
    files = sorted(name for name in content if name.startswith(addon + '/'))
    assert len(files) == count
    assert ('## Version: ' + version).encode() in content[addon + '/' + addon + '.toc']
    target = args.output / filename
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_STORED) as archive:
        for name in files:
            entry = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_STORED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, content[name])
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert archive.namelist() == files
        for name in files:
            assert archive.read(name) == content[name]
    print(filename + ' sha256:' + hashlib.sha256(target.read_bytes()).hexdigest())
