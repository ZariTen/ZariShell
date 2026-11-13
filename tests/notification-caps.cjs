const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync(__dirname + '/../shell/Notifs.qml', 'utf8');
const context = vm.createContext({history: [], popups: [], times: {}, unread: 0, dnd: false,
    Theme: {notificationHistoryLimit: 2, notificationPopupLimit: 1}, NotificationUrgency: {Critical: 2}, ShellState: {panel: ''}});
context.root = context;
for (const f of source.matchAll(/^    function \w+\([^\n]*\) \{[\s\S]*?^    \}/gm)) vm.runInContext(f[0], context);
const receive = source.match(/onNotification: notification => \{([\s\S]*?)^        \}/m)[1];
for (let id = 0; id < 4; id++) {
    context.notification = {id, urgency: 1, closed: {connect() {}}};
    vm.runInContext(receive, context);
}
assert.equal(context.history.length, 2, 'History must honor configured cap');
assert.equal(context.popups.length, 1, 'Popups must honor configured cap');
context.Theme.notificationPopupLimit = 0;
context.notification = {id: 5, urgency: 2, closed: {connect() {}}};
vm.runInContext(receive, context);
assert.equal(context.popups.length, 0, 'Zero popup cap must disable popups, including critical');
console.log('PASS notification caps using production callbacks and fake notification objects');
