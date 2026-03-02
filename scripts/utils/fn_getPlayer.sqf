params [["_targetName", ""]];

private _playerObj = objNull;

{
    if (name _x == _targetName) exitWith {
        _playerObj = _x;
    };
} forEach allPlayers;

_playerObj