Missions.First_Assignment={
    dependencies = {
        weapons = {},
        attachments = {},
        items = {}
    }
}
function Missions.First_Assignment:Start(cb)
    local obj = self
    obj.CreateOnScreenMarker(150.0, -200.0, 31.0)
    cb()
end
function Missions.First_Assignment:End(cb)
    local obj = self
    cb()
end
