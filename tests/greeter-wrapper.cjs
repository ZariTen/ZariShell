const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const scratch = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-wrapper.'));
console.log('Retained wrapper scratch:', scratch);
const env = {...process.env, DBUS_SESSION_BUS_ADDRESS: 'unix:path=/nonexistent/zs-test', DBUS_SYSTEM_BUS_ADDRESS: 'unix:path=/nonexistent/zs-test'};
const evaluation = spawnSync('nix', ['eval', '--offline', '--option', 'allow-import-from-derivation', 'false', '--impure', '--json', '--file', 'tests/greeter-wrapper.nix'], {
    cwd: path.resolve(__dirname, '..'), env, encoding: 'utf8'
});
assert.equal(evaluation.status, 0, evaluation.stderr);
const {wrapper, rule, expected} = JSON.parse(evaluation.stdout);
fs.writeFileSync(path.join(scratch, 'evaluation.json'), evaluation.stdout);
// Execute only copied export statements, never cage, Quickshell or the runtime fallback.
const assignments = wrapper.split('\n').filter(line => line.startsWith('export ') && !line.startsWith('export PATH=')).join('\n');
const script = path.join(scratch, 'exports.sh');
fs.writeFileSync(script, assignments + '\nexec ' + JSON.stringify(process.execPath) + ' -e \'process.stdout.write(JSON.stringify(process.env))\'\n');
const child = spawnSync('/bin/sh', [script], {encoding: 'utf8', env: {PATH: scratch, XDG_CONFIG_HOME: scratch, ...Object.fromEntries(Object.entries(env).filter(([key]) => key.startsWith('DBUS_')))}});
assert.equal(child.status, 0, child.stderr);
const actual = JSON.parse(child.stdout);
for (const [key, value] of Object.entries({HOME: expected.stateDir, QS_GREETER_STATE: expected.stateDir,
    XDG_CACHE_HOME: expected.stateDir + '/cache', XDG_STATE_HOME: expected.stateDir + '/state',
    XDG_CONFIG_HOME: expected.stateDir + '/config', XDG_DATA_HOME: expected.stateDir + '/data',
    XCURSOR_THEME: expected.cursor.name, XCURSOR_SIZE: '24',
    QS_GREETER_SESSIONS: '/fixture sessions/share/wayland-sessions', QS_GREETER_MAIN_MONITOR: expected.mainMonitor,
    QS_GREETER_SESSION_COMMAND: expected.sessionCommand, QS_GREETER_SESSION_NAME: expected.sessionName, QS_GREETER_HOST_LABEL: expected.hostLabel}))
    assert.equal(actual[key], value, key + ' must round-trip literally');
const root = path.join(scratch, 'root');
fs.mkdirSync(path.join(root, 'etc'), {recursive: true});
fs.writeFileSync(path.join(root, 'etc/passwd'), 'greeter:x:999:999:Greeter:/:/bin/false\n');
fs.writeFileSync(path.join(root, 'etc/group'), 'greeter:x:999:\n');
const tmpfiles = spawnSync('/run/current-system/sw/bin/systemd-tmpfiles', ['--dry-run', '--create', '--root=' + root, '--inline', rule], {
    encoding: 'utf8', env: {PATH: scratch, SYSTEMD_LOG_LEVEL: 'debug', ...Object.fromEntries(Object.entries(env).filter(([key]) => key.startsWith('DBUS_')))}
});
fs.writeFileSync(path.join(scratch, 'tmpfiles.log'), tmpfiles.stdout + tmpfiles.stderr);
assert.equal(tmpfiles.status, 0, tmpfiles.stderr);
assert(tmpfiles.stderr.includes(root + expected.stateDir), 'Real tmpfiles parser must preserve the literal state path, including % specifiers');
assert.equal(fs.existsSync(path.join(root, expected.stateDir)), false, 'Dry-run must create no state directory');
console.log('PASS wrapper environment round-trip, control rejection, and isolated tmpfiles parser');
