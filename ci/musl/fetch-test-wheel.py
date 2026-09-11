import hashlib, json, urllib.request
from pathlib import Path
base='https://github.com/insightos-community/mujoco/releases/download/musl-v3.4.0-1/'
name='mujoco-3.4.0-cp313-cp313-musllinux_1_2_x86_64.whl'
checksums=urllib.request.urlopen(base+'SHA256SUMS',timeout=60).read().decode()
expected={line.split()[1]:line.split()[0] for line in checksums.splitlines()}[name]
data=urllib.request.urlopen(base+name,timeout=120).read()
assert hashlib.sha256(data).hexdigest()==expected
Path('/work/wheelhouse',name).write_bytes(data)
Path('/work/logs/test-dependency.json').write_text(json.dumps({'url':base+name,'sha256':expected},indent=2)+'\n')
