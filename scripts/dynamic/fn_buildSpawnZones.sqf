/*
	    dynamic_fnc_buildSpawnZones
	    Divides a circular marker area into a grid of spawn zones and
	    distributes garrison / patrol unit counts across them.
	
	    Parameters:
	        _markerPos     - Centre position of the marker
	        _markerRadius  - Radius of the marker in metres
	        _spawnZoneSize - Grid cell size in metres
	        _totalInfantry - Total infantry units to distribute
	        _density       - "light" | "medium" | "heavy" | "vheavy"
	
	    Returns:
	        Array of zone data: [triggerPos, spawnCenter, hasSpawned, garrisonCount, patrolCount, weight]
 */

params ["_markerPos", "_markerRadius", "_spawnZoneSize", "_totalInfantry", ["_density", "medium"], ["_activationDistance", 250]];

// ── Build zone grid ──────────────────────────────────────────────────────────

private _markerArea = pi * _markerRadius * _markerRadius;

// Build zones around expected group count, then place triggers semi-randomly
// inside the area with density-dependent spacing.
private _targetGroups = ceil (_totalInfantry / 3);
private _densityZoneFactor = switch (toLower _density) do {
	case "light": {
		0.75
	};
	case "medium": {
		1.0
	};
	case "heavy": {
		1.25
	};
	case "vheavy": {
		1.5
	};
	default {
		1.0
	};
};

private _desiredZones = ((ceil (_targetGroups * _densityZoneFactor)) max 4) min 36;

private _spacingFactor = switch (toLower _density) do {
	case "light": {
		1.05
	};
	case "medium": {
		0.9
	};
	case "heavy": {
		0.78
	};
	case "vheavy": {
		0.7
	};
	default {
		0.9
	};
};

private _minSpacing = (_activationDistance * _spacingFactor) max 70;
private _overlapSpacing = _minSpacing * 0.75;

private _spawnZones = [];
private _zoneId = 0;
private _markerKey = format ["%1_%2", round (_markerPos select 0), round (_markerPos select 1)];

