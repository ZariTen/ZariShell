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
function sessions(exec) {
    context.text = '/fixture.desktop\tName=Fixture\n/fixture.desktop\tExec=' + exec + '\n';
    context.root = {pickDefaultSession() {}};
    vm.runInContext(collector, context);
    return JSON.parse(JSON.stringify(context.root.sessions));
}
assert.deepEqual(sessions('"/session dir/start" "two words" escaped\\ value %% %f %F %u %U %i %c %k %d %D %n %N %v %m')[0].exec,
    ['/session dir/start', 'two words', 'escaped value', '%']);
assert.deepEqual(sessions(String.raw`start "a\\\\b" "quote\\"here" "dollar\\$HOME" ""`)[0].exec,
    ['start', 'a\\b', 'quote"here', 'dollar$HOME', '']);
for (const command of ['start "unterminated', 'start trailing\\', 'start %Z', '%f', '"" arg', 'start %'])
    assert.deepEqual(sessions(command), [], 'Malformed desktop entry must be skipped: ' + command);
assert.deepEqual(fallback('start $HOME ~ ; $(id) `id`'), ['start', '$HOME', '~', ';', '$(id)', '`id`']);
console.log('PASS greeter quoted commands, desktop field codes, and malformed input');
