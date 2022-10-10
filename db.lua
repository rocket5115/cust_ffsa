local resource = GetCurrentResourceName()
local encode,decode,unpack,insert,remove,saver,loadr,tostring,tonumber,type,path = json.encode,json.decode,table.unpack,table.insert,table.remove,SaveResourceFile,LoadResourceFile,tostring,tonumber,type,GetResourcePath(resource)
local ready = false
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

CreateThread(function()
    local debugdb=""
    local debugtp=""
    local debugmd=""
    for _,v in pairs(scandir(GetResourcePath(resource)..'/db'))do
        local l=v:len()
        local n=v:sub(1,l-5)
        local r=v:sub(l-4,l)
        local rn=decode(loadr(resource,'db/'..v))
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
    ready=true
    if(debugdb~="")then print(debugdb)end
    if(debugtp~="")then print(debugtp)end
    if(debugmd~="")then print(debugmd)end
end)

local handlers={}

function DB.Ready(handler)
    if ready then
        CreateThread(handler)
    else
        handlers[#handlers+1]=handler
    end
end

CreateThread(function()
    repeat Wait(10)until ready
    for i=1,#handlers do
        CreateThread(handlers[i])
    end
end)

function DB.New(db)
    return(db and DB.ManageDB()or DB.UpdateDB())
end

function DB.UpdateDB()
    return(function(cmd,...)
        cmd=cmd:gsub(' ', ''):gsub('AND',','):upper()
        local n=cmd:sub(1,10)
        local data={...}
        if n=='INSERTINTO'then
            local d=cmd:match('INSERTINTO(%a+)VALUES')
            if not d then 
                d=cmd:match('INSERTINTO(%a+)'):lower()
            else 
                d=d:lower()
            end
            if not d or not DB.Database[d]then return 'DB:'..d..' NOT FOUND'end
            local args=cmd:match('INSERTINTO'..d:upper()..'%((%a+)')
            if args==nil then
                args=cmd:match('VALUES%((%S+)%)'):lower()
                local first,last=0
                local var=','..args:lower()..','
                local res={}
                while true do
                    first,last=var:find(",(%a+)=@%a+,", first+1)
                    if not first then break end
                    res[#res+1]=var:sub(first,last):gsub(',','')
                end
                local values=data[1]
                local chgval={}
                for i=1,#res do
                    local f1,l1=res[i]:find("(%a+)=")
                    local val,ret=res[i]:sub(f1,l1-1),res[i]:sub(l1+1,res[i]:len())
                    local ty=type(values[ret])
                    if not DB.DatabaseTemplate[d][val]then
                        return 'DB:'..d..' VALUE:'..val..' COULD NOT BE FOUND'
                    elseif not values[ret]then
                        return 'DB:'..d..' VALUE:'..ret..' NOT PRESENT'
                    elseif DB.DatabaseTemplate[d][val]~=ty then
                        if DB.DatabaseTemplate[d][val]=='string'and ty=='number'then
                            values[ret]=tostring(values[ret])
                        elseif DB.DatabaseTemplate[d][val]=='number'and ty=='string'then
                            values[ret]=tonumber(values[ret])
                            if values[ret]==nil then
                                return 'DB:'..d..' VALUE:'..ret..' IS NOT A NUMBER'
                            end
                        else
                            return 'DB:'..d..' VALUE:'..ret..' EXPECTED:'..DB.DatabaseTemplate[d][val]:upper()..' GOT:'..ty:upper()
                        end                    
                    end
                    chgval[val]=ret
                end
                local tinc=""
                local prim=""
                for k,v in pairs(DB.DatabaseMetadata[d])do
                    local primary,increment,null,unique,v=false,false,nil,false,v
                    if type(v)~='table'then
                        v={}
                    end
                    for _,x in ipairs(v)do
                        if x=='NOT NULL'then
                            null=false
                        elseif x=='NULL'then
                            null=true
                        elseif x=='PRIMARY'then
                            primary=true
                        elseif x=='INCREMENT'then
                            increment=true
                        elseif x=='UNIQUE'then
                            unique=true
                        end
                    end
                    if primary then
                        if values[chgval[k]]==nil then
                            if increment and DB.DatabaseTemplate[d][k]=='number'then
                                tinc=k
                            else
                                return 'DB:'..d..' PRIMARY KEY:'..k..' CANNOT BE NULL'
                            end
                        else
                            if type(values[chgval[k]])=='number'and DB.DatabaseTemplate[d][k]=='number'then
                                if values[chgval[k]]<=v.inc then
                                    return 'DB:'..d..' PRIMARY KEY:'..k..' HAS TO BE GREATER THAN '..v.inc
                                else
                                    tinc=values[chgval[k]]
                                    prim=k
                                end
                            else
                                for i=1,#DB.Database[d]do
                                    if DB.Database[d][i][k]==values[chgval[k]]then
                                        return 'DB:'..d..' PRIMARY KEY:'..k..' CANNOT CONTAIN ALREADY ASSIGNED VALUE:'..values[chgval[k]]
                                    end
                                end
                                tinc=values[chgval[k]]
                            end
                        end
                    elseif unique then
                        for i=1,#DB.Database[d]do
                            if DB.Database[d][i][k]==values[chgval[k]]then
                                return 'DB:'..d..' UNIQUE KEY:'..k..' CANNOT CONTAIN ALREADY ASSIGNED VALUE:'..values[chgval[k]]
                            end
                        end
                    end
                    if null==false then
                        if not values[chgval[k]]and not increment then
                            return 'DB:'..d..' FIELD:'..k..' CANNOT BE NULL'
                        end
                    end
                end
                local retval={}
                for k,v in pairs(DB.DatabaseTemplate[d])do
                    retval[k]='NULL'
                end
                for k,v in pairs(values)do
                    retval[k:gsub('@','')]=v
                end
                if tinc~=""then
                    local ty=type(tinc)
                    if ty=='number'then
                        DB.DatabaseMetadata[d].inc=tinc
                    elseif ty=='string'then
                        DB.DatabaseMetadata[d].inc=DB.DatabaseMetadata[d].inc+1
                        retval[tinc]=DB.DatabaseMetadata[d].inc
                    else
                        return 'DB:'..d..' INVALID PRIMARY KEY'
                    end
                end
                DB.Database[d][#DB.Database[d]+1]=retval
                saver(resource, 'db/'..d..'.ffdb', encode(DB.Database[d]),-1)
                saver(resource, 'db/'..d..'.ffmd', encode(DB.DatabaseMetadata[d]),-1)
                return 'DB:'..d..' INSERTED DATA INTO:'..d
            elseif args~=nil then
                local args,args2=cmd:match(d:upper()..'%((%S+)%)VALUES'):lower(),cmd:match('VALUES%((%S+)%)'):lower()
                local first,last=0
                local var=','..args:lower()..','
                local res={}
                while true do
                    first,last=var:find(",(%a+),", first+1)
                    if not first then break end
                    res[#res+1]={var:sub(first,last):gsub(',','')}
                end
                first,last=0
                var=','..args2:lower()..','
                local i=1
                while true do
                    first,last=var:find(",@(%a+),", first+1)
                    if not first then break end
                    res[i][2]=var:sub(first,last):gsub(',','')
                    i=i+1
                end
                local values=data[1]
                local chgval={}
                for i=1,#res do
                    local val,ret=res[i][1],res[i][2]
                    local ty=type(values[ret])
                    if not DB.DatabaseTemplate[d][val]then
                        return 'DB:'..d..' VALUE:'..val..' COULD NOT BE FOUND'
                    elseif not values[ret]then
                        return 'DB:'..d..' VALUE:'..ret..' NOT PRESENT'
                    elseif DB.DatabaseTemplate[d][val]~=ty then
                        if DB.DatabaseTemplate[d][val]=='string'and ty=='number'then
                            values[ret]=tostring(values[ret])
                        elseif DB.DatabaseTemplate[d][val]=='number'and ty=='string'then
                            values[ret]=tonumber(values[ret])
                            if values[ret]==nil then
                                return 'DB:'..d..' VALUE:'..ret..' IS NOT A NUMBER'
                            end
                        else
                            return 'DB:'..d..' VALUE:'..ret..' EXPECTED:'..DB.DatabaseTemplate[d][val]:upper()..' GOT:'..ty:upper()
                        end                    
                    end
                    chgval[val]=ret
                end
                local tinc=""
                local prim=""
                for k,v in pairs(DB.DatabaseMetadata[d])do
                    local primary,increment,null,unique,v=false,false,nil,false,v
                    if type(v)~='table'then
                        v={}
                    end
                    for _,x in ipairs(v)do
                        if x=='NOT NULL'then
                            null=false
                        elseif x=='NULL'then
                            null=true
                        elseif x=='PRIMARY'then
                            primary=true
                        elseif x=='INCREMENT'then
                            increment=true
                        elseif x=='UNIQUE'then
                            unique=true
                        end
                    end
                    if primary then
                        if values[chgval[k]]==nil then
                            if increment and DB.DatabaseTemplate[d][k]=='number'then
                                tinc=k
                            else
                                return 'DB:'..d..' PRIMARY KEY:'..k..' CANNOT BE NULL'
                            end
                        else
                            if type(values[chgval[k]])=='number'and DB.DatabaseTemplate[d][k]=='number'then
                                if values[chgval[k]]<=v.inc then
                                    return 'DB:'..d..' PRIMARY KEY:'..k..' HAS TO BE GREATER THAN '..v.inc
                                else
                                    tinc=values[chgval[k]]
                                    prim=k
                                end
                            else
                                for i=1,#DB.Database[d]do
                                    if DB.Database[d][i][k]==values[chgval[k]]then
                                        return 'DB:'..d..' PRIMARY KEY:'..k..' CANNOT CONTAIN ALREADY ASSIGNED VALUE:'..values[chgval[k]]
                                    end
                                end
                                tinc=values[chgval[k]]
                            end
                        end
                    elseif unique then
                        for i=1,#DB.Database[d]do
                            if DB.Database[d][i][k]==values[chgval[k]]then
                                return 'DB:'..d..' UNIQUE KEY:'..k..' CANNOT CONTAIN ALREADY ASSIGNED VALUE:'..values[chgval[k]]
                            end
                        end
                    end
                    if null==false then
                        if not values[chgval[k]]and not increment then
                            return 'DB:'..d..' FIELD:'..k..' CANNOT BE NULL'
                        end
                    end
                end
                local retval={}
                for k,v in pairs(DB.DatabaseTemplate[d])do
                    retval[k]='NULL'
                end
                for k,v in pairs(values)do
                    retval[k:gsub('@','')]=v
                end
                if tinc~=""then
                    local ty=type(tinc)
                    if ty=='number'then
                        DB.DatabaseMetadata[d].inc=tinc
                    elseif ty=='string'then
                        DB.DatabaseMetadata[d].inc=DB.DatabaseMetadata[d].inc+1
                        retval[tinc]=DB.DatabaseMetadata[d].inc
                    else
                        return 'DB:'..d..' INVALID PRIMARY KEY'
                    end
                end
                DB.Database[d][#DB.Database[d]+1]=retval
                saver(resource, 'db/'..d..'.ffdb', encode(DB.Database[d]),-1)
                saver(resource, 'db/'..d..'.ffmd', encode(DB.DatabaseMetadata[d]),-1)
                return 'DB:'..d..' INSERTED DATA INTO:'..d
            end
        elseif n=='DELETEFROM'then
            local d=cmd:match('DELETEFROM(%a+)WHERE'):lower()
            if not d or not DB.Database[d]then return 'DB:'..d..' NOT FOUND'end
            local args=cmd:match('WHERE(%S+)'):gsub('AND',','):lower():gsub('%(', ''):gsub('%)','')
            local first,last=0
            local var=','..args:lower()..','
            local res={}
            while true do
                first,last=var:find(",(%a+)=@%a+,", first+1)
                if not first then break end
                res[#res+1]=var:sub(first,last):gsub(',','')
            end
            local values=data[1]
            local chgval={}
            for i=1,#res do
                local f1,l1=res[i]:find("(%a+)=")
                local val,ret=res[i]:sub(f1,l1-1),res[i]:sub(l1+1,res[i]:len())
                chgval[ret]=val
            end
            local deleted={}
            for i=1,#DB.Database[d]do
                local pass=true
                for k,v in pairs(values)do
                    if DB.Database[d][i][chgval[k]]~=v then
                        pass=false
                        break
                    end
                end
                if pass then
                    deleted[#deleted+1]=i
                end
            end
            for i=1,#deleted do
                table.remove(DB.Database[d], deleted[(#deleted+1)-i])
            end
            saver(resource, 'db/'..d..'.ffdb', encode(DB.Database[d]),-1)
            return 'DB:'..d..' DELETED:'..#deleted..' FIELDS FROM DB:'..d
        elseif n:sub(1,6)=='SELECT'then
            local d=cmd:match('FROM(%a+)WHERE')
            if not d then d=cmd:match('FROM(%a+)'):lower()else d=d:lower()end
            if not d or not DB.Database[d]then return 'DB:'..d..' NOT FOUND'end
            local args=cmd:match('WHERE(%S+)')
            if args==nil then
                local retval={}
                for k,v in pairs(DB.Database[d])do
                    retval[k]=v
                end
                return retval
            end
            local first,last=0
            local var=(','..args:lower()..','):gsub('AND', ',')
            local res={}
            while true do
                first,last=var:find(",(%a+)=@%a+,", first+1)
                if not first then break end
                res[#res+1]=var:sub(first,last):gsub(',','')
            end
            local values=data[1]
            local chgval={}
            for i=1,#res do
                local f1,l1=res[i]:find("(%a+)=")
                local val,ret=res[i]:sub(f1,l1-1),res[i]:sub(l1+1,res[i]:len())
                chgval[ret]=val
            end
            local search={}
            first,last=0,nil
            var=(','..cmd:match('(%a+%S+)FROM'):gsub('SELECT','')..','):lower()
            while true do
                first,last=var:find(",(%a+),", first+1)
                if not first then break end
                search[#search+1]=var:sub(first,last):gsub(',','')
            end
            if search[1]=='*'then
                local retval={}
                for i=1,#DB.Database[d]do
                    local pass=true
                    for k,v in pairs(values)do
                        if DB.Database[d][i][chgval[k]]~=v then
                            pass=false
                            break
                        end
                    end
                    if pass then
                        retval[#retval+1]=DB.Database[d][i]
                    end
                end
                return retval
            else
                local retval={}
                for i=1,#DB.Database[d]do
                    local pass=true
                    for k,v in pairs(values)do
                        if DB.Database[d][i][chgval[k]]~=v then
                            pass=false
                            break
                        end
                    end
                    if pass then
                        local x={}
                        for j=1,#search do
                            if DB.Database[d][i][search[j]]~=nil then
                                x[search[j]]=DB.Database[d][i][search[j]]
                            end
                        end
                        retval[#retval+1]=x
                    end
                end
                return retval
            end
        end
    end)
end
--[[
    local db = DB.New()
    db('INSERT INTO users (name,identifier) VALUES(@name,@identifier)', {
        ['@name']='test',
        ['@identifier']='identifier'
    })
    db('INSERT INTO users VALUES(name=@name,identifier=@identifier)', {
        ['@name']='test',
        ['@identifier']='qwe'
    })
]]
--[[
    local db = DB.New()
    db('DELETE FROM users WHERE(name=@name,identifier=@identifier)', {
        ['@name']='name',
        ['@identifier']='identifier'
    })
    db('DELETE FROM users WHERE name=@name AND identifier=@identifier', {
        ['@name']='name',
        ['@identifier']='identifier'
    })    
--]]
--[[db('SELECT * FROM users WHERE name=@name AND identifier=@identifier', {
    ['@name']='name',
    ['@identifier']='identifier'
})--]]

function DB.ManageDB()
    return function(cmd,...)
        local n=cmd
        cmd=cmd:gsub(' ', ''):upper():gsub('`','')
        if cmd:sub(1,11)=='CREATETABLE'then
            local d=cmd:match('CREATETABLE(%a+)%('):lower()
            if DB.Database[d]then return 'DB:'..d..' ALREADY EXISTS'end
            local args=','..n:gsub(' ',''):match('%((%S+)%)')..','
            local first,last=0
            local res={}
            while true do
                first,last=args:find(",(%a+)%a+,", first+1)
                if not first then break end
                res[#res+1]=args:sub(first,last):gsub(',','')
            end
            print('^3DB CREATE TABLE IS CASE SENSITIVE. PLEASE CONFIRM ANY CHANGES DONE TO DB^7')
            local retval = {database={},template={},metadata={}}
            for i=1,#res do
                local primary,increment,null,unique=res[i]:match('PRIMARY'),(res[i]:match('INC')or res[i]:match('INCREMENT')),not(res[i]:match('NOTNULL')or res[i]:match('NOTNIL')),res[i]:match('UNIQUE')
                local valuetype=(((res[i]:match('STRING')or res[i]:match('VARCHAR')and'string')or(res[i]:match('INT')or res[i]:match('INTEGER')or res[i]:match('NUMBER'))and'number')or(res[i]:match('BOOL')and'boolean'))
                local db=res[i]:match('%l%a+%l')
                local x=""
                if not db then 
                    if res[i]:sub(1,1):upper()~=res[i]:sub(1,1)then
                        db=""
                        for j=1,res[i]:len()do
                            x=res[i]:sub(j,j)
                            if x:upper()~=x then
                                db=db..x
                            else
                                break
                            end
                        end
                    else
                        return 'DB:'..d..' FIELD:'..i..' HAS NO NAME ^1THIS FUNCTION IS CASE SENSITIVE^7'
                    end
                end
                if valuetype==nil then
                    return 'DB:'..d..' FIELD:'..db..' HAS VALUE OF NULL'
                end
                retval.template[db]=valuetype
                retval.metadata[db]={(null==nil and'NULL'or'NOT NULL')}
                if unique~=nil then
                    if valuetype=='boolean'then
                        print('^3DB:'..d..' FIELD:'..db..' HAS VALUE OF:'..valuetype..' SET AS UNIQUE KEY^7')
                    end
                    retval.metadata[db][#retval.metadata[db]+1]='UNIQUE'
                end
                if primary~=nil then
                    if valuetype=='boolean'then
                        print('^3DB:'..d..' FIELD:'..db..' HAS VALUE OF:'..valuetype..' SET AS PRIMARY KEY^7')
                    end
                    retval.metadata[db][#retval.metadata[db]+1]='PRIMARY'
                end
                if increment~=nil then
                    if valuetype~='number'then
                        return'DB:'..d..' FIELD:'..db..' HAS VALUE OF '..valuetype..' EXPECTED NUMBER TO INCREMENT'
                    end
                    retval.metadata[db][#retval.metadata[db]+1]='INCREMENT'
                end
            end
            DB.Database[d]={}
            DB.DatabaseTemplate[d]={}
            DB.DatabaseMetadata[d]={}
            local tem,met=0,0
            for k,v in pairs(retval.template)do
                DB.DatabaseTemplate[d][k]=v
                tem=tem+1
            end
            local primary=false
            for k,v in pairs(retval.metadata)do
                DB.DatabaseMetadata[d][k]=v
                for _,v in ipairs(v)do
                    if v=='INCREMENT'then
                        DB.DatabaseMetadata[d].inc=0
                        if not primary then
                            primary=true
                        else
                            return 'DB:'..d..' PRIMARY KEY ALREADY ASSIGNED'
                        end
                    end
                end
                met=met+1
            end
            saver(resource, 'db/'..d..'.ffdb', encode(DB.Database[d]),-1)
            saver(resource, 'db/'..d..'.fftp', encode(DB.DatabaseTemplate[d]),-1)
            saver(resource, 'db/'..d..'.ffmd', encode(DB.DatabaseMetadata[d]),-1)
            return'DB:'..d..' CREATED TABLE:'..d..' FIELDS:'..tem..' METADATA:'..met
        elseif cmd:sub(1,9)=='DROPTABLE'then
            local d=cmd:match('DROPTABLE(%a+)'):lower()
            if not DB.Database[d]then return 'DB:'..d..' DOES NOT EXISTS'end
            DB.Database[d]=nil
            DB.DatabaseTemplate[d]=nil
            DB.DatabaseMetadata[d]=nil
            local path=path..'/db/'..d
            os.remove(path..'.ffdb')
            os.remove(path..'.fftp')
            os.remove(path..'.ffmd')
            return 'DB:'..d..' DROPPED TABLE:'..d
        end
    end
end
