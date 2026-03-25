/*
	    dynamic_fnc_calcUnitCount
	    Returns the total number of infantry to spawn for a given area and density.
	
	    Parameters:
	        _markerArea - Area of the marker in m²
	        _density    - "light" | "medium" | "heavy" | "vheavy"
	
	    Returns: Integer unit count (clamped 4-150)
*/

params ["_markerArea", ["_density", "medium"]];

// Use sqrt scaling so larger areas continue to increase, but without runaway growth.
// Divisor controls the overall unit density across all densities uniformly.
private _base = (sqrt (_markerArea max 2500)) / 8;

private _count = switch (_density) do {
	case "light": {
		round (_base * 0.70)
	};
	case "medium": {
		round (_base * 1.15)
	};
	case "heavy": {
		round (_base * 1.55)
	};
	case "vheavy": {
		round (_base * 2.05)
	};
	default {
		round (_base * 1.15)
	};
};

(_count max 4) min 150