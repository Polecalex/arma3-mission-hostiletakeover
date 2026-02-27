// Enables Close Air Support for group leader only
params ["_player"];

missionNamespace setVariable ["casAvailable", true, true];

// Display Notification to all players within group.
systemChat "Enabling CAS for leader";

// Enable Close Air Support action for player
[_player, "CloseAirSupport"] call BIS_fnc_addCommMenuItem;

private _groupUnits = units group _player;
private _leader = owner (leader group _player);
private _targets = _groupUnits apply {owner _x};
_targets = (_targets arrayIntersect _targets) - [_leader]; // Remove duplicates

[
    "SupportAvailable",
    ["<t color='#FFFFFF'>Close Air Support is now available in the area</t>"]
] remoteExec ["BIS_fnc_showNotification", _targets, true];