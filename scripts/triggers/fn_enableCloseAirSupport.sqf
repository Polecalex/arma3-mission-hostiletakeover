params ["_player"];

// Enable Close Air Support for group leader only
// Display Notification to all players within group.

systemChat "Enabling CAS for leader";
// Enable Close Air Support action for player
[_player] call Shared_fnc_closeAirSupport;

private _groupUnits = units group player;
private _targets = _groupUnits apply {owner _x};
_targets = _targets arrayIntersect _targets; // Remove duplicates

[
    "SupportAvailable",
    ["<t color='#FFFFFF'>Close Air Support is now available in the area</t>"]
] remoteExec ["BIS_fnc_showNotification", _targets, true];