const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const {spawnSync} = require('node:child_process');
const root=path.resolve(__dirname,'..');
const work=fs.mkdtempSync(path.join(process.env.TMPDIR,'zs-nss.'));console.log('Retained NSS scratch:',work);
const greeter=fs.readFileSync(root+'/greeter/Greeter.qml','utf8');
const lock=fs.readFileSync(root+'/shell/LockSurface.qml','utf8');
const block=source=>source.match(/    Process \{\n        id: userQuery[\s\S]*?^    \}/m)?.[0];
assert(block(greeter)&&block(lock),'Greeter and lock identity discovery must query NSS using getent');
const users='local:x:1000:1000:Local User:/home/local:/bin/sh\nremote:x:200000:200000:Remote User,room:/srv/remote:/bin/bash\nservice:x:200001:200001:Service:/srv/service:/usr/sbin/nologin\nbroken:x:1000junk:1:Bad:/bad:/bin/sh\n';
fs.writeFileSync(path.join(work,'users'),users);
fs.writeFileSync(path.join(work,'getent'),`#!${process.execPath}\nconst fs=require('node:fs'),a=process.argv.slice(2);fs.appendFileSync(process.env.ZS_TRACE,JSON.stringify(a)+'\\n');if(process.env.ZS_FAIL)process.exit(2);if(JSON.stringify(a)==='["passwd"]')process.stdout.write(fs.readFileSync(process.env.ZS_USERS));else {require('node:assert/strict').deepEqual(a,['--','passwd','-remote;$HOME']);process.stdout.write('-remote;$HOME:x:200000:1:Remote Identity:/srv/remote:/bin/bash\\n');}`,{mode:0o700});
const helper=vm.createContext({});vm.runInContext(fs.readFileSync(root+'/shell/UserAccounts.js','utf8').replace(/^\.pragma library\s*/m,''),helper);
const context=vm.createContext({UserAccounts:helper,GreeterConfig:{minUid:100000,maxUid:300000},Quickshell:{env:()=>'-remote;$HOME'},qsTr:t=>t,
    users:[],userName:'',savedUser:'',submitted:false,awaitingPrompt:false,password:{forceActiveFocus(){}},Greetd:{state:0},GreetdState:{Inactive:0}});
context.root=context;context.surface=context;
for(const name of ['pickDefaultUser','selectUser','resetAuth'])vm.runInContext(greeter.match(new RegExp('^    function '+name+'\\([^\\n]*\\) \\{[\\s\\S]*?^    \\}','m'))[0],context);
function query(source,fail=false) {
    const body=block(source);context.userQuery={output:''};
    const args=Array.from(vm.runInContext(body.match(/command: (.+)/)[1],context));
    const env={PATH:work,HOME:work,XDG_CONFIG_HOME:work,ZS_TRACE:path.join(work,'trace'),ZS_USERS:path.join(work,'users'),DBUS_SESSION_BUS_ADDRESS:'unix:path=/nonexistent/zs-test',DBUS_SYSTEM_BUS_ADDRESS:'unix:path=/nonexistent/zs-test',...(fail?{ZS_FAIL:'1'}:{})};
    const result=spawnSync(args[0],args.slice(1),{env,encoding:'utf8'});assert(!result.error);
    context.text=result.stdout;
    vm.runInContext(body.match(/onStreamFinished: (.+)/)[1],context);
    context.exitCode=result.status;
    vm.runInContext(body.match(/onExited: \(exitCode, exitStatus\) => \{([\s\S]*?)^        \}/m)[1],context);
}
query(greeter);
assert.deepEqual(Array.from(context.users,x=>x.name),['remote']);assert.equal(context.users[0].real,'Remote User');
query(greeter,true);assert.equal(context.users.length,0);assert.match(context.infoText,/Other user/);
context.selectUser('manual-unlisted');assert.equal(context.userName,'manual-unlisted','NSS failure must not block manual login');
query(lock);assert.equal(context.realName,'Remote Identity');
query(lock,true);assert.equal(context.realName,'-remote;$HOME','Failed lookup must retain a usable account label');
const config=fs.readFileSync(root+'/greeter/GreeterConfig.qml','utf8');
const expression=config.match(/property var uidRange: (.+)/)[1];
function limits(env) {
    const c=vm.createContext({UserAccounts:helper,Quickshell:{env:key=>env[key]||''}});
    return Array.from(vm.runInContext(expression,c));
}
assert.deepEqual(limits({}),[1000,60000]);
assert.deepEqual(limits({QS_GREETER_MIN_UID:'100000',QS_GREETER_MAX_UID:'300000'}),[100000,300000]);
assert.deepEqual(limits({QS_GREETER_MIN_UID:'-1',QS_GREETER_MAX_UID:'4294967295'}),[1000,60000]);
assert.deepEqual(limits({QS_GREETER_MIN_UID:'90000',QS_GREETER_MAX_UID:'60000'}),[1000,60000]);
console.log('PASS NSS remote users, UID filtering, failed discovery/manual login and argv-safe identity lookup');
