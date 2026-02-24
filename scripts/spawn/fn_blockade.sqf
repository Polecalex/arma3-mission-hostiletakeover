params ["_blockadeMarkers"];

private _allGroups = [];

{
    private _markerName = _x;
    private _blockadePos = getMarkerPos _markerName;
    private _markerSize = getMarkerSize _markerName;
    private _radius = (_markerSize select 0) max (_markerSize select 1);
    private _markerArea = (_markerSize select 0) * (_markerSize select 1);

    // Dynamic group size based on area
    private _groupSize = ceil (_markerArea / 75);
    _groupSize = (_groupSize max 2) min 12;

    // Create Rifle group at blockade position
    private _group = [_blockadePos, "rifle"] call Shared_fnc_createSquad;

    // Guard waypoint - slight wandering
    private _wp = _group addWaypoint [_blockadePos, _radius * 0.6];
    _wp setWaypointType "GUARD";

    _allGroups pushBack _group;

} forEach _blockadeMarkers;

_allGroups;