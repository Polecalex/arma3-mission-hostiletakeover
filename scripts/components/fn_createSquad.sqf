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

// Create template group for units
private _group = createGroup [_side, true];

// Default -1 - Select all units from _squadComposition
private _groupSize = count _squadComposition;

if (_count == 0) then { // _count == 0 - Randomly select group size
    _groupSize = 2 + floor random (count _squadComposition);
};
if (_count > 1) then { // _count == 1+ - Specify group size
    _groupSize = _count;
};

// Select spawnable units from _squadComposition
private _spawnableUnits = _squadComposition select [0, _groupSize];

// Create spawnable units within group
{
    _spawnPos = [_pos, 3, random 360] call BIS_fnc_relPos;

    private _unit = _group createUnit [_x, _spawnPos, [], 3, "NONE"];

    // Random stance
    _unit setUnitPos "UP";  // Always standing
    _unit setDir (random 360);
} forEach _spawnableUnits;

// Default natural guard behavior
_group setBehaviour "SAFE";
_group setCombatMode "YELLOW";
_group setSpeedMode "LIMITED";

_group;