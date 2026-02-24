params ["_markerName", "_markerPos", "_markerRadius", "_count"];

private _vehicleType = getText (missionConfigFile >> "CfgVariables" >> "Units" >> "Motorised" >> "standard");

private _allGroups = [];

for "_i" from 1 to _count do {
    private _spawnPos = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
    
    private _roadPos = [_spawnPos, 100] call BIS_fnc_nearestRoad;

    // Set spawn position to nearest road or a safe position if no roads within 100m
    if (!isNull _roadPos) then {
        _spawnPos = getPos _roadPos;
    } else {
        _spawnPos = [_spawnPos, 0, 100, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
    };

    // Create vehicle group and set parameters
    private _group = createGroup [east, true];
    private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "NONE"];
    _vehicle setDir (random 360);
    _vehicle setVectorUp surfaceNormal position _vehicle;
    
    createVehicleCrew _vehicle;
    crew _vehicle joinSilent _group;
    
    // Create road waypoints
    private _roadsInArea = _markerPos nearRoads _markerRadius;
    
    if (count _roadsInArea > 4) then {
        for "_w" from 0 to (3 + floor random 3) do {
            private _roadNode = selectRandom _roadsInArea;
            private _wp = _group addWaypoint [getPos _roadNode, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "LIMITED";
            _wp setWaypointBehaviour "SAFE";
        };
        
        private _wpCycle = _group addWaypoint [_spawnPos, 0];
        _wpCycle setWaypointType "CYCLE";
    } else {
        [_group, _markerPos, _markerRadius * 0.7] call BIS_fnc_taskPatrol;
    };
    
    _group setBehaviour "SAFE";
    _group setSpeedMode "LIMITED";
    
    // Add spawn check
    [_vehicle, _markerName, _markerRadius] spawn Shared_fnc_vehicleSpawnCheck;
    
    _allGroups pushBack _group;
};

_allGroups;