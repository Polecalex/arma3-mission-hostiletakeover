// list of blacklisted mods and partial mod classes to prevent mission-breaking mods from being used, which may cause desyncs or other issues.
private _blacklist = getArray (missionConfigFile >> "CfgVariables" >> "Misc" >> "Blacklist" >> "mods");
private _prefixes = getArray (missionConfigFile >> "CfgVariables" >> "Misc" >> "Blacklist" >> "prefixes");

if (isServer && (count _blacklist == 0 || count _prefixes == 0)) exitWith {};

waitUntil {
    time > 3 && !isNull player && !isNull (findDisplay 46)
};

// Search configClasses for blacklisted mods in CfgPatches
private _classes = ("true" configClasses (configFile >> "CfgPatches")) apply {
    configName _x
};

// Loop through CfgPatches' classes, locating class names that match blacklist entries or prefixes.
private _badAddons = _classes select {
    _y = _x;
    _blacklist find _y > -1 ||
    _prefixes findIf {
        _x find _y > -1
    } > -1
};

// Print a report of detected addons to the player & End Mission if any blacklisted mods are detected.
if (count _badAddons > 0) then {
    private _blacklistMsg = ("Bad Addons Detected: " + (_badAddons joinString ", "));
    [_blacklistMsg] call BIS_fnc_error;
    hintC _blacklistMsg;
    ["end2"] call BIS_fnc_endMission;
};