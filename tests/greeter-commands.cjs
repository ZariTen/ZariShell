const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const base = path.resolve(__dirname, '..');
const helper = path.join(base, 'shell/Command.js');
const context = vm.createContext({Command: vm.createContext({})});
if (fs.existsSync(helper)) vm.runInContext(fs.readFileSync(helper, 'utf8').replace(/^\.pragma library\s*/m, ''), context.Command);
const config = fs.readFileSync(path.join(base, 'greeter/GreeterConfig.qml'), 'utf8');
const expression = config.match(/property var sessionCommand: (.+)/)[1];
function fallback(command) {
    context.Quickshell = {env: () => command};
    return Array.from(vm.runInContext(expression, context));
}
assert.deepEqual(fallback('"/session dir/start" --label "two words" escaped\\ value'), ['/session dir/start', '--label', 'two words', 'escaped value']);
assert.deepEqual(fallback("start 'single quoted' \"\" '$HOME;$(id)'"), ['start', 'single quoted', '', '$HOME;$(id)']);
assert.deepEqual(fallback('start "unfinished'), [], 'Malformed fallback must not become a launchable command');
const source = fs.readFileSync(path.join(base, 'greeter/Greeter.qml'), 'utf8');
const collector = source.slice(source.indexOf('// Wayland sessions')).match(/onStreamFinished: \{([\s\S]*?)^            \}/m)[1];
function sessions(exec, metadata = {}) {
    const file = metadata.path || '/fixture.desktop';
    context.text = file + '\tName=' + (metadata.name || 'Fixture') + '\n' + file + '\tIcon=' + (metadata.icon || '') + '\n' + file + '\tExec=' + exec + '\n';
    context.root = {pickDefaultSession() {}};
    vm.runInContext(collector, context);
    return JSON.parse(JSON.stringify(context.root.sessions));
}
assert.deepEqual(sessions('"/session dir/start" "two words" escaped\\ value %% %f %F %u %U %i %c %k %d %D %n %N %v %m')[0].exec,
    ['/session dir/start', 'two words', 'escaped value', '%', 'Fixture', '/fixture.desktop']);
const metadata = {name: 'Name "quoted" $(id)', path: '/session dir/quoted.desktop', icon: 'icon with spaces;$HOME'};
assert.deepEqual(sessions('start "%c" --desktop=%k %i %%', metadata)[0].exec,
    ['start', metadata.name, '--desktop=' + metadata.path, '--icon', metadata.icon, '%']);
assert.deepEqual(sessions('start prefix%i', metadata), [], 'Multi-argument icon code cannot be embedded');
assert.deepEqual(sessions(String.raw`start "a\\\\b" "quote\\"here" "dollar\\$HOME" ""`)[0].exec,
    ['start', 'a\\b', 'quote"here', 'dollar$HOME', '']);
for (const command of ['start "unterminated', 'start trailing\\', 'start %Z', '%f', '"" arg', 'start %'])
    assert.deepEqual(sessions(command), [], 'Malformed desktop entry must be skipped: ' + command);
assert.deepEqual(fallback('start $HOME ~ ; $(id) `id`'), ['start', '$HOME', '~', ';', '$(id)', '`id`']);
const {spawnSync} = require('node:child_process');
const work = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-session-metadata.'));
console.log('Retained session metadata scratch:', work);
const discovery = path.join(work, 'discover.sh');
fs.copyFileSync(path.join(base, 'shell/scripts/greeter-sessions.sh'), discovery);
const desktop = path.join(work, 'fixture.desktop');
function discovered(name, icon) {
    fs.writeFileSync(desktop, '[Desktop Entry]\nName=' + name + '\nIcon=' + icon + '\nExec=start %c %i %k\n');
    const result = spawnSync('/bin/sh', [discovery, work], {encoding:'utf8',env:{PATH:work,HOME:work,XDG_CONFIG_HOME:work,
        DBUS_SESSION_BUS_ADDRESS:'unix:path=/nonexistent/zs-test',DBUS_SYSTEM_BUS_ADDRESS:'unix:path=/nonexistent/zs-test'}});
    assert.equal(result.status,0,result.stderr);
    context.text = result.stdout;
    context.root = {pickDefaultSession() {}};
    vm.runInContext(collector, context);
    return JSON.parse(JSON.stringify(context.root.sessions));
}
const decodedName = String.raw`Fancy Session\s ; $(probe)`;
assert.deepEqual(discovered(String.raw`Fancy\sSession\\s ; $(probe)`, String.raw`/fixture/icons/Fancy\sSession.svg`),
    [{name:decodedName,exec:['start',decodedName,'--icon','/fixture/icons/Fancy Session.svg',desktop]}], 'Discovery must decode metadata exactly once for display and argv');
assert.deepEqual(discovered(String.raw`Line\nTab\tCarriage\rEnd`, ''),
    [{name:'Line\nTab\tCarriage\rEnd',exec:['start','Line\nTab\tCarriage\rEnd',desktop]}], 'Standard string escapes must remain valid argv data');
assert.deepEqual(discovered('Trailing' + '\\', ''), [], 'Incomplete escapes must skip the entry');
assert.deepEqual(discovered(String.raw`Bad\qName`, ''), [], 'Unknown Name escapes must skip the entry');
assert.deepEqual(discovered('Valid', String.raw`bad\qIcon`), [], 'Unknown Icon escapes must skip the entry');
console.log('PASS greeter quoted commands, decoded desktop metadata, and malformed input');
