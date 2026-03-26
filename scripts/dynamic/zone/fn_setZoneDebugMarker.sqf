// Updates zone debug marker position/state when debug mode is enabled.
params ["_debugMarkerName", "_spawnCenter", "_color", "_alpha"];

if (debugMode && _debugMarkerName != "") then {
	_debugMarkerName setMarkerPos _spawnCenter;
	_debugMarkerName setMarkerColor _color;
	_debugMarkerName setMarkerAlpha _alpha;
};

true;
