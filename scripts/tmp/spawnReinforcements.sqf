params [
    "_task",
    "_marker",
    "_dest",
    "_count"
];

// Create a group for all reinforcement units
// Create transport unit
// Create squad composition
// Place squad into transport unit
// Create waypoint to players position
// Create waypoint to get out and search and destroy.

private _vehicleType = getText (missionConfigFile >> "CfgVariables" >> "Units" >> "Transport" >> "standard");
private _destination = if (typeName _dest == "OBJECT") then {
    getPos _dest
} else {
    _dest  // Already a position
};

private _pos = getMarkerPos _marker;

// Create reinforcement group
private _parentGroup = createGroup [east, true];

// Trigger reinforcement task failure
[_task, "FAILED", true] call BIS_fnc_taskSetState;

([_pos, "rifle"] call Shared_fnc_vehicleReinforcements) params ["_crewGroup", "_passengerGroup"];
private _vehicle = vehicle (leader _crewGroup);

_wp = _crewGroup addWaypoint [_destination, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "FULL";

// Monitor - unload when close to insertion point
[_vehicle, _destination, _passengerGroup, _crewGroup, _pos] spawn {
    params ["_veh", "_insertPos", "_passGrp", "_crewGrp", "_exitPos"];

    // Wait until vehicle reaches insertion point
    waitUntil {
        sleep 1;
        (_veh distance2D _insertPos < 25) || !alive _veh
    };

    if (!alive _veh) exitWith {};

    // Trigger vehicle to stop and wait until speed is below 5
    _veh limitSpeed 0;
    (driver _veh) doMove (getPos _veh);

    waitUntil {
        sleep 0.5;
        speed _veh < 5 || !alive _veh
    };
    if (!alive _veh) exitWith {};

    // Eject all passengers out of the vehicle
    {
        unassignVehicle _x;
        _x action ["Eject", _veh];
    } forEach units _passGrp;

    // Wait for passengers to get out
    waitUntil {
        sleep 1;
        {_x in _veh} count (units _passGrp) == 0
    };

    private _wpSad = _passGrp addWaypoint [_insertPos, 0];
    _wpSad setWaypointType "SAD";
    _wpSad setWaypointFormation "LINE";

    private _wpSad2 = _passGrp addWaypoint [_insertPos, 0];
    _wpSad2 setWaypointType "SAD";

    private _wpCycle = _passGrp addWaypoint [_insertPos, 0];
    _wpCycle setWaypointType "CYCLE";
    _wpCycle setWaypointFormation "LINE";

    // Remove speed limit and allow vehicle to move again
    sleep 0.5;
    _veh limitSpeed -1;

    // Clear vehicle waypoints
    while {count waypoints _crewGrp > 0} do {
        deleteWaypoint ((waypoints _crewGrp) select 0);
    };

    // Allow vehicle to exit to a custom location
    private _wpExit = _crewGrp addWaypoint [_exitPos, 0];
    _wpExit setWaypointType "MOVE";

    // Remove vehicle once it has reached it's exit destination
    [_veh, _exitPos] spawn {
        params ["_vehicle", "_exit"];

        waitUntil {
            sleep 5;
            (_vehicle distance2D _exit < 100) || !alive _vehicle
        };

        sleep 10;
        {deleteVehicle _x} forEach crew _vehicle;
        deleteVehicle _vehicle;
    };
};