// Returns [spawnDistance, LOSDistance] using config values with shared fallbacks.
params [
	"_activationDistance",
	"_markerRadius"
];

private _areaCfg = missionConfigFile >> "CfgVariables" >> "Dynamic" >> "AreaOccupation";

// Shared fallbacks used by both startup and monitor logic when config keys are missing.
private _spawnDistanceMultiplierDefault = 3.1;
private _losDistanceMultiplierDefault = 4.5;
private _spawnDistanceMinDefault = 340;
private _losDistanceMinDefault = 580;

private _blockadeSpawnDistanceMultiplier = if (isNumber (_areaCfg >> "blockadeSpawnDistanceMultiplier")) then {
	getNumber (_areaCfg >> "blockadeSpawnDistanceMultiplier")
} else {
	_spawnDistanceMultiplierDefault
};

private _blockadeLOSDistanceMultiplier = if (isNumber (_areaCfg >> "blockadeLOSProbeDistanceMultiplier")) then {
	getNumber (_areaCfg >> "blockadeLOSProbeDistanceMultiplier")
} else {
	_losDistanceMultiplierDefault
};

private _blockadeSpawnDistanceMin = if (isNumber (_areaCfg >> "blockadeSpawnDistanceMin")) then {
	getNumber (_areaCfg >> "blockadeSpawnDistanceMin")
} else {
	_spawnDistanceMinDefault
};

private _blockadeLOSDistanceMin = if (isNumber (_areaCfg >> "blockadeLOSProbeDistanceMin")) then {
	getNumber (_areaCfg >> "blockadeLOSProbeDistanceMin")
} else {
	_losDistanceMinDefault
};

private _blockadeSpawnDistance = ((_activationDistance * _blockadeSpawnDistanceMultiplier) max (_markerRadius * 0.60)) max _blockadeSpawnDistanceMin;
private _blockadeLOSDistance = ((_activationDistance * _blockadeLOSDistanceMultiplier) max (_markerRadius * 0.90)) max _blockadeLOSDistanceMin;

[_blockadeSpawnDistance, _blockadeLOSDistance];
