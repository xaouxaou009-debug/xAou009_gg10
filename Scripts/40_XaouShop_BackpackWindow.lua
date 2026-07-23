-- Shared RPG-style backpack window for Xaou 009.

local XBAG_View, XBAG_CategoryView, XBAG_Target = nil, nil, nil
local XBAG_Mode, XBAG_Rows = "bag", {}
local XBAG_Selected, XBAG_Page, XBAG_Quantity = 1, 1, 1
local XBAG_Busy, XBAG_Status, XBAG_StatusKind = false, nil, nil
local XBAG_Category = "all"

local XBAG_Categories = {
    {id="all", button="catAll", th="ทั้งหมด", en="All"},
    {id="food", button="catFood", th="อาหาร", en="Food"},
    {id="medicine", button="catMedicine", th="ยาและโอสถ", en="Medicine"},
    {id="practice", button="catPractice", th="ของบ่มเพาะ", en="Cultivation"},
    {id="material", button="catMaterial", th="วัตถุดิบ", en="Materials"},
    {id="equipment", button="catEquipment", th="อุปกรณ์", en="Equipment"},
    {id="other", button="catOther", th="อื่น ๆ", en="Other"},
}

local function child(obj, name)
    if obj == nil then return nil end
    local value = nil
    pcall(function() value = obj:GetChild(name) end)
    return value
end

local function set_text(obj, value)
    if obj == nil then return end
    local text = XaouShop_Localize and XaouShop_Localize(value) or tostring(value or "")
    pcall(function() obj.text = text end)
    pcall(function() obj.title = text end)
end

local function set_visible(obj, value)
    if obj == nil then return end
    pcall(function() obj.visible = value == true end)
    pcall(function() obj.touchable = value == true end)
end

local function set_enabled(obj, value)
    if obj == nil then return end
    pcall(function() obj.enabled = value == true end)
    pcall(function() obj.touchable = value == true end)
    pcall(function() obj.alpha = value == true and 1 or 0.45 end)
end

local function def_info(id)
    local def = XaouShop_GetDef and XaouShop_GetDef(id) or nil
    local info = {name=tostring(id or ""), desc="", icon=""}
    if def ~= nil then
        local value = nil
        pcall(function() value = def.ThingName end)
        if value == nil then pcall(function() value = def.DisplayName end) end
        if value ~= nil and tostring(value) ~= "" then info.name = tostring(value) end
        pcall(function() info.desc = tostring(def.Desc or "") end)
        pcall(function() info.icon = tostring(def.TexPath or "") end)
    end
    return info
end

local function is_english()
    return XaouShop_GetLanguage ~= nil and XaouShop_GetLanguage() == "EN"
end

local function category_label(category)
    for _, row in ipairs(XBAG_Categories) do
        if row.id == tostring(category or "all") then return is_english() and row.en or row.th end
    end
    return is_english() and "All" or "ทั้งหมด"
end

local function item_category(id)
    id = tostring(id or "")
    local def = XaouShop_GetDef and XaouShop_GetDef(id) or nil
    local itemData, label = nil, 0
    pcall(function()
        itemData = def.Item
        label = tonumber(itemData.Lable) or 0
    end)

    local remoteItem = nil
    pcall(function() remoteItem = Map.SpaceRing:FindItem(id, nil, 0, 9999, nil) end)
    if remoteItem == nil then
        pcall(function() remoteItem = CS.XiaWorld.World.Instance.map.SpaceRing:FindItem(id, nil, 0, 9999, nil) end)
    end
    local function has_tag(name)
        local value = 0
        pcall(function() value = tonumber(remoteItem.TagData:CheckTag(name)) or 0 end)
        return value > 0
    end

    if has_tag("PracticeFood") then return "practice" end
    if label == 20 or label == 21 or string.find(string.lower(id), "drug", 1, true) then return "medicine" end
    local food = nil
    pcall(function() food = itemData.Food end)
    if label == 19 or food ~= nil or has_tag("Food") or has_tag("DiscipleFood") then return "food" end
    if (label >= 1 and label <= 12) or label == 24 or label == 26 or label == 27 or label == 28 then return "material" end
    if (label >= 13 and label <= 18) or label == 23 or label == 35 then return "equipment" end
    return "other"
end

