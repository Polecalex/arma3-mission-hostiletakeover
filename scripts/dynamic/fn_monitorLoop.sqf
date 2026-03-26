/*
	    dynamic_fnc_monitorLoop
	    Background loop that activates spawn zones and blockades as players approach,
	    then spawns vehicle patrols once the main area is entered.
	
	    This function is intended to be called via `spawn` - it runs until all
	    zones and blockades have been activated, then exits cleanly.
	
	    Parameters:
	        _marker             - Area marker name
	        _activationDistance - Outer trigger radius (m)
	        _minSpawnDistance   - Inner exclusion radius - units won't spawn closer (m)
	        _spawnZoneSize      - Radius of each spawn zone (m)
	        _vehiclePatrols     - Minimum vehicle patrol count
	        _markerArea         - Pre-calculated marker area (m²)
	        _markerPos          - Centre position of the marker
	        _markerRadius       - Radius of the marker (m)
	        _locationName       - Human-readable location label
*/

params [
	"_marker",
	"_activationDistance",
	"_minSpawnDistance",
	"_spawnZoneSize",
	"_vehiclePatrols",
	"_markerArea",
	"_markerPos",
	"_markerRadius",
	"_locationName",
	["_maxZonesPerCycle", 2],
	["_minZoneActivationSpacing", 120],
	["_density", "medium"],
	["_aliveUnitCap", 120]
];

private _baseMul = 0.30;
private _baseMin = 30;
private _baseMax = 70;
private _baseTries = 22;
private _expandedMul = 0.55;
private _expandedMin = 45;
private _expandedMax = 120;
private _expandedTries = 30;
private _spawnAreaMul = 0.40;
private _spawnAreaMin = 35;
private _spawnAreaMax = 90;
private _loopIntervalSec = 3;
private _startupDelaySec = 1;

sleep _startupDelaySec;

