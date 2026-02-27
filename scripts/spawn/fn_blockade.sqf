params ["_blockadeMarkers"];

private _allGroups = [];

{
    private _markerName = _x;
    private _blockadePos = getMarkerPos _markerName;
    private _markerSize = getMarkerSize _markerName;
    private _radius = (_markerSize select 0) max (_markerSize select 1);
    private _markerArea = (_markerSize select 0) * (_markerSize select 1);

    // Dynamic group size based on area
    private _groupSize = ceil (_markerArea / 75);
    _groupSize = (_groupSize max 2) min 12;

    // Create Rifle group at blockade position
    private _group = [_blockadePos, "rifle"] call Shared_fnc_createSquad;
    private _units = units _group;

    // Split units: 60% hunker down, 40% wander
    private _hunkerCount = floor (count _units * 0.6);
    private _hunkerUnits = _units select [0, _hunkerCount];
    private _wanderUnits = _units select [_hunkerCount, count _units - _hunkerCount];

    private _usedCover = [];

    // Hunker down logic
    {
        private _unit = _x;
        // Search for nearby cover (buildings, walls, or static objects)
        // Use marker radius for search, up to 30m
        private _searchRadius = (_radius max 15) min 30;
        private _nearbyCover = nearestObjects [_unit, ["House", "Building", "Wall", "Static", "Fences", "Thing"], _searchRadius];
        
        // Filter out very small objects (like grass or tiny clutter) and already used cover
        _nearbyCover = _nearbyCover select {
            private _box = boundingBoxReal _x;
            private _size = (_box select 1) vectorDiff (_box select 0);
            (_size select 0) > 0.5 && (_size select 2) > 0.4 && !(_x in _usedCover)
        };

        if (count _nearbyCover > 0) then {
            private _cover = _nearbyCover select 0;
            _usedCover pushBack _cover;
            private _positions = _cover buildingPos -1;
            
            if (count _positions > 0) then {
                // If it's a building with positions, use one
                _unit setPosATL (selectRandom _positions);
                _unit setDir (_blockadePos getDir _unit); // Face outwards
            } else {
                // For custom objects (sandbags, etc.), position the unit BEHIND it
                // relative to the center of the blockade (assuming threat comes from outside)
                private _dirToCenter = _cover getDir _blockadePos;
                if (_cover distance _blockadePos < 1) then { _dirToCenter = random 360; }; // Handle objects at the center
                
                // Calculate thickness to place unit precisely behind it
                private _box = boundingBoxReal _cover;
                private _size = (_box select 1) vectorDiff (_box select 0);
                private _thickness = (_size select 0) min (_size select 1);
                private _offset = (_thickness / 2) + 0.6; // 0.6m from the edge for a good "hug"
                
                private _posBehind = _cover getPos [_offset, _dirToCenter];
                _unit setPosATL _posBehind;
                _unit setDir (_dirToCenter + 180); // Face away from center (towards the cover/enemy)
            };
            
            // Determine stance based on object height
            private _box = boundingBoxReal _cover;
            private _height = (_box select 1 select 2) - (_box select 0 select 2);
            if (_height < 1.1) then {
                _unit setUnitPos "MIDDLE"; // Crouch for low cover (sandbags)
            } else {
                _unit setUnitPos "UP"; // Stand for walls
            };

            _unit disableAI "PATH";
            doStop _unit;
        } else {
            // No cover nearby, just face outwards and crouch
            // Add small random offset to prevent stacking at the center
            private _randomPos = [_blockadePos, 1 + random 3, random 360] call BIS_fnc_relPos;
            _unit setPosATL _randomPos;
            _unit setDir (_blockadePos getDir _unit);
            _unit setUnitPos "MIDDLE";
            _unit disableAI "PATH";
            doStop _unit;
        };
    } forEach _hunkerUnits;

    // Guard waypoint - slight wandering for the rest
    if (count _wanderUnits > 0) then {
        // Create a new group for the wanderers so they don't wait for the hunkered units
        private _wanderGroup = createGroup [side _group, true];
        _wanderUnits joinSilent _wanderGroup;
        
        // Create multiple waypoints to ensure continuous movement
        for "_w" from 0 to 3 do {
            private _wpPos = [_blockadePos, random (_radius * 0.7), random 360] call BIS_fnc_relPos;
            private _wp = _wanderGroup addWaypoint [_wpPos, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "LIMITED";
            _wp setWaypointBehaviour "SAFE";
            _wp setWaypointTimeout [5, 10, 15];
        };

        private _wpCycle = _wanderGroup addWaypoint [_blockadePos, 0];
        _wpCycle setWaypointType "CYCLE";
        _wanderGroup setBehaviour "SAFE";
        
        _allGroups pushBack _wanderGroup;
    };

    _allGroups pushBack _group;

} forEach _blockadeMarkers;

_allGroups;