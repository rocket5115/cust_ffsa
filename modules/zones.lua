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

RegisterNetEvent('ffsa:patrolMetadata', function(data,zone,pos)
    local coords=GetEntityCoords(obj.player)
    local c=#(coords-vector3(data.x,data.y,data.z))
    if c<150.0 and c>30.0 and(not(HasEntityClearLosToEntity(obj.ped))or not GetScreenCoordFromWorldCoord(data.x,data.y,data.z))then
        TriggerServerEvent('ffsa:createPatrol',zone,pos)
    end
end)

RegisterNetEvent('ffsa:createPatrol',function(data)
    local c=data.coords
    local veh,hash,p = obj.CreateVehicle(data.model,data.ped,c,true,true)
    Wait(100)
    local vehs=obj.CreateVehiclesInLine(veh,data.models,data.num,data.ped)
    TaskVehicleDriveWander(p,veh,data.speed,786603)
    Wait(200)
    local j=1
    for i=1,#vehs do
        TaskVehicleEscort(vehs[i][2],vehs[i][1],(vehs[i-1]~=nil and vehs[i-1][1]or veh),(data.formation[j]~=nil and data.formation[j]or -1),data.speed+5.0,786603,3.0,1,10.0)
        if data.formation[j]==nil then
            j=1
        else
            j=j+1
        end
    end
end)