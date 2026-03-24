debugOptions = missionConfigFile >> "CfgVariables" >> "Misc" >> "Debug";
debugMode = getNumber (debugOptions >> "enabled") > 0;

private _runTestsOnStart = debugMode && ((getNumber (debugOptions >> "runTestsOnStart")) > 0);
if (_runTestsOnStart) exitWith {
	[] spawn Shared_fnc_runTests;
};

dcon_garage_whitelist = [];
dcon_garage_blacklist = [];

missionNamespace setVariable ["casAvailable", false, true];

[] spawn Shared_fnc_respawnInit;
[] call Shared_fnc_whitelistArsenal;