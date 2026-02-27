params ["_pos"];

if !(missionNamespace getVariable ["casAvailable", false]) exitWith {
    hint "Close Air Support units are either deployed or returning to base.";
};

// Disable CAS to start cooldown
missionNamespace setVariable ["casAvailable", false, true];

hint "CAS Strike Requesting at marked position...";

// Get group units and their owners
private _groupUnits = units group blufor_leader;
private _targets = _groupUnits apply {owner _x};
_targets = _targets arrayIntersect _targets; // Remove duplicates

// Create a disposable marker for all units within _player's group
[_pos, "mil_destroy", "ColorRed", "CAS Target", 80] remoteExec ["Shared_fnc_disposableMarker", _targets];

// Randomly select CAS audio and play it for all units within _player's group
private _soundName = selectRandom ["CAS_HellOnEarth", "CAS_GiveEmHell", "CAS_Inbound"];
[_soundName] remoteExec ["Shared_fnc_playLocalSound", _targets];

// Execute Close Air Support script.
[_pos] remoteExec ["Shared_fnc_requestCAS", 2];

// Cooldown Logic (5 Minutes)
[] spawn {
    private _cooldown = getNumber (missionConfigFile >> "CfgVariables" >> "CAS" >> "cooldown");
    sleep _cooldown; // Cooldown in seconds

    // Re-enable CAS globally
    missionNamespace setVariable ["casAvailable", true, true];

    // Notify the group that support is back online
    private _groupUnits = units group blufor_leader;
    private _targets = _groupUnits apply {owner _x};
    _targets = _targets arrayIntersect _targets;

    [
        "SupportAvailable",
        ["<t color='#FFFFFF'>Close Air Support has resupplied and is available again.</t>"]
    ] remoteExec ["BIS_fnc_showNotification", _targets];
};