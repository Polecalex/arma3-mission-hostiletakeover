/*
	    Dynamic Area Occupation System - Main Entry Point
	    Spawns units progressively as players enter the area
	
	    Parameters:
	        _marker             - Marker name for the area
	        _blockadeMarkers    - Array of blockade marker names (optional)
	        _vehiclePatrols     - Number of vehicle patrols (optional)
	        _density            - Spawn density: "light", "medium", "heavy", "vheavy" (optional)
	        _activationDistance - distance at which spawning begins (optional, default 250m)
	        _minSpawnDistance   - Minimum distance from players to spawn (optional, default 100m)
	        _spawnZoneSize      - size of spawn zones in meters (optional, default 100m)
	
	    Usage:
	        [_marker] call dynamic_fnc_areaOccupation;
	        [_marker, [], 2, "heavy", 300, 120, 80] call dynamic_fnc_areaOccupation;
*/

params [
	"_marker",
	["_blockadeMarkers", []],
	["_vehiclePatrols", 0],
	["_density", "medium"],
	["_activationDistance", 250],
	["_minSpawnDistance", 100],
	["_spawnZoneSize", 200]
];

// ── Calculate unit counts ────────────────────────────────────────────────────

private _markerPos = getMarkerPos _marker;
private _markerSize = getMarkerSize _marker;
private _markerRadius = (_markerSize select 0) max (_markerSize select 1);
private _markerArea = (_markerSize select 0) * (_markerSize select 1);

private _totalInfantry = [_markerArea, _density] call Shared_fnc_calcUnitCount;

private _locationName = markerText _marker;
if (_locationName == "") then {
	_locationName = [_marker] call Shared_fnc_getNearestAreaName;
};

if (isServer) then {
	systemChat format ["[DYNAMIC] %1: %2m² - spawning %3 infantry total", _locationName, floor _markerArea, _totalInfantry];
};

// ── Build spawn zones ────────────────────────────────────────────────────────

private _spawnZones = [_markerPos, _markerRadius, _spawnZoneSize, _totalInfantry] call Shared_fnc_buildSpawnZones;

if (isServer) then {
	systemChat format ["[DYNAMIC] Created %1 spawn zones | activation: %2m | min spawn: %3m", count _spawnZones, _activationDistance, _minSpawnDistance];
};

// ── Persist state ────────────────────────────────────────────────────────────

missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
missionNamespace setVariable [_marker + "_allGroups", []];
missionNamespace setVariable [_marker + "_vehiclesSpawned", false];

if (count _blockadeMarkers > 0) then {
	missionNamespace setVariable [_marker + "_blockadeMarkers", _blockadeMarkers];
	missionNamespace setVariable [_marker + "_blockadeSpawned", []];
};

// ── Start monitoring loop ────────────────────────────────────────────────────

[
	_marker, _activationDistance, _minSpawnDistance, _spawnZoneSize,
	_vehiclePatrols, _markerArea, _markerPos, _markerRadius, _locationName
] spawn Shared_fnc_monitorLoop;

[]