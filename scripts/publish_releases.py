"""Create the two user-authorized addon releases using the workflow token."""
import hashlib
import json
import os
from pathlib import Path
import subprocess

repo = os.environ['GITHUB_REPOSITORY']
assert repo == 'AlohaG0/Guild-Panel'
target = os.environ['GITHUB_SHA']

def gh(*arguments, check=True):
    result = subprocess.run(['gh', *arguments], capture_output=True, text=True)
    if check and result.returncode:
        raise SystemExit('GitHub CLI failed; no credentials printed: ' + arguments[0])
    return result

# Publish the tank release first, then mark Guild Panel as the latest release.
for tag, filename, title, notes, latest in (
    ('tank-tools-v1.0.0', 'TankAlertsForever-1.0.0.zip', 'Tank Tools Forever 1.0.0', 'releases/TankTools-1.0.0.md', False),
    ('v0.3.41', 'WinxGuild-0.3.41.zip', 'Guild Panel 0.3.41', 'releases/GuildPanel-0.3.41.md', True),
):
    artifact = Path('dist') / filename
    digest = 'sha256:' + hashlib.sha256(artifact.read_bytes()).hexdigest()
    current = gh('api', f'repos/{repo}/releases/tags/{tag}', check=False)
    if current.returncode:
        # Only a confirmed 404 permits creating a new release.
        if '404' not in current.stderr:
            raise SystemExit('Release lookup failed; no create attempted.')
        gh('release', 'create', tag, '--repo', repo, '--draft', '--target', target,
           '--title', title, '--notes-file', notes)
        current = gh('api', f'repos/{repo}/releases/tags/{tag}')
    release = json.loads(current.stdout)
    asset = next((item for item in release['assets'] if item['name'] == filename), None)
    if asset:
        assert asset.get('digest') == digest, 'Existing asset differs; refusing to overwrite.'
    else:
        gh('release', 'upload', tag, str(artifact), '--repo', repo)
    verified = json.loads(gh('api', f'repos/{repo}/releases/tags/{tag}').stdout)
    asset = next(item for item in verified['assets'] if item['name'] == filename)
    assert asset['state'] == 'uploaded' and asset.get('digest') == digest
    gh('release', 'edit', tag, '--repo', repo, '--draft=false', '--latest=' + str(latest).lower())
    print('Published and verified: ' + verified['html_url'])
