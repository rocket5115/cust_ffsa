local obj = Modules['zones']

--[[local function XY(center,xradius,yradius,rot)
    local x1,x2,y1,y2=center.x-(xradius-rot),center.x+(xradius-rot),center.y-(yradius-rot),center.y+(yradius-rot)
    DrawLine(x1, y1, center.z, x2, y1, center.z, 255,0,0,255)
    DrawLine(x1, y1, center.z, x1, y2, center.z, 255,0,0,255)
    DrawLine(x2, y1, center.z, x2, y2, center.z, 255,0,0,255)
    DrawLine(x1, y2, center.z, x2, y2, center.z, 255, 0, 0, 255)
end

local function Dist(center,xradius,yradius,c)
    return((center.x-xradius<c.x and center.x+xradius>c.x)and(center.y-yradius<c.y and center.y+yradius>c.y))
end--]]

local zones = {
    {x1=-3300,x2=700,y1=-4000,y2=-1000,id=1,center=vector2(-1300.0,-2500.0)},
    {x1=700,x2=4700,y1=-4000,y2=-1000,id=2,center=vector2(2700.0,-2500.0)},
    {x1=-3300,x2=700,y1=-1000,y2=2000,id=3,center=vector2(-1300.0,500.0)},
    {x1=700,x2=4700,y1=-1000,y2=2000,id=4,center=vector2(2700.0,500.0)},
    {x1=-3300,x2=700,y1=2000,y2=5000,id=5,center=vector2(-1300.0,3500.0)},
    {x1=700,x2=4700,y1=2000,y2=5000,id=6,center=vector2(2700.0,3500.0)},
    {x1=-3300,x2=700,y1=5000,y2=8000,id=7,center=vector2(-1300.0,6500.0)},
    {x1=700,x2=4700,y1=5000,y2=8000,id=8,center=vector2(2700.0,6500)}
}

local zone = 1

CreateThread(function()
    while true do
        local coords = GetEntityCoords(obj.ped)
        for i=1,#zones do
            if((zones[i].center.x-2000.0<coords.x and zones[i].center.x+2000.0>coords.x)and(zones[i].center.y-1500.0<coords.y and zones[i].center.y+1500.0>coords.y))then
                if(zone~=zones[i].id)then
                    zone=zones[i].id
                    TriggerServerEvent('ffsa:changeZone', zone)
                end
                break
            end
        end
        Wait(50)
    end
end)

RegisterNetEvent('ffsa:changeZone', function(metadata)
    local patrols=(metadata:sub(1,1)=="1"and Emit('ffsa:patrolsOn',true,zone)or Emit('ffsa:patrolsOn',false,zone))
    local patrol_types=tonumber(metadata:sub(2,2))
    local difficulty=tonumber(metadata:sub(3,3))

end)