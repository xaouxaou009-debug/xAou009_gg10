-- Xaou 009 Quest Journal. Combines native ACS quests with optional Xaou quests.

local XQ_View, XQ_Target = nil, nil
local XQ_Filter, XQ_Selected = "all", nil
local XQ_Visible, XQ_Page = {}, 1
local XQ_PerPage, XQ_LastDay = 4, nil
local XQ_Errors = {}

local QUESTS = {
    {id="xq_meet", kind="npc", target=5, rewardId="Item_LingStone", rewardCount=20,
     titleTH="ทำความรู้จักผู้คน", titleEN="Meet the Locals",
     descTH="เลือกดู NPC จำนวน 5 คน เพื่อทำความรู้จักผู้คนในแผนที่",
     descEN="Select 5 NPCs to meet people on the map.", objectiveTH="เลือก NPC", objectiveEN="Select NPCs"},
    {id="xq_items", kind="item", target=8, rewardId="Item_LingStone", rewardCount=25,
     titleTH="สำรวจทรัพยากร", titleEN="Survey Resources",
     descTH="เลือกดูไอเทมบนแผนที่จำนวน 8 ชิ้น",
     descEN="Inspect 8 items on the map.", objectiveTH="เลือกไอเทม", objectiveEN="Inspect items"},
    {id="xq_build", kind="building", target=1, rewardId="Item_LingStone", rewardCount=40,
     titleTH="วางรากฐานสำนัก", titleEN="Lay the Foundation",
     descTH="สร้างอาคารให้เสร็จ 1 หลัง",
     descEN="Finish 1 building.", objectiveTH="สร้างอาคารสำเร็จ", objectiveEN="Finish buildings"},
    {id="xq_days", kind="days", target=3, rewardId="Item_LingStone", rewardCount=50,
     titleTH="สามวันแห่งการบ่มเพาะ", titleEN="Three Days of Cultivation",
     descTH="ใช้ชีวิตในสำนักให้ครบ 3 วันหลังรับภารกิจ",
     descEN="Spend 3 game days in the sect after accepting.", objectiveTH="ผ่านวันในเกม", objectiveEN="Pass game days"},
}

local function is_en()
    return XaouShop_GetLanguage ~= nil and XaouShop_GetLanguage() == "EN"
end

local function tr(th, en) return is_en() and en or th end

local function child(view, name)
    local obj = nil
    pcall(function() obj = view:GetChild(name) end)
    return obj
end

local function set_text(obj, value)
    if obj == nil then return end
    pcall(function() obj.text = tostring(value or "") end)
    pcall(function() obj.title = tostring(value or "") end)
end

local function set_visible(obj, value)
    if obj == nil then return end
    pcall(function() obj.visible = value == true end)
    pcall(function() obj.touchable = value == true end)
end

local function bind(obj, callback)
    if obj == nil then return end
    pcall(function() obj.onClick:Clear() end)
    pcall(function() obj.onClick:Add(callback) end)
end

local function quest_state()
    XaouShop_State = XaouShop_State or {}
    if type(XaouShop_State.quests) ~= "table" then XaouShop_State.quests = {version=2, rows={}} end
    if type(XaouShop_State.quests.rows) ~= "table" then XaouShop_State.quests.rows = {} end
    return XaouShop_State.quests
end

local function custom_state(id)
    local rows = quest_state().rows
    if type(rows[id]) ~= "table" then rows[id] = {status="available", progress=0, acceptedDay=-1} end
    return rows[id]
end

local function custom_definition(id)
    for _, quest in ipairs(QUESTS) do if quest.id == id then return quest end end
    return nil
end

local function refresh_day_quest()
    local today = XaouShop_GetDay and XaouShop_GetDay() or 0
    XQ_LastDay = today
    for _, quest in ipairs(QUESTS) do
        if quest.kind == "days" then
            local data = custom_state(quest.id)
            if data.status == "active" then
                data.progress = math.max(0, today - (tonumber(data.acceptedDay) or today))
                if data.progress >= quest.target then data.status = "ready" end
            end
        end
    end
end

local function advance(kind, amount)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    for _, quest in ipairs(QUESTS) do
        local data = custom_state(quest.id)
        if quest.kind == kind and data.status == "active" then
            data.progress = math.min(quest.target, (tonumber(data.progress) or 0) + amount)
            if data.progress >= quest.target then data.status = "ready" end
        end
    end
    if XQ_View ~= nil and XaouQuest_Refresh then pcall(XaouQuest_Refresh) end
end

function XaouQuest_OnNpcSelected(npc) if npc ~= nil then advance("npc", 1) end end
function XaouQuest_OnItemSelected(item) if item ~= nil then advance("item", 1) end end
function XaouQuest_OnBuildingFinished(building) if building ~= nil then advance("building", 1) end end

function XaouQuest_Step()
    local today = XaouShop_GetDay and XaouShop_GetDay() or 0
    if XQ_LastDay ~= today then
        refresh_day_quest()
        if XQ_View ~= nil then pcall(XaouQuest_Refresh) end
    end
