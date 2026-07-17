-- Xaou 009 seven-day login rewards, based only on the current in-game day.

local XLOGIN_View, XLOGIN_Target = nil, nil
local XLOGIN_Status, XLOGIN_StatusKind = nil, nil

local function child(obj, name)
    local value = nil
    if obj ~= nil then pcall(function() value = obj:GetChild(name) end) end
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
    pcall(function() obj.alpha = value == true and 1 or 0.48 end)
end

local function today_info()
    local gameDay = XaouShop_GetDay and XaouShop_GetDay() or 0
    return math.floor(gameDay), "วันเกม " .. tostring(gameDay), "GAME"
end

local function next_random(seed)
    seed = (seed * 48271) % 2147483647
    if seed <= 0 then seed = seed + 2147483646 end
    return seed
end

local function reward_pool()
    local rows, seen = {}, {}
    local function add(entry)
        if type(entry) ~= "table" then return end
        local id = entry.id or entry.ID or entry.Name or entry.name
        if id == nil then return end
        id = tostring(id)
        if id == "" or id == "Item_LingStone" or seen[id] then return end
        if XaouShop_GetDef and XaouShop_GetDef(id) ~= nil then
            seen[id] = true
            rows[#rows + 1] = id
        end
    end
    for _, pack in ipairs(Xaou_ItemPacks or {}) do
        local entries = type(pack) == "table" and (pack.items or pack) or nil
        if type(entries) == "table" then for _, entry in ipairs(entries) do add(entry) end end
    end
    for _, entry in ipairs(XaouShop_ItemPool or {}) do add(entry) end
    table.sort(rows)
    return rows
end

local function generate_rewards(startDay)
    local pool = reward_pool()
    local rewards = {}
    local seed = math.max(1, math.floor(tonumber(startDay) or 1) * 7009 + 970200009)
    while #rewards < 7 and #pool > 0 do
        seed = next_random(seed)
        rewards[#rewards + 1] = {id=table.remove(pool, (seed % #pool) + 1), amount=10}
    end
    return rewards
end

local function state()
    XaouShop_State = XaouShop_State or {day=-1, items={}, backpack={}}
    local today, label, source = today_info()
    local data = XaouShop_State.login
    if type(data) ~= "table" or tonumber(data.startDay) == nil then
        data = {startDay=today, lastSeen=today, claimed={}, rewards=generate_rewards(today), source=source}
        XaouShop_State.login = data
    end
    data.claimed = type(data.claimed) == "table" and data.claimed or {}
    data.rewards = type(data.rewards) == "table" and data.rewards or {}
    local startDay = math.floor(tonumber(data.startDay) or today)
    if today >= startDay + 7 then
        startDay = startDay + math.floor((today - startDay) / 7) * 7
        data = {startDay=startDay, lastSeen=today, claimed={}, rewards=generate_rewards(startDay), source=source}
        XaouShop_State.login = data
    elseif #data.rewards < 7 then
        data.rewards = generate_rewards(startDay)
    end
    data.rollback = tonumber(data.lastSeen) ~= nil and today < tonumber(data.lastSeen)
    if not data.rollback and (tonumber(data.lastSeen) == nil or today > tonumber(data.lastSeen)) then data.lastSeen = today end
    data.today, data.todayLabel = today, label
    data.index = math.floor(today - tonumber(data.startDay)) + 1
    return data
end

local function def_info(id)
    local def = XaouShop_GetDef and XaouShop_GetDef(id) or nil
    local info = {name=tostring(id or ""), icon=""}
    if def ~= nil then
        pcall(function() info.name = tostring(def.ThingName or def.DisplayName or id) end)
        pcall(function() info.icon = tostring(def.TexPath or "") end)
    end
    return info
end

local function claimed(data, index)
    return data.claimed[index] == true or data.claimed[tostring(index)] == true
end

local function set_status(text, kind)
    XLOGIN_Status, XLOGIN_StatusKind = tostring(text or ""), kind
end

local function refresh()
    local view = XLOGIN_View
    if view == nil then return end
    local data = state()
    set_text(child(view, "title"), "Xaou 009 เช็กอินรายวัน")
    set_text(child(view, "subtitle"), "เข้าเกมต่อเนื่อง 7 วัน รับไอเทมสุ่มวันละ 10 ชิ้น")
    set_text(child(view, "btnClose"), "×")
    set_text(child(view, "cycleText"), "วันที่ " .. tostring(math.max(1, math.min(7, data.index))) .. "/7 • " .. tostring(data.todayLabel))
    set_text(child(view, "btnClaim"), claimed(data, data.index) and "รับแล้ว" or "รับรางวัลวันนี้")
    set_text(child(view, "hint"), "วันที่ไม่ได้เข้าเกมจะถือว่าพลาด และไม่สามารถรับย้อนหลังได้")
    set_text(child(view, "brand"), "Xaou 009 • Seven-Day Random Rewards")

    for i = 1, 7 do
        local card = child(view, "day" .. tostring(i))
        local reward = data.rewards[i]
        if card ~= nil and reward ~= nil then
            local info = def_info(reward.id)
            set_visible(card, true)
            set_text(child(card, "dayText"), "วันที่ " .. tostring(i))
            set_text(child(card, "itemName"), info.name)
            set_text(child(card, "amountText"), "จำนวน " .. tostring(reward.amount or 10))
            local status = "รอรับ"
            if claimed(data, i) then status = "รับแล้ว"
            elseif i < data.index then status = "พลาด"
            elseif i == data.index then status = data.rollback and "ตรวจพบวันที่ย้อนหลัง" or "รับได้วันนี้"
            end
            set_text(child(card, "statusText"), status)
            local icon = child(card, "icon")
            pcall(function() icon.url = info.icon end)
            set_visible(icon, info.icon ~= "")
            pcall(function() card.selected = i == data.index end)
        elseif card ~= nil then
            set_visible(card, false)
        end
    end

    local canClaim = not data.rollback and data.index >= 1 and data.index <= 7 and not claimed(data, data.index) and data.rewards[data.index] ~= nil
    set_enabled(child(view, "btnClaim"), canClaim)
    local status = XLOGIN_Status
    if status == nil or status == "" then
        if data.rollback then status = "ตรวจพบวันที่เครื่องย้อนหลัง จึงระงับการรับรางวัลชั่วคราว"
        elseif claimed(data, data.index) then status = "วันนี้รับรางวัลแล้ว กลับมาใหม่วันพรุ่งนี้"
        elseif data.index >= 1 and data.index <= 7 then status = "รางวัลวันนี้พร้อมรับแล้ว"
        else status = "กำลังเตรียมรอบเช็กอินใหม่" end
    end
    set_text(child(view, "status"), status)
    local field = child(view, "status")
    if field ~= nil and CS ~= nil and CS.UnityEngine ~= nil then
        pcall(function()
            if XLOGIN_StatusKind == "success" then field.color = CS.UnityEngine.Color(0.13,0.42,0.20,1)
            elseif XLOGIN_StatusKind == "error" then field.color = CS.UnityEngine.Color(0.68,0.12,0.10,1)
            else field.color = CS.UnityEngine.Color(0.30,0.27,0.20,1) end
        end)
    end
end

local function claim_today()
    local data = state()
    if data.rollback then set_status("รับไม่ได้: วันที่เครื่องถูกปรับย้อนหลัง", "error"); refresh(); return end
    local index = data.index
    if index < 1 or index > 7 then set_status("วันนี้ไม่อยู่ในรอบเช็กอิน", "error"); refresh(); return end
    if claimed(data, index) then set_status("วันนี้รับรางวัลแล้ว", "error"); refresh(); return end
    local reward = data.rewards[index]
    if reward == nil then set_status("ไม่พบข้อมูลรางวัล", "error"); refresh(); return end
    local ok, result, detail = pcall(function() return XaouShop_GrantItem(reward.id, reward.amount or 10, XLOGIN_Target) end)
    if ok and result == true then
        data.claimed[index] = true
        local info = def_info(reward.id)
        set_status("รับ " .. info.name .. " จำนวน " .. tostring(reward.amount or 10) .. " สำเร็จ", "success")
    else
        set_status("รับรางวัลไม่สำเร็จ: " .. tostring(detail or result), "error")
    end
    refresh()
end

function XaouDailyLogin_ShouldAutoOpen()
    local data = state()
    return not data.rollback and data.index >= 1 and data.index <= 7 and not claimed(data, data.index)
end

function XaouDailyLogin_GetToday()
    local today = today_info()
    return today
end

function XaouDailyLogin_Close()
    if XLOGIN_View ~= nil then
        pcall(function() XLOGIN_View:RemoveFromParent() end)
        pcall(function() XLOGIN_View:Dispose() end)
        XLOGIN_View = nil
    end
end

function XaouDailyLogin_Open(target)
    XaouDailyLogin_Close()
    XLOGIN_Target = target
    set_status(nil, nil)
    local pkg = UIPackage or (CS.FairyGUI and CS.FairyGUI.UIPackage)
    local root = (GRoot and GRoot.inst) or (CS.FairyGUI and CS.FairyGUI.GRoot.inst)
    if pkg == nil or root == nil then return false, "FairyGUI/GRoot not found" end
    pcall(function() pkg.AddPackage("UI/XaouShop") end)
    local view = nil
    local ok, err = pcall(function() view = pkg.CreateObject("XaouShop", "DailyLoginWindow") end)
    if not ok or view == nil then return false, tostring(err or "CreateObject returned nil") end
    XLOGIN_View = view
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
    local closeButton = child(view, "btnClose")
    if closeButton ~= nil then closeButton.onClick:Add(XaouDailyLogin_Close) end
    local claimButton = child(view, "btnClaim")
    if claimButton ~= nil then claimButton.onClick:Add(claim_today) end
    refresh()
    pcall(function() view:BringToFront() end)
    return true
end
