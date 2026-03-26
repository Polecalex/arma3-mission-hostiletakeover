// Creates/updates blockade debug rings and applies spawned/pending colors.
params ["_blockadeMarker", "_blockadePos", "_blockadeSpawnDistance", "_blockadeLOSDistance", ["_isSpawned", false]];

private _spawnDebugName = format ["debug_blockade_spawn_%1", _blockadeMarker];
private _losDebugName = format ["debug_blockade_los_%1", _blockadeMarker];

createMarker [_spawnDebugName, _blockadePos];
createMarker [_losDebugName, _blockadePos];

_spawnDebugName setMarkerPos _blockadePos;
_spawnDebugName setMarkerSize [_blockadeSpawnDistance, _blockadeSpawnDistance];
_spawnDebugName setMarkerShape "ELLIPSE";
_spawnDebugName setMarkerBrush "SolidBorder";

_losDebugName setMarkerPos _blockadePos;
_losDebugName setMarkerSize [_blockadeLOSDistance, _blockadeLOSDistance];
_losDebugName setMarkerShape "ELLIPSE";
_losDebugName setMarkerBrush "Border";

if (_isSpawned) then {
	_spawnDebugName setMarkerColor "ColorGreen";
	_spawnDebugName setMarkerAlpha 0.45;
	_losDebugName setMarkerColor "ColorGreen";
	_losDebugName setMarkerAlpha 0.12;
} else {
	_spawnDebugName setMarkerColor "ColorOrange";
	_spawnDebugName setMarkerAlpha 0.35;
	_losDebugName setMarkerColor "ColorYellow";
	_losDebugName setMarkerAlpha 0.1;
};

true;
