private _infantryCfg = missionConfigFile >> "CfgVariables" >> "Squads" >> "Infantry";
private _rifleExpected = getArray (_infantryCfg >> "rifle");

private _fromDefault = [] call Shared_fnc_getSquadComposition;
[_fromDefault, _rifleExpected, "Default call should return rifle template"] call Shared_fnc_assertEqual;

private _fromEmpty = [""] call Shared_fnc_getSquadComposition;
[_fromEmpty, _rifleExpected, "Empty type should fallback to rifle"] call Shared_fnc_assertEqual;

private _fromCaseInsensitive = ["RIFLE"] call Shared_fnc_getSquadComposition;
[_fromCaseInsensitive, _rifleExpected, "Type match should be case-insensitive"] call Shared_fnc_assertEqual;

private _fromUnknown = ["doesnotexist"] call Shared_fnc_getSquadComposition;
[_fromUnknown, [], "Unknown type should return empty array"] call Shared_fnc_assertEqual;

true;
