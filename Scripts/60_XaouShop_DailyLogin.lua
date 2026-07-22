-- Xaou 009 seven-day login rewards with persistent membership progression.

local XLOGIN_View, XLOGIN_Target = nil, nil
local XLOGIN_Status, XLOGIN_StatusKind = nil, nil
local XLOGIN_ConfirmUpgrade = false
local REWARD_VERSION = 3

local MEMBERSHIP = {
    [1] = {name="ผู้เริ่มต้น", cap=4, day7=5},
    [2] = {name="ศิษย์", cap=6, day7=7, checkins=20, requirements={
        {id="Item_Wood", amount=60}, {id="Item_GrayRock", amount=60},
        {id="Item_LingStoneBlock", amount=60}, {id="Item_LingStone", amount=2000},
    }},
    [3] = {name="ผู้อาวุโส", cap=8, day7=9, checkins=80, requirements={
        {id="Item_LingWoodBlock", amount=80}, {id="Item_IronRock", amount=80},
        {id="Item_LingStoneBlock", amount=100}, {id="Item_LingStone", amount=5000},
        {id="Item_Dan_LongDan1", amount=1},
    }},
    [4] = {name="เซียน", cap=10, day7=12, checkins=300, requirements={
        {id="Item_Jade", amount=120}, {id="Item_LingCrystal", amount=120},
        {id="Item_LingStone", amount=20000}, {id="Item_BossLong_Jiao", amount=1},
        {id="Item_BossLong_Jing", amount=1}, {id="Item_BossLong_Meat", amount=5},
        {id="Item_BossLong_Lin", amount=2},
    }},
}

local ITEM_LABELS = {
    Item_Wood="ไม้", Item_GrayRock="หินสีเทา", Item_LingWoodBlock="ไม้วิญญาณแปรรูป",
    Item_IronRock="แร่เหล็ก", Item_Jade="หยก", Item_LingCrystal="ผลึกวิญญาณ",
    Item_LingStone="หินวิญญาณ", Item_LingStoneBlock="อิฐหินวิญญาณ",
    Item_Dan_LongDan1="โอสถมังกร", Item_BossLong_Jiao="เขามังกรวารี",
    Item_BossLong_Jing="ชีพจรมังกรวารี", Item_BossLong_Meat="เนื้อมังกรวารี",
    Item_BossLong_Lin="เกล็ดมังกรวารี",
}

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
    pcall(function() obj.alpha = value == true and 1 or 0.48 end)
end

local function today_info()
    local gameDay = XaouShop_GetDay and XaouShop_GetDay() or 0
    return math.floor(gameDay), "วันที่เกม " .. tostring(gameDay), "GAME"
end

local function next_random(seed)
    seed = (seed * 48271) % 2147483647
    if seed <= 0 then seed = seed + 2147483646 end
    return seed
end

local function membership_state()
    XaouShop_State = XaouShop_State or {day=-1, items={}, backpack={}}
    if type(XaouShop_State.membership) ~= "table" then XaouShop_State.membership = {level=1} end
    local level = math.max(1, math.min(4, math.floor(tonumber(XaouShop_State.membership.level) or 1)))
    XaouShop_State.membership.level = level
    if tonumber(XaouShop_State.membership.totalClaims) == nil then
        local migrated = 0
        local oldLogin = XaouShop_State.login
        if type(oldLogin) == "table" and type(oldLogin.claimed) == "table" then
            for i = 1, 7 do
                if oldLogin.claimed[i] == true or oldLogin.claimed[tostring(i)] == true then migrated = migrated + 1 end
            end
        end
        XaouShop_State.membership.totalClaims = migrated
    end
    XaouShop_State.membership.totalClaims = math.max(0, math.floor(tonumber(XaouShop_State.membership.totalClaims) or 0))
    return XaouShop_State.membership, level, MEMBERSHIP[level]
end

local function item_rate(id)
    local def = XaouShop_GetDef and XaouShop_GetDef(id) or nil
    if def == nil then return nil end
    local rate = nil
    pcall(function() rate = tonumber(def.Rate) end)
    if rate == nil then pcall(function() rate = tonumber(def.Rarity) end) end
    return math.max(1, math.min(12, math.floor(rate or 5))), def
