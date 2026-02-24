params ["_targetPos"];

hint "CAS gun run approved. Aircraft inbound...";
systemChat ">>> A-10 departing for gun run.";

sleep 5;

systemChat ">>> Aircraft on approach vector.";

// Spawn at distance
private _direction = random 360;
private _spawnPos = _targetPos getPos [4000, _direction];
_spawnPos set [2, 500]; // 500m altitude for gun run

private _casPlane = createVehicle ["B_Plane_CAS_01_dynamicLoadout_F", _spawnPos, [], 0, "FLY"];
createVehicleCrew _casPlane;

_casPlane flyInHeight 400;
_casPlane setSpeedMode "NORMAL";

private _casGroup = group driver _casPlane;
_casGroup setBehaviour "CARELESS";
_casGroup setCombatMode "RED";

// Create invisible target helper at exact position
private _helper = createVehicle ["Land_HelipadEmpty_F", _targetPos, [], 0, "NONE"];
private _laserTarget = createVehicle ["LaserTargetW", _targetPos, [], 0, "NONE"];

// Make plane aware of laser target
_casGroup reveal [_laserTarget, 4];
driver _casPlane doTarget _laserTarget;
gunner _casPlane doTarget _laserTarget;

// Simple flyover waypoint
private _wp1 = _casGroup addWaypoint [_targetPos, 0];
_wp1 setWaypointType "MOVE";

// Exit
private _exitPos = [_targetPos, 4000, _direction + 180] call BIS_fnc_relPos;
private _wp2 = _casGroup addWaypoint [_exitPos, 0];
_wp2 setWaypointType "MOVE";

systemChat ">>> Gun run commencing!";

// Force gun fire at target position
[_casPlane, _targetPos, _laserTarget, _direction] spawn {
    params ["_plane", "_target", "_laser", "_dir"];

    // Wait until in range
    waitUntil {
        sleep 0.5;
        (!alive _plane || {(_plane distance2D _target) < 1200})
    };

    if (!alive _plane) exitWith {};

    systemChat ">>> BRRRRRT! Gun run in progress!";

    // Fire gun at target area while approaching
    private _startDist = _plane distance2D _target;

    while {alive _plane && (_plane distance2D _target) < _startDist && (_plane distance2D _target) > 100} do {

        // Force gunner to fire at laser target
        gunner _plane doTarget _laser;
        gunner _plane doFire _laser;

        // Also manually create gun impacts at target
        private _impactPos = [_target, random 40, random 360] call BIS_fnc_relPos;

        // Create bullet impacts/tracers
        private _bullet = createVehicle ["B_30mm_AP", getPosATL _plane, [], 0, "NONE"];
        _bullet setVelocity [
            ((_impactPos select 0) - (getPosATL _plane select 0)) / 5,
            ((_impactPos select 1) - (getPosATL _plane select 1)) / 5,
            -50
        ];

        sleep 0.05; // Rapid fire
    };

    systemChat ">>> Gun run complete!";

    // Cleanup helpers
    deleteVehicle _laser;
    deleteVehicle _helper;
};

// Cleanup
[_casPlane] spawn {
    params ["_plane"];
    sleep 180;
    if (alive _plane) then {
        {deleteVehicle _x} forEach crew _plane;
        deleteVehicle _plane;
        systemChat ">>> CAS returning to base.";
    };
};




params ["_targetPos"];

hint "CAS gun run approved. Aircraft inbound...";
systemChat ">>> CAS departing for gun run.";

// Use the built-in BIS CAS function
[
    _targetPos,     // Target position
    1,              // Type: 0 = bombs, 1 = gun run, 2 = rockets
    200,            // Radius of effect
    5,              // Number of runs
    0,              // Direction (0 = random)
    0,              // Altitude offset
    player          // Who requested it (for radio messages)
] spawn BIS_fnc_CASGunRun;

systemChat ">>> CAS strike inbound!";