local function refresh_rows()
    local source = nil
    if XBAG_Mode == "map" then source = XaouShop_GetMapItems and XaouShop_GetMapItems() or {}
    else source = XaouShop_GetBackpackItems and XaouShop_GetBackpackItems() or {} end
    XBAG_Rows = {}
    for _, row in ipairs(source) do
        row.category = item_category(row.id)
        if XBAG_Category == "all" or row.category == XBAG_Category then
            XBAG_Rows[#XBAG_Rows + 1] = row
        end
    end
end

local function selected_row()
    return XBAG_Rows[XBAG_Selected]
end

local function page_count()
    return math.max(1, math.ceil(#XBAG_Rows / 10))
end

local function selected_quantity(row)
    if row == nil then return 1 end
    local available = math.max(1, math.floor(tonumber(row.count) or 1))
    if XBAG_Quantity == "all" then return available end
    return math.min(available, math.max(1, math.floor(tonumber(XBAG_Quantity) or 1)))
end

local function set_status(text, kind)
    XBAG_Status, XBAG_StatusKind = text and tostring(text) or nil, kind
end

function XaouBackpack_CloseWindow()
    if XBAG_CategoryView ~= nil then
        pcall(function() XBAG_CategoryView:RemoveFromParent() end)
        pcall(function() XBAG_CategoryView:Dispose() end)
        XBAG_CategoryView = nil
    end
    if XBAG_View ~= nil then
        pcall(function() XBAG_View:RemoveFromParent() end)
        pcall(function() XBAG_View:Dispose() end)
        XBAG_View = nil
    end
end

local function refresh_detail(view)
    local row = selected_row()
    if row == nil then
        set_text(child(view, "detailName"), "เลือกสิ่งของ")
        set_text(child(view, "detailDesc"), "แตะสิ่งของเพื่อดูรายละเอียด")
        set_text(child(view, "detailCount"), "จำนวน: -")
        set_text(child(view, "qtyLabel"), "จัดการ: -")
        set_visible(child(view, "detailIcon"), false)
        set_enabled(child(view, "btnAction"), false)
        return
    end
    local info = def_info(row.id)
    local quantity = selected_quantity(row)
    set_text(child(view, "detailName"), info.name)
    set_text(child(view, "detailDesc"), info.desc ~= "" and info.desc or tostring(row.id))
    set_text(child(view, "detailCount"), "จำนวน: " .. tostring(row.count))
    set_text(child(view, "qtyLabel"), "จัดการ: " .. tostring(quantity))
    local loader = child(view, "detailIcon")
    pcall(function() loader.url = info.icon end)
    set_visible(loader, info.icon ~= "")
    set_enabled(child(view, "btnAction"), not XBAG_Busy and quantity <= (tonumber(row.count) or 0))
end

local function refresh(view)
    refresh_rows()
    local pages = page_count()
    if XBAG_Page > pages then XBAG_Page = pages end
    if XBAG_Page < 1 then XBAG_Page = 1 end
    if XBAG_Selected < 1 or XBAG_Selected > #XBAG_Rows then XBAG_Selected = #XBAG_Rows > 0 and 1 or 0 end

    set_text(child(view, "title"), "กระเป๋า Xaou 009")
    set_text(child(view, "subtitle"), "จัดเก็บและนำสิ่งของออกใกล้ NPC ที่เลือก")
    set_text(child(view, "btnClose"), "×")
    set_text(child(view, "btnCategory"), (is_english() and "Category: " or "หมวด: ") .. category_label(XBAG_Category))
    set_text(child(view, "btnBagMode"), XBAG_Mode == "bag" and "▶ ในกระเป๋า" or "ในกระเป๋า")
    set_text(child(view, "btnMapMode"), XBAG_Mode == "map" and "▶ บนแผนที่" or "บนแผนที่")
    set_text(child(view, "modeText"), XBAG_Mode == "bag" and "สิ่งของในกระเป๋า" or "ไอเทมบนแผนที่")
    set_text(child(view, "countText"), tostring(#XBAG_Rows) .. " รายการ")
    set_text(child(view, "btnQty1"), "1")
    set_text(child(view, "btnQty10"), "10")
    set_text(child(view, "btnQtyAll"), "ทั้งหมด")
    set_text(child(view, "btnAction"), XBAG_Mode == "bag" and "นำออกใกล้ NPC" or "เก็บเข้ากระเป๋า")
    set_text(child(view, "brand"), "Xaou 009 • Shared RPG Backpack")
    set_text(child(view, "btnPrev"), "◀")
    set_text(child(view, "btnNext"), "▶")
    set_text(child(view, "pageText"), tostring(XBAG_Page) .. "/" .. tostring(pages))
    set_enabled(child(view, "btnPrev"), XBAG_Page > 1)
    set_enabled(child(view, "btnNext"), XBAG_Page < pages)

    for i = 1, 10 do
        local absoluteIndex = (XBAG_Page - 1) * 10 + i
        local card, row = child(view, "item" .. tostring(i)), XBAG_Rows[absoluteIndex]
        if row ~= nil then
            local info = def_info(row.id)
            set_visible(card, true)
            set_text(child(card, "itemName"), info.name)
            set_text(child(card, "price"), XBAG_Mode == "bag" and "ในกระเป๋า" or "บนแผนที่")
            set_text(child(card, "stock"), "จำนวน " .. tostring(row.count))
            local icon = child(card, "icon")
            pcall(function() icon.url = info.icon end)
            set_visible(icon, info.icon ~= "")
            pcall(function() card.selected = absoluteIndex == XBAG_Selected end)
            set_enabled(card, tonumber(row.count) ~= nil and tonumber(row.count) > 0)
        else
            set_visible(card, false)
        end
    end

    local status = XBAG_Status
    if status == nil or status == "" then
        status = XBAG_Mode == "bag" and "เลือกของในกระเป๋าเพื่อนำออกใกล้ NPC" or "เลือกไอเทมบนแผนที่เพื่อเก็บเข้ากระเป๋า"
    end
    set_text(child(view, "status"), status)
    local statusField = child(view, "status")
    if statusField ~= nil and CS ~= nil and CS.UnityEngine ~= nil then
        pcall(function()
            if XBAG_StatusKind == "success" then statusField.color = CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XBAG_StatusKind == "error" then statusField.color = CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else statusField.color = CS.UnityEngine.Color(0.30,0.27,0.20,1) end
        end)
    end
    refresh_detail(view)
end

local function close_category_window()
    if XBAG_CategoryView ~= nil then
        pcall(function() XBAG_CategoryView:RemoveFromParent() end)
        pcall(function() XBAG_CategoryView:Dispose() end)
        XBAG_CategoryView = nil
    end
end

local function open_category_window(view)
    close_category_window()
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then
        set_status(is_english() and "Category window is unavailable" or "ไม่พบหน้าต่างหมวดหมู่", "error")
        refresh(view)
        return
    end

    local categoryView = nil
    local ok, err = pcall(function() categoryView = pkg.CreateObject("XaouShop", "BackpackCategoryWindow") end)
    if not ok or categoryView == nil then
        set_status((is_english() and "Cannot open category window: " or "เปิดหน้าต่างหมวดหมู่ไม่ได้: ") .. tostring(err), "error")
        refresh(view)
        return
    end
    XBAG_CategoryView = categoryView
    root:AddChild(categoryView)
    categoryView.x = (root.width - categoryView.width) / 2
    categoryView.y = (root.height - categoryView.height) / 2

    set_text(child(categoryView, "title"), is_english() and "Select Category" or "เลือกหมวดหมู่")
    set_text(child(categoryView, "subtitle"), is_english() and "Filter items in the backpack and on the map" or "กรองสิ่งของในกระเป๋าและบนแผนที่")
    set_text(child(categoryView, "hint"), is_english() and "Choose a category to return to the backpack" or "เลือกหนึ่งหมวดเพื่อกลับไปยังหน้ากระเป๋า")
    set_text(child(categoryView, "btnClose"), "×")
    for _, row in ipairs(XBAG_Categories) do
        local selected = row
        local button = child(categoryView, row.button)
        set_text(button, (XBAG_Category == row.id and "▶ " or "") .. (is_english() and row.en or row.th))
        if button ~= nil then button.onClick:Add(function()
            XBAG_Category, XBAG_Page, XBAG_Selected, XBAG_Quantity = selected.id, 1, 1, 1
            close_category_window()
            set_status(nil, nil)
            refresh(view)
            pcall(function() view:BringToFront() end)
        end) end
    end
    local close = child(categoryView, "btnClose")
    if close ~= nil then close.onClick:Add(function()
        close_category_window()
        pcall(function() view:BringToFront() end)
    end) end
    pcall(function() categoryView:BringToFront() end)
end

function XaouBackpack_RefreshWindow()
    if XBAG_View ~= nil then refresh(XBAG_View) end
end

local function act(view)
    if XBAG_Busy then return end
    local row = selected_row()
    if row == nil then set_status("กรุณาเลือกสิ่งของ", "error"); refresh(view); return end
    local quantity = selected_quantity(row)
    XBAG_Busy = true
    set_status(XBAG_Mode == "bag" and "กำลังนำของออก..." or "กำลังเก็บของ...", nil)
    refresh_detail(view)
    local ok, result, detail = pcall(function()
        if XBAG_Mode == "bag" then return XaouShop_BackpackWithdraw(row.id, quantity, XBAG_Target) end
        return XaouShop_BackpackDeposit(row.id, quantity, XBAG_Target)
    end)
    XBAG_Busy = false
    if ok and result == true then
        local info = def_info(row.id)
        local verb = XBAG_Mode == "bag" and "นำออก " or "เก็บ "
        set_status(verb .. info.name .. " จำนวน " .. tostring(quantity) .. " สำเร็จ", "success")
    else
        local reason = detail or result
        if reason == "NOT_ENOUGH_ITEMS" then reason = "จำนวนไอเทมไม่เพียงพอ"
        elseif reason == "ITEM_NOT_FOUND" then reason = "ไม่พบไอเทม"
        elseif reason == "REMOVE_FAILED" or reason == "REMOVE_INCOMPLETE" then reason = "นำไอเทมออกจากแผนที่ไม่สำเร็จ" end
        set_status("ดำเนินการไม่สำเร็จ: " .. tostring(reason or "ไม่ทราบสาเหตุ"), "error")
    end
    refresh(view)
end

function XaouBackpack_OpenWindow(target)
    XaouBackpack_CloseWindow()
    XBAG_Target, XBAG_Mode, XBAG_Page, XBAG_Category = target, "bag", 1, "all"
    XBAG_Selected, XBAG_Quantity, XBAG_Busy = 1, 1, false
    set_status(nil, nil)

    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaouShop") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaouShop", "BackpackWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XBAG_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    for i = 1, 10 do
        local index = i
        local card = child(view, "item" .. tostring(i))
        if card ~= nil then card.onClick:Add(function()
            XBAG_Selected = (XBAG_Page - 1) * 10 + index
            XBAG_Quantity = 1
            set_status(nil, nil)
            refresh(view)
        end) end
    end
    local quantities = {{"btnQty1",1},{"btnQty10",10},{"btnQtyAll","all"}}
    for _, pair in ipairs(quantities) do
        local amount, button = pair[2], child(view, pair[1])
        if button ~= nil then button.onClick:Add(function() XBAG_Quantity = amount; refresh_detail(view) end) end
    end
    local bagMode = child(view, "btnBagMode")
    if bagMode ~= nil then bagMode.onClick:Add(function()
        XBAG_Mode, XBAG_Page, XBAG_Selected, XBAG_Quantity = "bag", 1, 1, 1
        set_status(nil, nil); refresh(view)
    end) end
    local mapMode = child(view, "btnMapMode")
    if mapMode ~= nil then mapMode.onClick:Add(function()
        XBAG_Mode, XBAG_Page, XBAG_Selected, XBAG_Quantity = "map", 1, 1, 1
        set_status(nil, nil); refresh(view)
    end) end
    local category = child(view, "btnCategory")
    if category ~= nil then category.onClick:Add(function() open_category_window(view) end) end
    local prev = child(view, "btnPrev")
    if prev ~= nil then prev.onClick:Add(function()
        if XBAG_Page > 1 then XBAG_Page = XBAG_Page - 1; XBAG_Selected = (XBAG_Page - 1) * 10 + 1; refresh(view) end
    end) end
    local next = child(view, "btnNext")
    if next ~= nil then next.onClick:Add(function()
        if XBAG_Page < page_count() then XBAG_Page = XBAG_Page + 1; XBAG_Selected = (XBAG_Page - 1) * 10 + 1; refresh(view) end
    end) end
    local action = child(view, "btnAction")
    if action ~= nil then action.onClick:Add(function() act(view) end) end
    local close = child(view, "btnClose")
    if close ~= nil then close.onClick:Add(XaouBackpack_CloseWindow) end
    refresh(view)
    pcall(function() view:BringToFront() end)
    return true
end
