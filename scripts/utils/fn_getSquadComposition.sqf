params [["_type", "rifle"]];

switch (_type) do {
    case "rifle": {
        getArray (missionConfigFile >> "CfgVariables" >> "Squads" >> "Infantry" >> "rifleSquad");
    };
    case "at": {
        getArray (missionConfigFile >> "CfgVariables" >> "Squads" >> "Infantry" >> "atSquad");
    };
    default {
        getArray (missionConfigFile >> "CfgVariables" >> "Squads" >> "Infantry" >> "rifleSquad");
    };
};