private _whitelist = [];

private _fnc_addFromConfig = {
	params ["_category"];
	private _cfgCat = configFile >> _category;

	for "_i" from 0 to (count _cfgCat - 1) do {
		private _entry = _cfgCat select _i;

		        // Some entries in config trees are values (e.g. access=...) not classes.
		if (!isClass _entry) then {
			continue
		};

		private _classname = configName _entry;
		private _picture = getText (_entry >> "picture");
		private _model = getText (_entry >> "model");
		private _dlc = getText (_entry >> "dlc");

		if (
            _classname find "CUP_" == 0 ||
            _picture find "\CUP" == 0 ||
            _model find "\CUP" == 0 ||
            _dlc == "CUP"
		) then {
			_whitelist pushBackUnique _classname;
		};
	};
};

["CfgWeapons"] call _fnc_addFromConfig;
["CfgMagazines"] call _fnc_addFromConfig;
["CfgGlasses"] call _fnc_addFromConfig;
["CfgVehicles"] call _fnc_addFromConfig;

// Add whitelisted items to the virtual arsenal
// Vanilla requires adding categories separately, but BIS_fnc_addVirtualItemCargo
// is robust enough to handle most types if passed correctly.
[rhsusf_arsenal, _whitelist] call BIS_fnc_addVirtualItemCargo;
[rhsusf_arsenal, _whitelist] call BIS_fnc_addVirtualWeaponCargo;
[rhsusf_arsenal, _whitelist] call BIS_fnc_addVirtualMagazineCargo;
[rhsusf_arsenal, _whitelist] call BIS_fnc_addVirtualBackpackCargo;