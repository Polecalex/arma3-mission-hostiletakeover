/*
	    Dynamic Area Occupation System - Main Entry Point
	    Spawns units progressively as players enter the area
	
	    Parameters:
	        _marker             - Marker name for the area
	        _blockadeMarkers    - Array of blockade marker names (optional)
	        _vehiclePatrols     - Number of vehicle patrols (optional)
	        _density            - Spawn density: "light", "medium", "heavy", "vheavy" (optional)
	        _activationDistance - distance at which spawning begins (optional, default from config)
	        _minSpawnDistance   - Minimum distance from players to spawn (optional, default from config)
	        _spawnZoneSize      - size of spawn zones in meters (optional, default from config)
	        _maxZonesPerCycle   - Max zone activations per monitor cycle (optional, default from config)
	        _minZoneActivationSpacing - Min spacing between zone activations (optional, default from config)
	        _aliveUnitCap       - Alive EAST AI cap for dynamic activations (optional, default from config)
	
	    Usage:
	        [_marker] call dynamic_fnc_areaOccupation;
	        [_marker, [], 2, "heavy", 300, 110, 100, 4, 140] call dynamic_fnc_areaOccupation;
*/

private _areaCfg = missionConfigFile >> "CfgVariables" >> "Dynamic" >> "AreaOccupation";

private _cfgActivationDistance = if (isNumber (_areaCfg >> "activationDistance")) then {
	getNumber (_areaCfg >> "activationDistance")
} else {
	250
};

private _cfgMinSpawnDistance = if (isNumber (_areaCfg >> "minSpawnDistance")) then {
	getNumber (_areaCfg >> "minSpawnDistance")
} else {
	85
};

private _cfgSpawnZoneSize = if (isNumber (_areaCfg >> "spawnZoneSize")) then {
	getNumber (_areaCfg >> "spawnZoneSize")
} else {
	130
};

private _cfgAliveUnitCap = if (isNumber (_areaCfg >> "aliveUnitCap")) then {
	getNumber (_areaCfg >> "aliveUnitCap")
} else {
	120
};

private _cfgMinSpawnDistanceFloor = if (isNumber (_areaCfg >> "minSpawnDistanceFloor")) then {
	getNumber (_areaCfg >> "minSpawnDistanceFloor")
} else {
	70
};

params [
	"_marker",
	["_blockadeMarkers", []],
	["_vehiclePatrols", 0],
	["_density", "medium"],
	["_activationDistance", -1],
	["_minSpawnDistance", -1],
	["_spawnZoneSize", -1],
	["_maxZonesPerCycle", -1],
	["_minZoneActivationSpacing", -1],
	["_aliveUnitCap", -1]
];

if (_activationDistance < 0) then {
	_activationDistance = _cfgActivationDistance;
};
if (_minSpawnDistance < 0) then {
	_minSpawnDistance = _cfgMinSpawnDistance;
};
if (_spawnZoneSize < 0) then {
	_spawnZoneSize = _cfgSpawnZoneSize;
};
if (_aliveUnitCap < 0) then {
	_aliveUnitCap = _cfgAliveUnitCap;
};

// Keep a safety floor so low values do not cause "spawn on top of players" moments.
_minSpawnDistance = _minSpawnDistance max _cfgMinSpawnDistanceFloor;
_minSpawnDistance = _minSpawnDistance min ((_activationDistance - 25) max _cfgMinSpawnDistanceFloor);

private _cfgMaxZonesPerCycle = switch (toLower _density) do {
	case "light": {
		1
	};
	case "medium": {
		3
	};
	case "heavy": {
		4
	};
	case "vheavy": {
		5
	};
	default {
		3
	};
};

if (_maxZonesPerCycle < 0) then {
	_maxZonesPerCycle = _cfgMaxZonesPerCycle;
};

if (_minZoneActivationSpacing < 0) then {
	_minZoneActivationSpacing = (_spawnZoneSize * 1.25) max 120;
};

// ── Calculate unit counts ────────────────────────────────────────────────────

private _markerPos = getMarkerPos _marker;
private _markerSize = getMarkerSize _marker;
private _markerRadius = (_markerSize select 0) max (_markerSize select 1);
private _markerArea = (_markerSize select 0) * (_markerSize select 1);

private _totalInfantry = [_markerArea, _density] call Shared_fnc_calcUnitCount;

private _plannedByArea = missionNamespace getVariable ["dynamic_plannedInfantryByArea", []];
private _existingIndex = _plannedByArea findIf { (_x select 0) isEqualTo _marker };
if (_existingIndex >= 0) then {
	_plannedByArea set [_existingIndex, [_marker, toLower _density, _totalInfantry]];
} else {
	_plannedByArea pushBack [_marker, toLower _density, _totalInfantry];
};

private _plannedByDensity = [];
{
	_x params ["", "_entryDensity", "_entryCount"];
	private _densityIndex = _plannedByDensity findIf { (_x select 0) isEqualTo _entryDensity };
	if (_densityIndex >= 0) then {
		private _row = _plannedByDensity select _densityIndex;
		_row set [1, (_row select 1) + _entryCount];
		_plannedByDensity set [_densityIndex, _row];
	} else {
		_plannedByDensity pushBack [_entryDensity, _entryCount];
	};
} forEach _plannedByArea;

