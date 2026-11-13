#!/usr/bin/env node
// Execute the production functions/Process callbacks without a desktop or NM bus.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { spawnSync } = require('node:child_process');

assert.ok(process.env.TMPDIR, 'Set TMPDIR to a scratch directory');
const scratch = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-wifi.'));
console.log('Scratch:', scratch);
const bin = path.join(scratch, 'bin');
fs.mkdirSync(bin);
const stateFile = path.join(scratch, 'state.json');
const traceFile = path.join(scratch, 'trace.jsonl');
fs.writeFileSync(path.join(bin, 'nmcli'), `#!${process.execPath}
const fs = require('node:fs');
const state = JSON.parse(fs.readFileSync(process.env.ZS_WIFI_STATE, 'utf8'));
const args = process.argv.slice(2);
const match = state.calls.find(call => JSON.stringify(call.args) === JSON.stringify(args));
fs.appendFileSync(process.env.ZS_WIFI_TRACE, JSON.stringify({ args, accepted: !!match }) + '\\n');
if (!match) { console.error('Unexpected nmcli invocation: ' + JSON.stringify(args)); process.exit(99); }
process.stdout.write(match.output || '');
process.exit(match.code || 0);
`, { mode: 0o700 });
const childEnv = {
    PATH: bin,
    DBUS_SYSTEM_BUS_ADDRESS: 'unix:path=' + path.join(scratch, 'no-system-bus'),
    DBUS_SESSION_BUS_ADDRESS: 'unix:path=' + path.join(scratch, 'no-session-bus'),
    ZS_WIFI_STATE: stateFile,
    ZS_WIFI_TRACE: traceFile,
    LC_ALL: 'C'
};
const source = fs.readFileSync(path.join(__dirname, '../shell/WifiPage.qml'), 'utf8');
const processes = [...source.matchAll(/^    Process \{\n([\s\S]*?)^    \}/gm)];

function harness(calls, settings = {}) {
    fs.writeFileSync(stateFile, JSON.stringify({ calls }));
    const queue = [];
    const context = vm.createContext({
        Settings: { get: (key, fallback) => settings[key] ?? fallback },
        connectGuard: { restart() {}, stop() {} },
        finishTimer: { restart() {} },
        networkChanged() {},
        Qt: { callLater: (fn, ...args) => queue.push(() => fn(...args)) }
    });
    context.page = context;
    for (const [, key, value] of source.matchAll(/^    property \w+ (\w+): (.+)$/gm))
        context[key] = vm.runInContext(value, context);
    for (const match of source.matchAll(/^    function (\w+)\([^\n]*\) \{\n[\s\S]*?^    \}/gm))
        vm.runInContext(match[0], context);
    for (const [, block] of processes) {
        const id = block.match(/id: (\w+)/)[1];
        const command = block.match(/^        command: (.+)$/m)?.[1];
        const props = {};
        for (const [, key, value] of block.matchAll(/^        property \w+ (\w+): (.+)$/gm))
            props[key] = vm.runInContext(value, context);
        context[id] = props;
        let running = false;
        Object.defineProperty(props, 'running', {
            get: () => running,
            set(value) {
                running = value;
                if (!value) return;
                context.__process = props;
                const args = props.command || vm.runInContext('(function() { with (__process) { return ' + command + '; } })()', context);
                queue.push(() => {
                    const result = spawnSync(args[0], Array.from(args).slice(1), { env: childEnv, encoding: 'utf8' });
                    assert.equal(result.error, undefined, 'fake nmcli must execute');
                    assert.notEqual(result.status, 99, result.stderr);
                    for (const stream of ['stdout', 'stderr']) {
                        const collector = block.match(new RegExp(stream + ': StdioCollector \\{\\n([\\s\\S]*?)^        \\}', 'm'))?.[1];
                        if (!collector) continue;
                        const body = collector.replace(/^\s*onStreamFinished:\s*/, '').trim();
                        context.text = result[stream];
                        context.__process = props;
                        vm.runInContext('(function() { with (__process) { ' + body + ' } })()', context);
                    }
                    running = false;
                    const exited = block.match(/^        onExited: (?:\(exitCode, exitStatus\) => )?\{\n([\s\S]*?)^        \}/m)?.[1];
                    if (exited) {
                        context.exitCode = result.status;
                        context.exitStatus = 0;
                        context.__process = props;
                        vm.runInContext('(function() { with (__process) { ' + exited + ' } })()', context);
                    }
                });
            }
        });
    }
    return {
        page: context,
        step() { assert.ok(queue.length, 'expected queued production operation'); queue.shift()(); },
        drain() {
            let count = 0;
            while (queue.length) {
                assert.ok(++count < 100, 'process loop');
                this.step();
            }
        }
    };
}

