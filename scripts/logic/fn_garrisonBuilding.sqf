params ["_grp"];

sleep 2;

private _leaderPos = getPos leader _grp;
private _buildings = nearestObjects [_leaderPos, ["House", "Building"], 80];
_buildings = _buildings select {count (_x buildingPos -1) > 0};

private _units = units _grp;
private _buildingIndex = 0;

{
    private _unit = _x;
    
    if (_buildingIndex < count _buildings) then {
        private _building = _buildings select _buildingIndex;
        private _positions = _building buildingPos -1;
        
        if (count _positions > 0) then {
            private _buildingPos = selectRandom _positions;
            _unit setPosATL _buildingPos;
            _unit setDir (random 360);
            _unit setUnitPos "MIDDLE";
            doStop _unit;
            
            if ((random 1) > 0.5) then {
                _buildingIndex = _buildingIndex + 1;
            };
        };
    };
} forEach _units;

_grp setBehaviour "COMBAT";
_grp setCombatMode "RED";