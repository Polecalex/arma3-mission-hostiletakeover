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

private _fnc_findHiddenSpawnPos = {
	params ["_spawnCenter", "_zoneRadius", "_players", "_minSpawnDistance", ["_tries", 20]];
	private _fallback = _spawnCenter;
	private _bestScore = -1;
	private _foundHidden = false;

	for "_i" from 1 to _tries do {
		private _candidateRaw = [_spawnCenter, random _zoneRadius, random 360] call BIS_fnc_relPos;
		private _candidate = [_candidateRaw, 0, 40, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;

		// Keep candidate local to the spawn zone even when findSafePos drifts.
		if ((_candidate distance2D _spawnCenter) > _zoneRadius || {_candidate isEqualTo [0, 0, 0]}) then {
			_candidate = _candidateRaw;
		};

		private _tooClose = false;
		private _visible = false;
		private _nearestPlayerDist = 99999;

		{
			private _playerDist = _x distance2D _candidate;
			if (_playerDist < _nearestPlayerDist) then {
				_nearestPlayerDist = _playerDist;
			};

			if (_playerDist < _minSpawnDistance) exitWith {
				_tooClose = true;
			};

			private _startASL = AGLToASL (_x modelToWorld [0, 0, 1.7]);
			private _endASL = AGLToASL (_candidate vectorAdd [0, 0, 1]);
			private _terrainBlocked = terrainIntersectASL [_startASL, _endASL];
			private _hits = lineIntersectsWith [_startASL, _endASL, _x];

			// Visible only if neither terrain nor objects block LOS.
			if (!_terrainBlocked && (count _hits) == 0) exitWith {
				_visible = true;
			};
		} forEach _players;

		if (!_tooClose) then {
			private _score = _nearestPlayerDist;
			if (!_visible && _score > _bestScore) then {
				_bestScore = _score;
				_fallback = _candidate;
			};
			if (_visible && _bestScore < 0 && _score > (_bestScore max 0)) then {
				_bestScore = _score;
				_fallback = _candidate;
			};
		};

		if (!_tooClose && !_visible) exitWith {
			_fallback = _candidate;
			_foundHidden = true;
		};
	};

	[_fallback, _foundHidden]
};

sleep 2;

while { true } do {
	sleep 5;

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

				private _shouldActivate = false;
				private _closestDist = 9999;

				{
					private _dist = _x distance2D _triggerPos;
					if (_dist < _activationDistance && _dist > _minSpawnDistance) then {
						_shouldActivate = true;
					};
					if (_dist < _closestDist) then {
						_closestDist = _dist
					};
				} forEach _players;

				private _aliveEastAI = {
					alive _x && !isPlayer _x && side _x == east
				} count allUnits;
				if (_aliveEastAI > _aliveUnitCap) then {
					_shouldActivate = false
				};

				if (_shouldActivate) then {
					sleep (0.15 + random 0.25);

					private _spawnResult = [_spawnCenter, _hiddenSearchRadiusBase, _players, _minSpawnDistance, _baseTries] call _fnc_findHiddenSpawnPos;
					_spawnResult params ["_spawnPos", "_isHiddenSpawn"];

					// Second pass expands the search radius slightly for difficult terrain,
					// still requiring hidden LOS.
					if (!_isHiddenSpawn) then {
						_spawnResult = [_spawnCenter, _hiddenSearchRadiusExpanded, _players, _minSpawnDistance, _expandedTries] call _fnc_findHiddenSpawnPos;
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

						if (debugMode && _debugMarkerName != "") then {
							_debugMarkerName setMarkerPos _spawnCenter;
							_debugMarkerName setMarkerColor "ColorYellow";
							_debugMarkerName setMarkerAlpha 0.5;
						};
						continue;
					};

					private _tempMarker = createMarker [format ["%1_zone_%2", _marker, _zoneIndex], _spawnPos];
					_tempMarker setMarkerShape "ELLIPSE";
					_tempMarker setMarkerSize [_spawnAreaRadius, _spawnAreaRadius];
					_tempMarker setMarkerAlpha 0;

					private _newGroups = [];

					if (_garrisonCount > 0) then {
						private _g = [_tempMarker, _spawnPos, _spawnAreaRadius, _garrisonCount] call Shared_fnc_garrison;
						_newGroups append _g;
					};

					if (_patrolCount > 0) then {
						private _g = [_tempMarker, _spawnPos, _spawnAreaRadius, _patrolCount] call Shared_fnc_patrol;
						_newGroups append _g;
					};

					// Normalise health on all spawned units
					{
						{
							[_x] call Shared_fnc_normaliseUnitHealth;
							_x setVariable ["dynamic_isInfantryManaged", true, true];
							_x setVariable ["dynamic_density", toLower _density, true];
						} forEach units _x
					} forEach _newGroups;

					_allGroups append _newGroups;
					_spawnZones set [_zoneIndex, [_triggerPos, _spawnCenter, true, _garrisonCount, _patrolCount, _weight, _debugMarkerName, _blockedLOSCount]];
					missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
					missionNamespace setVariable [_marker + "_allGroups", _allGroups];

					if (debugMode && _debugMarkerName != "") then {
						_debugMarkerName setMarkerColor "ColorGreen";
						_debugMarkerName setMarkerAlpha 0.8;
					};

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
			{
				private _blockadeMarker = _x;

				if (!(_blockadeMarker in _blockadeSpawned)) then {
					private _blockadePos = getMarkerPos _blockadeMarker;
					private _shouldSpawn = false;

					{
						private _dist = _x distance2D _blockadePos;
						// if (_dist < (_activationDistance + _spawnZoneSize) && _dist > _minSpawnDistance) then {
						if (_dist < _activationDistance && _dist > _minSpawnDistance) exitWith {
							_shouldSpawn = true;
						};
					} forEach _players;

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