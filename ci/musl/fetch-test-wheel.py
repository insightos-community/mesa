import hashlib, json, urllib.request
from pathlib import Path
base='https://github.com/insightos-community/mujoco/releases/download/musl-v3.4.0-3/'
checksums=urllib.request.urlopen(base+'SHA256SUMS',timeout=60).read().decode()
checksums={line.split()[1]:line.split()[0] for line in checksums.splitlines()}
records=[]
for name in ('mujoco-3.4.0-cp313-cp313-musllinux_1_2_x86_64.whl','glfw-2.10.2-py3-none-any.whl'):
    data=urllib.request.urlopen(base+name,timeout=120).read()
    assert hashlib.sha256(data).hexdigest()==checksums[name]
    Path('/work/wheelhouse',name).write_bytes(data)
    records.append({'url':base+name,'sha256':checksums[name]})
Path('/work/logs/test-dependency.json').write_text(json.dumps(records,indent=2)+'\n')
