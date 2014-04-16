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

local RELEVANT_INVENTORY_SLOTS = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17 }
local ENCHANTABLE_INVENTORY_SLOTS = {[3]=true,[5]=true,[7]=true,[8]=true,[9]=true,[10]=true,[15]=true}
local ENCHANTER_ADDITIONAL_SLOTS = {[11]=true,[12]=true }
local PROFESSIONS = {["Blacksmithing"]=164,["Enchanting"]=333,["Engineering"]=202}
function Shroud:AuditMyInventory()
    local missingEnchantmentSlots = {}
    local missingGemSlots = {}
    local prof1, prof2 = GetProfessions()
    local _, _, _, _, _, _, sl1 = GetProfessionInfo(prof1)
    local _, _, _, _, _, _, sl2 = GetProfessionInfo(prof2)

    for _, slot in RELEVANT_INVENTORY_SLOTS do
        local link = GetInventoryItemLink("player", slot)
        local itemId, enchantId, gem1, gem2, gem3, gem4 = link:match("item:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
        -- local countSockets = GetNumSockets(itemId)
        local gems = 0

        if (gem4 > 0) then gems = 4
        elseif (gem3 > 0) then gems = 3
        elseif (gem2 > 0) then gems = 2
        elseif (gem1 > 0) then gems = 1 end

        -- Enchantment
        if (Shroud:Contains(ENCHANTABLE_INVENTORY_SLOTS, slot) and enchantId == 0) then
            table.insert(missingEnchantmentSlots, slot)
        end

        -- Enchanters get extra slots
        if ((sl1 == PROFESSIONS["Enchanting"] or sl2 == PROFESSIONS["Enchanting"]) and Shroud:Contains(ENCHANTER_ADDITIONAL_SLOTS, slot) and enchantId == 0) then
            table.insert(missingEnchantmentSlots, slot)
        end

        -- Engineers get extra slots, but they cannot be detected easily and are going away, so we're just going to IGNORE THIS LA LA LA

        -- Gems
        -- if (countSockets > gems) then
        --     table.insert(missingGemSlots, slot)
        -- end

        -- Blacksmiths get extra slots
        -- if(sl1 == PROFESSIONS["Blacksmithing"] or sl2 == PROFESSIONS["Blackmsithing"]) and Shroud:Contains(BLACKSMITHING_ADDITIONAL_SLOTS, slot) and countSockets + 1 > gems) then
        --     table.insert(missingGemSlots, slot)
        -- end
    end

    return #missingEnchantmentSlots, #missingGemSlots
end

function Shroud:Contains(t, key)
    return t[key] ~= nil
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
    if (count > 1) then
        local type,count = Shroud:GetGroupComposition()
        local _, ilvl = GetAverageItemLevel()
        local missingEnchants, missingGems = Shroud:AuditMyInventory()

        Shroud:debug("Reporting info the %s.", Shroud.VERSION, type)

        local message = string.format("MyInfo %d %d %d %d", Shroud.VERSION, ilvl, missingEnchants, missingGems)
        Shroud:SendCommMessage("shroud", message, type)
    end
end
