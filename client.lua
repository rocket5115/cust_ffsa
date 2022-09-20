local sub,gsub,len,random,ceil,floor,unpack,await = string.sub,string.gsub,string.len,math.random,math.ceil,math.floor,table.unpack,Citizen.Await
local ped = PlayerPedId()
local coords = vector3(0.0, 0.0, 0.0)
local playerId = PlayerId()
local source = GetPlayerServerId(playerId)

CreateThread(function()
    while true do
        Wait(50)
        coords = GetEntityCoords(ped)
    end
end)

local callbacks = {}
local callbacksID = 0

local function TriggerAsyncServerCallback(name,cb,...)
    callbacksID=callbacksID+1
    callbacks[callbacksID]=cb
    TriggerServerEvent('ffsa:ServerCallback',name,false,callbacksID,...)
end

local function TriggerSyncServerCallback(name,...)
    callbacksID=callbacksID+1
    callbacks[callbacksID]=promise:new()
    TriggerServerEvent('ffsa:ServerCallback',name,true,callbacksID,...)
    local retval=await(callbacks[callbacksID])
    return unpack(retval)
end

local ccallbacks = {}
local listeners = {}

local function RegisterClientCallback(name,cb)
    ccallbacks[name]=cb
end

local function AddCallbackListener(name,handler)
    if not listeners[name]then
        listeners[name]={}
    end
    listeners[name][#listeners[name]+1]=handler
end

RegisterNetEvent('ffsa:ServerCallback', function(sync,id,...)
    if callbacksID>1000 then
        callbacksID=0
    end
    if sync then
        callbacks[id]:resolve({...})
    else
        callbacks[id](...)
    end
end)

RegisterNetEvent('ffsa:ClientCallback', function(name,sync,id,...)
    local data={...}
    ccallbacks[name](function(...)
        TriggerServerEvent('ffsa:ClientCallback',sync,id,...)
        if listeners[name]then
            for i=1,#listeners[name]do
                listeners[name][i](unpack(data))
            end
        end
    end,...)
end)

function notification(...)
    Emit('ffsa:notification', ...)
end

local safeListeners = {['ffsa:enteredGreenzone']=1,['ffsa:exitedGreenzone']=1,['ffsa:enteredRedzone']=1,['ffsa:exitedRedzone']=1}
local listeners = {}

function AddListener(name, handler, mission, mission_name)
    if not listeners[name]then
        listeners[name]={}
    end
    listeners[name][#listeners[name]+1]=handler
end

function RemoveListener(name, num)
    if not listeners[name]then
        return false
    end
    if not num then 
        num = 1
    end
    if listeners[name]and safeListeners[name]then
        for i=1,#listeners[name]do
            if i~=1 then
                listeners[name][i]=nil
            end
        end
        return true
    end
    listeners[name][num]=nil
    return true
end

function Emit(name,...)
    if not listeners[name]then
        return false
    end
    for i=1,#listeners[name]do
        listeners[name][i](...)
    end
    return true
end

local items = {}
local function HasItem(item,list)
    if not item then
        return true
    end
    if not list then
        return items[item]
    else
        for i=1,#item do
            if not items[item[i]]then
                return false
            end
        end
        return true
    end
end

local missions = {}
local function HasFinishedMission(mission,list)
    if not mission then
        return true
    end
    if not list then
        return missions[mission].finished
    else
        for i=1,#missions do
            if not missions[mission].finished then
                return false
            end
        end
        return true
    end
end

local spheres = {}

local function CreateInteractableZone(...)
    local d = {...}
    local x,y,z,radius,r,g,b,opacity,dist=d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9]
    if not(x and y and z and radius and r and g and b and opacity and dist) then
        return
    end
    local hand
    local handData
    local func
    local funcData = {}
    for i=1,#d do
        if type(d[i])=='function'then
            if not func then
                hand = d[i]
                func='found'
                handData=i
            elseif func=='found'then
                func=d[i]
            end
        end
        if type(func)=='function'then
            local res={}
            for j=handData+1,i-1 do
                res[#res+1]=d[j]
            end
            handData=res
            for j=i+1,#d do
                funcData[#funcData+1]=d[j]
            end
            break
        end
    end
    if type(func)~='function' then
        return
    end
    local id = random(99999)
    spheres[#spheres+1] = {vector3(x,y,z),(radius/2)*2,r,g,b,opacity,(dist/2)*2,hand,handData,func,funcData,id}
    return id
end

CreateThread(function()
    local handlers = {}
    local entered = {}
    while true do
        if #spheres > 0 then
            Wait(5)
            for i=1,#spheres do
                if#(coords-spheres[i][1])<spheres[i][7]then
                    DrawSphere(spheres[i][1].x,spheres[i][1].y,spheres[i][1].z,spheres[i][2],spheres[i][3],spheres[i][4],spheres[i][5],spheres[i][6])
                    if#(coords-spheres[i][1])<=spheres[i][2]then
                        if entered[i]~=true then
                            entered[i] = true
                            spheres[i][8](unpack(spheres[i][9]))
                        end
                    else
                        if entered[i]==true then
                            entered[i]=false
                            spheres[i][10](unpack(spheres[i][11]))
                        end
                    end
                else
                    if entered[i]==true then
                        entered[i]=false
                        spheres[i][10](unpack(spheres[i][11]))
                    end
                end
            end
        else
            Wait(200)
        end
    end
end)

local function CreateGreenzone(x,y,z,radius,r,g,b,opacity,dist)
    local enter = function()
        SetPlayerInvincible(playerId, true)
        SetEntityHealth(ped, 200)
        Emit('ffsa:enteredGreenzone')
    end
    local exit = function()
        SetPlayerInvincible(playerId, false)
        Emit('ffsa:exitedGreenzone')
    end
    local id = random(999999)
    spheres[#spheres+1] = {vector3(x,y,z),(radius/2)*2,r,g,b,opacity,(dist/2)*2,enter,{},exit,{},id}
    return id
end

local function CreateRedZone(x,y,z,radius,r,g,b,opacity,dist)
    local enter = function()
        SetPlayerInvincible(playerId, false)
        notification('You\'ve entered ~r~Red Zone!~w~ Watch out for enemies')
        Emit('ffsa:enteredRedzone')
    end
    local exit = function()
        SetPlayerInvincible(playerId, false)
        notification('You\'ve left ~r~Red Zone!~w~ Watch out for nearby enemies')
        Emit('ffsa:exitedRedzone')
    end
    local id = random(999999)
    spheres[#spheres+1] = {vector3(x,y,z),(radius/2)*2,r,g,b,opacity,(dist/2)*2,enter,{},exit,{},id}
    return id
end

local function CanStartMission(dependencies)
    dependencies = dependencies or{}
    for _,v in ipairs(dependencies.weapons or{})do
        if not HasPedGotWeapon(ped,v,false)then
            return false
        end
    end
    for _,v in ipairs(dependencies.components or{})do
        if not HasPedGotWeaponComponent(ped,v.weapon,v.component)then
            return false
        end
    end
    if not HasItem(dependencies.items or{},true)then
        return false
    end
    return true
end

local function FixWeaponConfig(config)
    local result = config
    for k,v in ipairs(config.weapons)do
        local data=type(v)
        if data=='string'and not v:match('weapon_')then
            result.weapons[k]=GetHashKey('weapon_'..v)
        elseif data=='string'then
            result.weapons[k]=GetHashKey(v)
        elseif data~='number'then
            result.weapons[k]=nil
        end
    end
    for k,v in ipairs(config.components)do
        local data=type(v)
        if data=='string'then
            result.components[k]=GetHashKey(v)
        elseif data~='number'then
            result.components[k]=nil
        end
    end
    return result
end

local function CreateMissionZone(x,y,z,radius,r,g,b,opacity,dist,config)
    local enter = function()
        notification('~y~You\'ve entered Mission Zone!')
        Emit('ffsa:enteredMissionzone:'..config.name)
    end
    local exit = function()
        notification('~r~You\'ve exited Mission Zone!')
        Emit('ffsa:exitedMissionzone:'..config.name)
    end
    local id = random(99999)
    CreateInteractableMission(config)
    spheres[#spheres+1] = {vector3(x,y,z),(radius/2)*2,r,g,b,opacity,(dist/2)*2,enter,{},exit,{},id}
    return id
end

local function GetGroundzAtCoords(x,y)
    local retval,z,z2=false,20.0,0.0
    while not retval do
        z=z+10
        retval,z2=GetGroundZFor_3dCoord(x,y,z,true)
        Wait(0)
    end
    return z2
end

local function GetScreenCoordFromCoords(x,y,z)
    local retval,x2,y2=GetScreenCoordFromWorldCoord(x,y,z)
    if retval then
        return vector2(x2,y2)
    end
    return nil
end

local markers = {}

local function AddDrawableMarker(x,y,z)
    local id = random(99999)
    SendNUIMessage({d='c',id})
    markers[#markers+1] = {x,y,z,id}
    return id
end

local function RemoveDrawableMarker(id)
    for i=1,#markers do
        if markers[i][4]==id then
            markers[i]=nil
            break
        end
    end
end

CreateThread(function()
    local showed = {}
    while true do
        if #markers>0 then
            Wait(10)
            for i=1,#markers do
                local c,x,y=GetScreenCoordFromWorldCoord(markers[i][1],markers[i][2],markers[i][3])
                if c then
                    showed[markers[i][4]]=false
                    SendNUIMessage({d='m',x,y,#(vector3(markers[i][1],markers[i][2],markers[i][3])-coords),markers[i][4]})
                else
                    if not showed[markers[i][4]]then
                        showed[markers[i][4]]=true
                        SendNUIMessage({d='h',markers[i][4]})
                    end
                end
            end
        else
            Wait(200)
        end
    end
end)

CreateThread(function()
    Wait(500)
    local c = GetEntityCoords(ped)
    --AddDrawableMarker(c.x+500.0, c.y+100.0, c.z)
end)

AddRelationshipGroup('COMPANION_PLAYER')
AddRelationshipGroup('RESPECT_PLAYER')
AddRelationshipGroup('LIKE_PLAYER')
AddRelationshipGroup('NEUTRAL_PLAYER')
AddRelationshipGroup('DISLIKE_PLAYER')
AddRelationshipGroup('HATE_PLAYER')

SetRelationshipBetweenGroups(0, GetHashKey('COMPANION_PLAYER'), GetHashKey('PLAYER'))
SetRelationshipBetweenGroups(1, GetHashKey('RESPECT_PLAYER'), GetHashKey('PLAYER'))
SetRelationshipBetweenGroups(2, GetHashKey('LIKE_PLAYER'), GetHashKey('PLAYER'))
SetRelationshipBetweenGroups(3, GetHashKey('NEUTRAL_PLAYER'), GetHashKey('PLAYER'))
SetRelationshipBetweenGroups(4, GetHashKey('DISLIKE_PLAYER'), GetHashKey('PLAYER'))
SetRelationshipBetweenGroups(5, GetHashKey('HATE_PLAYER'), GetHashKey('PLAYER'))

local relationships = {'COMPANION_PLAYER', 'RESPECT_PLAYER', 'LIKE_PLAYER', 'NEUTRAL_PLAYER', 'DISLIKE_PLAYER', 'HATE_PLAYER'}

local function CreateMission(name,config)
    local self = {}
    self.config = config
    self.listeners = {}
    self.setters = {}
    self.player = PlayerPedId()
    self.playerId = PlayerId()
    self.Spawn = {}
    self.Callback = {}
    self.Misc = {}
    self.Zones = {}
    self.Markers = {}
    self.Spawn.CreatePedsBetweenCoords = function(models,friendly,num,x1,x2,y1,y2,h1,h2)
        models = (type(models)=='table'and models or {models})
        for i=1,#models do
            if type(models[i])~='number'then
                models[i]=GetHashKey(models[i])
            end
        end
        for i=1,#models do
            RequestModel(models[i])
        end
        for i=1,#models do
            while not HasModelLoaded(models[i])do
                Wait(10)
            end
        end
        if not h1 then
            h1=0.0
        end
        local peds={}
        for i=1,num do
            local x,y=GetRandomFloatInRange(x1,x2),GetRandomFloatInRange(y1,y2)
            peds[i]=CreatePed(1,models[random(#models)],x,y,GetGroundzAtCoords(x,y),GetRandomFloatInRange(h1,(h2~=nil and h2 or h1)),true,true)
            local data=type(friendly)
            if data=='boolean'and friendly then
                SetPedRelationshipGroupHash(peds[i], GetHashKey('LIKE_PLAYER'))
            elseif data=='boolean'and not friendly then
                SetPedRelationshipGroupHash(peds[i], GetHashKey('HATE_PLAYER'))
            elseif data=='number'then
                SetPedRelationshipGroupHash(peds[i], GetHashKey(relationships[friendly+1]))
            else
                SetPedRelationshipGroupHash(peds[i], GetHashKey('NEUTRAL_PLAYER'))
            end
        end
        return peds
    end
    self.Spawn.CreatePedAtCoords = function(model,friendly,x,y,z,h,check)
        model = (type(model)=='number'and model or GetHashKey(model))
        if check then
            h=(type('h')=='number'and h or 0.0)
            z=GetGroundzAtCoords(x,y)
        end
        RequestModel(model)
        while not HasModelLoaded(model)do
            Wait(10)
        end
        local ped = CreatePed(1,model,x,y,z,h,true,true)
        if friendly then
            SetPedRelationshipGroupHash(ped, GetHashKey('LIKE_PLAYER'))
        else
            SetPedRelationshipGroupHash(ped, GetHashKey('HATE_PLAYER'))
        end
        return ped
    end
    self.Callback.Async = TriggerAsyncServerCallback
    self.Callback.Sync = TriggerSyncServerCallback
    self.Misc.GetGroundzAtCoords = GetGroundzAtCoords
    self.Misc.CanStartMission = CanStartMission(self.config.dependencies)
    self.Misc.Set = function(name,...)
        self.setters[name] = {...}
    end
    self.Misc.Get = function(name)
        return unpack(self.setters[name]or{})
    end
    self.Misc.Emit = Emit
    self.Misc.AddListener = function(name,cb)
        self.listeners[name]=true
        AddListener(name,cb)
    end
    self.Misc.RemoveListener = function(name)
        self.listeners[name]=nil
        RemoveListener(name)
    end
    self.Misc.RemoveAllListeners = function(name)
        for k in pairs(self.listeners)do
            RemoveListener(k)
            self.listeners[k]=nil
        end
    end
    self.Zones.CreateRedzone = CreateRedzone
    self.Zones.CreateGreenzone = CreateGreenzone
    self.Zones.CreateInteractableZone = CreateInteractableZone
    self.Zones.CreateMissionZone = CreateMissionZone
    self.Markers.CreateOnScreenMarker = AddDrawableMarker
    self.Markers.RemoveOnScreenMarker = RemoveDrawableMarker
    return self
end

function GetMissionByName(name)
    return missions[name]
end

function CreateMissionHandler(name, config)
    if missions[name]then
        return
    end
    missions[name]=CreateMission(config,name)
    return missions[name]
end
DisableIdleCamera(false)

CreateThread(function()
	while true do
		Citizen.Wait(3)
		--SetPauseMenuActive(false)
	end
end)

local status = false

local function OpenPauseMenu(st)
    status = st
    SetNuiFocus(status,status)
    SendNUIMessage({
        st=status
    })
end

RegisterNUICallback('close', function()
    OpenPauseMenu(false)
end)

RegisterNUICallback('quit', function()
    RestartGame()
end)

local mapHash = GetHashKey('FE_MENU_VERSION_MP_PAUSE')

RegisterNUICallback('map', function()
    OpenPauseMenu(false)
    ActivateFrontendMenu(mapHash,0,-1)
end)

RegisterNUICallback('objectives', function()

end)

--[[RegisterCommand('ffsa_pause_menu', function(source,args)
    if not IsPauseMenuActive()then
        OpenPauseMenu(true)
    else
        OpenPauseMenu(false)
    end
end)--]]

--RegisterKeyMapping("ffsa_pause_menu", "ImLew", "keyboard", "ESCAPE")

local c = GetEntityCoords(ped)

--[[local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

local function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

local objs = GetGamePool('CObject')
for _, obj in ipairs(objs) do
    if NetworkGetEntityIsNetworked(obj) then
        DeleteNetworkedEntity(obj)
        DeleteEntity(obj)
    else
        DeleteEntity(obj)
    end
end
for object in EnumerateObjects() do
    SetEntityAsMissionEntity(object, false, false)
    DeleteObject(object)
    if (DoesEntityExist(object)) then 
        DeleteObject(object)
    end
end

DisableIdleCamera(true)
--print(CreateAmbientPickup(GetHashKey('pickup_weapon_assaultrifle'), c.x+2.6, c.y, c.z, 2, 255, GetHashKey('weapon_assaultrifle'), true, true))

CreateThread(function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local n='w_ar_assaultrifle'
    RequestModel(n)
    while not HasModelLoaded(n)do
        Wait(1)
    end
    local obj = CreateObject(GetHashKey(n), c.x, c.y, c.z, false, true, false) --CreateWeaponObject(GetHashKey('WEAPON_MACHETE'), 255, c.x, c.y, c.z, true, 1.0, 0)
    print(obj)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 0x8CBD), 0.12, 0.0, 0.03, -120.0, 25.0, 15.0, true, true, true, true, 5, true)
    Wait(100)
    print(IsEntityStatic(obj))
end)
--]]

RegisterCommand('ta', function(source,args)
    local dict='cust@ffsa_pose'
    local anim='ffsa_pose_01'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict)do
        Wait(1)
    end
    TaskPlayAnim(ped, dict, anim, 4.0, 4.0, 1000, 1, 0.0, true, true, true)
end)

RegisterCommand('obj', function()
    local model = GetHashKey('house')
    RequestModel(model)
    while not HasModelLoaded(model)do
        Wait(1)
    end
    local c = GetEntityCoords(ped)
    local obj = CreateObject(model, c.x+2.0, c.y, c.z, true, true, false)
    print(obj)
    FreezeEntityPosition(obj, true)
end)