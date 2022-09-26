local obj = Modules['zones']
local user_zones = {}

local zone_coords = { --vector4
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

local zone_metadata = {
    {

    },
    {
        
    },
    {
        {model='police',models={'police'},ped='csb_cop',num=3,speed=10.0,formation={-1}},
        {model='police',models={'police'},ped='csb_cop',num=3,speed=10.0,formation={-1}}
    }
}

for k,v in pairs(zone_coords)do
    for i=1,#v do
        if zone_metadata[k][i]then
            zone_metadata[k][i].coords = v[i]
        end
    end
end

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
            local rand=math.random(#zone_coords[user_zones[source]])
            TriggerClientEvent('ffsa:patrolMetadata', source, zone_coords[user_zones[source]][rand],user_zones[source],rand)
        end)
    end
end)

RegisterNetEvent('ffsa:createPatrol', function(zone,pos)
    TriggerClientEvent('ffsa:createPatrol', source, zone_metadata[zone][pos])
end)