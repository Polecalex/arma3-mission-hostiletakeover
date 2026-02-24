params ["_player"];

systemChat "Running cas action";

_player addAction [
    "<t color='#FFFFFF'>Request CAS Strike</t>",
    {
        hint "Click on the map to mark your CAS target...";
        openMap true;

        onMapSingleClick {
            // Get group units and their owners
            private _groupUnits = units group player;
            private _targets = _groupUnits apply {owner _x};
            _targets = _targets arrayIntersect _targets; // Remove duplicates

            // Create a disposable marker for all units within _player's group
            [_pos, "mil_destroy", "ColorRed", "CAS Target", 80] remoteExec ["Shared_fnc_disposableMarker", _targets];

            // Randomly select CAS audio and play it for all units within _player's group
            private _soundName = selectRandom ["CAS_HellOnEarth", "CAS_GiveEmHell", "CAS_Inbound"];
            [_soundName] remoteExec ["Shared_fnc_playLocalSound", _targets];

            // Execute Close Air Support script.
            [_pos] remoteExec ["Shared_fnc_requestCAS", 2];

            onMapSingleClick {};
            true
        };
    },
    [],
    1.5,
    true,
    true,
    "",
    "missionNamespace getVariable ['casAvailable', false]"
];