while { true } do {
	sleep _loopIntervalSec;

	// Keep hidden-spawn search practical and tuneable from config/caller overrides.
	private _hiddenSearchRadiusBase = ((_spawnZoneSize * _baseMul) max _baseMin) min _baseMax;
	private _hiddenSearchRadiusExpanded = ((_spawnZoneSize * _expandedMul) max _expandedMin) min _expandedMax;
	private _spawnAreaRadius = ((_spawnZoneSize * _spawnAreaMul) max _spawnAreaMin) min _spawnAreaMax;

	private _spawnZones = missionNamespace getVariable [_marker + "_spawnZones", []];
	private _allGroups = missionNamespace getVariable [_marker + "_allGroups", []];
	private _players = allPlayers select {
		alive _x
	};

	if (count _players > 0) then {
		// ── Activate infantry spawn zones ────────────────────────────────────

		private _activatedThisCycle = 0;
		private _activatedCenters = [];

		{
			_x params ["_triggerPos", "_spawnCenter", "_hasSpawned", "_garrisonCount", "_patrolCount", "_weight", ["_debugMarkerName", ""], ["_blockedLOSCount", 0]];
			private _zoneIndex = _forEachIndex;

			if (!_hasSpawned && (_garrisonCount > 0 || _patrolCount > 0)) then {
				if (_activatedThisCycle >= _maxZonesPerCycle) then {
					continue;
				};

				private _tooCloseToActivatedZone = false;
				{
					if (_triggerPos distance2D _x < _minZoneActivationSpacing) exitWith {
						_tooCloseToActivatedZone = true;
					};
				} forEach _activatedCenters;

				if (_tooCloseToActivatedZone) then {
					continue;
				};

				private _activationResult = [
					_triggerPos,
					_players,
					_activationDistance,
					_minSpawnDistance,
					_aliveUnitCap,
					_garrisonCount,
					_patrolCount
				] call Shared_fnc_canActivateZone;
				_activationResult params ["_shouldActivate", "_closestDist"];

				if (_shouldActivate) then {
					sleep (0.15 + random 0.25);

					private _spawnResult = [_spawnCenter, _hiddenSearchRadiusBase, _players, _minSpawnDistance, _baseTries] call Shared_fnc_findHiddenSpawnPos;
					_spawnResult params ["_spawnPos", "_isHiddenSpawn"];

					// Second pass expands the search radius slightly for difficult terrain,
					// still requiring hidden LOS.
					if (!_isHiddenSpawn) then {
						_spawnResult = [_spawnCenter, _hiddenSearchRadiusExpanded, _players, _minSpawnDistance, _expandedTries] call Shared_fnc_findHiddenSpawnPos;
						_spawnResult params ["_spawnPos", "_isHiddenSpawn"];
					};

					// Never force a visible spawn; relocate spawn center and retry on next loop.
					if (!_isHiddenSpawn) then {
						_blockedLOSCount = _blockedLOSCount + 1;

						// Reroll spawn center to a new random position within the marker area.
						private _newCenter = [_markerPos, random _markerRadius, random 360] call BIS_fnc_relPos;
						if (_newCenter distance2D _markerPos <= _markerRadius) then {
							_spawnCenter = _newCenter;
						};

						_spawnZones set [_zoneIndex, [_triggerPos, _spawnCenter, false, _garrisonCount, _patrolCount, _weight, _debugMarkerName, _blockedLOSCount]];
						missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
						[_debugMarkerName, _spawnCenter, "ColorYellow", 0.5] call Shared_fnc_setZoneDebugMarker;
						continue;
					};

					private _tempMarker = createMarker [format ["%1_zone_%2", _marker, _zoneIndex], _spawnPos];
					_tempMarker setMarkerShape "ELLIPSE";
					_tempMarker setMarkerSize [_spawnAreaRadius, _spawnAreaRadius];
					_tempMarker setMarkerAlpha 0;

					private _newGroups = [_tempMarker, _spawnPos, _spawnAreaRadius, _garrisonCount, _patrolCount, _density] call Shared_fnc_spawnZoneGroups;

					_allGroups append _newGroups;
					_spawnZones set [_zoneIndex, [_triggerPos, _spawnCenter, true, _garrisonCount, _patrolCount, _weight, _debugMarkerName, _blockedLOSCount]];
					missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
					missionNamespace setVariable [_marker + "_allGroups", _allGroups];
					[_debugMarkerName, _spawnCenter, "ColorGreen", 0.8] call Shared_fnc_setZoneDebugMarker;

					_activatedThisCycle = _activatedThisCycle + 1;
					_activatedCenters pushBack _triggerPos;

					if (isServer) then {
						systemChat format [
							"[DYNAMIC] Zone %1/%2 activated (%3m away) - spawned %4 groups with %5 garrison and %6 patrol | %7 total groups now active",
							_zoneIndex + 1, count _spawnZones,
							round _closestDist,
							_garrisonCount + _patrolCount,
							_garrisonCount, _patrolCount,
							count _allGroups
						];
					};
				};
			};
		} forEach _spawnZones;

		if (isServer && _activatedThisCycle > 0) then {
			systemChat format ["[DYNAMIC] Activated %1 zones this check (cap %2)", _activatedThisCycle, _maxZonesPerCycle];
		};

		// ── Activate blockades ───────────────────────────────────────────────

		private _blockadeMarkers = missionNamespace getVariable [_marker + "_blockadeMarkers", []];
		private _blockadeSpawned = missionNamespace getVariable [_marker + "_blockadeSpawned", []];

		if (count _blockadeMarkers > 0) then {
			private _enableBlockadeMarkers = getNumber (debugOptions >> "enableBlockadeMarkers") > 0;
			private _blockadeDistances = [_activationDistance, _markerRadius] call Shared_fnc_getBlockadeDistances;
			_blockadeDistances params ["_blockadeSpawnDistance", "_blockadeLOSDistance"];
			{
				private _blockadeMarker = _x;
				private _blockadePos = getMarkerPos _blockadeMarker;

				if (debugMode && _enableBlockadeMarkers) then {
					[_blockadeMarker, _blockadePos, _blockadeSpawnDistance, _blockadeLOSDistance, (_blockadeMarker in _blockadeSpawned)] call Shared_fnc_updateBlockadeDebugMarkers;
				};

				if (!(_blockadeMarker in _blockadeSpawned)) then {
					private _shouldSpawn = [_blockadePos, _players, _blockadeSpawnDistance, _blockadeLOSDistance] call Shared_fnc_shouldSpawnBlockade;

					if (_shouldSpawn) then {
						private _bGroups = [[_blockadeMarker]] call Shared_fnc_blockade;
						{
							{
								[_x] call Shared_fnc_normaliseUnitHealth
							} forEach units _x
						} forEach _bGroups;

						_allGroups append _bGroups;
						missionNamespace setVariable [_marker + "_allGroups", _allGroups];

						_blockadeSpawned pushBack _blockadeMarker;
						missionNamespace setVariable [_marker + "_blockadeSpawned", _blockadeSpawned];

						if (isServer) then {
							systemChat format ["[DYNAMIC] Blockade spawned at %1", _blockadeMarker];
						};
					};
				};
			} forEach _blockadeMarkers;
		};

		// ── spawn vehicle patrols (once only) ────────────────────────────────
		private _vehiclesSpawned = missionNamespace getVariable [_marker + "_vehiclesSpawned", false];

		if (!_vehiclesSpawned) then {
			private _playerInArea = false;
			{
				if (_x distance2D _markerPos < _markerRadius + _activationDistance) exitWith {
					_playerInArea = true;
				};
			} forEach _players;

			if (_playerInArea && _markerArea > 75000) then {
				private _maxVehicleCount = (ceil (_markerArea / 75000)) max 1 min 6;
				private _finalVehicleCount = _vehiclePatrols max _maxVehicleCount;

				private _vGroups = [_marker, _markerPos, _markerRadius, _finalVehicleCount] call Shared_fnc_vehiclePatrol;
				_allGroups append _vGroups;
				missionNamespace setVariable [_marker + "_allGroups", _allGroups];
				missionNamespace setVariable [_marker + "_vehiclesSpawned", true];

				if (isServer) then {
					systemChat format ["[DYNAMIC] Vehicle patrols spawned: %1", _finalVehicleCount];
				};
			};
		};
	};

	// ── exit when everything is spawned ─────────────────────────────────────

	private _spawnZones = missionNamespace getVariable [_marker + "_spawnZones", []];
	private _allSpawned = true;
	{
		if (!(_x select 2) && ((_x select 3) > 0 || (_x select 4) > 0)) exitWith {
			_allSpawned = false
		};
	} forEach _spawnZones;

	private _blockadeMarkers = missionNamespace getVariable [_marker + "_blockadeMarkers", []];
	private _blockadeSpawned = missionNamespace getVariable [_marker + "_blockadeSpawned", []];
	private _allBlockadesSpawned = (count _blockadeMarkers == count _blockadeSpawned);

	if (_allSpawned && _allBlockadesSpawned) exitWith {
		if (isServer) then {
			systemChat format ["[DYNAMIC] %1: All spawn zones activated", _locationName];
		};
	};
};