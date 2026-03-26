params ["_actual", "_expected", ["_message", "Values are not equal"]];

if !(_actual isEqualTo _expected) exitWith {
    throw format ["%1 | expected=%2 actual=%3", _message, _expected, _actual];
};

true;
