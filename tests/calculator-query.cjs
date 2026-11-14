const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const file = path.join(__dirname, '../shell/CalculatorQuery.js');
const context = vm.createContext({});
if (fs.existsSync(file)) vm.runInContext(fs.readFileSync(file, 'utf8').replace(/^\.pragma library\s*/m, ''), context);
assert.equal(typeof context.expression, 'function', 'Launcher needs a calculator query classifier');
for (const [query, expected] of [['2 + 2', '2 + 2'], ['(3*4)/2', '(3*4)/2'], ['-2^3', '-2^3'], ['= sqrt(81)', 'sqrt(81)'], ['= -sqrt(81)', '-sqrt(81)'], ['= -pi', '-pi'], ['= 10 km to mi', '10 km to mi'], ['Firefox', ''], ['7zip', ''], ['org.gnome.Calculator', ''], ['foo-bar', ''], ['2', ''], ['', ''], ['=', ''], ['= --help', ''], ['2; touch /tmp/unsafe', ''], ['2+', ''], ['(2*3', ''], ['= sqrt(', ''], ['2**3', '']]) {
    assert.equal(context.expression(query), expected, query);
}
console.log('PASS calculator query detection preserves application searches');
