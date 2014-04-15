local Shroud = LibStub("AceAddon-3.0"):NewAddon("Shroud", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Shroud", false);
_G.Shroud = Shroud

Shroud.VERSION = 10101
Shroud.DEBUG = false

-- By default we just use RAID_CLASS_COLORS as class colors.
Shroud.CLASS_COLORS = RAID_CLASS_COLORS

local RaidInfo = {}
local VersionTimer

function debug(...)
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


function Shroud:OnCommReceived(prefix, message, distribution, sender)
    local args = {Shroud:GetArgs(message, 10, 1) }

    if (args[1] == "my-info") then
        local type, count = Shroud:GetGroupComposition()
        RaidInfo[sender] = {}
        RaidInfo[sender].version = tonumber(args[2])

        if (#RaidVersions == (count - 1)) then
            Shroud:ReportShroudVersions(true)
        end
    end
end

function Shroud:OnSlashCommand(input)
    if (input == "ver" or input == "version") then
        Shroud:PrintShroudVersions()
    end
end

function Shroud:OnInitialize()
    ShroudPerCharDB = ShroudPerCharDB or {}
    Shroud.db = ShroudPerCharDB
    Shroud:RegisterChatCommand("shroud", "OnSlashCommand")
    Shroud:RegisterComm("shroud")
    Shroud:TimedGroupInfoUpdate()
    VersionTimer = Shroud:ScheduleRepeatingTimer("TimedGroupInfoUpdate", 30)
end

function Shroud:OnEnable()
    debug("OnEnable")
    if type(CUSTOM_CLASS_COLORS) == "table" then
        Shroud.CLASS_COLORS = CUSTOM_CLASS_COLORS
    end
end

function Shroud:OnDisable()
end

function Shroud:PrintShroudVersions()
    local myOutOfDate = ""
    local missing = 0
    local outOfDate = {}
    if (#RaidVersions > 0) then

        local type,count = Shroud:GetGroupComposition()
        count = count - 1
        missing = count - #RaidVersions
        outOfDate = Shroud:FilterTable(RaidVersions, function (player)
            if (player.version > Shroud.VERSION) then
                myOutOfDate = " Your version is out of date!"
            end
            return player.version < Shroud.VERSION
        end)
        local good = count - (#outOfDate + missing)
    end

    Shroud:Printf("You are using version r%s.%s", Shroud.VERSION, myOutOfDate)
    if (#outOfDate > 0) then Shroud:Printf("%d player(s) are out of date.", #outOfDate) end
    if (missing > 0) then Shroud:Printf("%d player(s) did not answer.", missing) end
end

function Shroud:TimedGroupInfoUpdate()
    local type,count = Shroud:GetGroupComposition()

    if (count > 1) then
        debug("Reporting version to the %s.", type)
        local message = string.format("my-info %d %d", Shroud.VERSION)
        Shroud:SendCommMessage("shroud", "my-info" .. Shroud.VERSION, type)
    end
end