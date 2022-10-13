local obj = Modules['zones']
local user_zones = {}

AddListener('ffsa:playerLoaded', function(source)
    user_zones[source]=1
end)

AddListener('ffsa:playerDropped', function(source)
    user_zones[source]=nil
end)

RegisterNetEvent('ffsa:changeZone', function(zone)
    if user_zones[source]then
        user_zones[source]=zone
        SetTimeout(30000, function()
            TriggerClientEvent('ffsa:patrolMetadata', source, 'riot', 's_m_y_swat_01')
        end)
    end
end)
