-- Separate FairyGUI window for fixed special items.

local XSPECIAL_View, XSPECIAL_Target = nil, nil
local XSPECIAL_CategoryIndex, XSPECIAL_Page = 1, 1
local XSPECIAL_Selected, XSPECIAL_Quantity = 1, 1
local XSPECIAL_Rows, XSPECIAL_Busy = {}, false
local XSPECIAL_Status, XSPECIAL_StatusKind = nil, nil

local function child(obj, name)
    local value = nil
    if obj ~= nil then pcall(function() value = obj:GetChild(name) end) end
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

local function info_for(id)
    local def = XaouShop_GetDef and XaouShop_GetDef(id) or nil
    if def == nil and XaouShop_GetBuildingDef ~= nil then
        def = XaouShop_GetBuildingDef(id)
    end
    local info = {name=tostring(id or ""), desc="", icon=""}
    if def ~= nil then
        pcall(function() info.name = tostring(def.ThingName or def.DisplayName or id) end)
        pcall(function() info.desc = tostring(def.Desc or "") end)
        pcall(function() info.icon = tostring(def.TexPath or "") end)
    end
    for _, entry in ipairs(XaouShop_SpecialItems or {}) do
        if tostring(entry.id or "") == tostring(id or "") then
            if entry.displayName ~= nil then info.name = tostring(entry.displayName) end
            if entry.description ~= nil then info.desc = tostring(entry.description) end
            if entry.icon ~= nil then info.icon = tostring(entry.icon) end
            break
        end
    end
    return info
end

local function categories()
    return XaouShop_SpecialCategories or {{id="all", text="ทั้งหมด"}}
end

local function category()
    return categories()[XSPECIAL_CategoryIndex] or categories()[1]
end

local function reload_rows()
    local cat = category()
    XSPECIAL_Rows = XaouShop_GetSpecialRows and XaouShop_GetSpecialRows(cat and cat.id or "all") or {}
end

