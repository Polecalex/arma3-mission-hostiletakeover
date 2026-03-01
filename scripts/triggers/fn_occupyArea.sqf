params ["_marker", ["_blockadeMarkers", []], ["_vehiclePatrols", 0], ["_density", "medium"]];

private _divisor = switch (_density) do {
    case "light": {2000 + random 500};    // ~80-100 soldiers
    case "medium": {1200 + random 400};   // ~125-167 soldiers
    case "heavy": {1000 + random 200};     // ~200-250 soldiers
    case "vheavy": {800 + random 200};    // ~250-333 soldiers
    default {1200 + random 400};
};

private _allGroups = [];

private _markerPos = getMarkerPos _marker;
private _markerSize = getMarkerSize _marker;
private _markerRadius = (_markerSize select 0) max (_markerSize select 1);
private _markerArea = (_markerSize select 0) * (_markerSize select 1);

// Calculate total infantry based on area and desity setting
private _totalInfantry = ceil (_markerArea / _divisor);
_totalInfantry = (_totalInfantry max 4) min 350; // Between 4-350 infantry

// Get nearest area name if marker text is blank
private _locationName = markerText _marker;

if (_locationName == "") then {
    _locationName = [_marker] call Shared_fnc_getNearestArea;
};

if (isServer) then {
    systemChat format ["%1 area: %2m², spawning %3 infantry total", _locationName, floor _markerArea, _totalInfantry];
};


// Spawn garrison groups (75% of infantry)
private _garrisonCount = floor (_totalInfantry * 0.75);
private _garrisonGroups = [_marker, _markerPos, _markerRadius, _garrisonCount] call Shared_fnc_garrison;
_allGroups append _garrisonGroups;

// Spawn patrol groups (25% of infantry)
private _patrolCount = _totalInfantry - _garrisonCount;
private _patrolGroups = [_marker, _markerPos, _markerRadius, _patrolCount] call Shared_fnc_patrol;
_allGroups append _patrolGroups;

// Spawn vehicle patrols - scale by area, minimum area threshold
if (_markerArea > 75000) then { // Only if area is larger than 75,000 sq meters (~100m radius)
    private _maxVehicleCount = ceil (_markerArea / 75000); // 1 vehicle per 75k sq meters
    _maxVehicleCount = (_maxVehicleCount max 1) min 6; // Between 1-6 vehicles

    // Use specified count or auto-calculated, whichever is higher
    private _finalVehicleCount = _vehiclePatrols max _maxVehicleCount;

    private _vehicleGroups = [_marker, _markerPos, _markerRadius, _finalVehicleCount] call Shared_fnc_vehiclePatrol;
    _allGroups append _vehicleGroups;
};

// Spawn blockade defenders
if (count _blockadeMarkers > 0) then {
    private _blockadeGroups = [_blockadeMarkers] call Shared_fnc_blockade;
    _allGroups append _blockadeGroups;
};

_allGroups;