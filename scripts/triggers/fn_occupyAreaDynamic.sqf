/*
    Dynamic Area Occupation System
    Spawns units progressively as players enter the area

    Parameters:
        _marker - Marker name for the area
        _blockadeMarkers - Array of blockade marker names (optional)
        _vehiclePatrols - Number of vehicle patrols (optional)
        _density - Spawn density: "light", "medium", "heavy", "vheavy" (optional)
        _activationDistance - Distance at which spawning begins (optional, default 250m)
        _minSpawnDistance - Minimum distance from players to spawn (optional, default 100m)
        _spawnZoneSize - Size of spawn zones in meters (optional, default 100m)
*/

params ["_marker", ["_blockadeMarkers", []], ["_vehiclePatrols", 0], ["_density", "medium"], ["_activationDistance", 250], ["_minSpawnDistance", 100], ["_spawnZoneSize", 100]];

private _divisor = switch (_density) do {
    case "light": {3000 + random 500};    // ~35-45 soldiers
    case "medium": {2000 + random 400};   // ~50-75 soldiers
    case "heavy": {1500 + random 300};    // ~85-110 soldiers
    case "vheavy": {1200 + random 200};   // ~110-150 soldiers
    default {2000 + random 400};
};

private _markerPos = getMarkerPos _marker;
private _markerSize = getMarkerSize _marker;
private _markerRadius = (_markerSize select 0) max (_markerSize select 1);
private _markerArea = (_markerSize select 0) * (_markerSize select 1);

private _totalInfantry = ceil (_markerArea / _divisor);
_totalInfantry = (_totalInfantry max 4) min 150;

private _locationName = markerText _marker;
if (_locationName == "") then {
    _locationName = [_marker] call Shared_fnc_getNearestAreaName;
};

if (isServer) then {
    systemChat format ["[DYNAMIC] %1 area: %2m² - spawning %3 infantry total", _locationName, floor _markerArea, _totalInfantry];
};

// Create spawn zones by dividing the area into grid sections
private _numZones = ceil (_markerRadius / _spawnZoneSize);
private _spawnZones = [];

for "_x" from -_numZones to _numZones do {
    for "_y" from -_numZones to _numZones do {
        private _zonePos = [
            (_markerPos select 0) + (_x * _spawnZoneSize),
            (_markerPos select 1) + (_y * _spawnZoneSize),
            0
        ];
        
        // Only include zones within the marker radius
        if (_zonePos distance2D _markerPos <= _markerRadius) then {
            _spawnZones pushBack [_zonePos, false, 0, 0]; // [position, hasSpawned, garrisonCount, patrolCount]
        };
    };
};

// Distribute units across zones
private _totalGarrison = floor (_totalInfantry * 0.75);
private _totalPatrol = _totalInfantry - _totalGarrison;
private _zoneCount = count _spawnZones;

// Assign units to random zones
for "_i" from 1 to _totalGarrison do {
    private _randomIndex = floor (random _zoneCount);
    private _zone = _spawnZones select _randomIndex;
    _zone set [2, (_zone select 2) + 1]; // Increment garrison count
};

for "_i" from 1 to _totalPatrol do {
    private _randomIndex = floor (random _zoneCount);
    private _zone = _spawnZones select _randomIndex;
    _zone set [3, (_zone select 3) + 1]; // Increment patrol count
};

// Store zone data in namespace for persistence
missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
missionNamespace setVariable [_marker + "_allGroups", []];
missionNamespace setVariable [_marker + "_vehiclesSpawned", false];

if (isServer) then {
    systemChat format ["[DYNAMIC] Created %1 spawn zones, activation: %2m, min spawn: %3m", _zoneCount, _activationDistance, _minSpawnDistance];
};

// Spawn blockades immediately (they're always at fixed positions)
if (count _blockadeMarkers > 0) then {
    private _blockadeGroups = [_blockadeMarkers] call Shared_fnc_blockade;
    private _allGroups = missionNamespace getVariable [_marker + "_allGroups", []];
    _allGroups append _blockadeGroups;
    missionNamespace setVariable [_marker + "_allGroups", _allGroups];
};