private _attempts = 0;
private _maxAttempts = (_desiredZones * 50) max 100;
private _candidatePoolSize = 8;
while { (count _spawnZones < _desiredZones) && (_attempts < _maxAttempts) } do {
	_attempts = _attempts + 1;

	private _triggerPos = [];
	private _nearestDist = -1;
	private _bestScore = -1;

	// Build a small random candidate pool and pick the one with best spacing score.
	for "_c" from 1 to _candidatePoolSize do {
		private _candidateRaw = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
		private _candidate = [_candidateRaw, 0, 40, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
		if ((_candidate distance2D _markerPos) > _markerRadius || {_candidate isEqualTo [0, 0, 0]}) then {
			_candidate = _candidateRaw;
		};
		if (_candidate distance2D _markerPos > _markerRadius) then {
			continue;
		};

		private _candidateNearest = 1e9;
		{
			private _dist = _candidate distance2D (_x select 0);
			if (_dist < _candidateNearest) then {
				_candidateNearest = _dist;
			};
		} forEach _spawnZones;

		if ((count _spawnZones) == 0) then {
			_candidateNearest = _minSpacing;
		};

		private _candidateScore = _candidateNearest + random 8;
		if (_candidateNearest >= _minSpacing) then {
			_candidateScore = _candidateScore + 20;
		};

		if (_candidateScore > _bestScore) then {
			_bestScore = _candidateScore;
			_triggerPos = _candidate;
			_nearestDist = _candidateNearest;
		};
	};

	if (count _triggerPos == 0) then {
		continue;
	};

	private _accept = false;
	if ((count _spawnZones) == 0 || {_nearestDist >= _minSpacing}) then {
		_accept = true;
	} else {
		if (_nearestDist >= _overlapSpacing && random 1 < 0.35) then {
			_accept = true;
		};
	};

	if (!_accept) then {
		continue;
	};

	private _spawnCenter = [_triggerPos, random (_spawnZoneSize * 0.35), random 360] call BIS_fnc_relPos;
	if (_spawnCenter distance2D _markerPos > _markerRadius) then {
		_spawnCenter = _triggerPos;
	};

	private _weight = 1;
	private _zoneLabel = _zoneId + 1;
	private _debugMarkerName = format ["debug_%1_zone_%2", _markerKey, _zoneId];

	// [triggerPos, spawnCenter, hasSpawned, garrisonCount, patrolCount, weight, debugMarkerName]
	_spawnZones pushBack [_triggerPos, _spawnCenter, false, 0, 0, _weight, _debugMarkerName];
	_zoneId = _zoneId + 1;

	private _enableSpawnZoneMarkers = getNumber (debugOptions >> "enableSpawnZoneMarkers") > 0;
	if (debugMode && _enableSpawnZoneMarkers) then {
		private _debugMarker = createMarker [_debugMarkerName, _triggerPos];
		_debugMarker setMarkerShape "ELLIPSE";
		private _debugRadius = _activationDistance;
		_debugMarker setMarkerSize [_debugRadius, _debugRadius];
		_debugMarker setMarkerColor "ColorRed";
		_debugMarker setMarkerAlpha 0.5;
		_debugMarker setMarkerText format ["Z%1", _zoneLabel];
	};
};

if (count _spawnZones == 0) then {
	private _debugMarkerName = format ["debug_%1_zone_0", _markerKey];
	_spawnZones pushBack [_markerPos, _markerPos, false, 0, 0, 1, _debugMarkerName];
};

// ── Distribute units across zones ────────────────────────────────────────────

private _garrisonRatio = switch (toLower _density) do {
	case "light": {
		0.45
	};
	case "medium": {
		0.58
	};
	case "heavy": {
		0.70
	};
	case "vheavy": {
		0.80
	};
	default {
		0.58
	};
};

private _totalGarrison = floor (_totalInfantry * _garrisonRatio);
private _totalPatrol = _totalInfantry - _totalGarrison;

// Helper: spread units evenly, then move a small percentage for natural variance.
private _fnc_distributeUnits = {
	params ["_unitTotal", "_slotIndex", ["_variance", 0.15]];

	if (_unitTotal <= 0 || {count _spawnZones == 0}) exitWith {};

	private _zoneCount = count _spawnZones;
	private _basePerZone = floor (_unitTotal / _zoneCount);
	private _remainder = _unitTotal mod _zoneCount;

	private _zoneIndexes = [];
	for "_i" from 0 to (_zoneCount - 1) do {
		_zoneIndexes pushBack _i;
	};
	_zoneIndexes = _zoneIndexes call BIS_fnc_arrayShuffle;

	for "_i" from 0 to (_zoneCount - 1) do {
		private _zoneIndex = _zoneIndexes select _i;
		private _zone = _spawnZones select _zoneIndex;
		private _allocation = _basePerZone;
		if (_i < _remainder) then {
			_allocation = _allocation + 1;
		};
		_zone set [_slotIndex, _allocation];
		_spawnZones set [_zoneIndex, _zone];
	};

	private _moves = floor (_unitTotal * _variance);
	for "_m" from 1 to _moves do {
		private _donorIndexes = [];
		{
			if ((_x select _slotIndex) > 0) then {
				_donorIndexes pushBack _forEachIndex;
			};
		} forEach _spawnZones;

		if (count _donorIndexes == 0) exitWith {};

		private _donorIndex = selectRandom _donorIndexes;
		private _receiverIndex = floor random _zoneCount;
		if (_receiverIndex == _donorIndex) then {
			continue;
		};

		private _donorZone = _spawnZones select _donorIndex;
		private _receiverZone = _spawnZones select _receiverIndex;

		_donorZone set [_slotIndex, (_donorZone select _slotIndex) - 1];
		_receiverZone set [_slotIndex, (_receiverZone select _slotIndex) + 1];

		_spawnZones set [_donorIndex, _donorZone];
		_spawnZones set [_receiverIndex, _receiverZone];
	};
};

[ _totalGarrison, 3, 0.06 ] call _fnc_distributeUnits;
[ _totalPatrol, 4, 0.08 ] call _fnc_distributeUnits;

// Accumulate total zone count so the HUD can use it as a denominator.
missionNamespace setVariable [
	"dynamic_totalDesiredZones",
	(missionNamespace getVariable ["dynamic_totalDesiredZones", 0]) + count _spawnZones,
	true
];

_spawnZones