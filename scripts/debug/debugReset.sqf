// Clear everything
{deleteVehicle _x} forEach allUnits select {side _x == east};
{deleteVehicle _x} forEach vehicles select {side _x == east};
{if (count units _x == 0) then {deleteGroup _x}} forEach allGroups;

if (isServer) then {
    systemChat "All units cleared!";
};

// Respawn
// ["city_occupation", 30, 5, []] execVM "scripts\fn_occupyArea.sqf";

// Script for enabling close air support (for trigger)
private _leader = missionNamespace getVariable ["blufor_leader", objNull];
if (isNull _leader) exitWith {};

if (player isEqualTo _leader) then {
  [player] call Shared_fnc_enableCloseAirSupport;
};