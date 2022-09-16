DB = {}
local callbacks = {}
local listeners = {}
local encode,decode,unpack,insert = json.encode,json.decode,table.unpack,table.insert
local resource = GetCurrentResourceName()

local function scandir(directory)
    local i, t = 0, {}
    local pfile = io.popen('dir "'..directory..'" /b')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

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

DB.Data = {}
DB.ActiveData={}

DB.PrepareTemplate = function(data)
    local tp = {}
    for k,v in pairs(data)do
        tp[k]=type(v)
    end
    return encode(tp)
end

DB.ManageDB = function()
    return function(prt, ...)
        if type(prt)~='string'then
            return
        end
        local data={...}
        prt=prt:upper()
        if prt=='CREATE'then
            if #data==2 then
                if LoadResourceFile(resource, 'db/'..data[1]..'.fftp')then
                    return 'DB ALREADY EXISTS:'..data[1]
                else
                    local dcd = (type(data[2])=='string'and decode(data[2])or true)
                    if dcd and dcd~=true then
                        local tp = DB.PrepareTemplate(dcd)
                        DB.Data[data[1]]=decode(tp)
                        DB.ActiveData[data[1]]={}
                        SaveResourceFile(resource, 'db/'..data[1]..'.fftp',tp,-1)
                        SaveResourceFile(resource, 'db/'..data[1]..'.ffdb',encode({}),-1)
                        return 'DB CREATED:'..data[1]
                    else
                        return 'DB NEEDS .JSON TEMPLATE'
                    end
                end
            else
                return 'DB DATA LENGTH < 2 OR > 2'
            end
        elseif prt=='DROP'then
            if #data==1 then
                local path=GetResourcePath(resource)..'/db/'..data[1]
                local file=io.open(path..'.fftp', "r")
                local file2=io.open(path..'.ffdb', "r")
                if file and file2 then    
                    file:close()
                    file2:close()
                    os.remove(path..'.fftp')
                    os.remove(path..'.ffdb')
                    return 'DB DROPPED TABLE:'..data[1]
                else
                    return 'DB TABLE DOES NOT EXISTS:'..data[1]
                end
            else
                return 'DB DATA LENGTH < 1 OR > 1'
            end
        elseif prt=='ALTER'then
            if #data==3 then
                local file=LoadResourceFile(resource, 'db/'..data[1]..'.fftp')
                if file then
                    local retval=data[2]
                    local where=data[3]
                    local override=(data[4]==true)
                    if(not retval or not where)then
                        return 'DB ALTER REQUIRE OLD AND NEW TEMPLATES'
                    end
                    local d={}
                    local dcd={}
                    for k,v in pairs(retval)do
                        d[k]=v
                    end
                    local tp = DB.PrepareTemplate(where)
                    DB.Data[data[1]]=decode(tp)
                    SaveResourceFile(resource, 'db/'..data[1]..'.fftp',tp,-1)
                    local file=LoadResourceFile(resource, 'db/'..data[1]..'.ffdb')
                    if file then
                        file=decode(file)
                        local ret={}
                        for i=1,#file do
                            ret[i]={}
                            for p,x in pairs(file[i])do
                                if d[p]then
                                    ret[i][d[p]]=x
                                end
                            end
                            for k,v in pairs(where)do
                                if not ret[i][k]then
                                    ret[i][k]=''
                                end
                            end
                        end
                        SaveResourceFile(resource, 'db/'..data[1]..'.ffdb',encode(ret),-1)
                        return 'DB ALTERED TEMPLATE AND DATABASE:'..data[1]
                    else
                        return 'DB ALTERED TEMPLATE:'..data[1]
                    end
                else
                    return 'DB TABLE DOES NOT EXISTS:'..data[1]
                end
            end
        else
            return -1,'FAILED TO RECOGNIZE COMMAND'
        end
    end
end

local queue = {}

