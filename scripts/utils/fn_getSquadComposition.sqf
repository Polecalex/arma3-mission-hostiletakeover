params [["_type", "rifle", [""]]];

if (_type isEqualTo "") then {
    _type = "rifle";
};

private _infantryCfg = missionConfigFile >> "CfgVariables" >> "Squads" >> "Infantry";

private _availableSquads = (configProperties [_infantryCfg, "isArray _x", false]) apply {
    configName _x
};

private _matchingSquads = _availableSquads select {
    toLower _x isEqualTo toLower _type
};

if (count _matchingSquads == 0) exitWith {
    []
};

getArray (_infantryCfg >> (_matchingSquads select 0));