local callbacks = {}
local listeners = {}
local encode,decode,unpack,insert = json.encode,json.decode,table.unpack,table.insert
local resource = GetCurrentResourceName()

function GetPlayer(source)
    return users[source]or{}
end

RegisterNetEvent('ffsa:ServerCallback', function(name,sync,id,...)
    local _source=source
    local data={...}
    callbacks[name](_source,function(...)
        TriggerClientEvent('ffsa:ServerCallback',_source,sync,id,...)
        if listeners[name]then
            for i=1,#listeners[name]do
                listeners[name][i](_source,unpack(data))
            end
        end
    end,...)
end)

function RegisterServerCallback(name,cb)
    callbacks[name]=cb
end

function AddCallbackListener(name, handler)
    if not listeners[name]then
        listeners[name]={}
    end
    listeners[name][#listeners[name]+1]=handler
end

local ccallbacks = {}
local callbacksID = 0

RegisterNetEvent('ffsa:ClientCallback', function(sync,id,...)
    if callbacksID>1000 then
        callbacksID=0
    end
    if sync then
        ccallbacks[id]:resolve(...)
    else
        ccallbacks[callbacksID](...)
    end
end)

function TriggerAsyncClientCallback(name,source,cb,...)
    callbacksID=callbacksID+1
    ccallbacks[callbacksID]=cb
    TriggerClientEvent('ffsa:ClientCallback',source,name,false,callbacksID,...)
end

function TriggerSyncClientCallback(name,source,...)
    callbacksID=callbacksID+1
    ccallbacks[callbacksID]=promise:new()
    TriggerClientEvent('ffsa:ClientCallback',source,name,true,callbacksID,...)
    local retval=await(ccallbacks[callbacksID])
    return unpack(retval)
end

function TriggerClientCallback(name,source,cb,...)
    if type(cb)=='function'then
        TriggerAsyncClientCallback(name,source,cb,...)
    else
        return TriggerSyncClientCallback(name,source,cb,...)
    end
end

AddEventHandler('ffsa:playerDropped', function()
    Emit('ffsa:playerDropped', source)
end)

for i=1,8 do
    SetRoutingBucketEntityLockdownMode(i,'strict')
    SetRoutingBucketPopulationEnabled(i, false)
end

AddEventHandler('entityCreating', function(entity)
    if(GetEntityType(entity)~=1 and GetEntityPopulationType(entity)~=7)then
        CancelEvent()
        return
    end
end)