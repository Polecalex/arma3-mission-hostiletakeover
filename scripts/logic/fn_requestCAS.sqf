params ["_targetPos", ["_etaDuration", 40]];

private _casVehicle = getText (missionConfigFile >> "CfgVariables" >> "CAS" >> "vehicle");
private _casAttackType = getNumber (missionConfigFile >> "CfgVariables" >> "CAS" >> "attackType");

systemChat ">>> CAS departing for gun run.";

// Add delay to extend ETA of splash down
sleep _etaDuration;

// Convert targetPos to Above Sea Level position
private _posATL = ATLToASL [_targetPos select 0, _targetPos select 1, 0];

// Create a simple target object for casModule
private _casModule = createSimpleObject ["target", _posATL, true];

_casModule setDir random 360;
_casModule setVariable ["vehicle", _casVehicle];
_casModule setVariable ["type", _casAttackType];

// Activate the module - correct syntax
[_casModule, [], true] spawn BIS_fnc_moduleCAS;

systemChat ">>> CAS strike inbound!";

// Cleanup
[_casModule, _etaDuration] spawn {
    params ["_module", "_delay"];
    // Sleep ETA + 40 seconds to delete after attack
    sleep _delay + 40;
    deleteVehicle _module;
};