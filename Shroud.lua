local Shroud = LibStub("AceAddon-3.0"):NewAddon("Shroud", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Shroud", false);
_G.Shroud = Shroud

Shroud.VERSION = 10101
Shroud.DEBUG = true

-- By default we just use RAID_CLASS_COLORS as class colors.
Shroud.CLASS_COLORS = RAID_CLASS_COLORS

local RaidVersions = {}
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

    if (args[1] == "check-version") then
        debug("Reporting version to %s.", sender)
        Shroud:SendCommMessage("shroud", "my-version " .. Shroud.VERSION, "WHISPER", sender)
    elseif (args[1] == "my-version") then
        local type, count = Shroud:GetGroupComposition()
        RaidVersions[sender] = {}
        RaidVersions[sender].version = tonumber(args[2])

        if (#RaidVersions == (count - 1)) then
            Shroud:ReportShroudVersions(true)
        end
    end
end

function Shroud:OnSlashCommand(input)
    if (input == "ver" or input == "version") then
        local type,count = self:GetGroupComposition()
        if (count > 1) then
            if (#RaidVersions == 0) then
                debug("Checking with the raid.")
                VersionTimer = Shroud:ScheduleTimer("ReportShroudVersions", 2, true)
                Shroud:SendCommMessage("shroud", "check-version", type)
            end
        else
            self:ReportShroudVersions(false)
        end
    end
end

function Shroud:OnInitialize()
    ShroudPerCharDB = ShroudPerCharDB or {}
    self.db = ShroudPerCharDB
    self:RegisterChatCommand("shroud", "OnSlashCommand")
    self:RegisterComm("shroud")
end

function Shroud:OnEnable()
    if type(CUSTOM_CLASS_COLORS) == "table" then
        Shroud.CLASS_COLORS = CUSTOM_CLASS_COLORS
    end
end

function Shroud:OnDisable()
end

function Shroud:ReportShroudVersions(incoming)
    local myOutOfDate = ""
    local missing = 0
    local outOfDate = 0
    if (incoming == true) then
        Shroud:CancelTimer(VersionTimer)

        local type,count = self:GetGroupComposition()
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

    self:Printf("You are using version r%s.%s", Shroud.VERSION, myOutOfDate)
    if (#outOfDate > 0) then self:Printf("%d player(s) are out of date.", #outOfDate) end
    if (missing > 0) then self:Printf("%d player(s) did not answer.", missing) end
end
