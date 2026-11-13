const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const {spawnSync} = require('node:child_process');
const assert = require('node:assert/strict');
const work = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-clipboard.'));
const bin = path.join(work, 'bin');
fs.mkdirSync(bin);
const trace = path.join(work, 'trace');
for (const name of ['wl-paste', 'cliphist', 'wl-copy']) {
    fs.writeFileSync(path.join(bin, name), `#!/bin/sh\nprintf '%s\\n' '${name} '"$*" >> "$ZS_TEST_TRACE"\n` +
        (name === 'wl-paste' ? 'if [ ! -e "$ZS_TEST_TRACE.once" ]; then : > "$ZS_TEST_TRACE.once"; exit 0; fi\nexec /run/current-system/sw/bin/sleep 3\n' :
        name === 'cliphist' ? '[ "$1" = list ] || exit 90\nprintf "42\\tprivate\\n"\n' : 'exit 91\n'), {mode: 0o755});
}
const result = spawnSync('bash', ['tests/run-qml-regression.sh', 'clipboard-privacy.qml'], {
    cwd: path.resolve(__dirname, '..'), encoding: 'utf8',
    env: {...process.env, PATH: `${bin}:${process.env.PATH}`, ZS_TEST_TRACE: trace,
        DBUS_SESSION_BUS_ADDRESS: 'unix:path=/nonexistent/zs-test', DBUS_SYSTEM_BUS_ADDRESS: 'unix:path=/nonexistent/zs-test'}
});
console.log(`Retained clipboard scratch: ${work}\n${result.stdout}${result.stderr}`);
assert.equal(result.status, 0, 'Real QML clipboard privacy regression');
const calls = fs.readFileSync(trace, 'utf8').trim().split('\n');
assert.equal(calls.filter(x => x === 'cliphist list').length, 1, 'Only enabled refresh may read history');
assert(calls.every(x => x === 'cliphist list' || x === 'wl-paste --watch cliphist store'), 'No decode, paste, or database clearing');
console.log('PASS clipboard fake-command trace');
