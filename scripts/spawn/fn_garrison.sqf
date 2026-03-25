params ["_markerName", "_markerPos", "_markerRadius", "_totalUnits"];

private _allGroups = [];

if (_totalUnits <= 0) exitWith { _allGroups };

private _maxGroupSize = 8;
private _groupCount = ceil (_totalUnits / _maxGroupSize);

for "_i" from 1 to _groupCount do {
    // Spawn within the specified radius of the specified position
    private _spawnPosRaw = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
    private _spawnPos = [_spawnPosRaw, 0, 50, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
    if ((_spawnPos distance2D _markerPos) > _markerRadius || {_spawnPos isEqualTo [0, 0, 0]}) then {
        _spawnPos = _spawnPosRaw;
    };

    private _group = [_spawnPos, "rifle", 0] call Shared_fnc_createSquad;
    _group setVariable ["dynamic_groupSize", count units _group, true];

    [_group] spawn Shared_fnc_garrisonBuilding;

    [_group, "garrison", _markerName, _markerRadius] spawn Shared_fnc_groupRespawnCheck;

    _allGroups pushBack _group;
};

// Explicitly return the groups array
_allGroups;