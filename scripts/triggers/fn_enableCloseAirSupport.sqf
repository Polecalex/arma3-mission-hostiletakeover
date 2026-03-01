// Enables Close Air Support for group leader only
params ["_player"];

missionNamespace setVariable ["casAvailable", true, true];

// Display Notification to all players within group.
if (isServer) then {
    systemChat "Enabling CAS for leader";
};

// Enable Close Air Support action for player
[blufor_leader, "CloseAirSupport"] call BIS_fnc_addCommMenuItem;

private _group = group blufor_leader;
private _groupUnits = units _group;

// Identify the leader to exclude them (if they already know CAS is enabled)
private _leader = leader _group;
private _targets = _groupUnits - [_leader];

// Filter to only include players (AI don't need notifications)
_targets = _targets select {isPlayer _x};

if (count _targets > 0) then {
    [
        "SupportAvailable",
        ["<t color='#FFFFFF'>Close Air Support is now available in the area</t>"]
    ] remoteExec ["BIS_fnc_showNotification", _targets];
};