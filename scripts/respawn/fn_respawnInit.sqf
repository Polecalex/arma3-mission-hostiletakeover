waitUntil {
    sleep 1;
    !isNil "blufor_leader" && !isNil "squad_respawn" && !isNull blufor_leader && !isNull squad_respawn
};

[group blufor_leader, squad_respawn] spawn Shared_fnc_respawn;

// Enables vehicle boarding if squad is in a vehicle
addMissionEventHandler ["EntityRespawned", {
    params ["_entity", "_corpse"];

    if !(isPlayer _entity) exitWith {};
    if (group _entity != group blufor_leader) exitWith {};

    [_entity] spawn Shared_fnc_boardVehicle;
}];