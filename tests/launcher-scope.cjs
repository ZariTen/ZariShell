const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const {spawnSync} = require('node:child_process');
const base = path.resolve(__dirname, '..');
const scratch = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-launcher.'));
console.log('Retained launcher scratch:', scratch);
fs.cpSync(path.join(base, 'shell'), path.join(scratch, 'shell'), {recursive: true, dereference: true});
fs.mkdirSync(path.join(scratch, 'config'));
const overlay = fs.readFileSync(path.join(base, 'shell/Overlay.qml'), 'utf8');
const activate = overlay.match(/^    function activate\(index\) \{[\s\S]*?^    \}/m)[0];
for (const [mode, systemd, manager, appCode, scoped] of [
    ['auto', false, false, 0, false], ['auto', true, false, 0, false],
    ['auto', true, true, 0, true], ['auto', true, true, 7, true],
    ['false', true, true, 0, false], ['true', true, true, 0, true]
]) {
    const work = fs.mkdtempSync(path.join(scratch, 'case.'));
    const trace = path.join(work, 'trace');
    function fake(name, body) {
        fs.writeFileSync(path.join(work, name), `#!${process.execPath}\nconst fs = require('node:fs');\nconst args = process.argv.slice(2);\nfs.appendFileSync(process.env.ZS_TRACE, JSON.stringify({name:'${name}',args})+'\\n');\n${body}\n`, {mode: 0o700});
    }
    fake('app', `process.exit(${appCode});`);
    if (systemd) fake('systemd-run', `const assert = require('node:assert/strict'); assert.deepEqual(args.slice(0,6), ['--user','--scope','--collect','--quiet','--','app']); const r = require('node:child_process').spawnSync('app',args.slice(6),{env:process.env}); process.exit(r.status);`);
    fake('systemctl', `require('node:assert/strict').deepEqual(args,['--user','show-environment']); process.exit(${manager ? 0 : 1});`);
    let launch;
    const app = {command: ['app', 'two words', '$HOME;$(id)'], workingDirectory: work};
    const context = vm.createContext({mode: 'launcher', apps: [app], calculator: {result: ''}, itemCount: () => 1,
        Theme: {useSystemdScope: mode}, Quickshell: {shellDir: path.join(scratch, 'shell'), execDetached: spec => launch = spec},
        ShellState: {close() {}}, recordLaunch() {}});
    context.root = context;
    vm.runInContext(activate, context);
    context.activate(0);
    assert.equal(launch.workingDirectory, work);
    const command = Array.from(launch.command);
    // Only the interpreter is resolved outside the child fake-only PATH.
    const result = spawnSync(command[0] === 'sh' ? '/bin/sh' : command[0], command.slice(1), {cwd: work, encoding: 'utf8',
        env: {PATH: work, XDG_CONFIG_HOME: path.join(scratch, 'config'), ZS_TRACE: trace, DBUS_SESSION_BUS_ADDRESS: 'unix:path=/nonexistent/zs-test', DBUS_SYSTEM_BUS_ADDRESS: 'unix:path=/nonexistent/zs-test'}});
    assert.equal(result.status, appCode, result.stderr || String(result.error));
    const calls = fs.readFileSync(trace, 'utf8').trim().split('\n').map(JSON.parse);
    assert.equal(calls.filter(x => x.name === 'app').length, 1, 'Never retry after an application fails');
    assert.equal(calls.filter(x => x.name === 'systemd-run').length, Number(scoped), `${mode}: scope availability`);
    assert.deepEqual(calls.find(x => x.name === 'app').args, ['two words', '$HOME;$(id)']);
}
console.log('PASS launcher auto detection, opt-out, argv/cwd, and single launch on failure');
