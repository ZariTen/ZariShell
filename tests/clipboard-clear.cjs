const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {execFileSync, spawnSync} = require('node:child_process');

const cliphist = execFileSync('sh', ['-c', 'command -v cliphist'], {encoding: 'utf8'}).trim();
const work = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-clip-clear.'));
const trace = path.join(work, 'trace');
const db = path.join(work, 'db');
const dbArgs = ['-config-path', db + '.config', '-db-path', db];
for (const text of ['first', 'second']) {
    execFileSync(cliphist, [...dbArgs, 'store'], {input: text});
}

for (const name of ['cliphist', 'wl-copy']) {
    const code = name === 'cliphist' ? `
        assert(args.length === 1 && ['list', 'wipe'].includes(args[0]));
        const {execFileSync} = require('node:child_process');
        const output = execFileSync(process.env.ZS_CLIPHIST, ['-config-path', process.env.ZS_DB + '.config', '-db-path', process.env.ZS_DB, ...args]);
        setTimeout(() => process.stdout.write(output), args[0] === 'list' ? 100 : 0);
    ` : `
        assert.deepEqual(args, ['--clear']);
        // Simulate a watcher child that has the old selection but hasn't stored it yet.
        if (!fs.existsSync(process.env.ZS_TRACE + '.storing')) {
            const {spawn} = require('node:child_process');
            const lock = process.env.XDG_CACHE_HOME + '/zarishell-clipboard.lock';
            const child = spawn('flock', ['-s', '-F', lock, process.execPath, '-e', \`
                const fs = require('node:fs');
                fs.writeFileSync(process.env.ZS_TRACE + '.storing', '');
                setTimeout(() => {
                    require('node:child_process').execFileSync(process.env.ZS_CLIPHIST,
                        ['-config-path', process.env.ZS_DB + '.config', '-db-path', process.env.ZS_DB, 'store'],
                        {input: 'late entry from the old selection'});
                    fs.appendFileSync(process.env.ZS_TRACE, 'old selection stored\\\\n');
                }, 450);
            \`], {stdio: 'ignore'});
            const ready = setInterval(() => {
                if (fs.existsSync(process.env.ZS_TRACE + '.storing')) {
                    clearInterval(ready);
                    child.unref();
                }
            }, 10);
        }
    `;
    fs.writeFileSync(path.join(work, name), `#!${process.execPath}
        const assert = require('node:assert/strict');
        const fs = require('node:fs');
        const args = process.argv.slice(2);
        fs.appendFileSync(process.env.ZS_TRACE, ${JSON.stringify(name)} + ' ' + args.join(' ') + '\\n');
        ${code}
    `, {mode: 0o700});
}

const result = spawnSync('bash', ['tests/run-qml-regression.sh', 'clipboard-clear.qml'], {
    cwd: path.resolve(__dirname, '..'), encoding: 'utf8',
    env: {...process.env, PATH: `${work}:${process.env.PATH}`,
        ZS_TRACE: trace, ZS_CLIPHIST: cliphist, ZS_DB: db}
});
console.log(`Retained clear scratch: ${work}\n${result.stdout}${result.stderr}`);
assert.equal(result.status, 0);
const commands = fs.readFileSync(trace, 'utf8').trim().split('\n');
assert.deepEqual(commands.filter(command => command !== 'cliphist list'), [
    'wl-copy --clear', 'old selection stored', 'cliphist wipe', 'wl-copy --clear', 'cliphist wipe'
]);
assert.equal(execFileSync(cliphist, [...dbArgs, 'list'], {encoding: 'utf8'}), '');
console.log('PASS clipboard clear command and persisted history wipe');
