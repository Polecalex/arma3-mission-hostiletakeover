/*
	    dynamic_fnc_buildSpawnZones
	    Divides a circular marker area into a weighted grid of spawn zones and
	    distributes garrison / patrol unit counts across them.
	
	    Parameters:
	        _markerPos     - Centre position of the marker
	        _markerRadius  - Radius of the marker in metres
	        _spawnZoneSize - Grid cell size in metres
	        _totalInfantry - Total infantry units to distribute
	
	    Returns:
	        Array of zone data: [triggerPos, spawnCenter, hasSpawned, garrisonCount, patrolCount, weight]
 */

params ["_markerPos", "_markerRadius", "_spawnZoneSize", "_totalInfantry"];

// ── Build zone grid ──────────────────────────────────────────────────────────

private _targetZones = _totalInfantry max 1;
private _markerArea = pi * _markerRadius * _markerRadius;
private _spawnZoneSize = sqrt (_markerArea / _targetZones);
private _numZones = ceil (_markerRadius / _spawnZoneSize);
private _spawnZones = [];
for "_x" from -_numZones to _numZones do {
	for "_y" from -_numZones to _numZones do {
		private _zonePos = [
			(_markerPos select 0) + (_x * _spawnZoneSize),
			(_markerPos select 1) + (_y * _spawnZoneSize),
			0
		];

		if (_zonePos distance2D _markerPos > _markerRadius) then {
			continue
		};

		// Weight: centre zones are more densely populated
		private _normalizedDist = (_zonePos distance2D _markerPos) / _markerRadius;
		private _weight = switch (true) do {
			case (_normalizedDist < 0.5): {
				3
			};
			case (_normalizedDist < 0.75): {
				2
			};
			default {
				1
			};
		};

		private _dirFromCenter = [_markerPos, _zonePos] call BIS_fnc_dirTo;
		private _triggerPos = [_markerPos, _markerRadius + (_spawnZoneSize * 0.75), _dirFromCenter] call BIS_fnc_relPos;
		_triggerPos set [2, 0];

		// [triggerPos, spawnCenter, hasSpawned, garrisonCount, patrolCount, weight]
		_spawnZones pushBack [_triggerPos, _zonePos, false, 0, 0, _weight];

		// Debug: visualise zones markers
		private _enableSpawnZoneMarkers = getNumber (debugOptions >> "enableSpawnZoneMarkers") > 0;
		if (debugMode && _enableSpawnZoneMarkers) then {
			private _debugMarker = createMarker [format ["debug_zone_%1_%2", _x, _y], _zonePos];
			_debugMarker setMarkerShape "ELLIPSE";
			_debugMarker setMarkerSize [_spawnZoneSize / 2, _spawnZoneSize / 2];
			_debugMarker setMarkerColor "ColorRed";
			_debugMarker setMarkerAlpha 0.5;
			_debugMarker setMarkerText format ["Z %1, %2", _x, _y];
		};
	};
};

// ── Distribute units across zones ────────────────────────────────────────────

private _totalWeight = 0;
{
	_totalWeight = _totalWeight + (_x select 4)
} forEach _spawnZones;

private _totalGarrison = floor (_totalInfantry * 0.75);
private _totalPatrol = _totalInfantry - _totalGarrison;

// Helper: assign one unit to a weighted-random zone, updating index _slotIndex
private _fnc_assignUnit = {
	params ["_slotIndex"];
	private _randomWeight = random _totalWeight;
	private _weightSum = 0;
	{
		_weightSum = _weightSum + (_x select 4);
		if (_weightSum >= _randomWeight) exitWith {
			_x set [_slotIndex, (_x select _slotIndex) + 1];
		};
	} forEach _spawnZones;
};

for "_i" from 1 to _totalGarrison do {
	[3] call _fnc_assignUnit
};
for "_i" from 1 to _totalPatrol do {
	[4] call _fnc_assignUnit
};

_spawnZones