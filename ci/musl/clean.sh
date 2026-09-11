#!/bin/sh
set -eu
exec > /work/logs/clean-install.log 2>&1
mkdir -p /opt/check /opt/runtime
tar -xzf /work/dist/*-musl-x86_64-prefix.tar.gz -C /opt/check
cp /work/runtime/* /opt/runtime/ 2>/dev/null || test -z "$(ls -A /work/runtime)"
export LD_LIBRARY_PATH=/opt/check/prefix/lib:/opt/runtime
python /src/ci/musl/smoke.py /opt/check/prefix
python -m pip install --no-index --no-deps /work/wheelhouse/*.whl
python /opt/check/prefix/share/insightos-mesa/launch.py --profile auto --mesa-prefix /opt/check/prefix --report /work/logs/egl-report.json --check
python - <<'PY'
import json
report=json.load(open('/work/logs/egl-report.json'))
assert report['selected']=='software' and report['opengl']['software']
print('PASS: source-built Mesa EGL RGB/depth and software fallback in clean offline musl container')
PY
