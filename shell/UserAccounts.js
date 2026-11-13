.pragma library

function entries(text) {
    var found = [];
    var seen = Object.create(null);
    text.split("\n").forEach(function(line) {
        var fields = line.split(":");
        if (fields.length < 7 || fields[0] === "" || !/^\d+$/.test(fields[2]))
            return;
        var uid = Number(fields[2]);
        if (uid > 4294967294 || seen[fields[0]])
            return;
        seen[fields[0]] = true;
        found.push({name: fields[0], real: fields[4].split(",")[0] || fields[0], home: fields[5], uid: uid, shell: fields[6]});
    });
    return found;
}

function loginUsers(text, minimum, maximum) {
    return entries(text).filter(user => user.uid >= minimum && user.uid <= maximum
        && user.shell !== "" && !/(^|\/)(nologin|false)$/.test(user.shell));
}

function realName(text, name) {
    var user = entries(text).find(entry => entry.name === name);
    return user ? user.real : name;
}

function uidRange(minimum, maximum) {
    function uid(value, fallback) {
        return /^\d+$/.test(value || "") && Number(value) <= 4294967294 ? Number(value) : fallback;
    }
    var low = uid(minimum, 1000), high = uid(maximum, 60000);
    return low <= high ? [low, high] : [1000, 60000];
}
