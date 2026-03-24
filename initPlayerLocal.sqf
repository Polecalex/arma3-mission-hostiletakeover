[] spawn Shared_fnc_modBlacklist;

// Allow Zeus for host only
if (isServer) then {
	zeusModule setVariable ["owner", player];
};