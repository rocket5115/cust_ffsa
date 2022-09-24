local obj = Modules['zones']
local user_zones = {}

--[[
    patrols_on = 1
    patrols_type = 2
    difficulty = 3
]]

local zone_metadata = {"111","111","111","111","111","111","111","111"}

obj.AddListener('ffsa:playerLoaded', function(source)
    TriggerClientEvent('ffsa:changeZone', source, zone_metadata[1])
    user_zones[source]=1
end)

obj.AddListener('ffsa:playerDropped', function(source)
    user_zones[source]=nil
end)

RegisterNetEvent('ffsa:changeZone', function(zone)
    if user_zones[source]then
        user_zones[source]=zone
        TriggerClientEvent('ffsa:changeZone', source, zone_metadata[zone])
    end
end)