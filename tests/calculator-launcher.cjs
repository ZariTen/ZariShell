const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../shell/Overlay.qml'), 'utf8');
let launched = 0, closed = 0;
const app = {name: 'Example', comment: '', icon: '', execute() { launched++; }};
const context = vm.createContext({mode: 'launcher', apps: [app], calculator: {result: '4'},
    Quickshell: {clipboardText: ''}, ShellState: {close() {closed++;}},
    qsTr: text => text, recordLaunch() {}});
context.root = context;
for (const name of ['itemCount', 'item', 'activate']) {
    vm.runInContext(source.match(new RegExp('^    function ' + name + '\\([^]*?^    \\}', 'm'))[0], context);
}
assert.equal(context.itemCount(), 2, 'Calculator result must precede app matches');
assert.equal(context.item(0).title, '4');
assert.equal(context.item(1).title, 'Example');
context.activate(0);
assert.equal(context.Quickshell.clipboardText, '4', 'Enter copies the result');
assert.equal(launched, 0);
assert.equal(closed, 1);
context.activate(1);
assert.equal(launched, 1, 'App offset preserves launching');
context.calculator.result = '';
assert.equal(context.itemCount(), 1);
assert.equal(context.item(0).title, 'Example');
context.activate(0);
assert.equal(launched, 2);
console.log('PASS calculator result, copy activation, and application offsets');
