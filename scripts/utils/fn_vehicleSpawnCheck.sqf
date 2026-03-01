params ["_vehicle", "_spawnMarker", "_radius"];

// Wait a bit for AI to start moving
sleep 15;

private _startPos = getPos _vehicle;

// Check again after 30 seconds
sleep 30;

// If vehicle hasn't moved much and isn't in combat, respawn it
if (alive _vehicle) then {
    private _currentPos = getPos _vehicle;
    private _distance = _startPos distance2D _currentPos;
    private _inCombat = behaviour (driver _vehicle) == "COMBAT";
    
    if (_distance < 20 && !_inCombat) then {
        private _group = group driver _vehicle;
        private _vehicleType = typeOf _vehicle;
        
        // Delete stuck vehicle
        {deleteVehicle _x} forEach crew _vehicle;
        deleteVehicle _vehicle;
        
        // Find new spawn position
        private _markerPos = getMarkerPos _spawnMarker;
        private _newSpawnPos = [_markerPos, random _radius, random 360] call BIS_fnc_relPos;
        private _roadPos = [_newSpawnPos, 100, []] call BIS_fnc_nearestRoad;
        
        if (!isNull _roadPos) then {
            _newSpawnPos = getPos _roadPos;
        } else {
            _newSpawnPos = [_newSpawnPos, 0, 100, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
        };
        
        // Spawn new vehicle
        private _newVehicle = createVehicle [_vehicleType, _newSpawnPos, [], 0, "NONE"];
        _newVehicle setDir (random 360);
        _newVehicle setVectorUp surfaceNormal position _newVehicle;
        
        createVehicleCrew _newVehicle;
        crew _newVehicle joinSilent _group;
        
        [_group, _markerPos, _radius] call BIS_fnc_taskPatrol;
        _group setBehaviour "SAFE";
        _group setSpeedMode "LIMITED";
        
        //systemChat format ["Stuck vehicle respawned at mission start"];
    };
};