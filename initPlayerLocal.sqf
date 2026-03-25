[] spawn Shared_fnc_modBlacklist;

[] spawn {
	waitUntil { uiSleep 0.5; !isNull player };
	disableSerialization;
	cutRsc ["HT_ActiveUnitsHUD", "PLAIN"];

	while { true } do {
		disableSerialization;

		private _display = uiNamespace getVariable ["HT_ActiveUnitsHUD", displayNull];
		if (isNull _display) then {
			cutRsc ["HT_ActiveUnitsHUD", "PLAIN"];
			_display = uiNamespace getVariable ["HT_ActiveUnitsHUD", displayNull];
		};

		if (!isNull _display) then {
			private _ctrl = _display displayCtrl 91001;
			if (!isNull _ctrl) then {
				private _activeEnemyUnits = {
					alive _x && (_x getVariable ["dynamic_isInfantryManaged", false])
				} count allUnits;

				private _plannedByArea = missionNamespace getVariable ["dynamic_plannedInfantryByArea", []];
				private _plannedMax = 0;
				{
					_plannedMax = _plannedMax + (_x param [2, 0]);
				} forEach _plannedByArea;

				private _activeGroupsArr = [];
				{
					if (alive _x && (_x getVariable ["dynamic_isInfantryManaged", false])) then {
						_activeGroupsArr pushBackUnique (group _x);
					};
				} forEach allUnits;
				private _activeGroupCount = count _activeGroupsArr;

				_ctrl ctrlSetStructuredText parseText format [
					"<t align='right' color='#FFFFFF' shadow='1'>Active Enemy Units: %1/%2</t><br/><t align='right' color='#D0D0D0' size='0.75' shadow='1'>Active Groups: %3</t>",
					_activeEnemyUnits,
					_plannedMax,
					_activeGroupCount
				];
			};
		};

		uiSleep 1;
	};
};

// Allow Zeus for host only
// if (isServer) then {
// 	zeusModule setVariable ["owner", player];
// };