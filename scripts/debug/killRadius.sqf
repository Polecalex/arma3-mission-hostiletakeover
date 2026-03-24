params [["_radius", 100], ["_centerPos", player]];

// Support passing an object (like player) instead of a raw position
private _pos = if (typeName _centerPos == "OBJECT") then {
	getPosATL _centerPos
} else {
	_centerPos
};

// find all units and vehicles within the radius
// including "Air", "Car", etc., ensures we find vehicles containing enemies
private _entities = _pos nearEntities [["Man", "Air", "Car", "Motorcycle", "tank"], _radius];

private _killcount = 0;

{
	private _entity = _x;

	if (_entity isKindOf "Man") then {
		// Handle units on foot
		if (side _entity == east) then {
			[_entity, 1] remoteExec ["setDamage", _entity];
			_killcount = _killcount + 1;
		};
	} else {
		// Handle units inside vehicles
		{
			if (side _x == east) then {
				[_x, 1] remoteExec ["setDamage", _x];
				_killcount = _killcount + 1;
			};
		} forEach (crew _entity);
		deleteVehicle _entity;
	};
} forEach _entities;

diag_log format ["[Killradius] Eliminated %1 east units within %2m (including vehicle crews)", _killcount, _radius];