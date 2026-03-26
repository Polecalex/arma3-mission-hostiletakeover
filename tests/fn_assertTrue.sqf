params ["_condition", ["_message", "Assertion failed"]];

if (!(_condition)) exitWith {
    throw _message;
};

true;
