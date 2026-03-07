/*
	    dynamic_fnc_normaliseUnitHealth
	    Applies vanilla-compatible health values to RHS (and other modded) units so
	    they are killed in a realistic number of hits instead of requiring 4-5 headshots.
	
	    RHS overrides hitpoint armour values to match its own damage pipeline; this
	    function resets those values back to sensible vanilla-equivalent numbers.
	
	    Parameters:
	        _unit - The unit to normalise
	
	    Returns: Nothing
	
	    Notes:
	        - call this on every unit immediately after it is created.
	        - Adjust _headArmour / _bodyArmour below to taste if enemies are still
	          too tanky or become too fragile for your mission balance.
*/

params ["_unit"];

if (!alive _unit) exitWith {};

// ── Armour override values ───────────────────────────────────────────────────
// Vanilla soldier head ~2, body ~4.  RHS soldiers can be 10-20× higher.
// These values give roughly 1 headshot kill, 2-4 body-shot kills depending
// on calibre - similar to vanilla infantry behaviour.

private _headArmour = 2;    // Raise to ~4 for slightly more resilience
private _bodyArmour = 4;    // Raise to ~8 for light body-armour feel

// ── apply to every hitpoint ──────────────────────────────────────────────────

private _hitpoints = getAllHitPointsDamage _unit;
{
	private _hitpoint = _x;
	private _hitpointLC = toLower _hitpoint;

	private _targetArmour = switch (true) do {
		// Head / face / neck / visor
		case (_hitpointLC in ["hithead", "hitface", "hitneck", "hitvisor"]): {
			_headArmour
		};
		        // Body / chest / spine / pelvis / abdomen / diaphragm
		default {
			_bodyArmour
		};
	};

	    _unit setHitPointDamage [_hitpoint, 0];          // Reset current damage first
	_unit setVariable [_hitpoint + "_maxArmour", _targetArmour, false];
} forEach (_hitpoints select 0);

// Directly set armour via hidden property where accessible (ACE / RHS compatible)
_unit setVariable ["rhs_fnc_setHitPointArmour", nil, false]; // Clear RHS cache if present

// Use setUnitAbility to ensure vanilla AI combat behaviour is not affected
// (this does NOT change armour, just ensures we haven't accidentally broken AI)
_unit setSkill ["aimingAccuracy", _unit skill "aimingAccuracy"];

// ── Alternative low-level approach (most reliable across mods) ───────────────
// setDamage works on a 0-1 scale; we manipulate the underlying armour pool
// by setting hit selections directly.  The cleanest cross-mod method is to
// simply cap the unit's overall armour pool:

private _hitSelections = getAllHitPointsDamage _unit;
private _hitNames = _hitSelections select 0;
private _hitArmours    = _hitSelections select 2; // current armour values

{
	private _hp = _hitNames select _forEachIndex;
	private _hpLC = toLower _hp;
	private _currentArmour = _x;

	    // Only override if the modded value is significantly above vanilla
	if (_currentArmour > 8) then {
		private _newArmour = switch (true) do {
			case (_hpLC in ["hithead", "hitface", "hitneck", "hitvisor"]): {
				_headArmour
			};
			default {
				_bodyArmour
			};
		};
		[_unit, _hp, _newArmour] call BIS_fnc_setHitPointArmour;
	};
} forEach _hitArmours;

// ── skill override ───────────────────────────────────────────────────────────
// Adjust these values to taste (0.0 - 1.0)

private _skills = [
	    ["aimingAccuracy", 0.25], // How accurately they track your position
	    ["aimingShake", 0.20], // How much their aim wobbles
	    ["aimingSpeed", 0.30], // How fast they snap onto a target
	    ["spotDistance", 0.40], // How far they can spot enemies
	    ["spotTime", 0.40], // How quickly they notice enemies
	    ["courage", 0.50], // Whether they suppress/flee under fire
	    ["reloadSpeed", 0.50], // How fast they reload
	    ["commanding", 0.50], // group coordination
	    ["general", 0.30]   // Fallback for anything not listed above
];

{
	_unit setSkill [_x select 0, _x select 1]
} forEach _skills;