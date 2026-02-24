params [
    "_pos",
    "_type",
    ["_colour", "ColorRed"],
    ["_text", ""],
    ["_duration", 60]
];

// Create a unique marker name using type and time
private _markerName = "disposable_marker_" + _type + "_" + str(time);

// Creates the marker using unique name, position and sets type, colour and text
private _marker = createMarker [_markerName, _pos];
_marker setMarkerType _type;
_marker setMarkerColor _colour;
_marker setMarkerText _text;

// Adds marker to global activeMarkers array
private _activeMarkers = missionNamespace getVariable ["activeMarkers", []];
_activeMarkers pushBack _markerName;
missionNamespace setVariable ["activeMarkers", _activeMarkers];

// Auto-delete after duration
[_marker, _duration] spawn {
    params ["_mkr", "_delay"];
    sleep _delay;
    deleteMarker _mkr;

    // Remove it from the global array
    private _markers = missionNamespace getVariable ["activeMarkers", []];
    // Doesn't seem to like this at all...
    _markers = _markers - [_mkr];
    missionNamespace setVariable ["activeMarkers", _markers];
};