missionNamespace setVariable ["dynamic_plannedInfantryByArea", _plannedByArea, true];
missionNamespace setVariable ["dynamic_plannedInfantryByDensity", _plannedByDensity, true];
missionNamespace setVariable ["dynamic_currentDensity", toLower _density, true];
missionNamespace setVariable ["dynamic_currentMarkerArea", _markerArea, true];
missionNamespace setVariable ["dynamic_currentPlannedInfantry", _totalInfantry, true];
missionNamespace setVariable ["dynamic_aliveUnitCap", _aliveUnitCap, true];

private _locationName = markerText _marker;
if (_locationName == "") then {
	_locationName = [_marker] call Shared_fnc_getNearestAreaName;
};

if (isServer) then {
	systemChat format ["[DYNAMIC] %1: %2m² - spawning %3 infantry total", _locationName, floor _markerArea, _totalInfantry];
};

// ── Build spawn zones ────────────────────────────────────────────────────────

private _spawnZones = [_markerPos, _markerRadius, _spawnZoneSize, _totalInfantry, _density, _activationDistance] call Shared_fnc_buildSpawnZones;

if (isServer) then {
	systemChat format ["[DYNAMIC] Created %1 spawn zones | activation: %2m | min spawn: %3m | cap: %4", count _spawnZones, _activationDistance, _minSpawnDistance, _aliveUnitCap];
};

// ── Persist state ────────────────────────────────────────────────────────────

missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
missionNamespace setVariable [_marker + "_allGroups", []];
missionNamespace setVariable [_marker + "_vehiclesSpawned", false];

if (count _blockadeMarkers > 0) then {
	missionNamespace setVariable [_marker + "_blockadeMarkers", _blockadeMarkers];
	missionNamespace setVariable [_marker + "_blockadeSpawned", []];

	if (debugMode && ((getNumber (debugOptions >> "enableBlockadeMarkers")) > 0)) then {
		private _blockadeSpawnDistanceMultiplier = if (isNumber (_areaCfg >> "blockadeSpawnDistanceMultiplier")) then {
			getNumber (_areaCfg >> "blockadeSpawnDistanceMultiplier")
		} else {
			2.8
		};
		private _blockadeLOSProbeDistanceMultiplier = if (isNumber (_areaCfg >> "blockadeLOSProbeDistanceMultiplier")) then {
			getNumber (_areaCfg >> "blockadeLOSProbeDistanceMultiplier")
		} else {
			4.0
		};
		private _blockadeSpawnDistanceMin = if (isNumber (_areaCfg >> "blockadeSpawnDistanceMin")) then {
			getNumber (_areaCfg >> "blockadeSpawnDistanceMin")
		} else {
			300
		};
		private _blockadeLOSProbeDistanceMin = if (isNumber (_areaCfg >> "blockadeLOSProbeDistanceMin")) then {
			getNumber (_areaCfg >> "blockadeLOSProbeDistanceMin")
		} else {
			500
		};

		private _blockadeSpawnDistance = ((_activationDistance * _blockadeSpawnDistanceMultiplier) max (_markerRadius * 0.60)) max _blockadeSpawnDistanceMin;
		private _blockadeLOSProbeDistance = ((_activationDistance * _blockadeLOSProbeDistanceMultiplier) max (_markerRadius * 0.90)) max _blockadeLOSProbeDistanceMin;

		{
			private _blockadeMarker = _x;
			private _blockadePos = getMarkerPos _blockadeMarker;

			private _spawnDebugName = format ["debug_blockade_spawn_%1", _blockadeMarker];
			private _losDebugName = format ["debug_blockade_los_%1", _blockadeMarker];

			createMarker [_spawnDebugName, _blockadePos];
			createMarker [_losDebugName, _blockadePos];

			_spawnDebugName setMarkerPos _blockadePos;
			_spawnDebugName setMarkerShape "ELLIPSE";
			_spawnDebugName setMarkerBrush "SolidBorder";
			_spawnDebugName setMarkerSize [_blockadeSpawnDistance, _blockadeSpawnDistance];
			_spawnDebugName setMarkerColor "ColorOrange";
			_spawnDebugName setMarkerAlpha 0.35;

			_losDebugName setMarkerPos _blockadePos;
			_losDebugName setMarkerShape "ELLIPSE";
			_losDebugName setMarkerBrush "Border";
			_losDebugName setMarkerSize [_blockadeLOSProbeDistance, _blockadeLOSProbeDistance];
			_losDebugName setMarkerColor "ColorYellow";
			_losDebugName setMarkerAlpha 0.1;
		} forEach _blockadeMarkers;
	};
};

// ── Start monitoring loop ────────────────────────────────────────────────────

[
	_marker, _activationDistance, _minSpawnDistance, _spawnZoneSize,
	_vehiclePatrols, _markerArea, _markerPos, _markerRadius, _locationName,
	_maxZonesPerCycle, _minZoneActivationSpacing, toLower _density, _aliveUnitCap
] spawn Shared_fnc_monitorLoop;

[]