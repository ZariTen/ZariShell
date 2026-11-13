const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(__dirname + '/../shell/Notifs.qml', 'utf8');
const messages = [];
const context = vm.createContext({qsTr: text => { messages.push(text); return 'translated ' + text; }});
vm.runInContext('String.prototype.arg = function(value) { return this.replace(/%1/g, value); };', context);
for (const name of ['relativeTime', 'appLabel'])
    vm.runInContext(source.match(new RegExp('^    function ' + name + '\\([^\\n]*\\) \\{[\\s\\S]*?^    \\}', 'm'))[0], context);
assert.equal(context.relativeTime(0, 300000), 'translated 5m ago', 'Dynamic count must be substituted into an extractable message');
assert(messages.includes('%1m ago'), 'Translator must receive the whole message, not an English suffix');
assert.equal(context.appLabel({appName: 'User-provided app name'}), 'User-provided app name', 'Never translate application content');
assert.equal(context.appLabel({appName: ''}), 'translated System');
console.log('PASS translation-ready messages, placeholders, and untouched application names');
