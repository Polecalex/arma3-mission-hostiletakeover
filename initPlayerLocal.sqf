[] spawn {
	if (isServer) exitWith {};

	waitUntil {
		time > 3 && !isNull player && !isNull (findDisplay 46)
	};

	private _blacklist = getArray (missionConfigFile >> "CfgVariables" >> "Misc" >> "Blacklist" >> "mods");

	// List of partial mod classes when a mod has a lot of PBO's but a normalized nominclature
	private _prefixes = getArray (missionConfigFile >> "CfgVariables" >> "Misc" >> "Blacklist" >> "prefixes");

	// Search configClasses for blacklisted mods in CfgPatches
	private _classes = ("true" configClasses (configFile >> "CfgPatches")) apply {
		configName _x
	};
	private _badAddons = _classes select {
		_y = _x;
		_blacklist find _y > -1 ||
		_prefixes findIf {
			_x find _y > -1
		} > -1
	};

	if (count _badAddons > 0) then {
		// Print a report of detected addons to the player & End Mission
		private _kickString = ("Bad Addons Detected: " + (_badAddons joinString ", "));
		systemChat _kickString;
		hintC _kickString;
		endMission "end2";
	};
};

// Allow Zeus for host only
if (isServer) then {
	zeusModule setVariable ["owner", player];
};