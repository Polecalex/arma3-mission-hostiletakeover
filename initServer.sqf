// Event handler to catch when the specific player joins
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];

    private _name = "Polecalex";
    private _player = [_name] call Shared_fnc_getPlayer;

    if (!isNull _player && !isNull zeusModule) then {
        _player assignCurator zeusModule;
    };
}];