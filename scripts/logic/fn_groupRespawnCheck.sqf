params ["_group", "_spawnType", "_areaName", "_areaRadius"];

// Wait before checking
sleep 30;

// Check if group is dead or has too few members
if (({alive _x} count units _group) == 0 || {alive _x} count units _group < 2) then {
    
    private _areaPos = getMarkerPos _areaName;
    private _newSpawnPos = [_areaPos, random _areaRadius, random 360] call BIS_fnc_relPos;
    _newSpawnPos = [_newSpawnPos, 0, 50, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
    
    // Delete any remaining units
    {deleteVehicle _x} forEach units _group;
    deleteGroup _group;
    
    // Respawn based on type
    if (_spawnType == "garrison") then {
        private _newGroup = createGroup [east, true];
        private _groupSize = 3 + floor random 4;
        
        for "_j" from 1 to _groupSize do {
            _newGroup createUnit ["O_Soldier_F", _newSpawnPos, [], 5, "NONE"];
        };
        
        [_newGroup] spawn {
            params ["_grp"];
            sleep 2;
            
            private _leaderPos = getPos leader _grp;
            private _buildings = nearestObjects [_leaderPos, ["House", "Building"], 80];
            _buildings = _buildings select {count (_x buildingPos -1) > 0};
            
            private _units = units _grp;
            private _buildingIndex = 0;
            
            {
                private _unit = _x;
                
                if (_buildingIndex < count _buildings) then {
                    private _building = _buildings select _buildingIndex;
                    private _positions = _building buildingPos -1;
                    
                    if (count _positions > 0) then {
                        private _buildingPos = selectRandom _positions;
                        _unit setPosATL _buildingPos;
                        _unit setDir (random 360);
                        _unit setUnitPos "MIDDLE";
                        doStop _unit;
                        
                        if ((random 1) > 0.5) then {
                            _buildingIndex = _buildingIndex + 1;
                        };
                    };
                };
            } forEach _units;
            
            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
        };
        
        systemChat "Garrison group respawned";
        
    } else {
        // Patrol group respawn
        private _newGroup = createGroup [east, true];
        private _groupSize = 2 + floor random 4;
        
        for "_j" from 1 to _groupSize do {
            _newGroup createUnit ["O_Soldier_F", _newSpawnPos, [], 3, "NONE"];
        };
        
        for "_w" from 0 to (4 + floor random 4) do {
            private _wpPos = [_areaPos, random _areaRadius, random 360] call BIS_fnc_relPos;
            _wpPos = [_wpPos, 0, 30, 2, 0, 0.5, 0] call BIS_fnc_findSafePos;
            
            private _wp = _newGroup addWaypoint [_wpPos, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "LIMITED";
            _wp setWaypointBehaviour "SAFE";
            _wp setWaypointFormation "COLUMN";
            _wp setWaypointCompletionRadius 15;
            
            if (random 1 > 0.7) then {
                _wp setWaypointTimeout [10, 15, 20];
            };
        };
        
        private _wpCycle = _newGroup addWaypoint [_newSpawnPos, 0];
        _wpCycle setWaypointType "CYCLE";
        
        _newGroup setBehaviour "SAFE";
        
        systemChat "Patrol group respawned";
    };
};