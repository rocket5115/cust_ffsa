local obj = Modules['ProjectManager']
--[[Start of Player Object]]--
local users = {}
AddListener('obj:player:handler', function(obj)
    users[obj.source]=obj
end)
obj.AddFunction('GetPlayerFromId', function(id)
    return users[id]or{}
end)
obj.AddFunction('GetPlayers', function()
    local retval={}
    for k,v in pairs(users)do
        retval[#retval+1]=v
    end
    return retval
end)
obj.AddFunction('GetPlayerFromIdentifier', function(identifier)
    local players=obj.GetPlayers()
    for i=1,#players do
        for j=1,#players[i].identifiers do
            if players[i].identifiers[j]:match(identifier)then
                return players[i]
            end
        end
    end
    return{}
end)
--[[End of Player Object]]--
--[[Start of DB Object]]--
local items = {}
obj.AddFunction('RegisterItem', function(item, limit)
    local db = DB.New()
    local res = db('SELECT FROM items', {'name'}, {name=item})
    if #res>0 then
        return false
    end
    local res = db('INSERT INTO items', {name=item,limit=limit})
    if(res:match('DB INSERTED DATA'))then
        items[item]={item,limit}
    end
end)
obj.AddFunction('GetItem', function(item)
    return items[item]
end)
--[[End of DB Object]]--