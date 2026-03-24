// Enables Close Air Support for either one player or all players in a group
params [["_target", objNull, [objNull, grpNull]]];

missionNamespace setVariable ["casAvailable", true, true];

private _targets = [];

if (_target isEqualType objNull) then {
    if (!isNull _target && {isPlayer _target}) then {
        _targets pushBack _target;
    };
};

if (_target isEqualType grpNull) then {
    if (!isNull _target) then {
        _targets = units _target select {isPlayer _x};
    };
};

// Add CAS comm menu item for each target player on their local client.
{
    [_x, "CloseAirSupport"] remoteExecCall ["BIS_fnc_addCommMenuItem", _x];
} forEach _targets;

if (debugMode) then {
    systemChat format ["[Support] CloseAirSupport Enabled for %1 targets", count _targets];
};

if (count _targets > 0) then {
    [
        "SupportAvailable",
        ["<t color='#FFFFFF'>Close Air Support is now available in the area</t>"]
    ] remoteExec ["BIS_fnc_showNotification", _targets];
};