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
	"_locationName"
];

private _fnc_findHiddenSpawnPos = {
	params ["_spawnCenter", "_zoneRadius", "_players", "_minSpawnDistance", ["_tries", 20]];
	private _fallback = _spawnCenter;

	for "_i" from 1 to _tries do {
		private _candidate = [_spawnCenter, random _zoneRadius, random 360] call BIS_fnc_relPos;
		_candidate = [_candidate, 0, 40, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;

		private _tooClose = false;
		private _visible = false;

		{
			if ((_x distance2D _candidate) < _minSpawnDistance) exitWith {
				_tooClose = true;
			};

			private _hits = lineIntersectsWith [
				AGLToASL (_x modelToWorld [0, 0, 1.7]),
				AGLToASL (_candidate vectorAdd [0, 0, 1]),
				_x
			];

			// if no hit, LOS is clear (visible)
			if ((count _hits) == 0) exitWith {
				_visible = true;
			};
		} forEach _players;

		if (!_tooClose && !_visible) exitWith {
			_fallback = _candidate;
		};
	};

	_fallback
};

sleep 2;

while { true } do {
	sleep 5;

	private _spawnZones = missionNamespace getVariable [_marker + "_spawnZones", []];
	private _allGroups = missionNamespace getVariable [_marker + "_allGroups", []];
	private _players = allPlayers select {
		alive _x
	};

	if (count _players > 0) then {
		// ── Activate infantry spawn zones ────────────────────────────────────

		private _activatedThisCycle = 0;

		{
			_x params ["_triggerPos", "_spawnCenter", "_hasSpawned", "_garrisonCount", "_patrolCount", "_weight"];
			private _zoneIndex = _forEachIndex;

			if (!_hasSpawned && (_garrisonCount > 0 || _patrolCount > 0)) then {
				private _shouldActivate = false;
				private _closestDist = 9999;

				{
					private _dist = _x distance2D _triggerPos;
					if (_dist < _activationDistance && _dist > _minSpawnDistance) then {
						// Extra check: no player should have line of sight to the zone
						private _hasLOS = lineIntersectsWith [
							AGLToASL (_x modelToWorld [0, 0, 1.7]), // player eye level
							AGLToASL (_spawnCenter vectorAdd [0, 0, 1]), // zone ground level
							_x
						];
						if (count _hasLOS > 0) then {
							_shouldActivate = true;
						};
					};
					if (_dist < _closestDist) then {
						_closestDist = _dist
					};
				} forEach _players;

				private _allAliveMission = {
					alive _x
				} count allUnits;
				if (_allAliveMission > 40) then {
					_shouldActivate = false
				};

				if (_shouldActivate) then {
					private _tempMarker = createMarker [format ["%1_zone_%2", _marker, _zoneIndex], _spawnPos];
					_tempMarker setMarkerShape "ELLIPSE";
					_tempMarker setMarkerSize [_spawnZoneSize / 2, _spawnZoneSize / 2];
					_tempMarker setMarkerAlpha 0;

					private _newGroups = [];

					private _spawnPos = [_spawnCenter, _spawnZoneSize / 2, _players, _minSpawnDistance, 20] call _fnc_findHiddenSpawnPos;

					if (_garrisonCount > 0) then {
						private _g = [_tempMarker, _spawnPos, _spawnZoneSize / 2, _garrisonCount] call Shared_fnc_garrison;
						_newGroups append _g;
					};

					if (_patrolCount > 0) then {
						private _g = [_tempMarker, _spawnPos, _spawnZoneSize / 2, _patrolCount] call Shared_fnc_patrol;
						_newGroups append _g;
					};

					// Normalise health on all spawned units
					{
						{
							[_x] call Shared_fnc_normaliseUnitHealth
						} forEach units _x
					} forEach _newGroups;

					_allGroups append _newGroups;
					_spawnZones set [_zoneIndex, [_triggerPos, _spawnCenter, true, _garrisonCount, _patrolCount, _weight]];
					missionNamespace setVariable [_marker + "_spawnZones", _spawnZones];
					missionNamespace setVariable [_marker + "_allGroups", _allGroups];

					_activatedThisCycle = _activatedThisCycle + 1;

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
			systemChat format ["[DYNAMIC] Activated %1 zones this check", _activatedThisCycle];
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