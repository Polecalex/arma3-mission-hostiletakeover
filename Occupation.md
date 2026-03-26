# AreaOccupation Workflow

This document explains the current dynamic area occupation pipeline used by this mission.

## 1) Entry Point

Main function: `Shared_fnc_areaOccupation` in `scripts/dynamic/fn_areaOccupation.sqf`.

Call signature:

```sqf
[
    _marker,                 // marker name
    _blockadeMarkers,        // optional array
    _vehiclePatrols,         // optional int
    _density,                // "light" | "medium" | "heavy" | "vheavy"
    _activationDistance,     // optional override, -1 = config default
    _minSpawnDistance,       // optional override, -1 = config default
    _spawnZoneSize,          // optional override, -1 = config default
    _maxZonesPerCycle,       // optional override, -1 = script default by density
    _minZoneActivationSpacing,// optional override, -1 = computed from script defaults
    _aliveUnitCap            // optional override, -1 = config default
] call Shared_fnc_areaOccupation;
```

Typical usage:

```sqf
["obj_marker"] call Shared_fnc_areaOccupation;

[
    "obj_marker",
    ["blockade_1", "blockade_2"],
    2,
    "heavy",
    90,
    55,
    70,
    4,
    100,
    140
] call Shared_fnc_areaOccupation;
```

## 2) Config Resolution

Defaults come from `description.ext`:

- `CfgVariables >> Dynamic >> AreaOccupation`
- Config-exposed values:
  - `activationDistance`
  - `minSpawnDistance`
  - `minSpawnDistanceFloor`
  - `spawnZoneSize`
  - `aliveUnitCap`
  - `blockadeSpawnDistanceMultiplier`
  - `blockadeLOSProbeDistanceMultiplier`
  - `blockadeSpawnDistanceMin`
  - `blockadeLOSProbeDistanceMin`
- Advanced values are script defaults in `fn_areaOccupation` (not config-exposed):
  - max zones per cycle by density: `1 / 3 / 4 / 5`
  - min zone spacing formula: `(_spawnZoneSize * 1.25) max 120`
  - hidden spawn tuning: `[0.30, 30, 70, 22, 0.55, 45, 120, 30, 0.40, 35, 90]`

Rules in `fn_areaOccupation`:

- Any optional argument passed as `-1` uses config default.
- `_minSpawnDistance` is clamped:
  - lower bound: `minSpawnDistanceFloor`
  - upper bound: `activationDistance - 25`

## 3) Infantry Total Calculation

Function: `Shared_fnc_calcUnitCount` in `scripts/dynamic/fn_calcUnitCount.sqf`.

Formula:

```sqf
_base = (sqrt (_markerArea max 2500)) / 8;
```

Density multipliers:

- light: `0.70`
- medium: `1.15`
- heavy: `1.55`
- vheavy: `2.05`

Final count is clamped to `4..150`.

## 4) Zone Build Phase

Function: `Shared_fnc_buildSpawnZones` in `scripts/dynamic/fn_buildSpawnZones.sqf`.

### 4.1 Zone count target

Current target-group seed:

```sqf
private _targetGroups = ceil (_totalInfantry / 3);
```

Then density factor is applied (`0.75/1.0/1.25/1.5`) and clamped to `4..36` zones.

### 4.2 Zone placement

- Trigger positions are random inside marker radius.
- Spacing is density-dependent and based on `activationDistance`.
- Placement uses a random candidate pool per zone (`_candidatePoolSize = 8`) and picks the best spacing score.
- Small overlap is allowed (controlled by `_overlapSpacing` + acceptance chance).

Each zone row currently looks like:

```sqf
[
    _triggerPos,
    _spawnCenter,
    _hasSpawned,
    _garrisonCount,
    _patrolCount,
    _weight,
    _debugMarkerName,
    _blockedLOSCount   // added later by monitor loop path
]
```

### 4.3 Unit split per zone

- Garrison ratio by density:
  - light 45%
  - medium 58%
  - heavy 70%
  - vheavy 80%
- Patrol gets the remainder.
- Distribution is even first, then slight shuffle variance.

HUD support value is also accumulated here:

```sqf
missionNamespace setVariable [
    "dynamic_totalDesiredZones",
    (missionNamespace getVariable ["dynamic_totalDesiredZones", 0]) + count _spawnZones,
    true
];
```

## 5) Monitor Loop (Activation + Spawn)

Function: `Shared_fnc_monitorLoop` in `scripts/dynamic/fn_monitorLoop.sqf`.

Runs every 5 seconds and:

1. Loads current zone state from `missionNamespace`.
2. Finds candidate zones near players (`distance < activationDistance` and `> minSpawnDistance`).
3. Enforces:
   - `maxZonesPerCycle`
   - `minZoneActivationSpacing`
   - alive EAST AI cap (`aliveUnitCap`)
