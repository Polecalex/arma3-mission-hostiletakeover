// Returns [spawnPos, isHidden] by sampling candidates and enforcing LOS concealment.
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

[_fallback, _foundHidden];
