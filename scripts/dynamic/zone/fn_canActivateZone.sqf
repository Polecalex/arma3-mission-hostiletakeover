// Returns [shouldActivate, closestDist] after player distance and cap checks.
params [
	"_triggerPos",
	"_players",
	"_activationDistance",
	"_minSpawnDistance",
	"_aliveUnitCap",
	"_garrisonCount",
	"_patrolCount"
];

private _shouldActivate = false;
private _closestDist = 9999;

{
	private _dist = _x distance2D _triggerPos;
	if (_dist < _activationDistance && _dist > _minSpawnDistance) then {
		_shouldActivate = true;
	};
	if (_dist < _closestDist) then {
		_closestDist = _dist;
	};
} forEach _players;

private _aliveEastAI = {
	alive _x && !isPlayer _x && side _x == east
} count allUnits;

private _totalRequestedUnits = _garrisonCount + _patrolCount;
private _wouldExceedCap = (_aliveEastAI + _totalRequestedUnits) > _aliveUnitCap;

if (_aliveEastAI >= _aliveUnitCap || _wouldExceedCap) then {
	_shouldActivate = false;
};

[_shouldActivate, _closestDist];
