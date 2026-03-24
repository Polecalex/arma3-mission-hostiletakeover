params [
    "_pos",
    "_type",
    ["_colour", "ColorRed"],
    ["_text", ""],
    ["_duration", 60]
];

// Creates a marker with a position, sets type, colour and texts with a unique name, 
private _markerName = "disposable_marker_" + _type + "_" + str(time);
private _marker = createMarker [_markerName, _pos];
_marker setMarkerType _type;
_marker setMarkerColor _colour;
_marker setMarkerText _text;

// Auto-delete after duration
[_marker, _duration] spawn {
    params ["_mkr", "_delay"];
    sleep _delay;
    deleteMarker _mkr;
};
