const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
assert.ok(process.env.TMPDIR, 'TMPDIR must point to retained scratch');
const scratch = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-calc.'));
const trace = path.join(scratch, 'trace.jsonl');
console.log('Retained calculator scratch:', scratch);
fs.writeFileSync(path.join(scratch, 'qalc'), `#!${process.execPath}
const assert = require('node:assert/strict');
const fs = require('node:fs');
const args = process.argv.slice(2);
assert.deepEqual(args.slice(0, -1), ['-t', '-defaults', '-s', 'update exchange rates 0', '-s', 'autoconversion 0', '-s', 'decimal comma 0', '-m', '500', '--']);
const expression = args.at(-1);
fs.appendFileSync(process.env.ZS_CALC_TRACE, JSON.stringify(expression) + '\\n');
switch (expression) {
case '2+2': setTimeout(() => process.stdout.write('4\\n'), 400); break;
case '3+3': process.stdout.write('6'); setTimeout(() => process.stdout.write('\\n'), 80); break;
case '9/0': process.stdout.write('bad result\\n'); process.stderr.write('calculation failed\\n'); process.exitCode = 1; break;
case '8+8': process.stdout.write('16\\n'); process.exitCode = 127; break;
case '4+4': setTimeout(() => process.stdout.write('8\\n'), 3000); break;
case '5+5': process.stdout.write('10\\n'); break;
case '6+6': setTimeout(() => process.stdout.write('12\\n'), 300); break;
case 'sqrt(81)': process.stdout.write('9\\n'); break;
default: throw new Error('Unexpected calculation: ' + expression);
}
`, {mode: 0o700});
const result = spawnSync('bash', ['tests/run-qml-regression.sh', 'calculator-async.qml'], {
    cwd: root, encoding: 'utf8', timeout: 25000,
    env: {...process.env, PATH: scratch + path.delimiter + process.env.PATH, ZS_CALC_TRACE: trace}
});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
assert.equal(result.status, 0, String(result.error || 'QML regression failed'));
assert.deepEqual(fs.readFileSync(trace, 'utf8').trim().split('\n').map(JSON.parse),
    ['2+2', '3+3', '9/0', '8+8', '4+4', '5+5', '6+6', 'sqrt(81)']);
console.log('PASS exact calculator argv, async recovery, and bounded execution');
