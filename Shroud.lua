local Shroud = LibStub("AceAddon-3.0"):NewAddon("Shroud", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Shroud", false);
_G.Shroud = Shroud

Shroud.VERSION = 10100

-- By default we just use RAID_CLASS_COLORS as class colors.
Shroud.CLASS_COLORS = RAID_CLASS_COLORS

local RaidVersions = {}
local VersionTimer

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
        Shroud:SendCommMessage("shroud", "my-version " .. Shroud.VERSION, "WHISPER", sender)
    elseif (args[1] == "my-version") then
        local type, count = Shroud:GetGroupComposition()
        RaidVersions[sender] = {}
        RaidVersions[sender].version = args[2]

        if (count == #RaidVersions) then
            Shroud:ReportShroudVersions(true)
        end
    end
end

function Shroud:OnSlashCommand(input)
    if (input == "ver" or input == "version") then
        local type,count = self:GetGroupComposition()
        if (count > 1) then
            if (#RaidVersions == 0) then
                Shroud:Print("Checking with the raid.")
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
    if (incoming == true) then
        Shroud:CancelTimer(VersionTimer)

        local type,count = self:GetGroupComposition()
        local missing = count - #RaidVersion
        local outOfDate = Shroud:FilterTable(RaidVersions, function (v, k, t)
            if (v > Shroud.version) then
                myOutOfDate = " Your version is out of date!"
            end
            return v < Shroud.Version
        end)
        local good = count - (outOfDate + missing)
    end

    self:Printf("You are using version r%s.%s", Shroud.VERSION, myOutOfDate)
    if (incoming == true) then
        self:Printf("%d player(s) are out of date.", outOfDate)
        self:Printf("%d player(s) did not answer.", missing)
    end
end
