debugOptions = missionConfigFile >> "CfgVariables" >> "Misc" >> "Debug";
debugMode = getNumber (debugOptions >> "enabled") > 0;

dcon_garage_whitelist = [];
dcon_garage_blacklist = [];

missionNamespace setVariable ["casAvailable", false, true];

[] spawn Shared_fnc_respawnInit;
[] call Shared_fnc_whitelistArsenal;