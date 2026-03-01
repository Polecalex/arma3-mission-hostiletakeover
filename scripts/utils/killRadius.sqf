params [["_radius", 100], ["_centerPos", player]];

/*
    Author: Junie
    Description: Kills all EAST units within a specified radius, including those in vehicles.
    Compatible with Multiplayer.
*/

// Support passing an object (like player) instead of a raw position
private _pos = if (typeName _centerPos == "OBJECT") then { getPosATL _centerPos } else { _centerPos };

// Find all units and vehicles within the radius
// Including "Air", "Car", etc., ensures we find vehicles containing enemies
private _entities = _pos nearEntities [["Man", "Air", "Car", "Motorcycle", "Tank"], _radius];

private _killCount = 0;

{
    private _entity = _x;

    if (_entity isKindOf "Man") then {
        // Handle units on foot
        if (side _entity == east) then {
            [_entity, 1] remoteExec ["setDamage", _entity];
            _killCount = _killCount + 1;
        };
    } else {
        // Handle units inside vehicles
        {
            if (side _x == east) then {
                [_x, 1] remoteExec ["setDamage", _x];
                _killCount = _killCount + 1;
            };
        } forEach (crew _entity);
    };
} forEach _entities;

diag_log format ["[KillRadius] Eliminated %1 EAST units within %2m (including vehicle crews)", _killCount, _radius];