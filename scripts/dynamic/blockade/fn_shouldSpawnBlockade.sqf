// Returns true when players are in blockade range or have clear LOS.
params ["_blockadePos", "_players", "_blockadeSpawnDistance", "_blockadeLOSDistance"];

private _shouldSpawn = false;

{
	private _dist = _x distance2D _blockadePos;

	// Spawn when players are near enough OR when they can already see the blockade area.
	if (_dist <= _blockadeSpawnDistance) exitWith {
		_shouldSpawn = true;
	};

	if (_dist <= _blockadeLOSDistance) then {
		private _startASL = AGLToASL (_x modelToWorld [0, 0, 1.7]);
		private _endASL = AGLToASL (_blockadePos vectorAdd [0, 0, 1.2]);
		private _terrainBlocked = terrainIntersectASL [_startASL, _endASL];
		private _hits = lineIntersectsWith [_startASL, _endASL, _x];

		if (!_terrainBlocked && (count _hits) == 0) exitWith {
			_shouldSpawn = true;
		};
	};
} forEach _players;

_shouldSpawn;
