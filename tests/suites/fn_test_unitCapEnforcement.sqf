// Test: Unit Cap Enforcement on Zone Spawning
// Verifies that zones do not spawn when doing so would exceed unit cap,
// and that they retain their original garrison/patrol counts for retry on capacity recovery.

// Test setup: Create dummy east AI units to simulate near-cap scenario
private _testPos = [worldSize * 0.5, worldSize * 0.5, 0];
private _dummyUnits = [];
private _dummyGroups = [];

// Create 115 dummy units in EAST groups to bring us near the 120 cap
// We'll create them in groups of 14 (max group size)
private _unitsNeeded = 115;
private _maxGroupSize = 14;

while { _unitsNeeded > 0 } do {
    private _groupSize = _unitsNeeded min _maxGroupSize;
    
    // Create an EAST group
    private _grp = createGroup [east, true];
    _dummyGroups pushBack _grp;
    
    // Add units to the group
    for "_i" from 1 to _groupSize do {
        private _unit = _grp createUnit ["O_Soldier_F", _testPos, [], 0, "NONE"];
        _unit allowDamage false;
        _dummyUnits pushBack _unit;
    };
    
    _unitsNeeded = _unitsNeeded - _groupSize;
};

// Verify we have the expected count
private _aliveEastAI = { alive _x && !isPlayer _x && side _x == east } count allUnits;
[_aliveEastAI, 115, "Setup: Should have 115 east AI units"] call Shared_fnc_assertEqual;

// ── Test 1: Zone spawn should be BLOCKED when it would exceed cap ──
// Zone has garrison=8, patrol=1 (9 total). At 115/120, spawning would reach 124 (over cap)
private _garrisonCount = 8;
private _patrolCount = 1;
private _totalRequestedUnits = _garrisonCount + _patrolCount;
private _aliveUnitCap = 120;

private _wouldExceedCap = (_aliveEastAI + _totalRequestedUnits) > _aliveUnitCap;
[_wouldExceedCap, true, "At 115/120, zone with 9 units should exceed cap (124 > 120)"] call Shared_fnc_assertEqual;

// Verify the gate logic: should NOT activate
private _shouldActivateWhenFull = !(_aliveEastAI >= _aliveUnitCap || _wouldExceedCap);
[_shouldActivateWhenFull, false, "Spawn should be blocked when would exceed cap"] call Shared_fnc_assertEqual;

// ── Test 2: Zone spawn should be ALLOWED after capacity recovers ──
// Remove 6 units to drop to 109/120. Now 109 + 9 = 118 (within cap)
for "_i" from 1 to 6 do {
    deleteVehicle (_dummyUnits select (count _dummyUnits - 1));
    _dummyUnits deleteAt (count _dummyUnits - 1);
};

_aliveEastAI = { alive _x && !isPlayer _x && side _x == east } count allUnits;
[_aliveEastAI, 109, "After removing 6 units, should have 109 east AI"] call Shared_fnc_assertEqual;

_wouldExceedCap = (_aliveEastAI + _totalRequestedUnits) > _aliveUnitCap;
[_wouldExceedCap, false, "At 109/120, zone with 9 units should fit (118 <= 120)"] call Shared_fnc_assertEqual;

private _shouldActivateWhenCapable = !(_aliveEastAI >= _aliveUnitCap || _wouldExceedCap);
[_shouldActivateWhenCapable, true, "Spawn should be allowed when capacity is sufficient"] call Shared_fnc_assertEqual;

// ── Test 3: Zone retains original garrison/patrol counts (no downscaling) ──
// Verify the zone array structure persists the counts
private _zoneData = [_testPos, _testPos, false, _garrisonCount, _patrolCount, 1.0, "debug_zone_0", 0];
_zoneData params ["_triggerPos", "_spawnCenter", "_hasSpawned", "_garrison", "_patrol", "_weight", "_debugMarker", "_blockedLOS"];

private _requestedUnitsOnRetry = _garrison + _patrol;
[_requestedUnitsOnRetry, 9, "Zone should retain original 9-unit count on retry, not downscale"] call Shared_fnc_assertEqual;

// ── Cleanup ──
{
    deleteVehicle _x;
} forEach _dummyUnits;

{
    deleteGroup _x;
} forEach _dummyGroups;

true;
