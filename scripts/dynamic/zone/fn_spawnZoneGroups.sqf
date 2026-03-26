// Spawns garrison/patrol groups for a zone and tags units for dynamic tracking.
params ["_tempMarker", "_spawnPos", "_spawnAreaRadius", "_garrisonCount", "_patrolCount", "_density"];

private _newGroups = [];

if (_garrisonCount > 0) then {
	private _g = [_tempMarker, _spawnPos, _spawnAreaRadius, _garrisonCount] call Shared_fnc_garrison;
	_newGroups append _g;
};

if (_patrolCount > 0) then {
	private _g = [_tempMarker, _spawnPos, _spawnAreaRadius, _patrolCount] call Shared_fnc_patrol;
	_newGroups append _g;
};

// Normalise health and tag all managed infantry for HUD/accounting.
{
	{
		[_x] call Shared_fnc_normaliseUnitHealth;
		_x setVariable ["dynamic_isInfantryManaged", true, true];
		_x setVariable ["dynamic_density", toLower _density, true];
	} forEach units _x;
} forEach _newGroups;

_newGroups;
