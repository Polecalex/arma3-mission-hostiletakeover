params ["_unit"];

waitUntil { alive _unit && !isNull (group _unit) };

private _groupUnits = units group _unit;
private _groupVehicles = (_groupUnits apply { vehicle _x }) select { _x != _unit };
_groupVehicles = _groupVehicles arrayIntersect _groupVehicles;

if (count _groupVehicles == 0) exitWith {};

private _nearestVehicle = _groupVehicles select 0;

private _parachute = vehicle _unit;
if (_parachute != _unit) then {
    unassignVehicle _unit;
    _unit action ["GetOut", _parachute];
    deleteVehicle _parachute;
};

waitUntil { vehicle _unit == _unit };

_unit moveInCargo _nearestVehicle;

if (vehicle _unit != _nearestVehicle) then {
    _unit moveInGunner _nearestVehicle;
};

if (vehicle _unit != _nearestVehicle) then {
    _unit moveInDriver _nearestVehicle;
};

if (vehicle _unit != _nearestVehicle) then {
    systemChat "Warning: No seats available, respawning at vehicle position.";
}