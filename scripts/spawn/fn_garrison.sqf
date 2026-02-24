params ["_markerName", "_markerPos", "_markerRadius", "_totalUnits"];

private _allGroups = [];

// Determine number of groups (groups of 3-6)
private _groupCount = ceil (_totalUnits / 4.5); // Average 4.5 units per group

for "_i" from 1 to _groupCount do {
    private _spawnPos = objNull;

    // 50% spawn in city center, 50% in outskirts
    if (_i <= (_groupCount / 2)) then {
        _spawnPos = [_markerPos, random (_markerRadius * 0.5), random 360] call BIS_fnc_relPos;
    } else {
        private _minDist = _markerRadius * 0.5;
        private _maxDist = _markerRadius * 0.9;
        _spawnPos = [_markerPos, _minDist + random (_maxDist - _minDist), random 360] call BIS_fnc_relPos;
    };

    _spawnPos = [_spawnPos, 0, 50, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;

    //private _group = createGroup [east, true];

    // Variable group size (3-6 soldiers)
    //private _groupSize = 3 + floor random 4;

    //for "_j" from 1 to _groupSize do {
    //    _group createUnit ["O_Soldier_F", _spawnPos, [], 5, "NONE"];
    //};

    private _group = [_spawnPos, "rifle"] call Shared_fnc_createSquad;

    [_group] spawn Shared_fnc_garrisonBuilding;

    [_group, "garrison", _markerName, _markerRadius] spawn Shared_fnc_groupRespawnCheck;

    _allGroups pushBack _group;
};

// Explicitly return the groups array
_allGroups;