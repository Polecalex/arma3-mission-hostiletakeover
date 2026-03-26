private _spawnPos = [worldSize * 0.5, worldSize * 0.5, 0];
private _group = [_spawnPos, "rifle", 3] call Shared_fnc_createSquad;

[!isNull _group, "createSquad should return a valid group"] call Shared_fnc_assertTrue;

private _units = units _group;
[(count _units), 3, "createSquad should spawn requested unit count"] call Shared_fnc_assertEqual;

{
    deleteVehicle _x;
} forEach _units;
deleteGroup _group;

true;
