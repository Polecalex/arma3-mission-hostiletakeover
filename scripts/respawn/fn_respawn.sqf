params ["_group", "_respawnModule"];

// During playtime, keep Respawn Module location up-to-date with group average location.
while { true } do {
    private _aliveUnits = units _group select { alive _x };

    if (count _aliveUnits > 0) then {
        private _sumX = 0;
        private _sumY = 0;
        private _sumZ = 0;

        {
            private _pos = getPosATL _x;
            _sumX = _sumX + (_pos select 0);
            _sumY = _sumY + (_pos select 1);
            _sumZ = _sumZ + (_pos select 2);
        } forEach _aliveUnits;

        private _count = count _aliveUnits;
        _respawnModule setPos [_sumX / _count, _sumY / _count, _sumZ / _count];

    } else {
        _respawnModule setPos [0, 0, 0];
    };

    sleep 1;
};