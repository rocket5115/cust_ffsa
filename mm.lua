Missions = {}
local users = {}
local function MinimizeCode(code)
    code=code:gsub('\n', ' ')
    while code:match('  ')do
        code=code:gsub('  ',' ')
    end
    return code
end

local inventory = {}
local weapons = {}
local addons = {}
local metadata = {}

local items = {}

DB.Ready(function()
    local db = DB.New()
    local result = db('SELECT', 'users')
    local decode = json.decode
    for i=1,#result do
        inventory[result[i].identifier]=decode(result[i].inventory)
        weapons[result[i].identifier]=decode(result[i].weapons)
        addons[result[i].identifier]=decode(result[i].addons)
        metadata[result[i].identifier]=decode(result[i].metadata)
    end
    local result = db('SELECT', 'items')
    for i=1,#result do
        items[result[i].name]={name=result[i].name,limit=result[i].limit,mission=result[i].mission}
    end
end)

local function getvalue(list,value)
    if type(value)=='string'then
        for _,v in pairs(list)do
            if string.match(v,value)then
                return v
            end
        end
        return nil
    end
    for _,v in pairs(list)do
        if v==value then
            return v
        end
    end
    return nil
end

local weapons={[GetHashKey('WEAPON_PISTOL')]=1,[GetHashKey('WEAPON_COMBATPISTOL')]=1,[GetHashKey('WEAPON_APPISTOL')]=1,[GetHashKey('WEAPON_COMBATPDW')]=1,[GetHashKey('WEAPON_MACHINEPISTOL')]=1,[GetHashKey('WEAPON_MICROSMG')]=1,[GetHashKey('WEAPON_MINISMG')]=1,[GetHashKey('WEAPON_PISTOL_MK2')]=1,[GetHashKey('WEAPON_SNSPISTOL')]=1,[GetHashKey('WEAPON_SNSPISTOL_MK2')]=1,[GetHashKey('WEAPON_VINTAGEPISTOL')]=1,[GetHashKey('WEAPON_ADVANCEDRIFLE')]=1,[GetHashKey('WEAPON_ASSAULTSMG')]=1,[GetHashKey('WEAPON_BULLPUPRIFLE')]=1,[GetHashKey('WEAPON_BULLPUPRIFLE_MK2')]=1,[GetHashKey('WEAPON_CARBINERIFLE')]=1,[GetHashKey('WEAPON_CARBINERIFLE_MK2')]=1,[GetHashKey('WEAPON_COMPACTRIFLE')]=1,[GetHashKey('WEAPON_DOUBLEACTION')]=1,[GetHashKey('WEAPON_GUSENBERG')]=1,[GetHashKey('WEAPON_HEAVYPISTOL')]=1,[GetHashKey('WEAPON_MARKSMANPISTOL')]=1,[GetHashKey('WEAPON_PISTOL50')]=1,[GetHashKey('WEAPON_REVOLVER')]=1,[GetHashKey('WEAPON_REVOLVER_MK2')]=1,[GetHashKey('WEAPON_SMG')]=1,[GetHashKey('WEAPON_SMG_MK2')]=1,[GetHashKey('WEAPON_SPECIALCARBINE')]=1,[GetHashKey('WEAPON_SPECIALCARBINE_MK2')]=1,[GetHashKey('WEAPON_ASSAULTRIFLE')]=1,[GetHashKey('WEAPON_ASSAULTRIFLE_MK2')]=1,[GetHashKey('WEAPON_COMBATMG')]=1,[GetHashKey('WEAPON_COMBATMG_MK2')]=1,[GetHashKey('WEAPON_HEAVYSNIPER')]=1,[GetHashKey('WEAPON_HEAVYSNIPER_MK2')]=1,[GetHashKey('WEAPON_MARKSMANRIFLE')]=1,[GetHashKey('WEAPON_MARKSMANRIFLE_MK2')]=1,[GetHashKey('WEAPON_MG')]=1,[GetHashKey('WEAPON_MINIGUN')]=1,[GetHashKey('WEAPON_MUSKET')]=1,[GetHashKey('WEAPON_RAILGUN')]=1,[GetHashKey('WEAPON_ASSAULTSHOTGUN')]=1,[GetHashKey('WEAPON_BULLUPSHOTGUN')]=1,[GetHashKey('WEAPON_DBSHOTGUN')]=1,[GetHashKey('WEAPON_HEAVYSHOTGUN')]=1,[GetHashKey('WEAPON_PUMPSHOTGUN')]=1,[GetHashKey('WEAPON_PUMPSHOTGUN_MK2')]=1,[GetHashKey('WEAPON_SAWNOFFSHOTGUN')]=1,[GetHashKey('WEAPON_SWEEPERSHOTGUN')]=1,[GetHashKey('WEAPON_BATTLEAXE')]=1,[GetHashKey('WEAPON_BOTTLE')]=1,[GetHashKey('WEAPON_DAGGER')]=1,[GetHashKey('WEAPON_HATCHET')]=1,[GetHashKey('WEAPON_KNIFE')]=1,[GetHashKey('WEAPON_MACHETE')]=1,[GetHashKey('WEAPON_SWITCHBLADE')]=1,[GetHashKey('WEAPON_BALL')]=1,[GetHashKey('WEAPON_FLASHLIGHT')]=1,[GetHashKey('WEAPON_KNUCKLE')]=1,[GetHashKey('WEAPON_NIGHTSTICK')]=1,[GetHashKey('WEAPON_SNOWBALL')]=1,[GetHashKey('WEAPON_UNARMED')]=1,[GetHashKey('WEAPON_PARACHUTE')]=1,[GetHashKey('WEAPON_NIGHTVISION')]=1,[GetHashKey('WEAPON_BAT')]=1,[GetHashKey('WEAPON_CROWBAR')]=1,[GetHashKey('WEAPON_FIREEXTINGUISHER')]=1,[GetHashKey('WEAPON_FIRWORK')]=1,[GetHashKey('WEAPON_GOLFLCUB')]=1,[GetHashKey('WEAPON_HAMMER')]=1,[GetHashKey('WEAPON_PETROLCAN')]=1,[GetHashKey('WEAPON_POOLCUE')]=1,[GetHashKey('WEAPON_WRENCH')]=1,[GetHashKey('WEAPON_GRENADE')]=1,[GetHashKey('WEAPON_COMPACTLAUNCHER')]=1,[GetHashKey('WEAPON_HOMINGLAUNCHER')]=1,[GetHashKey('WEAPON_PIPEBOMB')]=1,[GetHashKey('WEAPON_PROXMINE')]=1,[GetHashKey('WEAPON_RPG')]=1,[GetHashKey('WEAPON_STICKYBOMB')]=1,[GetHashKey('WEAPON_STUNGUN')]=1,[GetHashKey('WEAPON_MOLOTOV')]=1,[GetHashKey('WEAPON_FLARE')]=1,[GetHashKey('WEAPON_FLAREGUN')]=1,[GetHashKey('WEAPON_BZGAS')]=1,[GetHashKey('WEAPON_SMOKEGRENADE')]=1}

