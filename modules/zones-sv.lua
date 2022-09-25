local obj = Modules['zones']
local user_zones = {}

local zone_metadata = { --vector4
    {},
    {},
    {
        {coords=vector4(1801.74,3566.925,35.753,299.8)},
        {coords=vector4(1801.74,3566.925,35.753,60.8)},
    },
    {},
    {},
    {},
    {},
    {}
}

AddListener('ffsa:playerLoaded', function(source)
    TriggerClientEvent('ffsa:changeZone', source, zone_metadata[1])
    user_zones[source]=1
end)

AddListener('ffsa:playerDropped', function(source)
    user_zones[source]=nil
end)

RegisterNetEvent('ffsa:changeZone', function(zone)
    if user_zones[source]then
        user_zones[source]=zone
        SetTimeout(30000, function()
            TriggerClientEvent('ffsa:patrolMetadata', source, zone_metadata[user_zones[source]][math.random(#zone_metadata[user_zones[source]])])
        end)
    end
end)