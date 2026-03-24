/*
 * Create config-driven squad with pre-defined squad variables
 * Returns squad group
 *
 * Parameters:
 *  _pos   - Spawn position
 *  _type  - Squad Type
 *  _count - Squad count - default: -1 - entire squad
 *  _side  - Squad side  - default: east - OPFOR
 */

params [
    "_pos",
    "_type",
    ["_count", -1], // -1 - Entire squad, 0 - Random size, 1+ - Specific count
    ["_side", east]
];

// Retrieve Squad Composition from CfgVariables
private _squadComposition = [_type] call Shared_fnc_getSquadComposition;

// Default -1 - Select all units from _squadComposition
private _groupSize = count _squadComposition;

if (_count == 0) then { // Random squad size between 2 and composition size (inclusive)
    private _maxGroupSize = count _squadComposition;
    _groupSize = if (_maxGroupSize <= 2) then {
        _maxGroupSize
    } else {
        2 + floor random (_maxGroupSize - 1)
    };
};

if (_count > 0) then { // Specify squad size with min 1 and max available
    _groupSize = (_count max 1) min _groupSize;
};

// Select spawnable units from _squadComposition
private _spawnableUnits = _squadComposition select [0, _groupSize];

// Creates template group and spawns + assigns units
private _group = createGroup [_side, true];
{
    _spawnPos = [_pos, 5, random 360] call BIS_fnc_relPos;

    private _unit = _group createUnit [_x, _spawnPos, [], 3, "NONE"];

    _unit setUnitPos "UP";  // Always standing
    _unit setDir (random 360);
} forEach _spawnableUnits;

// Default natural guard behavior
_group setBehaviour "SAFE";
_group setCombatMode "YELLOW";
_group setSpeedMode "LIMITED";

_group;