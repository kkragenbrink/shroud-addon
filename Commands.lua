local Commands = {}
Shroud = Shroud or {}
Shroud.Commands = Commands

local MethodBeforeShroud

function Commands.debug()
    Shroud.DEBUG = (Shroud.DEBUG ~= true)
end

function Commands.give(player, amount, reason)
    local type, _ = Shroud:GetGroupComposition()
    amount = tonumber(amount)

    if (Shroud:IsMasterLooter() ~= true) then
        Shroud:Print("You are not the master looter.")
        return
    end

    if (amount < 1) then
        Shroud:Print('You cannot give an amount less than 1. Did you mean to "spend" or "take" perhaps?')
        return
    end

    local data = Shroud.db[Shroud.GroupName][player] or {
        points = 0,
        log = {}
    }

    data.points = data.points + amount
    table.insert(data.log, {
        amount = amount,
        reason = reason
    })

    Shroud.db[Shroud.GroupName][player] = data

    local message = string.format("Give %s %d %q", player, amount, reason)
    Shroud:SendCommMessage("shroud", message, type)
end

function Commands.start(groupName)
    local type, count = Shroud:GetGroupComposition()
    groupName = groupName or Shroud.Options.DefaultGroupName

    if (HasLFGRestrictions()) then
        Shroud:Printf("You may not use Shroud while in Group Finder.")
    elseif (count > 0) then
        local method = GetLootMethod()
        if (UnitIsGroupLeader("player")) then
            local playerName = GetUnitName("player")

            if (method ~= "master") then
                MethodBeforeShroud = method
                SetLootMethod("master", playerName)
            end

            Shroud.GroupName = groupName
            Shroud.db[groupName] = Shroud.db[groupName] or {}
            local message = string.format('Broadcast "%s %s started by %s."', Shroud.GroupName, type, playerName)
            Shroud:SendCommMessage("shroud", message, type)
        else
            Shroud:Printf("You are not the %s leader.", type)
        end
    else
        Shroud:Printf("You are not in a group.")
    end
end

function Commands.stop()
    local type, count = Shroud:GetGroupComposition()

    if (HasLFGRestrictions()) then
        Shroud:Printf("You may not use Shroud while in Group Finder.")
    elseif (count > 0) then
        local method, partyLooter, raidLooter = GetLootMethod()
        if (UnitIsGroupLeader("player")) then
            local message = string.format('Broadcast "%s %s stopped by %s."', Shroud.GroupName, type, GetUnitName("player"))
            Shroud:SendCommMessage("shroud", message, type)

            if (method == "master" and MethodBeforeShroud ~= nil) then
                SetLootMethod(MethodBeforeShroud)
                Shroud.GroupName = Shroud.Options.DefaultGroupName
            end
        else
            Shroud:Printf("You are not the %s leader.", type)
        end
    else
        Shroud:Printf("You are not in a group.")
    end
end

function Commands.version()
    local myOutOfDate = ""
    local missing = 0
    local outOfDate = {}
    local raidSize = Shroud:GetTableLength(Shroud.GroupInfo)
    if (raidSize > 0) then
        local type,count = Shroud:GetGroupComposition()
        missing = count - raidSize
        outOfDate = Shroud:FilterTable(Shroud.GroupInfo, function (player)
            if (player.version > Shroud.VERSION) then
                myOutOfDate = " Your version is out of date!"
            end
            return player.version < Shroud.VERSION
        end)
        local good = count - (#outOfDate + missing)
    end

    Shroud:Printf("You are using version r%s.%s", Shroud.VERSION, myOutOfDate)
    if (#outOfDate > 0) then Shroud:Printf("%d player(s) have an out of date addon.", #outOfDate) end
    if (missing > 0) then Shroud:Printf("%d player(s) did not report a version.", missing) end
end
Commands.ver = Commands.version

function Commands.default()
    Shroud:Printf("Helpfile will go here.")
end