local function pages()
    return math.max(1, math.ceil(#XSPECIAL_Rows / 8))
end

local function set_status(text, kind)
    XSPECIAL_Status, XSPECIAL_StatusKind = text, kind
end

function XaouSpecialShop_Close()
    if XSPECIAL_View ~= nil then
        pcall(function() XSPECIAL_View:RemoveFromParent() end)
        pcall(function() XSPECIAL_View:Dispose() end)
        XSPECIAL_View = nil
    end
end

local function refresh_detail(view)
    local row = XSPECIAL_Rows[XSPECIAL_Selected]
    if row == nil then
        set_text(child(view, "detailName"), "เลือกของพิเศษ")
        set_text(child(view, "detailDesc"), "แตะสินค้าเพื่อดูรายละเอียด")
        set_text(child(view, "detailPrice"), "ราคา: -")
        set_text(child(view, "detailStock"), "สิทธิ์คงเหลือ: -")
        set_visible(child(view, "detailIcon"), false)
        set_enabled(child(view, "btnBuy"), false)
        return
    end
    local info = info_for(row.id)
    set_text(child(view, "detailName"), info.name)
    set_text(child(view, "detailDesc"), info.desc ~= "" and info.desc or row.id)
    local rowKind = tostring(row.kind or "item")
    local isBuilding = rowKind == "building"
    local isGong = rowKind == "gong"
    local isMindLevel = rowKind == "mind_level"
    local singleOnly = isBuilding or isGong or isMindLevel
    if singleOnly then XSPECIAL_Quantity = 1 end
    set_text(child(view, "detailPrice"), "ราคา: " .. tostring(row.price) .. " / ชิ้น  |  รวม " .. tostring(row.price * XSPECIAL_Quantity))
    set_text(child(view, "detailStock"), "สิทธิ์คงเหลือ: " .. tostring(row.stock) .. "/" .. tostring(row.limit))
    set_text(child(view, "qtyLabel"), isBuilding and "ซื้อและวางครั้งละ 1 ชิ้น"
        or (isGong and "ซื้อครั้งเดียว ปลดล็อกให้ทั้งสำนัก"
        or (isMindLevel and "ใช้กับ NPC ที่เลือกทันที" or ("จำนวน: " .. tostring(XSPECIAL_Quantity)))))
    local icon = child(view, "detailIcon")
    pcall(function() icon.url = info.icon end)
    set_visible(icon, info.icon ~= "")
    set_enabled(child(view, "btnBuy"), not XSPECIAL_Busy and row.stock >= XSPECIAL_Quantity)
    set_enabled(child(view, "btnQty1"), not singleOnly)
    set_enabled(child(view, "btnQty5"), not singleOnly)
    set_enabled(child(view, "btnQty10"), not singleOnly)
end

local function refresh(view)
    reload_rows()
    local cat = category() or {text="ทั้งหมด"}
    set_text(child(view, "title"), "Xaou 009 Special Shop")
    set_text(child(view, "subtitle"), "ของพิเศษแบบคงที่ โควตารีเซ็ตทุกเดือนในเกม")
    set_text(child(view, "btnClose"), "×")
    set_text(child(view, "categoryTitle"), "หมวด: " .. tostring(cat.text or cat.id))
    set_text(child(view, "walletText"), "หินวิญญาณ: " .. tostring(XaouShop_CountCurrency and XaouShop_CountCurrency() or 0))
    set_text(child(view, "btnQty1"), "1")
    set_text(child(view, "btnQty5"), "5")
    set_text(child(view, "btnQty10"), "10")
    set_text(child(view, "btnBuy"), "ซื้อของพิเศษ")
    set_text(child(view, "brand"), "Xaou 009 • Special Items")

    for i = 1, 6 do
        local button = child(view, "cat" .. tostring(i))
        local data = categories()[i]
        set_visible(button, data ~= nil)
        if data ~= nil then set_text(button, (i == XSPECIAL_CategoryIndex and "▶ " or "") .. tostring(data.text or data.id)) end
    end

    local maxPage = pages()
    if XSPECIAL_Page > maxPage then XSPECIAL_Page = maxPage end
    if XSPECIAL_Selected < 1 or XSPECIAL_Selected > #XSPECIAL_Rows then XSPECIAL_Selected = 1 end
    set_text(child(view, "btnPrev"), "◀")
    set_text(child(view, "btnNext"), "▶")
    set_text(child(view, "pageText"), tostring(XSPECIAL_Page) .. "/" .. tostring(maxPage))
    set_enabled(child(view, "btnPrev"), XSPECIAL_Page > 1)
    set_enabled(child(view, "btnNext"), XSPECIAL_Page < maxPage)

    for i = 1, 8 do
        local card = child(view, "item" .. tostring(i))
        local absolute = (XSPECIAL_Page - 1) * 8 + i
        local row = XSPECIAL_Rows[absolute]
        if row == nil then
            set_visible(card, false)
        else
            local info = info_for(row.id)
            set_visible(card, true)
            set_text(child(card, "itemName"), info.name)
            set_text(child(card, "price"), "ราคา " .. tostring(row.price))
            set_text(child(card, "stock"), "คงเหลือ " .. tostring(row.stock) .. "/" .. tostring(row.limit))
            local icon = child(card, "icon")
            pcall(function() icon.url = info.icon end)
            set_visible(icon, info.icon ~= "")
            pcall(function() card.selected = absolute == XSPECIAL_Selected end)
            set_enabled(card, row.stock > 0)
        end
    end

    local status = XSPECIAL_Status
    if status == nil or status == "" then
        status = #XSPECIAL_Rows == 0 and "ยังไม่มีสินค้าในหมวดนี้" or "ซื้อได้ธาตุละ 50 ชิ้น โควตารีเซ็ตทุก 28 วันเกม"
    end
    set_text(child(view, "status"), status)
    local statusField = child(view, "status")
    if statusField ~= nil and CS and CS.UnityEngine then
        pcall(function()
            if XSPECIAL_StatusKind == "success" then statusField.color = CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XSPECIAL_StatusKind == "error" then statusField.color = CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else statusField.color = CS.UnityEngine.Color(0.30,0.27,0.20,1) end
        end)
    end
    refresh_detail(view)
end

local function buy(view)
    if XSPECIAL_Busy then return end
    local row = XSPECIAL_Rows[XSPECIAL_Selected]
    if row == nil then set_status("กรุณาเลือกของพิเศษ", "error"); refresh(view); return end
    local rowKind = tostring(row.kind or "item")
    local isBuilding = rowKind == "building"
    local isGong = rowKind == "gong"
    local isMindLevel = rowKind == "mind_level"
    if isBuilding or isGong or isMindLevel then XSPECIAL_Quantity = 1 end

    if isGong then
        XSPECIAL_Busy = true
        set_status("กำลังปลดล็อกวิชาให้สำนัก...", nil); refresh(view)
        local ok, result, detail = pcall(function()
            return XaouShop_BuySpecial(row.id, 1, XSPECIAL_Target)
        end)
        XSPECIAL_Busy = false
        if ok and result == true then
            set_status("ปลดล็อกวิชาโพธิจิตเมตตาแห่ง Xaou สำเร็จแล้ว", "success")
        else
            local reason = detail or result
            if reason == "NOT_ENOUGH" then reason = "หินวิญญาณไม่เพียงพอ"
            elseif reason == "ALREADY_UNLOCKED" then reason = "สำนักปลดล็อกวิชานี้แล้ว"
            elseif reason == "UNLOCK_GONG_FAILED" then reason = "เกมไม่ยอมปลดล็อกวิชา"
            elseif reason == "ITEM_NOT_FOUND" then reason = "ไม่พบข้อมูลวิชา กรุณาตรวจไฟล์ Settings"
            end
            set_status("ปลดล็อกวิชาไม่สำเร็จ: " .. tostring(reason or "ไม่ทราบสาเหตุ"), "error")
        end
        refresh(view)
        return
    end
    XSPECIAL_Busy = true
    set_status("กำลังซื้อสินค้า...", nil); refresh(view)
    local ok, result, detail = pcall(function()
        return XaouShop_BuySpecial(row.id, XSPECIAL_Quantity, XSPECIAL_Target)
    end)
    XSPECIAL_Busy = false
    if ok and result == true then
        if isBuilding then
            local placementOk, placementError = XaouShop_StartBuildingPlacement(row.id)
            if placementOk then
                XaouSpecialShop_Close()
                if XaouShop_CloseWindow ~= nil then pcall(XaouShop_CloseWindow) end
                return
            end
            set_status("ซื้อสำเร็จ แต่เปิดโหมดวางอาคารไม่ได้: " .. tostring(placementError), "error")
            refresh(view)
            return
        end
        if isMindLevel then
            set_status("ใช้โอสถสำเร็จ ระดับสภาวะจิตของ NPC เพิ่มขึ้น 1 ระดับ", "success")
        else
            set_status("ซื้อ " .. info_for(row.id).name .. " จำนวน " .. tostring(XSPECIAL_Quantity) .. " สำเร็จ", "success")
        end
    else
        local reason = detail or result
        if reason == "NOT_ENOUGH" then reason = "หินวิญญาณไม่เพียงพอ"
        elseif reason == "OUT_OF_STOCK" then reason = "ซื้อสินค้านี้ครบจำนวนจำกัดแล้ว"
        elseif reason == "ITEM_NOT_FOUND" then reason = "ไม่พบ Item ID ในเกม"
        elseif reason == "BUILDING_ONE_AT_A_TIME" then reason = "เฟอร์นิเจอร์ซื้อและวางได้ครั้งละ 1 ชิ้น"
        elseif reason == "NOT_DIVINE_PRACTICE" then reason = "NPC ที่เลือกยังไม่ได้ฝึกวิชาสายเทพ"
        elseif reason == "MIND_LEVEL_NOT_CHANGED" then reason = "ระดับสภาวะจิตไม่เปลี่ยน อาจถึงระดับสูงสุดแล้ว"
        elseif reason == "MIND_LEVEL_FAILED" then reason = "เกมไม่ยอมเพิ่มระดับสภาวะจิต" end
        set_status("ซื้อไม่สำเร็จ: " .. tostring(reason or "ไม่ทราบสาเหตุ"), "error")
    end
    refresh(view)
end

function XaouSpecialShop_Open(target)
    XaouSpecialShop_Close()
    XSPECIAL_Target, XSPECIAL_CategoryIndex = target, 1
    XSPECIAL_Page, XSPECIAL_Selected, XSPECIAL_Quantity = 1, 1, 1
    XSPECIAL_Busy = false; set_status(nil, nil); reload_rows()

    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaouShop") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaouShop", "SpecialShopWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XSPECIAL_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    for i = 1, 6 do
        local index = i
        local button = child(view, "cat" .. tostring(i))
        if button ~= nil then button.onClick:Add(function()
            if categories()[index] ~= nil then
                XSPECIAL_CategoryIndex, XSPECIAL_Page, XSPECIAL_Selected, XSPECIAL_Quantity = index, 1, 1, 1
                set_status(nil, nil); refresh(view)
            end
        end) end
    end
    for i = 1, 8 do
        local index = i
        local card = child(view, "item" .. tostring(i))
        if card ~= nil then card.onClick:Add(function()
            XSPECIAL_Selected = (XSPECIAL_Page - 1) * 8 + index
            XSPECIAL_Quantity = 1; set_status(nil, nil); refresh(view)
        end) end
    end
    for _, pair in ipairs({{"btnQty1",1},{"btnQty5",5},{"btnQty10",10}}) do
        local amount, button = pair[2], child(view, pair[1])
        if button ~= nil then button.onClick:Add(function() XSPECIAL_Quantity = amount; refresh_detail(view) end) end
    end
    local prev = child(view, "btnPrev")
    if prev ~= nil then prev.onClick:Add(function() if XSPECIAL_Page > 1 then XSPECIAL_Page = XSPECIAL_Page - 1; XSPECIAL_Selected = (XSPECIAL_Page - 1) * 8 + 1; refresh(view) end end) end
    local nextButton = child(view, "btnNext")
    if nextButton ~= nil then nextButton.onClick:Add(function() if XSPECIAL_Page < pages() then XSPECIAL_Page = XSPECIAL_Page + 1; XSPECIAL_Selected = (XSPECIAL_Page - 1) * 8 + 1; refresh(view) end end) end
    local buyButton = child(view, "btnBuy")
    if buyButton ~= nil then buyButton.onClick:Add(function() buy(view) end) end
    local closeButton = child(view, "btnClose")
    if closeButton ~= nil then closeButton.onClick:Add(XaouSpecialShop_Close) end
    refresh(view)
    pcall(function() view:BringToFront() end)
    return true
end
