missionNamespace setVariable ["activeMarkers", []];

missionNamespace setVariable ["casAvailable", true, true];

[] spawn Shared_fnc_respawnInit;

[] call Shared_fnc_whitelistArsenal;
