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
			_x params ["_zonePos", "_hasSpawned", "_garrisonCount", "_patrolCount", "_weight"];
			private _zoneIndex = _forEachIndex;

			if (!_hasSpawned && (_garrisonCount > 0 || _patrolCount > 0)) then {
				private _shouldActivate = false;
				private _closestDist = 9999;

				{
					private _dist = _x distance2D _zonePos;
					if (_dist < _activationDistance && _dist > _minSpawnDistance) then {
						// Extra check: no player should have line of sight to the zone
						private _hasLOS = lineIntersectsWith [
							                            AGLToASL (_x modelToWorld [0, 0, 1.7]), // player eye level
							                            AGLToASL (_zonePos vectorAdd [0, 0, 1]), // zone ground level
							_x
						];
						if (count _hasLOS == 0) then {
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
					private _tempMarker = createMarker [format ["%1_zone_%2", _marker, _zoneIndex], _zonePos];
					_tempMarker setMarkerShape "ELLIPSE";
					_tempMarker setMarkerSize [_spawnZoneSize / 2, _spawnZoneSize / 2];
					_tempMarker setMarkerAlpha 0;

					private _newGroups = [];

					if (_garrisonCount > 0) then {
						private _g = [_tempMarker, _zonePos, _spawnZoneSize / 2, _garrisonCount] call Shared_fnc_garrison;
						_newGroups append _g;
					};

					if (_patrolCount > 0) then {
						private _g = [_tempMarker, _zonePos, _spawnZoneSize / 2, _patrolCount] call Shared_fnc_patrol;
						_newGroups append _g;
					};

					                    // Normalise health on all spawned units
					{
						{
							[_x] call Shared_fnc_normaliseUnitHealth
						} forEach units _x
					} forEach _newGroups;

					_allGroups append _newGroups;
					_spawnZones set [_zoneIndex, [_zonePos, true, _garrisonCount, _patrolCount, _weight]];
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
			if (!(_x select 1) && ((_x select 2) > 0 || (_x select 3) > 0)) exitWith {
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