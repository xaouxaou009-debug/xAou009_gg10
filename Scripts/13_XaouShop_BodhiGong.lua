-- Xaou 009 Bodhi support cultivation test integration.

XaouShop_BodhiGongId = "Gong_Xaou_009_Bodhi"
XaouShop_BodhiStarterEsoterica = {
    "XaouBodhi_Eso_GroupQi",
    "XaouBodhi_Eso_GroupShield",
    "XaouBodhi_Eso_MercyRain",
}

local function get_practice(npc)
    if npc == nil then return nil end
    local attempts = {
        function() return npc.PropertyMgr.Practice end,
        function() return npc.PropertyMgr:get_Practice() end,
        function() return npc.Practice end,
        function() return npc.practice end,
    }
    for _, fn in ipairs(attempts) do
        local ok, value = pcall(fn)
        if ok and value ~= nil then return value end
    end
    return nil
end

local function gong_key(practice)
    if practice == nil then return nil end
    local gong = nil
    pcall(function() gong = practice.Gong end)
    if gong == nil then pcall(function() gong = practice:get_Gong() end) end
    if gong == nil then return nil end
    local key = nil
    for _, field in ipairs({"Name", "Key", "Gong", "GongID", "GongId"}) do
        pcall(function() key = gong[field] end)
        if key ~= nil and tostring(key) ~= "" then return tostring(key) end
    end
    local text = tostring(gong)
    return string.match(text, "(Gong_[%w_]+)")
end

local function learn_esoterica(practice, id)
    local learned = false
    pcall(function() learned = practice:IsLearnedEsoterica(id) == true end)
    if learned then return true end
    local ok = pcall(function() practice:LearnEsotericaEx(id, 0.0, false, true) end)
    if not ok then ok = pcall(function() practice:LearnEsotericaEx(id, 0.0, 0, true) end) end
    if not ok then return false end
    learned = false
    pcall(function() learned = practice:IsLearnedEsoterica(id) == true end)
    return learned
end

function XaouShop_InstallBodhiGong(npc, gongId)
    gongId = tostring(gongId or XaouShop_BodhiGongId)
    if npc == nil then return false, "NPC_NOT_FOUND" end
    local mgr = CS and CS.XiaWorld and CS.XiaWorld.PracticeMgr and CS.XiaWorld.PracticeMgr.Instance or nil
    if mgr == nil then return false, "PRACTICE_MGR_NOT_FOUND" end

    local def = nil
    pcall(function() def = mgr:GetGongDef(gongId) end)
    if def == nil then return false, "GONG_DEF_NOT_FOUND: " .. gongId end

    local practice = get_practice(npc)
    if practice == nil then return false, "NPC_PRACTICE_NOT_FOUND" end
    if gong_key(practice) == gongId then return false, "ALREADY_LEARNED" end

    local loaded = false
    local attempts = {
        function() return practice:ChangeGong(gongId) end,
        function() return practice:SetGong_4RPG(def) end,
        function() return mgr:DoLoadGong(gongId, npc) end,
        function() return mgr:DoLoadGong(def, npc) end,
        function() return mgr:DoLoadGong(npc, gongId) end,
    }
    for _, fn in ipairs(attempts) do
        local ok, value = pcall(fn)
        if ok and value ~= false then
            loaded = true
            if gong_key(practice) == gongId then break end
        end
    end
    if not loaded or gong_key(practice) ~= gongId then
        return false, "LOAD_GONG_FAILED"
    end

    pcall(function() practice:RefreshLearnCache() end)
    pcall(function() practice:RandomTree(false, gongId, false) end)
    pcall(function() practice:RefreshLearnCache() end)

    local learnedCount = 0
    for _, esoId in ipairs(XaouShop_BodhiStarterEsoterica) do
        if learn_esoterica(practice, esoId) then learnedCount = learnedCount + 1 end
    end
    pcall(function() practice:RefreshLearnCache() end)
    return true, {gongId=gongId, learned=learnedCount, total=#XaouShop_BodhiStarterEsoterica}
end

local function list_count(list)
    if list == nil then return 0 end
    local value = 0
    pcall(function() value = tonumber(list.Count) or 0 end)
    return value
end

local function list_item(list, index)
    local value = nil
    pcall(function() value = list:get_Item(index) end)
    if value == nil then pcall(function() value = list[index] end) end
    return value
end

local function decode_selected_npc(result)
    if result == nil then return nil end
    local id = tonumber(result)
    if id == nil and list_count(result) > 0 then id = tonumber(list_item(result, 0)) end
    if id ~= nil then
        local npc = nil
        pcall(function() npc = CS.XiaWorld.ThingMgr.Instance:FindThingByID(id) end)
        return npc
    end
    if type(result) ~= "number" and type(result) ~= "string" and type(result) ~= "boolean" then return result end
    return nil
end

function XaouShop_SelectNpcForBodhi(callback)
    local wnd = CS and CS.Wnd_SelectNpc and CS.Wnd_SelectNpc.Instance or nil
    if wnd == nil then return false, "WND_SELECT_NPC_NOT_FOUND" end

    local wrapped = function(result)
        local npc = decode_selected_npc(result)
        callback(npc)
    end

    -- Wnd_SelectNpc expects the game's C# delegate, not a plain Lua function.
    local selectCallback = nil
    local okCallback = pcall(function()
        selectCallback = WorldLua:GetSelectNpcCallback(wrapped)
    end)
    if not okCallback or selectCallback == nil then
        return false, "SELECT_NPC_CALLBACK_FAILED"
    end

    local rank = 0
    pcall(function() rank = g_emNpcRank.Disciple end)
    local attempts = {
        function() return wnd:Select(selectCallback, rank, 1, 1, nil, nil, "เลือก NPC ที่จะเรียนวิชาโพธิจิตแห่ง Xaou") end,
        function() return wnd:Select(selectCallback, 0, 1, 1, nil, nil, "เลือก NPC ที่จะเรียนวิชาโพธิจิตแห่ง Xaou") end,
    }
    for _, fn in ipairs(attempts) do
        local ok = pcall(fn)
        if ok then return true end
    end
    return false, "OPEN_SELECT_NPC_FAILED"
end
