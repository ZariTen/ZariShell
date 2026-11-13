const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const assert = require('node:assert/strict');
const work = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-clip-cancel.'));
const trace = path.join(work, 'trace');
for (const name of ['cliphist', 'wl-copy']) {
    fs.writeFileSync(path.join(work, name), `#!${process.execPath}\nconst fs=require('node:fs');const args=process.argv.slice(2);` +
        (name === 'cliphist' ? `require('node:assert/strict').equal(args[0],'decode');process.stdout.write(Buffer.from([0,255,Number(args[1])]));` :
        `const parts=[];process.stdin.on('data',b=>parts.push(b));process.stdin.on('end',()=>{const data=Buffer.concat(parts);fs.appendFileSync(process.env.ZS_TRACE,'started '+data.toString('hex')+'\\n');setTimeout(()=>{fs.appendFileSync(process.env.ZS_TRACE,'completed '+data.toString('hex')+'\\n');},600);});`), {mode:0o700});
}
const result = spawnSync('bash', ['tests/run-qml-regression.sh', 'clipboard-cancel.qml'], {cwd:path.resolve(__dirname,'..'),encoding:'utf8',env:{...process.env,
    PATH:work+':'+process.env.PATH,ZS_TRACE:trace,DBUS_SESSION_BUS_ADDRESS:'unix:path=/nonexistent/zs-test',DBUS_SYSTEM_BUS_ADDRESS:'unix:path=/nonexistent/zs-test'}});
console.log('Retained cancellation scratch: '+work+'\n'+result.stdout+result.stderr);
assert.equal(result.status,0);
const events=fs.readFileSync(trace,'utf8');
assert(events.includes('started 00ff2a'), 'First copy must actually be in flight');
assert(!events.includes('completed 00ff2a'), 'Disabled in-flight copy must not complete in an orphan child');
assert(events.includes('completed 00ff2b'), 'Enabled copy must preserve binary NUL and non-UTF8 bytes');
console.log('PASS supervised in-flight cancellation and binary clipboard bytes');
