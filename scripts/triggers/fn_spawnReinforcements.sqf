params ["_taskName", "_markerName", "_target", ["_vehicleCount", 2]];

private _vehicleType = getText (missionConfigFile >> "CfgVariables" >> "Units" >> "Transport" >> "standard");

private _insertionPos = if (typeName _target == "OBJECT") then {
    getPos _target
} else {
    _target  // Already a position
};

private _pos = getMarkerPos _markerName;

[_taskName, "FAILED", true] call BIS_fnc_taskSetState;

// Create multiple transports vehicles with squads
([_pos, "Transport", "rifle", _vehicleCount] call Shared_fnc_vehicleReinforcements) params ["_allCrewGroups", "_allPassengerGroups", "_allVehicles"];

// Process each vehicle
{
    private _crewGroup = _allCrewGroups select _forEachIndex;
    private _passengerGroup = _allPassengerGroups select _forEachIndex;
    private _vehicle = _x;

    // Add waypoint to insertion point
    private _wp = _crewGroup addWaypoint [_insertionPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    _wp setWaypointFormation "COLUMN";

    // Monitor and unload for each vehicle
    [_vehicle, _insertionPos, _passengerGroup, _crewGroup, _pos] spawn {
        params ["_veh", "_insertPos", "_passGrp", "_crewGrp", "_exitPos"];

        // Wait until vehicle reaches insertion point
        waitUntil {
            sleep 0.5;
            (_veh distance2D _insertPos < 50) || !alive _veh
        };

        if (!alive _veh) exitWith {};

        // Stop the vehicle
        _veh limitSpeed 0;
        (driver _veh) doMove (getPos _veh);

        waitUntil {
            sleep 0.5;
            speed _veh < 1 || !alive _veh
        };

        if (!alive _veh) exitWith {};

        systemChat format ["Vehicle %1 reached insertion point - unloading troops", _veh];

        // Unload all passengers
        {
            private _unit = _x;
            unassignVehicle _unit;
            _unit action ["GetOut", _veh];

            private _scatterPos = [getPos _veh, 15 + random 10, random 360] call BIS_fnc_relPos;
            _unit commandMove _scatterPos;
        } forEach units _passGrp;

        private _wpSad = _passGrp addWaypoint [_insertPos, 0];
        _wpSad setWaypointType "SAD";
        _wpMove setWaypointFormation "FILE";

        private _wpCycle = _passGrp addWaypoint [_insertPos, 0];
        _wpCycle setWaypointType "CYCLE";

        waitUntil {
            sleep 1;
            private _tooClose = {_x distance2D _veh < 10} count units _passGrp;
            _tooClose == 0
        };

        systemChat format ["Vehicle %1: All passengers disembarked", _veh];

        // Remove speed limit and allow vehicle to move again
        _veh limitSpeed -1;

        // Clear crew waypoints and send vehicle away
        while {count waypoints _crewGrp > 0} do {
            deleteWaypoint ((waypoints _crewGrp) select 0);
        };

        // Vehicle exits
        private _wpExit = _crewGrp addWaypoint [_exitPos, 0];
        _wpExit setWaypointType "MOVE";
        _wpExit setWaypointSpeed "NORMAL";

        systemChat format ["Vehicle %1 departing insertion zone", _veh];

        // Optional: Delete vehicle after it leaves
        [_veh, _exitPos] spawn {
            params ["_vehicle", "_exit"];

            waitUntil {
                sleep 5;
                (_vehicle distance2D _exit < 100) || !alive _vehicle
            };

            sleep 10;
            {deleteVehicle _x} forEach crew _vehicle;
            deleteVehicle _vehicle;

            systemChat format ["Vehicle %1 removed", _vehicle];
        };
    };
} forEach _allVehicles;

// Optional: Combine all passenger groups into one for coordinated attack
/*
private _combinedGroup = _allPassengerGroups select 0;
for "_i" from 1 to (count _allPassengerGroups - 1) do {
    private _grp = _allPassengerGroups select _i;
    {
        [_x] joinSilent _combinedGroup;
    } forEach units _grp;
};
*/