end

local function safe_reward(id, def)
    if id == "" or id == "Item_LingStone" or def == nil then return false end
    local blocked = {
        "Boss", "Story", "Quest", "System", "Box", "Gong", "Esoterica", "Secret",
        "Special", "NormalAttack", "Building", "Other_Portia", "Xaou_", "Zhen", "Formation",
        "Mount", "Ride", "Saddle", "LingShou", "Animal", "Egg", "Manual", "Book", "Skill",
        "Recipe", "Formula", "Profession", "Career", "Blueprint", "Diagram",
    }
    for _, word in ipairs(blocked) do
        if string.find(id, word, 1, true) ~= nil then return false end
    end
    local maxStack = 0
    pcall(function() maxStack = tonumber(def.MaxStack) or 0 end)
    return maxStack > 1
end

local function reward_pool()
    local rows, seen = {}, {}
    local function add(entry)
        if type(entry) ~= "table" then return end
        local id = entry.id or entry.ID or entry.Name or entry.name
        if id == nil then return end
        id = tostring(id)
        if seen[id] then return end
        local rate, def = item_rate(id)
        if rate ~= nil and safe_reward(id, def) then
            seen[id] = true
            rows[#rows + 1] = {id=id, rate=rate}
        end
    end
    -- Login rewards intentionally use only the curated beginner-safe pool.
    -- The complete item packs also contain manuals, formations, mounts and
    -- progression unlockers that should never be granted by daily login.
    for _, entry in ipairs(XaouShop_ItemPool or {}) do add(entry) end
    table.sort(rows, function(a, b) return a.id < b.id end)
    return rows
end

local function reward_amount(rate)
    if rate <= 4 then return 10 end
    if rate <= 6 then return 5 end
    if rate <= 8 then return 3 end
    if rate == 9 then return 2 end
    return 1
end

local function rate_range(level, dayIndex)
    local member = MEMBERSHIP[level] or MEMBERSHIP[1]
    local cap = dayIndex == 7 and member.day7 or member.cap
    if dayIndex <= 2 then cap = math.min(cap, 4)
    elseif dayIndex <= 4 then cap = math.min(cap, 6)
    elseif dayIndex <= 6 then cap = math.min(cap, 8) end
    local floor = 1
    if dayIndex >= 5 then floor = math.max(1, cap - 3) end
    if dayIndex == 7 then floor = math.max(1, cap - 2) end
    return floor, cap
end

local function generate_rewards(startDay, level)
    local pool = reward_pool()
    local rewards, used = {}, {}
    local seed = math.max(1, math.floor(tonumber(startDay) or 1) * 7009 + 970200009 + level * 131)
    for dayIndex = 1, 7 do
        local minRate, maxRate = rate_range(level, dayIndex)
        local candidates = {}
        for _, row in ipairs(pool) do
            if not used[row.id] and row.rate >= minRate and row.rate <= maxRate then candidates[#candidates + 1] = row end
        end
        if #candidates == 0 then
            for _, row in ipairs(pool) do
                if not used[row.id] and row.rate <= maxRate then candidates[#candidates + 1] = row end
            end
        end
        if #candidates > 0 then
            seed = next_random(seed)
            local selected = candidates[(seed % #candidates) + 1]
            used[selected.id] = true
            rewards[dayIndex] = {id=selected.id, amount=reward_amount(selected.rate), rate=selected.rate}
        end
    end
    return rewards
end

local function claimed(data, index)
    return data.claimed[index] == true or data.claimed[tostring(index)] == true
end

local function state()
    XaouShop_State = XaouShop_State or {day=-1, items={}, backpack={}}
    local _, level = membership_state()
    local today, label, source = today_info()
    local data = XaouShop_State.login
    if type(data) ~= "table" or tonumber(data.startDay) == nil then
        data = {startDay=today, lastSeen=today, claimed={}, rewards=generate_rewards(today, level), source=source, rewardVersion=REWARD_VERSION, memberLevel=level}
        XaouShop_State.login = data
    end
    data.claimed = type(data.claimed) == "table" and data.claimed or {}
    data.rewards = type(data.rewards) == "table" and data.rewards or {}
    local startDay = math.floor(tonumber(data.startDay) or today)
    if today >= startDay + 7 then
        startDay = startDay + math.floor((today - startDay) / 7) * 7
        data = {startDay=startDay, lastSeen=today, claimed={}, rewards=generate_rewards(startDay, level), source=source, rewardVersion=REWARD_VERSION, memberLevel=level}
        XaouShop_State.login = data
    elseif tonumber(data.rewardVersion) ~= REWARD_VERSION or #data.rewards < 7 then
        data.rewards = generate_rewards(startDay, level)
        data.rewardVersion, data.memberLevel = REWARD_VERSION, level
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

local function set_status(text, kind)
    XLOGIN_Status, XLOGIN_StatusKind = tostring(text or ""), kind
end

local function requirement_text(level, includeOwned)
    local member = MEMBERSHIP[level]
    if member == nil or type(member.requirements) ~= "table" then return "ระดับสมาชิกสูงสุดแล้ว" end
    local membership = membership_state()
    local parts = {"เช็กอิน " .. tostring(membership.totalClaims or 0) .. "/" .. tostring(member.checkins or 0) .. " วัน"}
    for _, row in ipairs(member.requirements) do
        local text = (ITEM_LABELS[row.id] or row.id) .. " " .. tostring(row.amount)
        if includeOwned and XaouShop_CountItem then text = text .. " (มี " .. tostring(XaouShop_CountItem(row.id)) .. ")" end
        parts[#parts + 1] = text
    end
    return table.concat(parts, "  •  ")
end

local function refresh()
    local view = XLOGIN_View
    if view == nil then return end
    local data = state()
    local _, level, member = membership_state()
    set_text(child(view, "title"), "Xaou 009 เช็กอินรายวัน")
    set_text(child(view, "subtitle"), "รางวัล 7 วันตามระดับสมาชิก ของหายากมีจำนวนลดลงและออกในวันท้าย ๆ")
    set_text(child(view, "btnClose"), "×")
    set_text(child(view, "cycleText"), "วันที่ " .. tostring(math.max(1, math.min(7, data.index))) .. "/7 • " .. tostring(data.todayLabel))
    set_text(child(view, "btnClaim"), claimed(data, data.index) and "รับแล้ว" or "รับรางวัลวันนี้")
    set_text(child(view, "hint"), "พลาดวันใดจะรับย้อนหลังไม่ได้ • ระดับสมาชิกและวัตถุดิบผูกกับเซฟนี้")
    local brand = child(view, "brand")
    set_text(brand, "Xaou 009 • Seven-Day Membership")
    if brand ~= nil then pcall(function() brand.width = 365 end) end
    local membership = membership_state()
    set_text(child(view, "memberText"), "สมาชิก: " .. member.name .. "  •  เช็กอิน " .. tostring(membership.totalClaims or 0) .. " วัน")
    set_text(child(view, "btnUpgrade"), level >= 4 and "ระดับสูงสุด" or (XLOGIN_ConfirmUpgrade and "ยืนยันอัปเกรด" or "อัปเกรดสมาชิก"))
    set_enabled(child(view, "btnUpgrade"), level < 4)

    for i = 1, 7 do
        local card = child(view, "day" .. tostring(i))
        local reward = data.rewards[i]
        if card ~= nil and reward ~= nil then
            local info = def_info(reward.id)
            set_visible(card, true)
            set_text(child(card, "dayText"), "วันที่ " .. tostring(i))
            set_text(child(card, "itemName"), info.name)
            set_text(child(card, "amountText"), "จำนวน " .. tostring(reward.amount or 1))
            local status = "รอรับ"
            if claimed(data, i) then status = "รับแล้ว"
            elseif i < data.index then status = "พลาด"
            elseif i == data.index then status = data.rollback and "วันที่ไม่ถูกต้อง" or "รับได้วันนี้" end
            set_text(child(card, "statusText"), status)
            local icon = child(card, "icon")
            pcall(function() icon.url = info.icon end)
            set_visible(icon, info.icon ~= "")
            pcall(function() card.selected = i == data.index end)
        elseif card ~= nil then set_visible(card, false) end
    end

    local canClaim = not data.rollback and data.index >= 1 and data.index <= 7 and not claimed(data, data.index) and data.rewards[data.index] ~= nil
    set_enabled(child(view, "btnClaim"), canClaim)
    local status = XLOGIN_Status
    if status == nil or status == "" then
        if data.rollback then status = "วันที่เครื่องย้อนกลับ ระบบระงับการรับรางวัลชั่วคราว"
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

local function upgrade_membership()
    local membership, level = membership_state()
    if level >= 4 then set_status("ระดับสมาชิกสูงสุดแล้ว", "success"); refresh(); return end
    local nextLevel = level + 1
    if not XLOGIN_ConfirmUpgrade then
        XLOGIN_ConfirmUpgrade = true
        set_status("ใช้วัตถุดิบเพื่อขึ้นเป็น " .. MEMBERSHIP[nextLevel].name .. ": " .. requirement_text(nextLevel, true), nil)
        refresh()
        return
    end

    XLOGIN_ConfirmUpgrade = false
    local totalClaims = math.max(0, math.floor(tonumber(membership.totalClaims) or 0))
    local neededClaims = math.max(0, math.floor(tonumber(MEMBERSHIP[nextLevel].checkins) or 0))
    if totalClaims < neededClaims then
        set_status("อัปเกรดไม่สำเร็จ: เช็กอินสะสม " .. tostring(totalClaims) .. "/" .. tostring(neededClaims) .. " วัน", "error")
        refresh()
        return
    end
    local ok, result, detail = pcall(function()
        return XaouShop_ConsumeItems(MEMBERSHIP[nextLevel].requirements, XLOGIN_Target)
    end)
    if not ok or result ~= true then
        local missing = type(detail) == "table" and detail.id or nil
        local reason = missing and ((ITEM_LABELS[missing] or missing) .. " ไม่เพียงพอ") or tostring(detail or result)
        set_status("อัปเกรดไม่สำเร็จ: " .. reason, "error")
        refresh()
        return
    end

    membership.level = nextLevel
    local data = state()
    local upgraded = generate_rewards(data.startDay, nextLevel)
    for i = 1, 7 do if not claimed(data, i) and upgraded[i] ~= nil then data.rewards[i] = upgraded[i] end end
    data.memberLevel, data.rewardVersion = nextLevel, REWARD_VERSION
    set_status("อัปเกรดสมาชิกเป็น " .. MEMBERSHIP[nextLevel].name .. " สำเร็จ", "success")
    refresh()
end

local function claim_today()
    local data = state()
    if data.rollback then set_status("รับไม่ได้: วันที่เครื่องถูกปรับย้อนหลัง", "error"); refresh(); return end
    local index = data.index
    if index < 1 or index > 7 then set_status("วันนี้ไม่อยู่ในรอบเช็กอิน", "error"); refresh(); return end
    if claimed(data, index) then set_status("วันนี้รับรางวัลแล้ว", "error"); refresh(); return end
    local reward = data.rewards[index]
    if reward == nil then set_status("ไม่พบข้อมูลรางวัล", "error"); refresh(); return end
    local ok, result, detail = pcall(function() return XaouShop_GrantItem(reward.id, reward.amount or 1, XLOGIN_Target) end)
    if ok and result == true then
        data.claimed[index] = true
        local membership = membership_state()
        membership.totalClaims = math.max(0, math.floor(tonumber(membership.totalClaims) or 0)) + 1
        local info = def_info(reward.id)
        set_status("รับ " .. info.name .. " จำนวน " .. tostring(reward.amount or 1) .. " สำเร็จ", "success")
    else set_status("รับรางวัลไม่สำเร็จ: " .. tostring(detail or result), "error") end
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
    XLOGIN_ConfirmUpgrade = false
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
    local upgradeButton = child(view, "btnUpgrade")
    if upgradeButton ~= nil then upgradeButton.onClick:Add(upgrade_membership) end
    refresh()
    pcall(function() view:BringToFront() end)
    return true
end
