missionNamespace setVariable ["activeMarkers", []];

// Default CAS Availability to false
missionNamespace setVariable ["casAvailable", false, true];

[] spawn Shared_fnc_respawnInit;

[] call Shared_fnc_whitelistArsenal;
