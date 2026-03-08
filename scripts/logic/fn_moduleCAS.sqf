_logic = _this select 0;
_units = _this select 1;
_activated = _this select 2;

// --- Terminate on client (unless it's curator who created the module)
if (!isServer && {
	local _x
} count (objectCurators _logic) == 0) exitWith {};

if (_activated) then {
	// --- Wait for params to be set
	if (_logic call BIS_fnc_isCuratorEditable) then {
		waitUntil {
			!isNil {
				_logic getvariable "vehicle"
			} || isNull _logic
		};
	};
	if (isNull _logic) exitWith {};

	// --- Show decal
	if ({
		local _x
	} count (objectCurators _logic) > 0) then {
		// --- reveal the circle to curators
		_logic hideObject false;
		_logic setPos position _logic;
	};
	if !(isServer) exitWith {};

	_planeClass = _logic getvariable ["vehicle", "B_Plane_CAS_01_F"];
	_planeCfg = configfile >> "cfgvehicles" >> _planeClass;
	if !(isClass _planeCfg) exitWith {
		["Vehicle class '%1' not found", _planeClass] call BIS_fnc_error;
		false
	};

	// --- Restore custom direction
	_dirVar = _fnc_scriptname + typeOf _logic;
	_logic setDir (missionNamespace getVariable [_dirVar, direction _logic]);

	// --- Detect gun
	_weaponTypesID = _logic getvariable ["type", getnumber (configfile >> "cfgvehicles" >> typeof _logic >> "moduleCAStype")];
	_weaponTypes = switch _weaponTypesID do {
		case 0: {
			["machinegun", "vehicleweapon"]
		};
		case 1: {
			["missilelauncher"]
		};
		case 2: {
			["machinegun", "missilelauncher", "vehicleweapon"]
		};
		case 3: {
			["bomblauncher"]
		};
		default {
			[]
		};
	};
	_weapons = [];
	{
		if (toLower ((_x call BIS_fnc_itemType) select 1) in _weaponTypes) then {
			_modes = getarray (configfile >> "cfgweapons" >> _x >> "modes");
			if (count _modes > 0) then {
				_mode = _modes select 0;
				if (_mode == "this") then {
					_mode = _x;
				};
				_weapons set [count _weapons, [_x, _mode]];
			};
		};
	} foreach (_planeClass call bis_fnc_weaponsEntityType);// getarray (_planeCfg >> "weapons");

	if (count _weapons == 0) exitWith {
		["No weapon of types %2 wound on '%1'", _planeClass, _weaponTypes] call BIS_fnc_error;
		false
	};

	_posATL = getPosATL _logic;
	_pos = +_posATL;
	_pos set [2, (_pos select 2) + getTerrainHeightASL _pos];
	_dir = direction _logic;

	_dis = 3000;
	_alt = 1000;
	_pitch = atan (_alt / _dis);
	_speed = 400 / 3.6;
	_duration = ([0, 0] distance [_dis, _alt]) / _speed;

	// --- Create plane
	_planePos = [_pos, _dis, _dir + 180] call BIS_fnc_relPos;
	_planePos set [2, (_pos select 2) + _alt];
	_planeSide = (getnumber (_planeCfg >> "side")) call BIS_fnc_sideType;
	_planeArray = [_planePos, _dir, _planeClass, _planeSide] call BIS_fnc_spawnVehicle;
	_plane = _planeArray select 0;
	_plane setPosASL _planePos;
	// This is the spawned plane object, use it directly
	removeAllWeapons _plane;

	// Clear all pylons
	{
		_plane removeMagazine _x;
	} forEach (getPylonMagazines _plane);

	{
		if (toLower ((_x call BIS_fnc_itemType) select 1) == "countermeasureslauncher") then {
			_plane removeWeapon _x;
		};
	} forEach (weapons _plane);

	// Re-add only the GAU-8
	_plane addWeapon "CUP_Vacannon_GAU8_veh";
	_plane addMagazine "CUP_1350Rnd_TE1_Red_Tracer_30mm_GAU8_M";

	systemChat format ["Weapons after cleanup: %1", weapons _plane];
	systemChat format ["Pylons after cleanup: %1", getPylonMagazines _plane];

	_plane move ([_pos, _dis, _dir] call BIS_fnc_relPos);
	_plane disableai "move";
	_plane disableai "target";
	_plane disableai "autotarget";
	_plane setcombatmode "blue";

	_vectorDir = [_planePos, _pos] call BIS_fnc_vectorFromXToY;
	_velocity = [_vectorDir, _speed] call BIS_fnc_vectorMultiply;
	_plane setVectorDir _vectorDir;
	[_plane, -90 + atan (_dis / _alt), 0] call BIS_fnc_setPitchBank;
	_vectorUp = vectorUp _plane;

	// --- Remove all other weapons;
	_currentWeapons = weapons _plane;
	{
		if !(tolower ((_x call bis_fnc_itemType) select 1) in (_weaponTypes + ["countermeasureslauncher"])) then {
			_plane removeWeapon _x;
		};
	} forEach _currentWeapons;

	// --- Cam shake
	_ehFired = _plane addEventHandler [
		"fired",
		{
			_this spawn {
				_plane = _this select 0;
				_plane removeeventhandler ["fired", _plane getvariable ["ehFired", -1]];
				_projectile = _this select 6;
				waitUntil {
					isNull _projectile
				};
				[[0.005, 4, [_plane getvariable ["logic", objnull], 200]], "bis_fnc_shakeCuratorCamera"] call BIS_fnc_MP;
			};
		}
	];
	_plane setvariable ["ehFired", _ehFired];
	_plane setvariable ["logic", _logic];
	_logic setvariable ["plane", _plane];

	// --- Show hint
	[[["Curator", "PlaceOrdnance"], nil, nil, nil, nil, nil, nil, true], "bis_fnc_advHint", objectCurators _logic] call BIS_fnc_MP;

	// --- Play radio
	[_plane, "CuratorModuleCAS"] call BIS_fnc_curatorSayMessage;

	// --- Debug - visualize tracers
	if (false) then {
		BIS_draw3d = [];
		{
			deleteMarker _x
		} forEach allMapMarkers;
		_m = createMarker [str _logic, _pos];
		_m setmarkertype "mil_dot";
		_m setMarkerSize [1, 1];
		_m setmarkercolor "colorgreen";
		_plane addEventHandler [
			"fired",
			{
				_projectile = _this select 6;
				[_projectile, position _projectile] spawn {
					_projectile = _this select 0;
					_posStart = _this select 1;
					_posEnd = _posStart;
					_m = str _projectile;
					_mColor = "colorred";
					_color = [1, 0, 0, 1];
					if (speed _projectile < 1000) then {
						_mColor = "colorblue";
						_color = [0, 0, 1, 1];
					};
					while { !isNull _projectile } do {
						_posEnd = position _projectile;
						sleep 0.01;
					};
					createMarker [_m, _posEnd];
					_m setmarkertype "mil_dot";
					_m setMarkerSize [1, 1];
					_m setMarkerColor _mColor;
					BIS_draw3d set [count BIS_draw3d, [_posStart, _posEnd, _color]];
				};
			}
		];
		if (isnil "BIS_draw3Dhandler") then {
			BIS_draw3Dhandler = addmissioneventhandler ["draw3d", {
				{
					drawLine3D _x;
				} foreach (missionnamespace getvariable ["BIS_draw3d", []]);
			}];
		};
	};

	// --- Approach
	_fire = [] spawn {
		waitUntil {
			false
		}
	};
	_fireNull = true;
	_time = time;
	_offset = if ({
		_x == "missilelauncher"
	} count _weaponTypes > 0) then {
		20
	} else {
		0
	};
	waitUntil {
		_fireProgress = _plane getvariable ["fireProgress", 0];

		// --- Update plane position when module was moved / rotated
		if ((getPosATL _logic distance _posATL > 0 || direction _logic != _dir) && _fireProgress == 0) then {
			_posATL = getPosATL _logic;
			_pos = +_posATL;
			_pos set [2, (_pos select 2) + getTerrainHeightASL _pos];
			_dir = direction _logic;
			missionNamespace setVariable [_dirVar, _dir];

			_planePos = [_pos, _dis, _dir + 180] call BIS_fnc_relPos;
			_planePos set [2, (_pos select 2) + _alt];
			_vectorDir = [_planePos, _pos] call BIS_fnc_vectorFromXToY;
			_velocity = [_vectorDir, _speed] call BIS_fnc_vectorMultiply;
			_plane setVectorDir _vectorDir;
			// [_plane, -90 + atan (_dis / _alt), 0] call BIS_fnc_setPitchBank;
			_vectorUp = vectorUp _plane;

			_plane move ([_pos, _dis, _dir] call BIS_fnc_relPos);
		};

		// --- set the plane approach vector
		_plane setVelocityTransformation [
			_planePos, [_pos select 0, _pos select 1, (_pos select 2) + _offset + _fireProgress * 12],
			_velocity, _velocity,
			_vectorDir, _vectorDir,
			_vectorUp, _vectorUp,
			(time - _time) / _duration
		];
		_plane setVelocity velocity _plane;

		// --- fire!
		if ((getPosASL _plane) distance _pos < 1000 && _fireNull) then {
			// --- Create laser target
			private _targetType = if (_planeSide getFriend west > 0.6) then {
				"LaserTargetW"
			} else {
				"LaserTargetE"
			};
			_target = ((position _logic nearEntities [_targetType, 250])) param [0, objNull];
			if (isNull _target) then {
				_target = createvehicle [_targetType, position _logic, [], 0, "none"];
			};
			_plane reveal laserTarget _target;
			_plane doWatch laserTarget _target;
			_plane doTarget laserTarget _target;

			_fireNull = false;
			terminate _fire;
			_fire = [_plane, _weapons, _target, _weaponTypesID] spawn {
				_plane = _this select 0;
				_planeDriver = driver _plane;
				_weapons = _this select 1;
				_target = _this select 2;
				_weaponTypesID = _this select 3;
				_duration = 3;
				_time = time + _duration;
				waitUntil {
					{
						// _plane selectWeapon (_x select 0);
						// _planeDriver forceWeaponFire _x;
						_planeDriver fireAtTarget [_target, (_x select 0)];
					} forEach _weapons;
					_plane setvariable ["fireProgress", (1 - ((_time - time) / _duration)) max 0 min 1];
					sleep 0.1;
					time > _time || _weaponTypesID == 3 || isNull _plane// --- Shoot only for specific period or only one bomb
				};
				sleep 1;
			};
		};

		sleep 0.01;
		scriptDone _fire || isNull _logic || isNull _plane
	};
	_plane setVelocity velocity _plane;
	_plane flyInHeight _alt;

	// --- fire CM
	if ({
		_x == "bomblauncher"
	} count _weaponTypes == 0) then {
		for "_i" from 0 to 1 do {
			driver _plane forceweaponfire ["CMFlareLauncher", "Burst"];
			_time = time + 1.1;
			waitUntil {
				time > _time || isNull _logic || isNull _plane
			};
		};
	};

	if !(isNull _logic) then {
		sleep 1;
		deleteVehicle _logic;
		waitUntil {
			_plane distance _pos > _dis || !alive _plane
		};
	};

	// --- Delete plane
	if (alive _plane) then {
		_group = group _plane;
		_crew = crew _plane;
		deleteVehicle _plane;
		{
			deleteVehicle _x
		} forEach _crew;
		deleteGroup _group;
	};
};