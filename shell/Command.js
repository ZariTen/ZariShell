.pragma library

// Argument vectors only: no shell expansion or execution. Invalid input is inert.
function parse(command, desktop, metadata) {
    if (typeof command !== "string" || /[\x00-\x1f\x7f]/.test(command))
        return [];
    if (desktop) {
        // Desktop Entry string escaping precedes Exec quoting (a literal
        // backslash inside double quotes consequently needs four backslashes).
        command = command.replace(/\\([sntr\\])/g, function(match, ch) {
            return ch === "s" ? " " : ch === "n" ? "\n" : ch === "t" ? "\t" : ch === "r" ? "\r" : ch === "\\" ? "\\" : match;
        });
        if (/[\x00-\x1f\x7f]/.test(command))
            return [];
    }
    var args = [];
    var token = "";
    var started = false;
    var quote = "";
    for (var i = 0; i < command.length; i++) {
        var ch = command[i];
        if (ch === "\\" && quote !== "'") {
            if (++i === command.length)
                return [];
            var next = command[i];
            if (quote === '"' && '\\"$`'.indexOf(next) < 0)
                token += "\\";
            token += next;
            started = true;
        } else if (quote !== "") {
            if (ch === quote)
                quote = "";
            else
                token += ch;
        } else if (ch === '"' || (!desktop && ch === "'")) {
            quote = ch;
            started = true;
        } else if (ch === " ") {
            if (started) {
                args.push(token);
                token = "";
                started = false;
            }
        } else {
            token += ch;
            started = true;
        }
    }
    if (quote !== "")
        return [];
    if (started)
        args.push(token);
    if (args.length === 0 || args[0] === "")
        return [];
    if (!desktop)
        return args;

    var info = metadata || {};
    var expanded = [];
    for (var a = 0; a < args.length; a++) {
        if (args[a] === "%i") {
            if (a === 0)
                return [];
            if (info.icon)
                expanded.push("--icon", info.icon);
            continue;
        }
        var value = "";
        var removed = false;
        for (var c = 0; c < args[a].length; c++) {
            if (args[a][c] !== "%") {
                value += args[a][c];
                continue;
            }
            var code = args[a][++c];
            if (code === "%")
                value += "%";
            else if (code === "c" || code === "k") {
                if (a === 0)
                    return [];
                value += (code === "c" ? info.name : info.path) || "";
            } else if (code && "fFuUdDnNvm".indexOf(code) >= 0) {
                if (a === 0)
                    return [];
                removed = true;
            } else {
                return [];
            }
        }
        if (value !== "" || !removed)
            expanded.push(value);
    }
    return expanded;
}