const radio = { args: ['-t', '-f', 'WIFI', 'g'], output: 'enabled\n' };
const devices = output => ({ args: ['-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'dev'], output });
const saved = { args: ['-t', '-f', 'UUID,TYPE', 'connection', 'show'], output: '' };
const scan = (device, mode = 'no', output = '*:Home:80:WPA2\n') => ({
    args: ['-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY', 'dev', 'wifi', 'list', 'ifname', device, '--rescan', mode], output
});

// A bad password must never delete an existing or newly created profile.
const failedPassword = harness([radio, devices(''), saved,
    { args: ['dev', 'wifi', 'connect', 'Renamed elsewhere', 'ifname', 'wlan1', 'password', 'bad secret'], code: 4 }
]);
failedPassword.page.profilesState = 'ready';
failedPassword.page.device = 'wlan1';
failedPassword.page.connectTo({ ssid: 'Renamed elsewhere', secured: true }, 'bad secret');
failedPassword.drain();
failedPassword.page.connectProcess.errText = 'Error: secrets were required';
failedPassword.page.finishConnect();
assert.ok(!failedPassword.page.deleteProfileProcess?.running, 'failed password must never delete a profile');
failedPassword.drain();

// Profile names are deliberately absent: identities come from UUID + actual SSID.
const uuids = [1, 2, 3].map(n => 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa' + n);
const escapedSsid = 'Cafe:West\\Guest';
const terse = text => text.replace(/\\/g, '\\\\').replace(/:/g, '\\:');
const profileList = { args: ['-t', '-f', 'UUID,TYPE', 'connection', 'show'], output: uuids.map(uuid => uuid + ':802-11-wireless\n').join('') };
const detail = (uuid, ifname, ssid = escapedSsid) => ({
    args: ['-t', '-f', 'connection.uuid,connection.interface-name,802-11-wireless.ssid', 'connection', 'show', 'uuid', uuid],
    output: 'connection.uuid:' + uuid + '\nconnection.interface-name:' + ifname + '\n802-11-wireless.ssid:' + terse(ssid) + '\n'
});
const profiles = harness([radio, devices('wlan1:wifi:disconnected:\n'), scan('wlan1'), profileList,
    detail(uuids[0], 'wlan0'), detail(uuids[1], 'wlan1'), detail(uuids[2], ''),
    { args: ['connection', 'up', 'uuid', uuids[1], 'ifname', 'wlan1'], code: 4 }
]);
const oldCache = [{ uuid: 'old', ssid: 'Old cached SSID', ifname: '' }];
profiles.page.saved = oldCache;
profiles.page.refresh(false);
let profileSteps = 0;
while (profiles.page.profileQuery?.uuid !== uuids[2]) {
    assert.ok(++profileSteps < 30, 'sequential profile discovery must finish');
    profiles.step();
}
assert.equal(profiles.page.saved, oldCache, 'publish no partial profile cache');
assert.equal(profiles.page.profilesState, 'loading');
profiles.page.connectTo({ ssid: 'Not yet known', secured: true }, 'must not be submitted');
assert.equal(profiles.page.connectProcess.running, false, 'loading is not definitely unsaved');
profiles.drain();
assert.equal(profiles.page.profilesState, 'ready');
assert.equal(profiles.page.saved.length, 3);
assert.equal(profiles.page.isSaved(escapedSsid), true, 'escaped actual SSID recognizes a renamed profile');
assert.equal(profiles.page.isSaved('Old cached SSID'), false);
profiles.page.connectTo({ ssid: escapedSsid, secured: true }, '');
profiles.drain();
assert.deepEqual(Array.from(profiles.page.connectProcess.command), ['nmcli', 'connection', 'up', 'uuid', uuids[1], 'ifname', 'wlan1']);
profiles.page.connectProcess.errText = 'Error: secrets were required';
profiles.page.finishConnect();
assert.match(profiles.page.error, /nm-connection-editor/, 'saved credential repair must name the editor');
assert.equal(profiles.page.askSsid, '', 'saved credentials must not use the new-network password flow');
profiles.drain();
profiles.page.connectTo({ ssid: escapedSsid, secured: true }, 'do not modify saved credentials');
assert.equal(profiles.page.connectProcess.running, false);
assert.match(profiles.page.error, /nm-connection-editor/);
profiles.page.device = 'wlan0';
assert.equal(profiles.page.savedProfile(escapedSsid).uuid, uuids[0], 'same SSID uses the other adapter profile');
profiles.page.device = 'wlan2';
assert.equal(profiles.page.savedProfile(escapedSsid).uuid, uuids[2], 'unbound profile is the fallback');

for (const failedCall of [
    { ...profileList, code: 10 },
    { ...detail(uuids[1], 'wlan1'), code: 10 },
    { ...detail(uuids[1], 'wlan1'), output: 'connection.uuid:wrong\n' }
]) {
    const fixture = [profileList, ...uuids.map(uuid => detail(uuid, 'wlan1'))];
    const failed = harness([failedCall, ...fixture.filter(call => JSON.stringify(call.args) !== JSON.stringify(failedCall.args))]);
    failed.page.saved = oldCache;
    failed.page.device = 'wlan1';
    failed.page.refreshProfiles();
    failed.drain();
    assert.equal(failed.page.profilesState, 'failed', 'failed or malformed metadata cannot mean unsaved');
    assert.equal(failed.page.saved, oldCache, 'failed refresh preserves the last complete cache');
    failed.page.activate({ ssid: 'Unknown secure SSID', secured: true });
    assert.equal(failed.page.askSsid, '');
    failed.page.connectTo({ ssid: 'Unknown open SSID' }, '');
    failed.drain(); // No mutation is allowlisted, even for an open SSID.
    assert.match(failed.page.error, /Couldn't load saved/);
}

const otherAdapter = harness([]);
otherAdapter.page.profilesState = 'ready';
otherAdapter.page.device = 'wlan1';
otherAdapter.page.saved = [{ uuid: uuids[0], ifname: 'wlan0', ssid: escapedSsid }];
otherAdapter.page.activate({ ssid: escapedSsid, secured: true });
otherAdapter.page.connectTo({ ssid: escapedSsid, secured: true }, 'must not create another profile');
otherAdapter.drain();
assert.match(otherAdapter.page.error, /nm-connection-editor/);
assert.equal(otherAdapter.page.askSsid, '', 'a profile bound elsewhere is not a new SSID');

// An old adapter's connection completion must not alter the newly selected page.
const staleConnect = harness([{ args: ['dev', 'wifi', 'connect', 'Old adapter SSID', 'ifname', 'wlan0', 'password', 'old secret'], code: 4 }]);
staleConnect.page.profilesState = 'ready';
staleConnect.page.parseDevices('wlan0:wifi:disconnected:\n');
staleConnect.page.connectTo({ ssid: 'Old adapter SSID', secured: true }, 'old secret');
staleConnect.page.parseDevices('wlan1:wifi:disconnected:\n');
staleConnect.page.error = 'Current adapter notice';
staleConnect.page.askSsid = 'Current adapter SSID';
staleConnect.page.connecting = 'Current pending state';
const currentHeld = [{ ssid: 'Current adapter SSID' }];
staleConnect.page.held = currentHeld;
staleConnect.step();
staleConnect.page.connectProcess.errText = 'Error: secrets were required';
staleConnect.page.finishConnect();
assert.equal(staleConnect.page.error, 'Current adapter notice', 'stale connection error must not leak across adapters');
assert.equal(staleConnect.page.askSsid, 'Current adapter SSID');
assert.equal(staleConnect.page.connecting, 'Current pending state');
assert.equal(staleConnect.page.held, currentHeld);
staleConnect.drain(); // No refresh or other old-adapter effect is allowlisted.

// A connected second adapter must own the displayed results and both actions.
const h = harness([
    radio, devices('wlan0:wifi:disconnected:\nwlan1:wifi:connected:Home\n'), saved, scan('wlan1'),
    { args: ['dev', 'wifi', 'connect', 'Cafe', 'ifname', 'wlan1'], output: '' },
    { args: ['dev', 'disconnect', 'wlan1'], output: '' }
]);
h.page.refresh(false);
h.step();
assert.equal(h.page.listQuery.running, false, 'cached scan must wait for adapter discovery');
h.drain();
assert.equal(h.page.device, 'wlan1', 'prefer the connected usable Wi-Fi adapter');
assert.equal(h.page.activeSsid, 'Home');
h.page.connectTo({ ssid: 'Cafe' }, '');
h.drain();
h.page.disconnect();
h.drain();
assert.equal(h.page.error, '');
const actionTrace = fs.readFileSync(traceFile, 'utf8').trim().split('\n').map(JSON.parse);
assert.ok(actionTrace.some(call => JSON.stringify(call.args) === JSON.stringify(['dev', 'wifi', 'connect', 'Cafe', 'ifname', 'wlan1'])), 'connect must run on the selected adapter');
assert.ok(actionTrace.some(call => JSON.stringify(call.args) === JSON.stringify(['dev', 'disconnect', 'wlan1'])), 'disconnect must run on the selected adapter');

// Hot-unplug/reselection while a scan is in flight must not publish old rows.
const changed = harness([scan('wlan0', 'no', '*:Old:90:WPA2\n'), scan('wlan1', 'no', '*:New:70:WPA2\n')]);
changed.page.radioOn = true;
changed.page.parseDevices('wlan0:wifi:disconnected:\n');
changed.page.networks = [{ ssid: 'Old' }];
changed.page.held = [{ ssid: 'Old held' }];
changed.page.askSsid = 'Old';
changed.page.activeSsid = 'Old';
changed.page.activeSignal = 90;
changed.page.error = 'old error';
changed.page.parseDevices('wlan1:wifi:connected:New\n');
assert.equal(changed.page.networks.length, 0, 'adapter change clears stale rows');
assert.equal(changed.page.held, null, 'adapter change discards held password rows');
assert.equal(changed.page.askSsid, '');
assert.equal(changed.page.activeSsid, '');
assert.equal(changed.page.activeSignal, 0);
assert.equal(changed.page.error, '');
changed.step();
assert.equal(changed.page.networks.length, 0, 'stale scan must not publish old rows');
changed.drain();
assert.equal(changed.page.activeSsid, 'New', 'scan the newly selected adapter after old scan exits');
changed.page.connecting = 'New';
changed.page.parseDevices('eth0:ethernet:connected:Wired\\: office\n');
assert.equal(changed.page.device, '');
assert.equal(changed.page.networks.length, 0);
assert.equal(changed.page.activeSsid, '');
assert.equal(changed.page.connecting, '');
assert.equal(changed.page.wired, 'Wired: office');
changed.page.scan('yes');
changed.page.connectTo({ ssid: 'Must not connect' }, 'secret');
changed.page.disconnect();
changed.drain(); // The allowlist deliberately contains no device-less actions.

// Discovery order is not policy; preserve an equally suitable current adapter.
const selection = harness([]);
selection.page.parseDevices('wlan9:wifi:disconnected:\nwlan2:wifi:disconnected:\n');
assert.equal(selection.page.device, 'wlan2', 'initial fallback is deterministic');
selection.page.parseDevices('wlan0:wifi:disconnected:\nwlan2:wifi:disconnected:\n');
assert.equal(selection.page.device, 'wlan2', 'retain a usable current fallback');
selection.page.parseDevices('wlan0:wifi:connected:Home\nwlan2:wifi:disconnected:\n');
assert.equal(selection.page.device, 'wlan0', 'connected adapter wins over current fallback');
for (const preferred of ['wlan2', 'missing', 'eth0', 'wlan9']) {
    const overridden = harness([], { wifiDevice: preferred });
    overridden.page.parseDevices('wlan2:wifi:disconnected:\nwlan0:wifi:connected:Home\nwlan9:wifi:unavailable:\neth0:ethernet:connected:Wired\n');
    assert.equal(overridden.page.device, preferred === 'wlan2' ? 'wlan2' : 'wlan0', 'override must be a discovered usable Wi-Fi interface');
}

// A disappearing and reappearing adapter must not revive its earlier scan.
const returned = harness([scan('wlan0', 'no', '*:Obsolete:90:WPA2\n')]);
returned.page.radioOn = true;
returned.page.parseDevices('wlan0:wifi:disconnected:\n');
returned.page.parseDevices('');
returned.page.parseDevices('wlan0:wifi:disconnected:\n');
returned.step();
assert.equal(returned.page.networks.length, 0, 'same interface name does not validate an earlier generation');
returned.drain();
assert.equal(returned.page.activeSsid, 'Obsolete', 'replacement scan is accepted');

const fresh = harness([radio, devices('wlan1:wifi:connected:Home\n'), saved, scan('wlan1'), scan('wlan1', 'auto')]);
fresh.page.refresh(true);
fresh.drain();
assert.equal(fresh.page.wantRescan, false);
assert.equal(fresh.page.scanning, false);

const trace = fs.readFileSync(traceFile, 'utf8').trim().split('\n').map(JSON.parse);
assert.ok(trace.length > 0 && trace.every(call => call.accepted), 'every nmcli call must be explicitly allowed');
assert.ok(trace.every(call => !call.args.includes('delete')), 'no password failure may delete profiles');
console.log('PASS Wi-Fi adapter consistency and saved-profile regression tests');