local function CreatePlayerHandler(source,identifier,identifiers)
    local self = {}
    self.source = source
    self.name = GetPlayerName(self.source)
    self.identifier = identifier
    self.identifiers = identifiers
    self.tokens = GetPlayerTokens(self.source)
    self.inventory = {}
    self.weapons = {}
    self.addons = {}
    self.TriggerEvent = function(event,...)
        TriggerClientEvent(event, self.source, ...)
    end
    self.giveWeapon = function(weapon,ammo,inhand)
        local prs=weapon
        weapon=(type(weapon)=='string'and GetHashKey(weapon)or weapon)
        if not weapons[weapon]then
            local chk=GetHashKey('weapon_'..prs)
            if not weapons[chk]then
                print('^1Is '..prs..' A Valid Weapon?^7')
                return
            else
                weapon=chk
            end
        end
        if not weapons[weapon]then
            return
        end
        self.weapons[weapon]={name=prs,ammo=tonumber(ammo)or 255}
        self.TriggerEvent('ffsa:GiveWeapon', weapon, weapons[weapon].ammo)
        return true
    end
    self.removeWeapon = function(weapon)
        local prs=weapon
        weapon=(type(weapon)=='string'and GetHashKey(weapon)or weapon)
        if not weapons[weapon]then
            local chk=GetHashKey('weapon_'..prs)
            if not weapons[chk]then
                print('^1Is '..prs..' A Valid Weapon?^7')
                return
            else
                weapon=chk
            end
        end
        if not weapons[weapon]then
            return
        end
        self.weapons[weapon]=nil
        self.TriggerEvent('ffsa:RemoveWeapon', weapon)
        return true
    end
    self.giveItem = function(item, amount)
        if not items[item]then
            print('^1Item '..item..' Not Found!^7')
            return
        end
        self.inventory[item]=self.inventory[item]or{name=name,amount=0}
        self.inventory[item].amount=self.inventory[item].amount+amount
        self.TriggerEvent('ffsa:AddItem', item, amount)
        return true
    end
    return self
end

local function GetPlayer(source)
    return users[source]or{}
end

RegisterNetEvent('ffsa:getMission', function(name,server)
    local _source=source
    local file=LoadResourceFile(GetCurrentResourceName(), '/missions/'..name..'.lua')
    if file then
        TriggerClientEvent('ffsa:mission', _source, name, MinimizeCode(file))
        if server then
            local file=LoadResourceFile(GetCurrentResourceName(), '/missions/'..name..'-sv.lua')
            if file then
                Missions[name]={}
                Missions[name].source=_source
                load(file)()
            end
        end
    else
        if server then
            local file=LoadResourceFile(GetCurrentResourceName(), '/missions/'..name..'-sv.lua')
            if file then
                Missions[name]={}
                Missions[name].source=_source
                load(file)()
            end
        end
    end
end)

RegisterServerCallback('ffsa:createPlayerHandler', function(source,cb)
    if users[source]then
        cb(true)
    end
    SetPlayerRoutingBucket(source, 1)
    local identifiers=GetPlayerIdentifiers(source)
    local identifier=getvalue(identifiers,'license:')
    users[source]=CreatePlayerHandler(source,identifier,identifiers)
    cb(true)
end)