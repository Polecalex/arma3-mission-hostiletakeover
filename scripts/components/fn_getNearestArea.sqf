params ["_marker"];

private _pos = getMarkerPos _marker;
private _locationName = _marker;

// Locate nearest City, Village, City Capital or Local area within 2000m
private _nearestCities = nearestLocations [_pos, [
    "NameCity",
    "NameVillage",
    "NameCityCapital",
    "NameLocal"
], 2000];

if (count _nearestCities > 0) then {
    _locationName = text (_nearestCities select 0);
};

_locationName;