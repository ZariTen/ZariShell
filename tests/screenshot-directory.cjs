const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const root = fs.mkdtempSync(path.join(process.env.TMPDIR, 'zs-screenshot.'));
console.log('Retained screenshot scratch:', root);
const bin = path.join(root, 'bin'); fs.mkdirSync(bin);
for (const command of ['mkdir', 'awk', 'basename']) {
    const location = spawnSync('/bin/sh', ['-c', 'command -v "$1"', 'sh', command], {encoding:'utf8'}).stdout.trim();
    fs.symlinkSync(location, path.join(bin, command));
}
for (const name of ['hyprpicker','slurp','grim','wl-copy','notify-send','sleep','date','probe']) {
    fs.writeFileSync(path.join(bin,name), `#!${process.execPath}\nconst fs=require('node:fs'); const a=process.argv.slice(2); fs.appendFileSync(process.env.ZS_TRACE,JSON.stringify({name:'${name}',args:a})+'\\n');` +
        ({hyprpicker:'setInterval(()=>{},1000);', slurp:'console.log("1,2 3x4");',grim:'fs.writeFileSync(a.at(-1),Buffer.from([0,255,1]));',
        'wl-copy':'process.stdin.resume();',date:'console.log("fixture");',probe:'process.exit(90);'}[name] || ''),{mode:0o700});
}
for (const mode of ['override','environment','userdirs','untrusted','fallback']) {
    const work=path.join(root,mode);fs.mkdirSync(work);fs.mkdirSync(path.join(work,'config'));
    const env={PATH:bin,HOME:work,XDG_CONFIG_HOME:path.join(work,'config'),ZS_TRACE:path.join(work,'trace'),DBUS_SESSION_BUS_ADDRESS:'unix:path=/nonexistent/zs-test',DBUS_SYSTEM_BUS_ADDRESS:'unix:path=/nonexistent/zs-test'};
    let expected=path.join(work,'Pictures/Screenshots');
    if(mode==='override') env.ZARISHELL_SCREENSHOT_DIR=expected=path.join(work,'chosen ; $HOME');
    if(mode==='environment') { env.XDG_PICTURES_DIR=path.join(work,'Pictures translated'); expected=env.XDG_PICTURES_DIR+'/Screenshots'; }
    if(mode==='userdirs'||mode==='untrusted') {
        const folder=mode==='userdirs'?'Localized pictures':'Pics $(probe)';
        fs.writeFileSync(path.join(work,'config/user-dirs.dirs'),'XDG_PICTURES_DIR="$HOME/'+folder+'"\n');
        expected=path.join(work,folder,'Screenshots');
    }
    const script=path.join(work,'capture.sh');fs.copyFileSync(__dirname+'/../nix/scripts/screenshot-region.sh',script);
    const result=spawnSync('/bin/sh',['-eu',script],{env,encoding:'utf8'});
    assert.equal(result.status,0,result.stderr);
    const calls=fs.readFileSync(env.ZS_TRACE,'utf8').trim().split('\n').map(JSON.parse);
    assert.equal(calls.find(c=>c.name==='grim').args.at(-1),expected+'/Screenshot_fixture.png',mode);
    assert(!calls.some(c=>c.name==='probe'),'User-dirs must never be sourced or expanded as shell code');
}
console.log('PASS screenshot directory override, XDG Pictures, fallback and inert user-dirs');