DB.UpdateDB = function()
    return function(prt,db,retval,where)
        if type(prt)~='string'then
            return
        end
        prt=prt:upper()
        if prt=='INSERT'then
            if not DB.Data[db]then
                return 'DB TABLE DOES NOT EXISTS:'..db
            end
            if type(retval)=='table' then
                local new=DB.Data[db]
                local nw={}
                for k,v in pairs(new)do
                    nw[k]=((type(retval[k])==new[k]and retval[k])or'')
                end
                insert(DB.ActiveData[db],nw)
                SaveResourceFile(resource,'db/'..db..'.ffdb',encode(DB.ActiveData[db]),-1)
                return 1, 'INSERT DATA INTO:'..db
            else
                return -1, 'DB DATA LENGTH IS NOT A TABLE'
            end
        elseif prt=='SELECT'then
            if not DB.Data[db]then
                return 'DB TABLE DOES NOT EXISTS:'..db
            end
            local new=DB.ActiveData[db]
            local tp={}
            retval=retval or{'*'}
            where=where or{'*'}
            for i=1,#new do
                if where[1]=='*'then
                    local c={}
                    local c2=false
                    for p in pairs(new[i])do
                        c[p]=new[i][p]
                        c2=true
                    end
                    if c2 then
                        tp[#tp+1]=c
                    end
                else
                    for k,v in pairs(where)do
                        if new[i][k]==v then
                            local c={}
                            local c2=false
                            if retval[1]~='*'and retval[1]~=''then
                                for _,p in pairs(retval)do
                                    c[p]=new[i][p]
                                    c2=true
                                end
                            else
                                for p in pairs(new[i])do
                                    c[p]=new[i][p]
                                    c2=true
                                end
                            end
                            if c2 then
                                tp[#tp+1]=c
                            end
                        end
                    end
                end
            end
            return tp,'SELECTED:'..#tp..' ITEMS FROM:'..db
        elseif prt=='DELETE'then
            if not DB.Data[db]then
                return 'DB TABLE DOES NOT EXISTS:'..db
            end
            local new=DB.ActiveData[db]
            local d={}
            for i=1,#new do
                local c=0
                for k,v in pairs(retval)do
                    if new[i][k]==v then
                        c=true
                    else
                        c=false
                        break
                    end
                end
                if c then
                    d[#d+1]=i
                end
            end
            for i=1,#d do
                table.remove(DB.ActiveData[db],d[(#d+1)-i])
            end
            return #d,'REMOVED:'..#d..' ITEMS FROM:'..db
        else
            return -1,'FAILED TO RECOGNIZE COMMAND'
        end
    end
end

DB.New = function(managedb)
    if managedb then
        return DB.ManageDB()
    else
        return DB.UpdateDB()
    end
end

local ready = 0
local query = {}

DB.Ready = function(handler)
    if ready==2 then
        handler()
    else
        query[#query+1]=handler
    end
end

CreateThread(function()
    repeat Wait(1)until ready==2
    for i=1,#query do
        query[i]()
    end
    query=nil
end)

DB.ready = promise:new()

local dbdirs = scandir(GetResourcePath(resource)..'/db')

CreateThread(function()
    for i=1,#dbdirs do
        if dbdirs[i]:match('.ffdb')then
            DB.ActiveData[dbdirs[i]:gsub('.ffdb','')]=decode(LoadResourceFile(resource, 'db/'..dbdirs[i]))
            print('^2Initiated Data From '..dbdirs[i]..' Data File^7')
        elseif dbdirs[i]:match('.fftp')then
            DB.Data[dbdirs[i]:gsub('.fftp','')]=decode(LoadResourceFile(resource, 'db/'..dbdirs[i]))
            print('^2Initiated Template From '..dbdirs[i]..' Template File^7')
        elseif dbdirs[i]:match('.gstp')then
            if dbdirs[i]=='tp.gstp'then
                print('^2Initiated Template From '..dbdirs[i]..' Save File^7')
            else
                print('^3Recognized Template From '..dbdirs[i]..' Save File^7')
            end
        else
            print('^1Failed To Load '..dbdirs[i]..' File! Wrong Type Of File?^7')
        end
    end
    ready=ready+1
    DB.ready:resolve(true)
end)

CreateThread(function()
    local res=LoadResourceFile(resource, 'db/tp.gstp')
    if not res then
        res={}
        SaveResourceFile(resource,'db/tp.gstp',res,-1)
    end
    local t=type(res)
    if t=='string'then
        res=decode(res)
    elseif t~='table'then
        res={}
    end
    local tp={}
    for i=1,#dbdirs do
        if dbdirs[i]:match('.fftp')then
            local new=decode(LoadResourceFile(resource, 'db/'..dbdirs[i]))
            if new then
                new.Rs_N=dbdirs[i]:gsub('.fftp','')
                tp[#tp+1]=new
            end
        end
    end
    local passed=true
    for i=1,#res do
        for k,v in pairs(res[i])do
            if not tp[i]or not tp[i][k]or tp[i][k]~=v then
                passed=false
                break
            end
        end
    end
    if passed then
        for i=1,#tp do
            for k,v in pairs(tp[i])do
                if not res[i]or not res[i][k]or res[i][k]~=v then
                    passed=false
                    break
                end
            end
        end
    end
    if not passed then
        tp=encode(tp)
        local name = os.date('%d-%m-%y-%S-%M-%H')..'.gstp'
        SaveResourceFile(resource,'db/'..name,tp,-1)
        SaveResourceFile(resource,'db/tp.gstp',tp,-1)
        print('^3Created Global Save Template: '..name..'^7')
    end
    ready=ready+1
end)

RegisterCommand('ffsa_load_db_template', function(source,args)
    if(source~=nil and source>0)then
        print('^1This Command Can Be Executed From Console Only! Failed To Load Save Template^7')
        return
    end
    if args[1]==nil then
        print('^1Arg Num 1 Is Required! Failed To Load Save Template^7')
    end
    local file = LoadResourceFile(resource, 'db/'..(args[1]:lower()=='save'and'tp.gstp'or args[1]))
    if not file then
        print(('^1File %s Not Found! Failed To Load Save Template^7'):format((args[1]:lower()=='save'and'tp.gstp'or args[1])))
        return
    end
    file=decode(file)
    for i=1,#file do
        local name=file[i].Rs_N
        file[i].Rs_N=nil
        SaveResourceFile(resource, 'db/'..name..'.gstp', encode(file[i]), -1)
    end
end)

RegisterCommand('ffsa_create_db_template', function(source, args)
    if(source~=nil and source>0)then
        print('^1This Command Can Be Executed From Console Only! Failed To Create Save Template^7')
        return
    end
    local tp={}
    for i=1,#dbdirs do
        if dbdirs[i]:match('.fftp')then
            local new=decode(LoadResourceFile(resource, 'db/'..dbdirs[i]))
            if new then
                new.Rs_N=dbdirs[i]:gsub('.fftp','')
                tp[#tp+1]=new
            end
        end
    end
    local name = (args[1]or os.date('%d-%m-%y-%S-%M-%H'))..'.gstp'
    SaveResourceFile(resource,'db/'..name,encode(tp),-1)
    print('^3Created Global Save Template: '..name..'^7')
end)

DB.Ready(function()
    db = DB.New(true)
    local res = db('CREATE', 'items', json.encode({
        name='',
        limit=0,
        mission=0
    }))
    print(res)
end)

SetRoutingBucketEntityLockdownMode(1, 'strict')

local filename = function()
    return debug.getinfo(2,"S").source:sub(2):match("^.*/(.*).lua$")
end
print(filename())