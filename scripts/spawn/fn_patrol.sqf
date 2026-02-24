params ["_markerName", "_markerPos", "_markerRadius", "_totalUnits"];

private _allGroups = [];

// Determine number of groups (groups of 2-5)
private _groupCount = ceil (_totalUnits / 3.5); // Average 3.5 units per group TODO: Update this to reflect new amount of units per group (maybe just 8)

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

    // Create Rifle group at spawn position
    private _group = [_spawnPos, "rifle"] call Shared_fnc_createSquad;

    // Patrol waypoints
    for "_w" from 0 to (4 + floor random 4) do {
        private _wpPos = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
        _wpPos = [_wpPos, 0, 30, 2, 0, 0.5, 0] call BIS_fnc_findSafePos;

        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointFormation "COLUMN";
        _wp setWaypointCompletionRadius 15;

        if (random 1 > 0.7) then {
            _wp setWaypointTimeout [10, 15, 20];
        };
    };

    private _wpCycle = _group addWaypoint [_spawnPos, 0];
    _wpCycle setWaypointType "CYCLE";

    _group setBehaviour "SAFE";

    [_group, "patrol", _markerName, _markerRadius] spawn Shared_fnc_groupRespawnCheck;

    _allGroups pushBack _group;
};

_allGroups;