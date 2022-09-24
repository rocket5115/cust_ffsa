local obj = Modules['patrols']

local state=false

obj.AddListener('ffsa:patrolsOn',function(on)
    state=(on~=nil and on~=false)
end)

local function GetRoadAtCoords(x,y,z)
    local is,road,vec3,p7,p8,num=GetClosestRoad(x,y,z,1.0,1,true)
    return is,road,vec3
end

function 

CreateThread(function()
    local ped = PlayerPedId()
    while true do
        if not state then
            Wait(200)
        else
            Wait(5)
            local coords = GetEntityCoords(ped)
            local is,road,any = GetRoadAtCoords(coords.x+random(500.0),coords.y+random(500.0),coords.z)
            if not is then
                Wait(200)
            else
                --create vehicle
                --task escort: first vehicle
                --driving style: any 
            end
        end
    end
end)