4. For each activation, finds hidden spawn position (LOS-safe):
   - base search pass
   - expanded search pass
5. If hidden spawn fails:
   - zone stays unspawned
   - spawn center is rerolled within marker
   - debug marker turns yellow
   - retries next cycle
6. If hidden spawn succeeds:
   - calls garrison/patrol spawners
   - tags units for HUD/accounting
   - marks zone as spawned
   - debug marker turns green
7. Blockade spawning uses independent range checks from each blockade marker:
  - near-distance ring (`blockadeSpawnDistance*`)
  - LOS probe ring (`blockadeLOSProbeDistance*`)
  - both include activation-distance multiplier, marker-radius floor, and absolute minimum distance

## 6) Squad Size Selection and Persistence

### 6.1 Initial spawn calls

`fn_monitorLoop` calls:

- `Shared_fnc_garrison`
- `Shared_fnc_patrol`

Both now create squads using random-size mode:

```sqf
private _group = [_spawnPos, "rifle", 0] call Shared_fnc_createSquad;
```

And persist selected size on the group:

```sqf
_group setVariable ["dynamic_groupSize", count units _group, true];
```

### 6.2 How `createSquad` picks size

In `scripts/components/fn_createSquad.sqf`:

- `-1`: full composition
- `0`: random size
- `1+`: explicit size

Current behavior:

- random path uses `4..compositionSize`
- explicit path clamps to at least 4 and max composition size

### 6.3 Respawn path

In `scripts/utils/fn_groupRespawnCheck.sqf`:

- if group dies (or has too few alive), it respawns
- respawn size is read from `dynamic_groupSize`
- same size is re-applied to the new group

```sqf
private _targetGroupSize = _group getVariable ["dynamic_groupSize", count units _group];
private _newGroup = [_newSpawnPos, "rifle", _targetGroupSize] call Shared_fnc_createSquad;
_newGroup setVariable ["dynamic_groupSize", _targetGroupSize, true];
```

This keeps squad size stable through that group's lifecycle.

## 7) HUD Values

HUD update loop: `initPlayerLocal.sqf`.

Displays:

- Line 1: `Active Enemy Units: current/denominator`
  - `current` = alive managed infantry across all active dynamic areas
  - denominator = total planned infantry summed from `dynamic_plannedInfantryByArea`
- Line 2: `Active Groups: X` (smaller text, `#D0D0D0`)
  - unique alive managed groups across all active dynamic areas

## 8) MissionNamespace State Used

Frequently used keys:

- Per marker:
  - `"<marker>_spawnZones"`
  - `"<marker>_allGroups"`
  - `"<marker>_vehiclesSpawned"`
  - `"<marker>_blockadeMarkers"`
  - `"<marker>_blockadeSpawned"`
- Global dynamic context:
  - `dynamic_currentDensity`
  - `dynamic_currentMarkerArea`
  - `dynamic_currentPlannedInfantry`
  - `dynamic_aliveUnitCap`
  - `dynamic_totalDesiredZones`
  - `dynamic_plannedInfantryByArea`
  - `dynamic_plannedInfantryByDensity`

## 9) Quick Tuning Guide

If gameplay is too quiet:

1. Increase total infantry: adjust divisor in `fn_calcUnitCount` (`/8` -> smaller number = more units).
2. Increase number of zones/groups: adjust `_targetGroups = ceil(_totalInfantry / N)` in `fn_buildSpawnZones`.
3. Increase activation throughput: adjust density defaults in `fn_areaOccupation` (`1 / 3 / 4 / 5`) or pass `_maxZonesPerCycle` override per call.

If spawns feel too visible:

1. Lower `activationDistance`.
2. Raise `minSpawnDistance` / `minSpawnDistanceFloor`.
3. Increase hidden search attempts/radius constants in `fn_monitorLoop` (`_base*`, `_expanded*`, `_spawnArea*`).

## 10) Debug Expectations

With debug markers enabled:

- Infantry zone markers (`enableSpawnZoneMarkers`):
  - `ColorRed` (alpha `0.5`): zone exists, not yet spawned
  - `ColorYellow`: hidden spawn failed this cycle; zone center rerolled for retry
  - `ColorGreen`: zone spawned successfully
- Blockade markers (`enableBlockadeMarkers`):
  - Orange solid-border ring: blockade near-distance spawn ring
  - Yellow border ring: blockade LOS probe ring
  - Green rings: blockade already spawned

Marker differences:

- Infantry zone marker = where dynamic infantry zone activation is checked.
- Blockade near-distance ring = distance condition that can trigger blockade spawn.
- Blockade LOS ring = longer-range visibility check that can trigger earlier blockade spawn when players can see the area.