end

local function custom_rows()
    local rows = {}
    for _, quest in ipairs(QUESTS) do
        local state = custom_state(quest.id)
        rows[#rows + 1] = {
            id=quest.id, category="xaou", status=state.status,
            title=tr(quest.titleTH, quest.titleEN),
            desc=tr(quest.descTH, quest.descEN),
            objective=tr(quest.objectiveTH, quest.objectiveEN) .. ": "
                .. tostring(math.min(quest.target, tonumber(state.progress) or 0)) .. "/" .. tostring(quest.target),
            reward=tr("หินวิญญาณ ", "Spirit Stones ") .. tostring(quest.rewardCount),
            progress=tonumber(state.progress) or 0, target=quest.target, native=false,
        }
    end
    return rows
end

local function collect_rows()
    local rows = {}
    XQ_Errors = {}
    if XaouNativeQuest_GetRows ~= nil then
        local ok, native, errors = pcall(XaouNativeQuest_GetRows)
        if ok and type(native) == "table" then
            for _, row in ipairs(native) do rows[#rows + 1] = row end
            if type(errors) == "table" then XQ_Errors = errors end
        else
            XQ_Errors[#XQ_Errors + 1] = tostring(native)
        end
    else
        XQ_Errors[#XQ_Errors + 1] = "Native quest adapter not loaded"
    end
    for _, row in ipairs(custom_rows()) do rows[#rows + 1] = row end
    return rows
end

local function status_label(row)
    if row.status == "available" then return tr("รับได้", "Available") end
    if row.status == "active" then return tr("กำลังทำ", "Active") end
    if row.status == "ready" then return tr("รับรางวัล", "Claim") end
    return tr("สำเร็จแล้ว", "Completed")
end

local function selected_row()
    for _, row in ipairs(XQ_Visible) do if row.id == XQ_Selected then return row end end
    return nil
end

local function render_detail()
    local row = selected_row()
    if row == nil then
        set_text(child(XQ_View, "questTitle"), tr("ไม่พบรายการในหมวดนี้", "No quests in this category"))
        set_text(child(XQ_View, "questType"), "")
        set_text(child(XQ_View, "questDesc"), tr("ลองเลือกหมวดอื่นหรือกดรีเฟรชหน้าต่าง", "Choose another category or refresh."))
        set_text(child(XQ_View, "objectiveTitle"), tr("เป้าหมาย", "Objective"))
        set_text(child(XQ_View, "objectiveText"), "-")
        set_text(child(XQ_View, "rewardText"), tr("รางวัล: -", "Reward: -"))
        set_visible(child(XQ_View, "btnAction"), false)
        pcall(function() child(XQ_View, "progressFill").width = 0 end)
        return
    end
    set_text(child(XQ_View, "questTitle"), row.title)
    set_text(child(XQ_View, "questType"), status_label(row) .. " | " .. tostring(row.source or tr("ภารกิจ Xaou", "Xaou quest")))
    set_text(child(XQ_View, "questDesc"), row.desc)
    set_text(child(XQ_View, "objectiveTitle"), tr("เป้าหมาย", "Objective"))
    set_text(child(XQ_View, "objectiveText"), row.objective or "-")
    set_text(child(XQ_View, "rewardText"), tr("รางวัล: ", "Reward: ") .. tostring(row.reward or "-"))
    local progress = tonumber(row.progress) or 0
    local target = tonumber(row.target) or 0
    pcall(function()
        child(XQ_View, "progressFill").width = target > 0 and math.floor(532 * math.min(target, progress) / target) or 0
    end)
    local button = child(XQ_View, "btnAction")
    set_visible(button, row.native ~= true and row.status ~= "active" and row.status ~= "completed")
    if row.status == "available" then set_text(button, tr("รับภารกิจ", "Accept"))
    elseif row.status == "ready" then set_text(button, tr("รับรางวัล", "Claim")) end
end

local function custom_action()
    local row = selected_row()
    if row == nil or row.native == true then return end
    local quest = custom_definition(row.id)
    if quest == nil then return end
    local data = custom_state(row.id)
    if data.status == "available" then
        data.status, data.progress = "active", 0
        data.acceptedDay = XaouShop_GetDay and XaouShop_GetDay() or 0
    elseif data.status == "ready" then
        local ok, result = pcall(function() return XaouShop_GrantItem(quest.rewardId, quest.rewardCount, XQ_Target) end)
        if ok and result ~= false then data.status = "completed" end
    end
    XaouQuest_Refresh()
end

local function choose_filter(filter)
    XQ_Filter, XQ_Selected, XQ_Page = filter, nil, 1
    XaouQuest_Refresh()
end

function XaouQuest_Refresh()
    if XQ_View == nil then return end
    refresh_day_quest()
    XQ_Visible = {}
    for _, row in ipairs(collect_rows()) do
        if XQ_Filter == "all" or row.category == XQ_Filter then XQ_Visible[#XQ_Visible + 1] = row end
    end
    local page_count = math.max(1, math.ceil(#XQ_Visible / XQ_PerPage))
    XQ_Page = math.max(1, math.min(page_count, XQ_Page))
    local first = (XQ_Page - 1) * XQ_PerPage + 1
    local last = math.min(#XQ_Visible, first + XQ_PerPage - 1)
    local selected_visible = false
    for index = first, last do
        if XQ_Visible[index] and XQ_Visible[index].id == XQ_Selected then selected_visible = true end
    end
    if not selected_visible then XQ_Selected = XQ_Visible[first] and XQ_Visible[first].id or nil end

    for slot = 1, 4 do
        local row = XQ_Visible[first + slot - 1]
        local button = child(XQ_View, "quest" .. tostring(slot))
        set_visible(button, row ~= nil)
        if row ~= nil then
            set_text(button, (row.id == XQ_Selected and "▶ " or "") .. row.title .. "  [" .. status_label(row) .. "]")
        end
    end
    local prev, next_button = child(XQ_View, "quest5"), child(XQ_View, "quest6")
    set_visible(prev, XQ_Page > 1)
    set_visible(next_button, XQ_Page < page_count)
    set_text(prev, tr("◀ หน้าก่อน", "◀ Previous"))
    set_text(next_button, tr("หน้าถัดไป ▶", "Next ▶"))

    set_text(child(XQ_View, "title"), tr("Xaou 009 สมุดเควส", "Xaou 009 Quest Journal"))
    set_text(child(XQ_View, "subtitle"), tr("รวมเนื้อเรื่อง คำขอสำนัก บทสอน และภารกิจ Xaou", "Story, sect requests, tutorials and Xaou quests"))
    set_text(child(XQ_View, "btnAvailable"), tr("เนื้อเรื่อง", "Story"))
    set_text(child(XQ_View, "btnActive"), tr("คำขอสำนัก", "Sect Requests"))
    set_text(child(XQ_View, "btnCompleted"), tr("บทสอน", "Tutorial"))
    set_text(child(XQ_View, "btnAll"), "Xaou")
    set_text(child(XQ_View, "btnRefresh"), tr("ทั้งหมด", "All"))
    local status = tr("พบ ", "Found ") .. tostring(#XQ_Visible) .. tr(" รายการ", " quests")
        .. " | " .. tr("หน้า ", "Page ") .. tostring(XQ_Page) .. "/" .. tostring(page_count)
    if #XQ_Errors > 0 then
        status = status .. " | " .. tr("บางระบบยังไม่พร้อม: ", "Some sources unavailable: ")
            .. tostring(XQ_Errors[1])
    end
    set_text(child(XQ_View, "statusText"), status)
    render_detail()
end

function XaouQuest_CloseWindow()
    if XQ_View == nil then return end
    pcall(function() XQ_View:RemoveFromParent() end)
    pcall(function() XQ_View:Dispose() end)
    XQ_View, XQ_Target = nil, nil
end

function XaouQuest_OpenWindow(npc)
    XaouQuest_CloseWindow()
    XQ_Target, XQ_Page, XQ_Filter = npc, 1, "all"
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI unavailable" end
    pcall(function() pkg.AddPackage("UI/XaouShop") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaouShop", "QuestWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XQ_View = view
    root:AddChild(view)
    view.x, view.y = (root.width - view.width) / 2, (root.height - view.height) / 2
    pcall(function() root:SetChildIndex(view, root.numChildren - 1) end)
    set_text(child(view, "btnClose"), "×")
    bind(child(view, "btnClose"), XaouQuest_CloseWindow)
    bind(child(view, "btnAction"), custom_action)
    bind(child(view, "btnAvailable"), function() choose_filter("story") end)
    bind(child(view, "btnActive"), function() choose_filter("school") end)
    bind(child(view, "btnCompleted"), function() choose_filter("tutorial") end)
    bind(child(view, "btnAll"), function() choose_filter("xaou") end)
    bind(child(view, "btnRefresh"), function() choose_filter("all") end)
    for slot = 1, 4 do
        local button_slot = slot
        bind(child(view, "quest" .. tostring(slot)), function()
            local index = (XQ_Page - 1) * XQ_PerPage + button_slot
            local row = XQ_Visible[index]
            if row ~= nil then XQ_Selected = row.id; XaouQuest_Refresh() end
        end)
    end
    bind(child(view, "quest5"), function() if XQ_Page > 1 then XQ_Page=XQ_Page-1; XQ_Selected=nil; XaouQuest_Refresh() end end)
    bind(child(view, "quest6"), function()
        local pages = math.max(1, math.ceil(#XQ_Visible / XQ_PerPage))
        if XQ_Page < pages then XQ_Page=XQ_Page+1; XQ_Selected=nil; XaouQuest_Refresh() end
    end)
    XaouQuest_Refresh()
    return true
end
