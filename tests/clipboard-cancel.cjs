const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const assert = require('node:assert/strict');
const work = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-clip-cancel.'));
const trace = path.join(work, 'trace');
for (const name of ['cliphist', 'wl-copy']) {
    fs.writeFileSync(path.join(work, name), `#!${process.execPath}\nconst fs=require('node:fs');const args=process.argv.slice(2);` +
        (name === 'cliphist' ? `require('node:assert/strict').equal(args[0],'decode');fs.appendFileSync(process.env.ZS_TRACE,'decode '+args[1]+'\\n');process.stdout.write(Buffer.from([0,255,Number(args[1])]));` :
        `require('node:assert/strict').deepEqual(args,['--foreground']);const parts=[];process.stdin.on('data',b=>parts.push(b));process.stdin.on('end',()=>{const data=Buffer.concat(parts).toString('hex');fs.appendFileSync(process.env.ZS_TRACE,'started '+data+'\\n');if(process.env.ZS_PASTE_REPLACEMENT==='1'){setInterval(()=>{},1000);process.on('SIGTERM',()=>setTimeout(()=>{fs.appendFileSync(process.env.ZS_TRACE,'stopped '+data+'\\n');process.exit(0);},200));}else setTimeout(()=>{fs.appendFileSync(process.env.ZS_TRACE,'completed '+data+'\\n');},600);});`), {mode:0o700});
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
const replacementTrace = path.join(work, 'replacement-trace');
const replacement = spawnSync('bash', ['tests/run-qml-regression.sh', 'clipboard-cancel.qml'], {cwd:path.resolve(__dirname,'..'),encoding:'utf8',env:{...process.env,
    PATH:work+':'+process.env.PATH,ZS_TRACE:replacementTrace,ZS_PASTE_REPLACEMENT:'1',DBUS_SESSION_BUS_ADDRESS:'unix:path=/nonexistent/zs-test',DBUS_SYSTEM_BUS_ADDRESS:'unix:path=/nonexistent/zs-test'}});
console.log(replacement.stdout + replacement.stderr);
assert.equal(replacement.status,0);
const owners = fs.readFileSync(replacementTrace,'utf8');
assert(owners.includes('started 00ff2a'), 'First foreground owner must stay alive');
assert(owners.includes('started 00ff2c'), 'Rapid 42/43/44 selections must start the latest owner');
assert(!owners.includes('decode 43'), 'Superseded pending selection must not start');
assert(owners.indexOf('stopped 00ff2a') < owners.indexOf('decode 44'), 'Replacement must wait for the old supervisor and owner to exit');
assert(!owners.includes('decode 45'), 'Disabling must discard pending selection even after re-enabling');
assert(owners.includes('stopped 00ff2c'), 'Disabling must stop the replacement owner');
console.log('PASS latest clipboard owner replacement and pending cancellation');
