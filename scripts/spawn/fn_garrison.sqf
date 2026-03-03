params ["_markerName", "_markerPos", "_markerRadius", "_totalUnits"];

private _allGroups = [];

// Determine number of groups (groups of 3-6)
private _groupCount = ceil (_totalUnits / 4.5); // Average 4.5 units per group

for "_i" from 1 to _groupCount do {
    // Spawn within the specified radius of the specified position
    private _spawnPos = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
    _spawnPos = [_spawnPos, 0, 50, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;

    private _group = [_spawnPos, "rifle"] call Shared_fnc_createSquad;

    [_group] spawn Shared_fnc_garrisonBuilding;

    [_group, "garrison", _markerName, _markerRadius] spawn Shared_fnc_groupRespawnCheck;

    _allGroups pushBack _group;
};

// Explicitly return the groups array
_allGroups;