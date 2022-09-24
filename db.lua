local resource=GetCurrentResourceName()
local encode,decode,unpack,insert,remove,saver,loadr,tostring,tonumber,type=json.encode,json.decode,table.unpack,table.insert,table.remove,SaveResourceFile,LoadResourceFile,tostring,tonumber,type
local ready=false
function scandir(directory)
    local i, t = 0, {}
    local pfile = io.popen('dir "'..directory..'" /b')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

DB = {}
DB.Database = {}
DB.DatabaseTemplate = {}
DB.DatabaseMetadata = {}

local handlers={}

function DB.Ready(handler)
    if ready then
        CreateThread(handlers[i])
    else
        handlers[#handlers+1]=handler
    end
end

--[[
    File Types
    *.fftp - template file, data types
    *.ffdb - database file, data file
    *.ffmd - metadata file, metadata file
]]

CreateThread(function()
    local debugdb=""
    local debugtp=""
    local debugmd=""
    for _,v in pairs(scandir(GetResourcePath(resource)..'/db'))do
        local l=v:len()
        local n=v:sub(1,l-5)
        local r=v:sub(l-4,l)
        if r~='.gstp'then
            local rn=decode(LoadResourceFile(resource,'db/'..v))
            if r=='.ffdb'then
                DB.Database[n]=rn
                debugdb=debugdb..((debugdb==""and "^2Loaded Data File:"..v)or"\n^2Loaded Data File:"..v)..'^7'
            elseif r=='.fftp'then
                DB.DatabaseTemplate[n]=rn
                debugtp=debugtp..((debugtp==""and "^2Loaded Template File:"..v)or"\n^2Loaded Template File:"..v)..'^7'
            elseif r=='.ffmd'then
                DB.DatabaseMetadata[n]=rn
                debugmd=debugmd..((debugmd==""and "^3Loaded Metadata File:"..v)or"\n^3Loaded Metadata File:"..v)..'^7'
            end
        end
    end
    ready=true
    for i=1,#handlers do
        CreateThread(handlers[i])
    end
    if(debugdb~=""and print(debugdb))
    print(debugtp)
    print(debugmd)
end)

local function ManageDB()
    return function(cmd,...)
        if type(cmd)~='string'then return'DB FAILED TO RECOGNIZE COMMAND'end
        local data={...}
        if cmd=='CREATE'then
            if DB.Database[data[1]]then return'DB TABLE ALREADY EXISTS'end
            if not(data[1]and data[2])then return'DB LACKS NAME,TEMPLATE'end
            local d3=type(data[3])
            if not(type(data[2])=='table'and(d3=='table'or d3=='nil'))then return'DB TEMPLATE,METADATA MUST BE A TABLE'end
            data[3]=data[3]or{}
            local ret={}
            local ty=''
            local int=0
            for k,v in pairs(data[2])do
                ty=type(v)
                ret[k]=((ty=='string'or ty=='number'or ty=='boolean')and ty or'string')
                int=int+1
            end
            if int==0 then return'DB TEMPLATE MUST CONTAIN AT LEAST 1 FIELD'end
            local md={}
            local int2=0
            local ty=''
            local ap=false
            for k,v in pairs(data[3])do
                if ret[k]then
                    ty=type(v)
                    if ty=='table'then
                        for _,x in pairs(v)do
                            if x=='NOT NULL'or x=='NULL'or x=='INCREMENT'or x=='PRIMARY'then
                                md[k]=md[k]or{}md[k][#md[k]+1]=x
                                if x=='INCREMENT'then
                                    md[k]=md[k].inc=0
                                end
                                if not ap then
                                    ap=true
                                else
                                    return 'DB METADATA CAN NOT CONTAIN MORE THAN ONE PRIMARY'
                                end
                                int2=int2+1
                            else
                                print('^1DB METADATA IS INVALID:'..data[1]..' '..k..'^7')
                            end
                        end
                    elseif ty=='string'then
                        if v=='NOT NULL'or v=='NULL'or v=='INCREMENT'or v=='PRIMARY'then
                            md[k]=md[k]or{}md[k][#md[k]+1]=v
                            if v=='INCREMENT'then
                                md[k].inc=0
                                if ret[k]~='number'then
                                    return 'DB FIELD:'..k..' HAS TO BE A NUMBER TO BE INCREMENTED'
                                end
                                if not ap then
                                    ap=true
                                else
                                    return 'DB METADATA CAN NOT CONTAIN MORE THAN ONE PRIMARY'
                                end
                            end
                            int2=int2+1
                        else
                            print('^1DB METADATA IS INVALID:'..data[1]..' '..k..'^7')
                        end
                    else
                        print('^1DB METADATA IS INVALID:'..data[1]..' '..k..'^7')
                    end
                else
                    print('^1DB METADATA FIELD IS INVALID:'..data[1]..' '..k..'^7')
                end
            end
            for _,v in pairs(md)do
                local null
                local nnull
                for i=1,#v do
                    if v[i]=='NULL'then
                        null=true
                        if nnull then
                            remove(v,nnull)
                            break
                        end
                    elseif v[i]=='NOT NULL'then
                        nnull=i
                        if null then
                            remove(v,i)
                            break
                        end
                    end
                end
                if null and nnull then
                    print('^1NULL AND NOT NULL CAN NOT BE ASSIGNED TO ONE FIELD; ASSIGNED NULL^7')
                end
            end
            DB.Database[data[1]]={}
            DB.DatabaseTemplate[data[1]]=ret
            DB.DatabaseMetadata[data[1]]=md
            saver(resource,'db/'..data[1]..'.ffdb','[]')
            saver(resource,'db/'..data[1]..'.fftp',encode(ret))
            saver(resource,'db/'..data[1]..'.ffmd',encode(md))
            return'DB CREATED TABLE:'..data[1]..' FIELDS:'..int..' METADATA:'..int2
        elseif cmd=='DELETE'or cmd=='DROP'then
            if not DB.Database[data[1]]then return'DB TABLE DOES NOT EXISTS'end
            if not(data[1])then return'DB LACKS TABLE NAME'end
            if not(type(data[1])=='string')then return'DB TABLE NAME MUST BE A STRING'end
            local path=GetResourcePath(resource)..'/db/'..data[1]
            os.remove(path..'.fftp')
            os.remove(path..'.ffdb')
            os.remove(path..'.ffmd')
            DB.Database[data[1]]=nil
            DB.DatabaseTemplate[data[1]]=nil
            DB.DatabaseMetadata[data[1]]=nil
            return 'DB DROPPED TABLE:'..data[1]
        else
            return'DB COMMAND NOT RECOGNISED'
        end
    end
end

local function UpdateDB()
    return function(cmd,...)
        if type(cmd)~='string'then return'DB FAILED TO RECOGNIZE COMMAND'end
        local data={...}
        local name=cmd:gsub(' ','')
        local sub=name:sub(1,10)
        if sub=='INSERTINTO'then
            local d=name:sub(11,cmd:len())
            if not DB.Database[d]then return'DB TABLE DOES NOT EXISTS:'..d end
            local db=data[1]
            local res={}
            for k,v in pairs(DB.DatabaseTemplate[d])do
                local ty=type(db[k])
                local primary,null,inc=nil,true,nil
                local inctc=false
                local keys=""
                for _,x in pairs(DB.DatabaseMetadata[d])do
                    if type(x)=='table'then
                        for i=1,#x do
                            if x[i]=='NOT NULL'then
                                null=false
                            elseif x[i]=='PRIMARY'then
                                for j=1,#DB.Database[d]do
                                    if DB.Database[d][j][k]==db[k]and db[k]~=nil then
                                        return 'DB PRIMARY KEY ALREADY EXISTS:'..db[k]
                                    elseif db[k]==nil then
                                        if not inc then
                                            inctc=true
                                        end
                                    elseif DB.Database[d][j][k]~=nil then
                                        keys=keys..DB.Database[d][j][k]..' '
                                    end
                                end
                                primary=true
                            elseif x[i]=='INCREMENT'then
                                inc=true
                            end
                        end
                    end
                end
                if inc and v=='string'then return'DB FIELD:'..k..' HAS TO BE A NUMBER TO BE INCREMENTED; CORRUPTED DATABASE? UPDATE DB MANUALLY'end
                if inctc then
                    if inc then
                        ty='number'
                        v='number'
                        db[k]=DB.DatabaseMetadata[d].inc+1
                        keys=keys..v..' '
                    else
                        return'DB PRIMARY KEY CAN NOT BE NULL'
                    end
                end
                if inc and ty~='number'then return'DB FIELD:'..k..' HAS TO BE A NUMBER TO BE INCREMENTED; CORRUPTED DATABASE? UPDATE DB MANUALLY'end
                if db[k]and ty==v then
                    if inc then
                        if DB.DatabaseMetadata[d].inc>=db[k] then
                            return 'DB INCREMENT FAILED IN FIELD:'..k..' DB INCREMENT >= VALUE; REMOVE THIS VALUE MANUALLY'
                        else
                            DB.DatabaseMetadata[d].inc=db[k]
                            res[k]=db[k]
                        end
                    end
                elseif db[k]and ty=='table'and v=='string'then
                    res[k]=encode(db[k])
                elseif not db[k]then
                    if inc then
                        DB.DatabaseMetadata[d].inc=DB.DatabaseMetadata[d].inc+1
                        if keys:match(DB.DatabaseMetadata[d].inc)then return'DB PRIMARY ALREADY EXISTS:'..DB.DatabaseMetadata[d].inc end
                        res[k]=DB.DatabaseMetadata[d].inc
                    elseif not null then
                        return 'DB FIELD:'..k..' CAN NOT BE NULL'
                    else
                        res[k]='null'
                    end
                else
                    return 'DB FIELD:'..k..' HAS VALUE TYPE OF:'..v..' GOT:'..ty
                end
            end
            insert(DB.Database[d], res)
            saver(resource, 'db/'..d..'.ffdb', encode(DB.Database[d]), -1)
            saver(resource, 'db/'..d..'.ffmd', encode(DB.DatabaseMetadata[d]), -1)
            return 'DB INSERTED DATA INTO:'..d
        elseif sub=='DELETEFROM'then
            local d=name:sub(11,name:len())
            if not DB.Database[d]then return'DB TABLE DOES NOT EXISTS:'..d end
            local db=data[1]
            local int=0
            local tr={}
            for i=1,#DB.Database[d]do
                local brk=false
                for k,v in pairs(db)do
                    if DB.Database[d][i][k]~=v then
                        brk=true
                        break
                    end
                end
                if not brk then
                    int=int+1
                    tr[#tr+1]=i
                end
            end
            for i=1,#tr do
                remove(DB.Database[d], tr[(#tr+1)-i])
            end
            saver(resource, 'db/'..d..'.ffdb', encode(DB.Database[d]), -1)
            return'DELETED '..int..' FIELDS FROM:'..d
        elseif sub=='SELECTFROM'then
            local d=name:sub(11,name:len())
            if not DB.Database[d]then return{},'DB TABLE DOES NOT EXISTS:'..d end
            local ret={}
            local from=((type(data[1])=='table'and data[1])or{'*'})
            local where=((type(data[2])=='table'and data[2])or{'*'})
            for i=1,#DB.Database[d]do
                local temp={}
                if where[1]=='*'then
                    if from[1]=='*'then
                        ret[#ret+1]=DB.Database[d][i]
                    else
                        for j=1,#from do
                            if DB.Database[d][i][from[j]]then
                                temp[from[j]]=DB.Database[d][i][from[j]]
                            end
                        end
                        ret[#ret+1]=temp
                    end
                else
                    local brk=false
                    for k,v in pairs(where)do
                        if DB.Database[d][i][k]~=v then
                            brk=true
                            break
                        end
                    end
                    if not brk then
                        if from[1]=='*'then
                            ret[#ret+1]=DB.Database[d][i]
                        else
                            for j=1,#from do
                                if DB.Database[d][i][from[j]]then
                                    temp[from[j]]=DB.Database[d][i][from[j]]
                                end
                            end
                            ret[#ret+1]=temp
                        end
                    end
                end
            end
            return ret,'DB RETURNED '..#ret..' RESULTS FROM:'..d
        end
    end
end

function DB.New(db)
    if db then return ManageDB()end
    return UpdateDB()
end

DB.Ready(function()
    local db = DB.New(true)
    local res = db('CREATE', 'users', {
        id=1,
        name='',
        license='',
        md=''
    }, {
        id={'PRIMARY', 'INCREMENT', 'NOT NULL'},
        name='NOT NULL',
        license='NOT NULL'
    })
    print(res)
end)
