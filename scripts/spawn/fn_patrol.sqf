params ["_markerName", "_markerPos", "_markerRadius", "_totalUnits"];

private _allGroups = [];

if (_totalUnits <= 0) exitWith { _allGroups };

private _maxGroupSize = 7;
private _groupCount = ceil (_totalUnits / _maxGroupSize);

for "_i" from 1 to _groupCount do {
    // Spawn within the specified radius of the specified position
    private _spawnPosRaw = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
    private _spawnPos = [_spawnPosRaw, 0, 50, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
    if ((_spawnPos distance2D _markerPos) > _markerRadius || {_spawnPos isEqualTo [0, 0, 0]}) then {
        _spawnPos = _spawnPosRaw;
    };

    // Create Rifle group at spawn position
    private _group = [_spawnPos, "rifle", 0] call Shared_fnc_createSquad;
    _group setVariable ["dynamic_groupSize", count units _group, true];

    // Patrol waypoints - keep within the specified area
    for "_w" from 0 to (4 + floor random 4) do {
        private _wpPosRaw = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
        private _wpPos = [_wpPosRaw, 0, 30, 2, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if ((_wpPos distance2D _markerPos) > _markerRadius || {_wpPos isEqualTo [0, 0, 0]}) then {
            _wpPos = _wpPosRaw;
        };

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