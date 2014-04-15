local Messages = {}
Shroud = Shroud or {}
Shroud.Messages = Messages

function Messages.Broadcast(sender, message)
    Shroud:debug(message)
    Shroud:Print(message)
end

function Messages.Give(sender, player, amount, reason)
    Shroud:Printf("%s gives %s %d points for %q", sender, player, amount, reason)
end

function Messages.MyInfo(sender, version)
    local type, count = Shroud:GetGroupComposition()
    Shroud.GroupInfo[sender] = {}
    Shroud.GroupInfo[sender].version = tonumber(version)
end