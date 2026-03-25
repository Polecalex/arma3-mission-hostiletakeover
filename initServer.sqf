// Event handler to catch when the specific player joins
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];

    private _name = "Polecalex";
    private _player = [_name] call Shared_fnc_getPlayer;

    if (!isNull _player && !isNull zeusModule) then {
        _player assignCurator zeusModule;
    };
}];

[] spawn {
    private _debugConfig = missionConfigFile >> "CfgVariables" >> "Misc" >> "Debug";

    if !((getNumber (_debugConfig >> "enabled")) > 0) exitWith {};
    if !((getNumber (_debugConfig >> "enableInvincibleConfiguredGroup")) > 0) exitWith {};

    private _groupVarName = getText (_debugConfig >> "invincibleGroupVarName");
    if (_groupVarName isEqualTo "") exitWith {};

    while { true } do {
        private _resolved = missionNamespace getVariable [_groupVarName, objNull];
        private _targetGroup = grpNull;

        if (_resolved isEqualType grpNull) then {
            _targetGroup = _resolved;
        } else {
            if (_resolved isEqualType objNull && {!isNull _resolved}) then {
                _targetGroup = group _resolved;
            };
        };

        if !(isNull _targetGroup) then {
            {
                if (alive _x) then {
                    [_x, false] remoteExecCall ["allowDamage", _x];
                };
            } forEach units _targetGroup;
        };

        sleep 2;
    };
};