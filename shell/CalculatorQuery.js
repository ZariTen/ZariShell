.pragma library

function expression(query) {
    var text = query.trim();
    var candidate = text.charAt(0) === "=" ? text.slice(1).trim() : text;
    if (candidate.length > 1024 || /[+*/^\-]$|\*\*/.test(candidate))
        return "";
    var depth = 0;
    for (var i = 0; i < candidate.length; i++) {
        if (candidate.charAt(i) === "(") depth++;
        if (candidate.charAt(i) === ")") depth--;
        if (depth < 0) return "";
    }
    if (depth !== 0)
        return "";
    if (text.charAt(0) === "=") {
        text = text.slice(1).trim();
        if (text === "" || (text.charAt(0) === "-" && !/^-\s*(?:\d|\(|\.|[a-zA-Z_])/.test(text)))
            return "";
        return text;
    }
    return /\d/.test(text) && /^[\d\s.+\-*/%^()]+$/.test(text)
        && /[+*/%^]|\d\s*-|^-|[()]/.test(text) ? text : "";
}
