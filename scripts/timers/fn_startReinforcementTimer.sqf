
params [
    "_relayObject",
    "_markerName",
    ["_duration", 15]
];

// Toggle reinforcementTimerActive
missionNamespace setVariable ["reinforcementTimerActive", true, true];

// private _targets = (units group player) apply {owner _x};
// _targets = _targets arrayIntersect _targets;

private _leader = missionNamespace getVariable ["blufor_leader", objNull];
private _group = group _leader;
private _groupUnits = units _group;
// private _targets = _groupUnits apply {owner _x};
// _targets = _targets arrayIntersect _targets; // Remove duplicates
_groupUnits = _groupUnits arrayIntersect _groupUnits;

[
    "HQ",
    "Increased radio traffic suggest imminent reinforcements, destroy the local communications relay to prevent transmission."
] remoteExecCall ["BIS_fnc_showSubtitle", _groupUnits];

sleep 2.5;

private _taskName = "destroyRelay_" + str time;
private _destroyRelayTask = [
    west,
    _taskName,
    [
        "Russian MSV forces operating in the AO have limited long-range communications but maintain a field relay capable of reaching higher command.<br/>
If the relay remains operational, they will be able to transmit a request for support and additional enemy units will deploy from nearby settlements.<br/>
Based off close range satelite positioning, we estimate transmission time to be 15 minutes.<br/>
Locate and destroy the communications relay before the transmission is completed to prevent reinforcements from entering the area.",
        "Disrupt Enemy Reinforcement Capability",
        ""
    ],
    objNull,
    "ASSIGNED"
] remoteExecCall ["BIS_fnc_taskCreate", _groupUnits];

// Initialise timer duration (duration * 60s - convert to minutes)
private _timerDuration = _duration * 60;
private _timeElapsed = 0;

// While timer is still active, increase _timerElapsed and check for _relayObject destruction
while {_timeElapsed < _timerDuration} do {
    sleep 1;
    _timeElapsed = _timeElapsed + 1;

    // Check if _relayObject is damaged, exit with notification if true
    if (!isNull _relayObject && {damage _relayObject >= 0.9}) exitWith {
        // Toggle timer variable
        missionNamespace setVariable [
            "reinforcementTimerActive",
            false,
            true
        ];

        [_taskName, "SUCCEEDED", true] call BIS_fnc_taskSetState;

        // Display destruction notification to all units within _leader's group
        [
            "CommsRelayDestroyed",
            ["<t color='#FFFFFF'>Communications relay has been destroyed, eliminate the remaining forces.</t>"]
        ] remoteExecCall ["BIS_fnc_showNotification", _groupUnits];
    };

    // Display count down for each player
    if (isServer) then {
        private _timeLeft = _timerDuration - _timeElapsed;
        private _minutes = floor(_timeLeft / 60);
        private _seconds = _timeLeft mod 60;
        private _timeString = format ["Reinforcements in %1:%2", _minutes, _seconds];
        if (_timeElapsed mod 5 == 0) then {
            systemChat _timeString;
        };
    };
};

// If reinforcementTimerActive is true, spawn reinforcements and toggle timer variable
if (missionNamespace getVariable ["reinforcementTimerActive", false]) then {
    [_taskName, _markerName, getPos _leader, 2] call Shared_fnc_spawnReinforcements;
    missionNamespace setVariable ["reinforcementTimerActive", false, true];
};
