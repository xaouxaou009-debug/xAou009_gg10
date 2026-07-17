-- Standalone FairyGUI window for Xaou 009 Daily Shop.

local XSHOP_View, XSHOP_Target = nil, nil
local XSHOP_Selected, XSHOP_Quantity = 1, 1
local XSHOP_Busy, XSHOP_Status, XSHOP_StatusKind = false, nil, nil
local XSHOP_Mode, XSHOP_Page, XSHOP_SellRows = "buy", 1, {}

local function child(obj, name)
    if obj == nil then return nil end
    local value = nil
    pcall(function() value = obj:GetChild(name) end)
    return value
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
        pcall(function() info.name = tostring(def.ThingName or def.DisplayName or id) end)
        pcall(function() info.desc = tostring(def.Desc or "") end)
        pcall(function() info.icon = tostring(def.TexPath or "") end)
    end
    return info
end

local function current_rows()
    if XSHOP_Mode == "sell" then return XSHOP_SellRows end
    return XaouShop_State and XaouShop_State.items or {}
end

local function selected_row()
    return current_rows()[XSHOP_Selected]
end

local function refresh_sell_rows()
    XSHOP_SellRows = XaouShop_GetSellItems and XaouShop_GetSellItems() or {}
end

local function page_count()
    return math.max(1, math.ceil(#current_rows() / 10))
end

local function set_status(text, kind)
    XSHOP_Status, XSHOP_StatusKind = tostring(text or ""), kind
end

function XaouShop_CloseWindow()
    if XSHOP_View ~= nil then
        pcall(function() XSHOP_View:RemoveFromParent() end)
        pcall(function() XSHOP_View:Dispose() end)
        XSHOP_View = nil
    end
end

local function refresh_detail(view)
    local row = selected_row()
    if row == nil then
        set_text(child(view, "detailName"), "เลือกสินค้า")
        set_text(child(view, "detailDesc"), "แตะสินค้าเพื่อดูรายละเอียด")
        set_text(child(view, "detailPrice"), "ราคา: -")
        set_text(child(view, "detailStock"), XSHOP_Mode == "sell" and "มีอยู่: -" or "คงเหลือ: -")
        set_visible(child(view, "detailIcon"), false)
        set_enabled(child(view, "btnBuy"), false)
        return
    end
    local info = def_info(row.id)
    local total = math.max(1, tonumber(row.price) or 1) * XSHOP_Quantity
    set_text(child(view, "detailName"), info.name)
    set_text(child(view, "detailDesc"), info.desc ~= "" and info.desc or tostring(row.id))
    set_text(child(view, "detailPrice"), "ราคา: " .. tostring(row.price) .. " / ชิ้น  |  รวม " .. tostring(total))
    local available = XSHOP_Mode == "sell" and tonumber(row.count) or tonumber(row.stock)
    if XSHOP_Mode == "sell" then
        set_text(child(view, "detailStock"), "มีอยู่: " .. tostring(available or 0))
    else
        set_text(child(view, "detailStock"), "คงเหลือ: " .. tostring(available or 0) .. "/10")
    end
    set_text(child(view, "qtyLabel"), "จำนวน: " .. tostring(XSHOP_Quantity))
    local loader = child(view, "detailIcon")
    pcall(function() loader.url = info.icon end)
    set_visible(loader, info.icon ~= "")
    set_enabled(child(view, "btnBuy"), not XSHOP_Busy and (available or 0) >= XSHOP_Quantity)
end

local function refresh(view)
    XaouShop_EnsureDaily()
    set_text(child(view, "title"), "Xaou 009 Daily Shop")
    set_text(child(view, "subtitle"), "ร้านค้าสำหรับผู้เริ่มต้น เปลี่ยนสินค้าทุกวัน")
    set_text(child(view, "btnClose"), "×")
    set_text(child(view, "dayText"), "สินค้าประจำวันที่ " .. tostring(XaouShop_State.day))
    set_text(child(view, "walletText"), "หินวิญญาณ: " .. tostring(XaouShop_CountCurrency()))
    set_text(child(view, "btnModeBuy"), XSHOP_Mode == "buy" and "▶ ซื้อสินค้า" or "ซื้อสินค้า")
    set_text(child(view, "btnModeSell"), XSHOP_Mode == "sell" and "▶ ขายของ" or "ขายของ")
    set_text(child(view, "btnDailyLogin"), "เช็กอิน 7 วัน")
    set_text(child(view, "btnQty1"), "1")
    set_text(child(view, "btnQty5"), "5")
    set_text(child(view, "btnQty10"), "10")
    set_text(child(view, "btnBuy"), XSHOP_Mode == "sell" and "ขายของ" or "ซื้อสินค้า")
    set_text(child(view, "brand"), "Xaou 009 • Beginner Buy & Sell Shop")

    if XSHOP_Mode == "sell" then refresh_sell_rows() end
    local pages = page_count()
    if XSHOP_Page > pages then XSHOP_Page = pages end
    if XSHOP_Page < 1 then XSHOP_Page = 1 end
    set_text(child(view, "btnPrev"), "◀")
    set_text(child(view, "btnNext"), "▶")
    set_text(child(view, "pageText"), tostring(XSHOP_Page) .. "/" .. tostring(pages))
    set_enabled(child(view, "btnPrev"), XSHOP_Page > 1)
    set_enabled(child(view, "btnNext"), XSHOP_Page < pages)

    local rows = current_rows()
    if XSHOP_Selected < 1 or XSHOP_Selected > #rows then XSHOP_Selected = 1 end
    for i = 1, 10 do
        local card = child(view, "item" .. tostring(i))
        local absoluteIndex = (XSHOP_Page - 1) * 10 + i
        local row = rows[absoluteIndex]
        if row ~= nil then
            local info = def_info(row.id)
            set_visible(card, true)
            set_text(child(card, "itemName"), info.name)
            set_text(child(card, "price"), "ราคา " .. tostring(row.price))
            if XSHOP_Mode == "sell" then
                set_text(child(card, "stock"), "มีอยู่ " .. tostring(row.count))
            else
                set_text(child(card, "stock"), "คงเหลือ " .. tostring(row.stock) .. "/10")
            end
            local icon = child(card, "icon")
            pcall(function() icon.url = info.icon end)
            set_visible(icon, info.icon ~= "")
            pcall(function() card.selected = absoluteIndex == XSHOP_Selected end)
            set_enabled(card, (tonumber(XSHOP_Mode == "sell" and row.count or row.stock) or 0) > 0)
        else
            set_visible(card, false)
        end
    end

    local status = XSHOP_Status
    if status == nil or status == "" then
        status = XSHOP_Mode == "sell" and "เลือกของที่มีบนแผนที่เพื่อขาย รับเป็นหินวิญญาณ" or "สินค้าแต่ละชนิดซื้อได้สูงสุด 10 ชิ้นต่อวัน"
    end
    set_text(child(view, "status"), status)
    local statusField = child(view, "status")
    if statusField ~= nil and CS ~= nil and CS.UnityEngine ~= nil then
        pcall(function()
            if XSHOP_StatusKind == "success" then statusField.color = CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XSHOP_StatusKind == "error" then statusField.color = CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else statusField.color = CS.UnityEngine.Color(0.30,0.27,0.20,1) end
        end)
    end
    refresh_detail(view)
end

function XaouShop_RefreshWindow()
    if XSHOP_View ~= nil then refresh(XSHOP_View) end
end

local function transact(view)
    if XSHOP_Busy then return end
    local row = selected_row()
    if row == nil then set_status("กรุณาเลือกสินค้า", "error"); refresh(view); return end
    XSHOP_Busy = true
    set_status(XSHOP_Mode == "sell" and "กำลังขายของ..." or "กำลังดำเนินการซื้อ...", nil)
    refresh(view)
    local ok, result, detail = pcall(function()
        if XSHOP_Mode == "sell" then return XaouShop_Sell(row.id, XSHOP_Quantity, XSHOP_Target) end
        return XaouShop_Buy(XSHOP_Selected, XSHOP_Quantity, XSHOP_Target)
    end)
    XSHOP_Busy = false
    if ok and result == true then
        local info = def_info(row.id)
        local verb = XSHOP_Mode == "sell" and "ขาย " or "ซื้อ "
        set_status(verb .. info.name .. " จำนวน " .. tostring(XSHOP_Quantity) .. " สำเร็จ", "success")
    else
        local reason = detail or result
        if reason == "NOT_ENOUGH" then reason = "หินวิญญาณไม่เพียงพอ"
        elseif reason == "OUT_OF_STOCK" then reason = "สินค้าเหลือไม่พอ"
        elseif reason == "ITEM_NOT_FOUND" then reason = "ไม่พบสินค้า"
        elseif reason == "REMOVE_FAILED" or reason == "REMOVE_INCOMPLETE" then reason = "หักหินวิญญาณไม่สำเร็จ"
        elseif reason == "NOT_ENOUGH_ITEMS" then reason = "ของที่เลือกมีไม่เพียงพอ"
        elseif reason == "ITEM_NOT_SELLABLE" then reason = "ไอเทมนี้ไม่สามารถขายได้"
        end
        local verb = XSHOP_Mode == "sell" and "ขาย" or "ซื้อ"
        set_status(verb .. "ไม่สำเร็จ: " .. tostring(reason or "ไม่ทราบสาเหตุ"), "error")
    end
    refresh(view)
end

function XaouShop_OpenWindow(target)
    XaouShop_CloseWindow()
    XaouShop_EnsureDaily()
    XSHOP_Target, XSHOP_Selected, XSHOP_Quantity = target, 1, 1
    XSHOP_Mode, XSHOP_Page, XSHOP_SellRows = "buy", 1, {}
    XSHOP_Busy = false
    set_status(nil, nil)

    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaouShop") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaouShop", "ShopWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XSHOP_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2

    for i = 1, 10 do
        local index = i
        local card = child(view, "item" .. tostring(i))
        if card ~= nil then card.onClick:Add(function()
            XSHOP_Selected = (XSHOP_Page - 1) * 10 + index
            XSHOP_Quantity = 1
            set_status(nil, nil)
            refresh(view)
        end) end
    end
    local quantities = {{"btnQty1",1},{"btnQty5",5},{"btnQty10",10}}
    for _, pair in ipairs(quantities) do
        local amount = pair[2]
        local button = child(view, pair[1])
        if button ~= nil then button.onClick:Add(function()
            XSHOP_Quantity = amount
            refresh_detail(view)
        end) end
    end
    local buyButton = child(view, "btnBuy")
    if buyButton ~= nil then buyButton.onClick:Add(function() transact(view) end) end
    local modeBuy = child(view, "btnModeBuy")
    if modeBuy ~= nil then modeBuy.onClick:Add(function()
        XSHOP_Mode, XSHOP_Page, XSHOP_Selected, XSHOP_Quantity = "buy", 1, 1, 1
        set_status(nil, nil); refresh(view)
    end) end
    local modeSell = child(view, "btnModeSell")
    if modeSell ~= nil then modeSell.onClick:Add(function()
        XSHOP_Mode, XSHOP_Page, XSHOP_Selected, XSHOP_Quantity = "sell", 1, 1, 1
        refresh_sell_rows(); set_status(nil, nil); refresh(view)
    end) end
    local dailyLogin = child(view, "btnDailyLogin")
    if dailyLogin ~= nil then dailyLogin.onClick:Add(function()
        if XaouDailyLogin_Open then XaouDailyLogin_Open(XSHOP_Target) end
    end) end
    local prevButton = child(view, "btnPrev")
    if prevButton ~= nil then prevButton.onClick:Add(function()
        if XSHOP_Page > 1 then XSHOP_Page = XSHOP_Page - 1; XSHOP_Selected = (XSHOP_Page - 1) * 10 + 1; refresh(view) end
    end) end
    local nextButton = child(view, "btnNext")
    if nextButton ~= nil then nextButton.onClick:Add(function()
        if XSHOP_Page < page_count() then XSHOP_Page = XSHOP_Page + 1; XSHOP_Selected = (XSHOP_Page - 1) * 10 + 1; refresh(view) end
    end) end
    local closeButton = child(view, "btnClose")
    if closeButton ~= nil then closeButton.onClick:Add(XaouShop_CloseWindow) end
    refresh(view)
    pcall(function() view:BringToFront() end)
    return true
end
