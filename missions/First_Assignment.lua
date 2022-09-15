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
    AddListener("ffsa:enteredGreenzone", function()
        print("You've entered Greenzone!")
    end)
    AddListener("ffsa:enteredRedzone", function()
        print("You've entered Redzone!")        
    end)
    cb()
end
function Missions.First_Assignment:End(cb)
    local obj = self
    obj.RemoveListener("ffsa:enteredGreenzone")
    obj.RemoveAllListeners()
    cb()
end