// Start monitoring loop
[_marker, _activationDistance, _minSpawnDistance, _spawnZoneSize, _vehiclePatrols, _markerArea, _markerPos, _markerRadius, _locationName] spawn {
    params ["_marker", "_activationDistance", "_minSpawnDistance", "_spawnZoneSize", "_vehiclePatrols", "_markerArea", "_markerPos", "_markerRadius", "_locationName"];
    
    // Wait a moment before starting checks
    sleep 2;
    
    while {true} do {
        sleep 5; // Check every 5 seconds
        
        private _spawnZones = missionNamespace getVariable [_marker + "_spawnZones", []];
        private _allGroups = missionNamespace getVariable [_marker + "_allGroups", []];
        
        // Get all players
        private _players = allPlayers select {alive _x};
        
        // Only proceed if there are players
        if (count _players > 0) then {
            private _activatedThisCycle = 0;
            
            // Check each spawn zone
            {
                _x params ["_zonePos", "_hasSpawned", "_garrisonCount", "_patrolCount"];
                private _zoneIndex = _forEachIndex;
                
                if (!_hasSpawned && (_garrisonCount > 0 || _patrolCount > 0)) then {
                    // Check if zone is within activation distance but NOT too close
                    private _shouldActivate = false;
                    private _closestDist = 9999;
                    
                    {
                        private _dist = _x distance2D _zonePos;
                        
                        // Zone must be within activation distance AND beyond minimum spawn distance
                        if (_dist < _activationDistance && _dist > _minSpawnDistance) then {
                            _shouldActivate = true;
                        };
                        
                        if (_dist < _closestDist) then {
                            _closestDist = _dist;
                        };
                    } forEach _players;
                    
                    if (_shouldActivate) then {
                        // Spawn units in this zone
                        private _tempMarker = createMarker [format ["%1_zone_%2", _marker, _zoneIndex], _zonePos];
                        _tempMarker setMarkerShape "ELLIPSE";
                        _tempMarker setMarkerSize [_spawnZoneSize / 2, _spawnZoneSize / 2];
                        _tempMarker setMarkerAlpha 0; // Invisible marker
                        
                        // Spawn garrison if any
                        if (_garrisonCount > 0) then {
                            private _garrisonGroups = [_tempMarker, _zonePos, _spawnZoneSize / 2, _garrisonCount] call Shared_fnc_garrison;
                            _allGroups append _garrisonGroups;
                        };
                        
                        // Spawn patrol if any
                        if (_patrolCount > 0) then {
                            private _patrolGroups = [_tempMarker, _zonePos, _spawnZoneSize / 2, _patrolCount] call Shared_fnc_patrol;
                            _allGroups append _patrolGroups;
                        };
                        
                        // Mark zone as spawned
                        _spawnZones set [_zoneIndex, [_zonePos, true, _garrisonCount, _patrolCount]];
                        missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
                        missionNamespace setVariable [_marker + "_allGroups", _allGroups];
                        
                        _activatedThisCycle = _activatedThisCycle + 1;
                        
                        if (isServer) then {
                            systemChat format ["[DYNAMIC] Zone %1/%2 activated (%3m away) - spawned %4 units", _zoneIndex + 1, count _spawnZones, round _closestDist, _garrisonCount + _patrolCount];
                        };
                    };
                };
            } forEach _spawnZones;
            
            // Debug output
            if (isServer && _activatedThisCycle > 0) then {
                systemChat format ["[DYNAMIC] Activated %1 zones this check", _activatedThisCycle];
            };
            
            // Spawn vehicles once when any player enters the main area
            private _vehiclesSpawned = missionNamespace getVariable [_marker + "_vehiclesSpawned", false];
            if (!_vehiclesSpawned) then {
                private _playerInArea = false;
                {
                    if (_x distance2D _markerPos < _markerRadius + _activationDistance) exitWith {
                        _playerInArea = true;
                    };
                } forEach _players;
                
                if (_playerInArea && _markerArea > 75000) then {
                    private _maxVehicleCount = ceil (_markerArea / 75000);
                    _maxVehicleCount = (_maxVehicleCount max 1) min 6;
                    private _finalVehicleCount = _vehiclePatrols max _maxVehicleCount;
                    
                    private _vehicleGroups = [_marker, _markerPos, _markerRadius, _finalVehicleCount] call Shared_fnc_vehiclePatrol;
                    _allGroups append _vehicleGroups;
                    missionNamespace setVariable [_marker + "_allGroups", _allGroups];
                    missionNamespace setVariable [_marker + "_vehiclesSpawned", true];
                    
                    if (isServer) then {
                        systemChat format ["[DYNAMIC] Vehicle patrols spawned: %1 vehicles", _finalVehicleCount];
                    };
                };
            };
        };
        
        // Check if all zones are spawned - if so, exit loop
        private _allSpawned = true;
        {
            if (!(_x select 1) && ((_x select 2) > 0 || (_x select 3) > 0)) exitWith {_allSpawned = false;};
        } forEach _spawnZones;
        
        if (_allSpawned) exitWith {
            if (isServer) then {
                systemChat format ["[DYNAMIC] %1: All spawn zones activated", _locationName];
            };
        };
    };
};

// Return empty array initially - groups will be added dynamically
[]