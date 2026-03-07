/*
	    dynamic_fnc_calcUnitCount
	    Returns the total number of infantry to spawn for a given area and density.
	
	    Parameters:
	        _markerArea - Area of the marker in m²
	        _density    - "light" | "medium" | "heavy" | "vheavy"
	
	    Returns: Integer unit count (clamped 4–150)
*/

params ["_markerArea", ["_density", "medium"]];

private _base = (_markerArea / 10000) min 9;

private _count = switch (_density) do {
	case "light": {
		floor (_base * 0.5)
	};  // max ~4 groups  (~4-32 units)
	case "medium": {
		floor (_base * 1.0)
	};  // max ~9 groups  (~9-72 units)
	case "heavy": {
		floor (_base * 1.5)
	};  // max ~13 groups (~13-104 units)
	case "vheavy": {
		floor (_base * 2.0)
	};  // max ~18 groups (~18-144 units, ~150 at 8 per group)
	default {
		floor (_base * 1.0)
	};
};

(_count max 1)