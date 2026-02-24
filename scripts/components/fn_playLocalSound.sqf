params ["_soundName", ["_delay", 1]];

if (!hasInterface) exitWith {};           // only clients with UI/audio
if (_soundName isEqualTo "") exitWith {};

preloadSound _soundName;

[_soundName, _delay] spawn {
    params ["_sound", "_duration"];
    sleep _duration;
    playSound _sound;
};