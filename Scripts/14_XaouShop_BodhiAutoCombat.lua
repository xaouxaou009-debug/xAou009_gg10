-- Xaou 009 Bodhi support AI integration.

if XaouBodhi_AutoCombatLoaded then return end
XaouBodhi_AutoCombatLoaded = true

local AUTO_SLOT_MODIFIER = "XaouBodhi_AutoSkillSlots"
local SUPPORT_SKILLS = {
    "XaouBodhi_GroupQi",
    "XaouBodhi_MercyRain",
    "XaouBodhi_GroupShield"
}

local function list_count(list)
    local count = 0
    if list ~= nil then pcall(function() count = tonumber(list.Count) or 0 end) end
    return count
end

local function list_item(list, index)
    local value = nil
    if list == nil then return nil end
    pcall(function() value = list:get_Item(index) end)
    if value == nil then pcall(function() value = list[index] end) end
    return value
end

local function new_string_list()
    local ok, result = pcall(function()
        local listType = CS.System.Collections.Generic.List(CS.System.String)
        return listType()
    end)
    if ok then return result end
    return nil
end

local function contains(values, needle)
    local count = list_count(values)
    for i = 0, count - 1 do
        if tostring(list_item(values, i)) == needle then return true end
    end
    return false
end

local function is_player_cultivator(npc)
    local valid = false
    pcall(function()
        valid = npc ~= nil
            and npc.IsPlayerThing
            and npc.IsDisciple
            and not npc.IsDeath
            and not npc.IsZombie
            and not npc.IsPuppet
            and npc.FightBody ~= nil
    end)
    return valid
end

local function ensure_support_auto_skills(npc)
    if not is_player_cultivator(npc) then return false end

    local body = npc.FightBody
    local learned = {}
    for _, skillName in ipairs(SUPPORT_SKILLS) do
        local hasSkill = false
        pcall(function() hasSkill = body:HasFightSkill(skillName) end)
        if hasSkill then learned[#learned + 1] = skillName end
    end
    if #learned == 0 then return false end

    local hasSlotModifier = false
    pcall(function() hasSlotModifier = npc.PropertyMgr:HasModifier(AUTO_SLOT_MODIFIER) end)
    if not hasSlotModifier then
        pcall(function() npc:AddModifier(AUTO_SLOT_MODIFIER) end)
    end

    local current = body.AutoSkills
    local changed = current == nil
    for _, skillName in ipairs(learned) do
        if not contains(current, skillName) then changed = true end
    end
    if not changed then return false end

    local merged = new_string_list()
    if merged == nil then return false end

    local oldCount = list_count(current)
    for i = 0, oldCount - 1 do
        local value = list_item(current, i)
        if value ~= nil and not contains(merged, tostring(value)) then
            pcall(function() merged:Add(tostring(value)) end)
        end
    end
    for _, skillName in ipairs(learned) do
        if not contains(merged, skillName) then
            pcall(function() merged:Add(skillName) end)
        end
    end

    pcall(function() body:SetAutoSkill(merged) end)
    return true
end

function XaouBodhi_RefreshAutoSkills()
    local manager, npcType = nil, nil
    pcall(function() manager = CS.XiaWorld.ThingMgr.Instance end)
    pcall(function() npcType = CS.XiaWorld.g_emThingType.Npc end)
    if manager == nil or npcType == nil then return 0 end

    local npcs = nil
    pcall(function() npcs = manager:GetThingList(npcType) end)
    if npcs == nil then return 0 end

    local changed = 0
    for i = 0, list_count(npcs) - 1 do
        local npc = list_item(npcs, i)
        local ok, updated = pcall(ensure_support_auto_skills, npc)
        if ok and updated then changed = changed + 1 end
    end
    return changed
end
