const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawn, execFileSync} = require('node:child_process');
assert.ok(process.env.TMPDIR, 'TMPDIR must point to retained scratch');
const scratch = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-start.'));
console.log('Retained calculator startup scratch:', scratch);
const shell = path.join(scratch, 'shell');
fs.cpSync(path.join(__dirname, '../shell'), shell, {recursive: true, dereference: true});
fs.copyFileSync(path.join(__dirname, 'calculator-startup.qml'), path.join(shell, 'shell.qml'));
for (const dir of ['bin', 'config/zarishell', 'cache', 'state']) fs.mkdirSync(path.join(scratch, dir), {recursive: true});
const resolveCommand = name => execFileSync('bash', ['-c', 'command -v "$1"', 'bash', name], {encoding: 'utf8'}).trim();
const quickshell = resolveCommand('quickshell');
const timeout = resolveCommand('timeout');
const trace = path.join(scratch, 'trace');
fs.writeFileSync(path.join(scratch, 'bin/qalc'), `#!${process.execPath}
const fs = require('node:fs');
const expression = process.argv.at(-1);
fs.appendFileSync(${JSON.stringify(trace)}, expression + '\\n');
if (expression !== '3+3') process.exit(1);
process.stdout.write('6\\n');
`, {mode: 0o700});
const env = {...process.env, PATH: path.join(scratch, 'bin'),
    XDG_CONFIG_HOME: path.join(scratch, 'config'), XDG_CACHE_HOME: path.join(scratch, 'cache'),
    XDG_STATE_HOME: path.join(scratch, 'state'), QT_QPA_PLATFORM: 'wayland',
    QT_QUICK_BACKEND: 'software', QT_QPA_PLATFORMTHEME: 'generic'};
for (const key of ['QS_CONFIG_PATH', 'QS_CONFIG_NAME', 'QS_MANIFEST']) delete env[key];
const child = spawn(quickshell, ['--no-color', '-p', shell], {env});
let output = '';
let repaired = false;
const watchdog = setTimeout(() => child.kill('SIGKILL'), 10000);
function collect(chunk) {
    output += chunk.toString();
    if (!repaired && output.includes('READY calculator startup recovery')) {
        fs.symlinkSync(timeout, path.join(scratch, 'bin/timeout'));
        repaired = true;
    }
}
child.stdout.on('data', collect);
child.stderr.on('data', collect);
child.on('close', code => {
    clearTimeout(watchdog);
    fs.writeFileSync(path.join(scratch, 'output.log'), output);
    process.stdout.write(output);
    assert.equal(code, 0, 'isolated Quickshell must exit successfully');
    // This fixture deliberately starts with no timeout executable. No other warning is allowed.
    assert.doesNotMatch(output, /FAIL/);
    const diagnostics = output.split('\n').filter(line => /WARN|ERROR/.test(line));
    assert.equal(diagnostics.length, 1, 'exactly one expected FailedToStart diagnostic');
    assert.equal(diagnostics[0].trim(), 'WARN: Process failed to start, likely because the binary could not be found. Command: QList("timeout", "2s", "qalc", "-t", "-defaults", "-s", "update exchange rates 0", "-s", "autoconversion 0", "-s", "decimal comma 0", "-m", "500", "--", "2+2")');
    assert.match(output, /PASS QML regression tests: failed startup/);
    assert.equal(fs.readFileSync(trace, 'utf8'), '3+3\n');
    console.log('PASS startup failure diagnostic, empty failed result, and real QML recovery');
});
