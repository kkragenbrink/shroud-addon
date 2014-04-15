Shroud = LibStub("AceAddon-3.0"):NewAddon("Shroud", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Shroud", false);
Shroud.VERSION = 10101
Shroud.DEBUG = false

-- By default we just use RAID_CLASS_COLORS as class colors.
Shroud.CLASS_COLORS = RAID_CLASS_COLORS

Shroud.GroupName = "default"
Shroud.GroupInfo = {}
local VersionTimer

function Shroud:debug(...)
    if (Shroud.DEBUG) then
        Shroud:Printf(...)
    end
end

function Shroud:FilterTable(t, filterIter)
    local out = {}
    for k, v in pairs(t) do
        if filterIter(v, k, t) then out[k] = v end
    end

    return out
end

function Shroud:GetGroupComposition()
    local type
    local count = GetNumGroupMembers()
    if IsInRaid() then
        type = "raid"
    elseif IsInGroup then
        type = "party"
    end
    return type, count
end

function Shroud:GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function Shroud:IsMasterLooter()
    local method, pID, rID = GetLootMethod()
    local type, count = Shroud:GetGroupComposition()
    local idx = UnitInRaid("player")

    return (type == "party" and pID == 0) or (type == "raid" and idx == rID)
end

function Shroud:OnCommReceived(prefix, input, distribution, sender)
    local message, args = Shroud:ParseArgs(input)
    Shroud:debug("Message %q with %d arguments.", message, #args)

    if (Shroud.Messages[message] ~= nil) then
        Shroud.Messages[message](sender, unpack(args))
    end
end

function Shroud:OnSlashCommand(input)
    local command, args = Shroud:ParseArgs(input)
    if (command == "") then
        command = "default"
    end
    command = command or "default"
    command = command:lower()
    Shroud:debug("Command %q with %d arguments.", command, #args)

    if (Shroud.Commands[command] ~= nil) then
        Shroud.Commands[command](unpack(args))
    else
        Shroud.Commands.default()
    end
end

function Shroud:OnInitialize()
    ShroudPerCharDB = ShroudPerCharDB or {}
    Shroud.db = ShroudPerCharDB
    Shroud:RegisterChatCommand("shroud", "OnSlashCommand")
    Shroud:RegisterComm("shroud")
    Shroud:TimedGroupInfoUpdate()

    VersionTimer = Shroud:ScheduleRepeatingTimer("TimedGroupInfoUpdate", 5)
end

function Shroud:OnEnable()
    Shroud:debug("OnEnable")
    if type(CUSTOM_CLASS_COLORS) == "table" then
        Shroud.CLASS_COLORS = CUSTOM_CLASS_COLORS
    end
end

function Shroud:OnDisable()
end

function Shroud:ParseArgs(input)
    local command = ""
    local args = {}
    local phrase = ""
    local phraseStart = false
    if (input ~= "") then
        for word in string.gmatch(input, "[%w|%p]+") do
            if (command == "") then
                command = word
            elseif (string.byte(word) == 34 and phraseStart == false) then
                phraseStart = true
                phrase = string.sub(word, 2)
            elseif (phraseStart == true and string.byte(string.reverse(word)) == 34) then
                phraseStart = false
                phrase = phrase .. " " .. string.sub(word, 1,#word - 1)
                table.insert(args, phrase)
            elseif (phraseStart == true) then
                phrase = phrase .. " " .. word
            else
                table.insert(args, word)
            end
        end
    end
    return command, args
end

function Shroud:TimedGroupInfoUpdate()
    local type,count = Shroud:GetGroupComposition()

    if (count > 1) then
        Shroud:debug("Reporting version %d to the %s.", Shroud.VERSION, type)
        local message = string.format("MyInfo %d", Shroud.VERSION)
        Shroud:SendCommMessage("shroud", message, type)
    end
end
