params ["_target", ["_etaDuration", 40]];

private _supportConfig = missionConfigFile >> "CfgVariables" >> "Support" >> "CloseAirSupport";
if (_supportConfig isEqualTo []) exitWith {
	["[Support] Configuration not found. Check CfgVariables >> Support >> CloseAirSupport."] remoteExecCall ["BIS_fnc_error", 0];
};

private _vehicle = getText (_supportConfig >> "vehicle");
private _attackType = getNumber (_supportConfig >> "attackType");

systemChat ">>> CAS departing for gun run.";

// Add delay to extend ETA of splash down
sleep _etaDuration;

// Convert target to Above Sea Level position
private _posATL = ATLToASL [_target select 0, _target select 1, 0];

// Create a simple target object for casModule
private _casModule = createSimpleObject ["target", _posATL, true];

_casModule setDir random 360;
_casModule setVariable ["vehicle", _vehicle];
_casModule setVariable ["type", _attackType];

// Activate the module - correct syntax
[_casModule, [], true] spawn Shared_fnc_moduleCAS;

systemChat ">>> CAS strike inbound!";

// Cleanup
[_casModule, _etaDuration] spawn {
	params ["_module", "_delay"];
	// sleep ETA + 40 seconds to delete after attack
	sleep _delay + 40;
	deleteVehicle _module;
};