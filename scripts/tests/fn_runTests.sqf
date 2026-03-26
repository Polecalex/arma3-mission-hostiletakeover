params [["_copyToClipboard", true], ["_showHint", true]];

if (hasInterface) then {
    systemChat "[TEST] Starting test suite...";
};

private _tests = [
    ["getSquadComposition", { call compile preprocessFileLineNumbers "scripts\\tests\\suites\\fn_test_getSquadComposition.sqf" }],
    ["createSquad", { call compile preprocessFileLineNumbers "scripts\\tests\\suites\\fn_test_createSquad.sqf" }],
    ["unitCapEnforcement", { call compile preprocessFileLineNumbers "scripts\\tests\\suites\\fn_test_unitCapEnforcement.sqf" }]
];

private _results = [];
private _passed = 0;
private _failed = 0;

{
    _x params ["_name", "_fn"];
    private _ok = true;
    private _error = "";

    try {
        call _fn;
    } catch {
        _ok = false;
        _error = _exception;
    };

    if (_ok) then {
        _passed = _passed + 1;
        systemChat format ["[TEST PASS] %1", _name];
    } else {
        _failed = _failed + 1;
        systemChat format ["[TEST FAIL] %1 | %2", _name, _error];
    };

    _results pushBack [_name, _ok, _error];
} forEach _tests;

systemChat format ["[TEST SUMMARY] Passed: %1 Failed: %2", _passed, _failed];

private _reportLines = [
    "# HostileTakeover Test Report",
    format ["Generated: %1", systemTime],
    "",
    format ["Summary: %1 passed, %2 failed", _passed, _failed],
    "",
    "| Test | Result | Details |",
    "|---|---|---|"
];

{
    _x params ["_name", "_ok", "_error"];

    private _status = if (_ok) then {"PASS"} else {"FAIL"};
    private _details = if (_ok) then {"-"} else {_error};
    _details = (_details splitString "|") joinString "/";

    _reportLines pushBack format ["| %1 | %2 | %3 |", _name, _status, _details];
} forEach _results;

private _report = _reportLines joinString toString [10];

missionNamespace setVariable ["HT_TEST_RESULTS", _results, true];
missionNamespace setVariable ["HT_TEST_PASSED", _passed, true];
missionNamespace setVariable ["HT_TEST_FAILED", _failed, true];
missionNamespace setVariable ["HT_TEST_REPORT", _report, true];

if (hasInterface && _copyToClipboard) then {
    copyToClipboard _report;
    profileNamespace setVariable ["HT_TEST_REPORT_LAST", _report];
    saveProfileNamespace;
    systemChat "[TEST] Report copied to clipboard and saved in profileNamespace as HT_TEST_REPORT_LAST.";
};

if (hasInterface && _showHint) then {
    hintSilent format [
        "Test run complete\nPassed: %1\nFailed: %2\n\nReport available in:\n- missionNamespace: HT_TEST_REPORT\n- profileNamespace: HT_TEST_REPORT_LAST",
        _passed,
        _failed
    ];
};

if (!hasInterface) then {
    missionNamespace setVariable ["HT_TEST_WARNING", "Tests were run in a non-client context. Clipboard copy requires Local Exec on a client.", true];
};

_results;
