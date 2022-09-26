local await = Citizen.Await
local function _CreateVehicle(v,m,c,n,o)
    local veh=(type(v)=='string'and GetHashKey(v)or v)
    RequestModel(veh)
    while not HasModelLoaded(veh)do
        Wait(1)
    end
    local ped=(type(m)=='string'and GetHashKey(m)or m)
    RequestModel(m)
    while not HasModelLoaded(m)do
        Wait(1)
    end
    local v=CreateVehicle(v,c.x,c.y,c.z,c.w,n,o)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh,true,true,false)
    local p=CreatePed(1,ped,c.x,c.y,c.z,c.w,n,o)
    TaskWarpPedIntoVehicle(p,v,-1)
    return v,veh,p
end

local function CreateVehiclesInLine(veh,model,num,ped)
    local vehs={}
    local vl=veh
    for i=1,num do
        local v,h,p=_CreateVehicle(model,ped or'csb_cop',vector4(GetOffsetFromEntityInWorldCoords(vl,0.0,-15.5,0.0),299.8),true,true)
        vehs[#vehs+1]={v,p}
        vl=v
    end
    return vehs
end

Missions = {}
Modules = {}

local function SharedObject(name,cfg)
    local mission = GetMissionByName(name)or CreateMissionHandler(name,cfg)
    local config = {}
    config.player = mission.player
    config.playerId = mission.playerId
    config.Callback = mission.Callback
    config.TriggerServerCallback = mission.Callback.Server
    config.CreateRedzone = mission.Zones.CreateRedzone
    config.CreateGreenzone = mission.Zones.CreateGreenzone
    config.CreateInteractableZone = mission.Zones.CreateInteractableZone
    config.CreateMissionZone = mission.Zones.CreateMissionZone
    config.Emit = mission.Misc.Emit
    config.AddListener = mission.Misc.AddListener
    config.RemoveListener = mission.Misc.RemoveListener
    config.RemoveAllListeners = mission.Misc.RemoveAllListeners
    config.GetGroundzAtCoords = mission.Misc.GetGroundzAtCoords
    config.CanStartMission = mission.Misc.CanStartMission
    config.Set = mission.Misc.Set
    config.Get = mission.Misc.Get
    config.CreateOnScreenMarker = mission.Markers.CreateOnScreenMarker
    config.RemoveOnScreenMarker = mission.Markers.RemoveOnScreenMarker
    config.Spawn = mission.Spawn
    config.CreateVehicle = _CreateVehicle
    config.CreateVehiclesInLine = CreateVehiclesInLine
    return config
end

setmetatable(Missions, {
    __newindex = function(t,k,v)
        rawset(t,k,SharedObject(k,v.dependencies or{}))
    end
})

local missionsToLoad = {}

AddListener('ffsa:notification', function(...)
    print(...)
    SendNUIMessage({
        type='message',
        args={...}
    })
end)

AddListener('ffsa:loadMission', function(name, server)
    name=name:gsub(' ','_')
    missionsToLoad[name]=true
    TriggerServerEvent('ffsa:getMission', name, server)
end)

RegisterNetEvent('ffsa:mission', function(name,code)
    if missionsToLoad[name]then
        missionsToLoad[name]=nil
        load(code)()
        CreateThread(function()
            local retval = promise:new()
            notification('You\'ve started the mission '..name)
            Missions[name]:Start(function(cb)
                retval:resolve(true)
                if type(cb)=='function'then
                    cb()
                end
            end)
            await(retval)
            Missions[name]:End(function(cb)
                notification('You\'ve finished the mission '..name)
                Missions[name].RemoveAllListeners()
                if type(cb)=='function'then
                    cb()
                end
                Missions[name]=nil
            end)
        end)
    end
end)

RegisterNetEvent('ffsa:loadModules', function(modules)
    for i=1,#modules do
        Modules[modules[i][2]]=SharedObject(modules[i][2],{})
        load(modules[i][1])()
    end
end)