// Same here for group notification
//[
//    "ReinforcementWarning",
    //["<t color='#FFFFFF'>Your position has been compromised.<br/>Destroy the communications relay before reinforcements are called.</t>"]
//    ["<t color='#FFFFFF'>Enemy are aware of your position.<br/>Destroy the comms relay!</t>"]
//] remoteExec ["BIS_fnc_showNotification", 0, true];

// Show subtitle at bottom of screen
//[
//    "HQ",
//    "All elements, enemy comms activity detected. Destroy that relay."
//] remoteExec ["BIS_fnc_showSubtitle", 0];

// Type text on screen, letter by letter
// [
//    ["HQ", "<t align='left'>Destroy relay before transmission completes.</t>"]
// ] remoteExec ["BIS_fnc_typeText", _targets];

// Player audio message to radio
//[
//    west,
//    "HQ",
//    "All elements, enemy comms activity detected. Destroy that relay."
//] remoteExec ["sideRadio", _targets];

// Show notification to player
//[
//    "PresenceDetected",
//    ["<t color='#FFFFFF'>Increased radio traffic suggests iminent reinforcements.</t>"]
//] remoteExec ["BIS_fnc_showNotification", _targets];



addMissionEventHandler ["EntityRespawned", {
    params ["_entity", "_corpse"];

    if !(isPlayer _entity) exitWith {};
    if (group _entity != group blufor_leader) exitWith {};

    [_entity] spawn {
        params ["_unit"];

        waitUntil { alive _unit && !isNull (group _unit) };

        // Get all vehicles occupied by the group
        private _groupUnits = units group _unit;
        private _groupVehicles = (_groupUnits apply { vehicle _x }) select { _x != _unit };
        _groupVehicles = _groupVehicles arrayIntersect _groupVehicles;

        // If nobody is in a vehicle, do nothing
        if (count _groupVehicles == 0) exitWith {};

        // Group is in a vehicle, handle parachute if needed
        private _parachute = vehicle _unit;
        if (_parachute != _unit && (typeOf _parachute isKindOf "ParachuteBase")) then {
            _unit setVehiclePosition [getPos _parachute, [], 0, "NONE"];
            deleteVehicle _parachute;
        };

        private _nearestVehicle = _groupVehicles select 0;

        _unit moveInCargo _nearestVehicle;

        if (vehicle _unit != _nearestVehicle) then {
            _unit moveInGunner _nearestVehicle;
        };

        if (vehicle _unit != _nearestVehicle) then {
            _unit moveInDriver _nearestVehicle;
        };

        if (vehicle _unit != _nearestVehicle) then {
            hint "Could not enter vehicle - all seats full";
        } else {
            hint "Boarded vehicle successfully";
        };
    };
}];