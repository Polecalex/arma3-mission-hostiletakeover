params ["_pos", "_vehicle", "_squadType", ["_vehicleCount", 1]];

private _vehicleType = getText (missionConfigFile >> "CfgVariables" >> "Units" >> toLower _vehicle);

private _allCrewGroups = [];
private _allPassengerGroups = [];
private _allVehicles = [];

for "_i" from 1 to _vehicleCount do {
    // Offset spawn position slightly for multiple vehicles
    private _spawnOffset = [_pos, _i * 15, random 360] call BIS_fnc_relPos;
    
    // Create vehicle
    private _vehicle = createVehicle [_vehicleType, _spawnOffset, [], 0, "NONE"];
    _vehicle setDir (random 360);
    
    // Create vehicle crew (driver)
    private _crewGroup = createGroup [east, true];
    private _driver = _crewGroup createUnit ["O_Soldier_F", _spawnOffset, [], 0, "NONE"];
    _driver moveInDriver _vehicle;
    
    // Create Rifle squad and move into cargo
    private _passengerGroup = [_spawnOffset, _squadType] call Shared_fnc_createSquad;
    {
        _x assignAsCargo _vehicle;
        _x moveInCargo _vehicle;
    } forEach units _passengerGroup;
    
    _allCrewGroups pushBack _crewGroup;
    _allPassengerGroups pushBack _passengerGroup;
    _allVehicles pushBack _vehicle;
};

[_allCrewGroups, _allPassengerGroups, _allVehicles];