params ["_soundName", ["_delay", 1]];

// Exists when not a client (e.g. dedicated server), or when soundName is empty
if (!hasInterface || _soundName isEqualTo "") exitWith {};

preloadSound _soundName;

[_soundName, _delay] spawn {
    params ["_sound", "_duration"];
    sleep _duration;
    playSound [_sound, true];
};