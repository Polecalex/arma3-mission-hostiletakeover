// Clear everything
{deleteVehicle _x} forEach allUnits select {side _x == east};
{deleteVehicle _x} forEach vehicles select {side _x == east};
{if (count units _x == 0) then {deleteGroup _x}} forEach allGroups;

systemChat "All units Cleared!";

// Respawn
// ["city_occupation", 30, 5, []] execVM "scripts\fn_occupyArea.sqf";