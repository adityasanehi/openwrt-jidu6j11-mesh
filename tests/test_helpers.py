#!/usr/bin/env python3
"""Run in a disposable root-owned Linux container; never on a router/host."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

assert os.environ.get('MESH_TEST_CONTAINER') == '1', 'Use the container command in tests/README.md'
repo = Path('/publish')
for script in (repo/'scripts').glob('*.sh'):
    subprocess.run(['sh', '-n', str(script)], check=True)
with tempfile.TemporaryDirectory() as td:
    tmp = Path(td)
    bins = tmp/'bin'
    bins.mkdir()
    def command(name, body):
        path = bins/name
        path.write_text('#!/bin/sh\n'+body+'\n')
        path.chmod(0o755)
    command('ubus', 'printf "%s\\n" "$MESH_BOARD"')
    command('jsonfilter', '''python3 -c 'import json,sys; v=json.load(sys.stdin); keys=sys.argv[-1][2:].split(".");
for k in keys: v=v[k]
print(v)' "$@"''')
    command('apk', 'exit 0')
    command('iw', 'exit 0')
    env = dict(os.environ, PATH=str(bins)+':'+os.environ['PATH'])
    import json
    for board, revision, expected in (
        ('wrong-board','r35553+1410-fdb162fb81','Untested board'),
        ('jiorouter,ax6000-jidu6j11','different-snapshot','Untested snapshot'),
    ):
        env['MESH_BOARD'] = json.dumps({'board_name':board,'release':{'revision':revision}})
        result = subprocess.run(['sh',str(repo/'scripts/check-compatibility.sh')],env=env,text=True,capture_output=True)
        assert result.returncode != 0 and expected in result.stderr, result
    # The recovery command is tested with the real APK hash, mocked package/service
    # actions, and disposable absolute paths inside this container.
    Path('/etc/config').mkdir(exist_ok=True)
    Path('/etc/init.d').mkdir(exist_ok=True)
    Path('/usr/share/hostap').mkdir(exist_ok=True)
    Path('/rom/usr/sbin').mkdir(parents=True,exist_ok=True)
    Path('/rom/usr/share/hostap').mkdir(parents=True,exist_ok=True)
    for rel in ('usr/sbin/wpad','usr/share/hostap/hostapd.uc','usr/share/hostap/wpa_supplicant.uc'):
        Path('/rom',rel).write_text('original '+rel)
    log = tmp/'actions'
    env['MESH_ACTION_LOG']=str(log)
    command('apk','echo "apk $*" >> "$MESH_ACTION_LOG"')
    command('wifi','echo "wifi $*" >> "$MESH_ACTION_LOG"')
    service = Path('/etc/init.d/wpad')
    service.write_text('#!/bin/sh\necho "wpad $*" >> "$MESH_ACTION_LOG"\n')
    service.chmod(0o755)
    work=tmp/'bundle'
    work.mkdir()
    (work/'backup').mkdir()
    (work/'backup/wireless').write_text('original test configuration\n')
    shutil.copy(repo/'scripts/rollback.sh',work/'rollback.sh')
    pkg='wpad-basic-mbedtls-2026.08.07~831364bf-r4.apk'
    shutil.copy(Path('/release')/pkg,work/pkg)
    subprocess.run(['sh',str(work/'rollback.sh')],env=env,check=True)
    assert Path('/etc/config/wireless').read_text() == 'original test configuration\n'
    assert Path('/usr/sbin/wpad').read_text() == 'original usr/sbin/wpad'
    assert Path('/usr/sbin/hostapd').is_symlink()
    actions=log.read_text()
    assert 'del wpad-mesh-mbedtls' in actions
    assert 'add ./'+pkg in actions
    assert actions.index('wpad stop') < actions.index('wpad start') < actions.index('wifi reload')
    log.unlink()
    (work/pkg).write_text('corrupt package')
    result=subprocess.run(['sh',str(work/'rollback.sh')],env=env,text=True,capture_output=True)
    assert result.returncode != 0 and 'checksum mismatch' in result.stderr
    assert not log.exists(), 'Corrupt APK must fail before package/service changes'
print('PASS: shell syntax, incompatible board/snapshot rejection, recovery sequence and corrupt-APK rejection.')
