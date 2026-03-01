// Event handler to catch when the specific player joins
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];

    if (_name == "Polecalex") then {
        [] spawn {
            // Wait for the player object to exist and be ready
            waitUntil {
                private _playerObj = objNull;
                { if (name _x == "Polecalex") exitWith { _playerObj = _x; }; } forEach allPlayers;
                !isNull _playerObj
            };

            // Find the player object again to be safe and assign Zeus
            {
                if (name _x == "Polecalex") exitWith {
                    _x assignCurator zeusModule;
                    diag_log "[Zeus] Polecalex has joined and been assigned to zeusModule.";
                };
            } forEach allPlayers;
        };
    };
}];