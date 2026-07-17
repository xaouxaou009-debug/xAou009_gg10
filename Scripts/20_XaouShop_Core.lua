-- Xaou 009 Daily Shop core. No dependency on another mod.

XaouShop_State = XaouShop_State or {day=-1, items={}, backpack={}}
local SHOP_POOL_VERSION = 2

local PRICE_BY_RATE = {
    [1]=1, [2]=2, [3]=3, [4]=4, [5]=5, [6]=10,
    [7]=50, [8]=100, [9]=500, [10]=1000, [11]=2000, [12]=5000,
}

local function count(list)
    if list == nil then return 0 end
    if type(list) == "table" then return #list end
    local value = 0
    pcall(function() value = tonumber(list.Count) or 0 end)
    return value
end

local function item_at(list, index)
    if list == nil then return nil end
    if type(list) == "table" then return list[index + 1] end
    local value = nil
    pcall(function() value = list:get_Item(index) end)
    if value == nil then pcall(function() value = list[index] end) end
    return value
end

local function thing_mgr()
    local mgr = nil
    pcall(function() mgr = CS.XiaWorld.ThingMgr.Instance end)
    if mgr == nil then pcall(function() mgr = ThingMgr end) end
    return mgr
end

local function item_kind()
    local kind = nil
    pcall(function() kind = CS.XiaWorld.g_emThingType.Item end)
    if kind == nil then pcall(function() kind = g_emThingType.Item end) end
    return kind or 2
end

function XaouShop_GetDef(id)
    local value = nil
    local mgr = thing_mgr()
    if mgr == nil then return nil end
    pcall(function() value = mgr:GetDef(item_kind(), tostring(id)) end)
    return value
end

function XaouShop_GetDay()
    local day = nil
    pcall(function() day = tonumber(World.DayCount) end)
    if day == nil then pcall(function() day = tonumber(world.DayCount) end) end
    if day == nil then pcall(function() day = tonumber(CS.XiaWorld.World.Instance.DayCount) end) end
    return math.floor(day or 0)
end

local function item_def_name(item)
    local value = nil
    pcall(function() value = item.def.Name end)
    if value == nil then pcall(function() value = item.Def.Name end) end
    if value == nil then pcall(function() value = item:GetDefName() end) end
    return value and tostring(value) or nil
end

local function stack_count(item)
    local value = nil
    pcall(function() value = tonumber(item.Count) end)
    if value == nil then pcall(function() value = tonumber(item.FreeCount) end) end
    return math.max(0, math.floor(value or 0))
end

local function is_real_map_item(item)
    if item == nil then return false end
    local key = nil
    pcall(function() key = tonumber(item.Key) end)
    if key == nil or key <= 0 then return false end

    local disabled = false
    pcall(function() disabled = item.ActDisable == true end)
    if disabled then return false end

    local id = item_def_name(item)
    if id == nil or id == "" then return false end
    if string.find(id, "_NormalAttack", 1, true) ~= nil then return false end
    return true
end

local function is_backpack_safe_item(item)
    if not is_real_map_item(item) then return false end
    local def = XaouShop_GetDef(item_def_name(item))
    local maxStack = nil
    if def ~= nil then pcall(function() maxStack = tonumber(def.MaxStack) end) end
    return maxStack ~= nil and maxStack > 1
end

local function item_list()
    local mgr = thing_mgr()
    if mgr == nil then return nil end
    local list = nil
    pcall(function() list = mgr:GetThingList(item_kind()) end)
    return list
end

function XaouShop_CountCurrency()
    local total = 0
    local list = item_list()
    for i = 0, count(list) - 1 do
        local item = item_at(list, i)
        if is_real_map_item(item) and item_def_name(item) == "Item_LingStone" then
            total = total + stack_count(item)
        end
    end
    return total
end

local function drop_item(id, amount, target)
    local def = XaouShop_GetDef(id)
    if def == nil then return false, "ThingDef not found: " .. tostring(id) end
    local map = nil
    pcall(function() map = Map end)
    if map == nil then pcall(function() map = CS.XiaWorld.World.Instance.map end) end
    if map == nil then return false, "Map not found" end

    local key = nil
    if target ~= nil then pcall(function() key = target.Key end) end
    if key == nil then pcall(function() key = map:GetRandomInLifeArea(4) end) end
    if key == nil then return false, "Drop position not found" end

    local remain = math.max(1, math.floor(tonumber(amount) or 1))
    local maxStack = remain
    pcall(function() maxStack = math.max(1, tonumber(def.MaxStack) or remain) end)
    while remain > 0 do
        local n = math.min(remain, maxStack)
        local created = nil
        local okCreate, createError = pcall(function()
            created = ItemRandomMachine.RandomItem(tostring(id), nil, 1, 12, 1, n)
        end)
        if not okCreate or created == nil then return false, createError or "RandomItem returned nil" end
        local okDrop, dropError = pcall(function()
            map:DropItem(created, key, true, true, false, true, 0, false)
        end)
        if not okDrop then return false, dropError end
        remain = remain - n
    end
    return true
end

function XaouShop_GrantItem(id, amount, target)
    return drop_item(id, amount, target)
end

local function remove_stack(item, amount)
    local before = stack_count(item)
    amount = math.min(before, math.max(0, math.floor(amount or 0)))
    if amount <= 0 then return true, 0 end
    if before > amount then
        local ok = pcall(function() item:SubCount(amount) end)
        if not ok then ok = pcall(function() item:ChangeCount(before - amount, false) end) end
        if not ok then ok = pcall(function() item:ChangeCount(before - amount) end) end
        return ok, ok and amount or 0
    end
    local mgr = thing_mgr()
    if mgr == nil then return false, 0 end
    local ok, value = pcall(function() return mgr:RemoveThing(item, false, false) end)
    if not ok then ok, value = pcall(function() return mgr:RemoveThing(item) end) end
    return ok and value ~= false, (ok and value ~= false) and amount or 0
end

local function deduct_currency(amount, target)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if XaouShop_CountCurrency() < amount then return false, "NOT_ENOUGH", 0 end
    local remain, removed = amount, 0
    local list = item_list()
    for i = count(list) - 1, 0, -1 do
        if remain <= 0 then break end
        local item = item_at(list, i)
        if is_real_map_item(item) and item_def_name(item) == "Item_LingStone" then
            local take = math.min(remain, stack_count(item))
            local ok, n = remove_stack(item, take)
            if not ok then
                if removed > 0 then drop_item("Item_LingStone", removed, target) end
                return false, "REMOVE_FAILED", removed
            end
            removed = removed + n
            remain = remain - n
        end
    end
    if remain > 0 then
        if removed > 0 then drop_item("Item_LingStone", removed, target) end
        return false, "REMOVE_INCOMPLETE", removed
    end
    return true, nil, removed
end

local function rate_price(def)
    local rate = nil
    pcall(function() rate = tonumber(def.Rate) end)
    if rate == nil then pcall(function() rate = tonumber(def.Rarity) end) end
    local base = PRICE_BY_RATE[math.floor(rate or 5)] or 10
    return math.max(1, math.floor(base * 0.5))
end

function XaouShop_GetSellItems()
    local grouped = {}
    local list = item_list()
    for i = 0, count(list) - 1 do
        local item = item_at(list, i)
        local id = item ~= nil and item_def_name(item) or nil
        local amount = item ~= nil and stack_count(item) or 0
        if is_real_map_item(item) and id ~= nil and id ~= "" and id ~= "Item_LingStone" and amount > 0 then
            local row = grouped[id]
            if row == nil then
                local def = XaouShop_GetDef(id)
                if def ~= nil then
                    row = {id=id, count=0, price=math.max(1, math.floor(rate_price(def) * 0.5))}
                    grouped[id] = row
                end
            end
            if row ~= nil then row.count = row.count + amount end
        end
    end
    local result = {}
    for _, row in pairs(grouped) do result[#result + 1] = row end
    table.sort(result, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return result
end

function XaouShop_GetMapItems()
    local grouped = {}
    local list = item_list()
    for i = 0, count(list) - 1 do
        local item = item_at(list, i)
        local id = item ~= nil and item_def_name(item) or nil
        local amount = item ~= nil and stack_count(item) or 0
        if is_backpack_safe_item(item) and id ~= nil and id ~= "" and amount > 0 and XaouShop_GetDef(id) ~= nil then
            grouped[id] = (grouped[id] or 0) + amount
        end
    end
    local result = {}
    for id, amount in pairs(grouped) do result[#result + 1] = {id=id, count=amount} end
    table.sort(result, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return result
end

local function ensure_backpack()
    XaouShop_State = XaouShop_State or {day=-1, items={}, backpack={}}
    XaouShop_State.backpack = XaouShop_State.backpack or {}
    return XaouShop_State.backpack
end

function XaouShop_GetBackpackItems()
    local result = {}
    for id, amount in pairs(ensure_backpack()) do
        amount = math.max(0, math.floor(tonumber(amount) or 0))
        if amount > 0 and XaouShop_GetDef(id) ~= nil then result[#result + 1] = {id=tostring(id), count=amount} end
    end
    table.sort(result, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return result
end

local function remove_items_by_id(id, amount, target)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local remain, removed = amount, 0
    local list = item_list()
    for i = count(list) - 1, 0, -1 do
        if remain <= 0 then break end
        local item = item_at(list, i)
        if is_real_map_item(item) and item_def_name(item) == id then
            local take = math.min(remain, stack_count(item))
            local ok, n = remove_stack(item, take)
            if not ok then
                if removed > 0 then drop_item(id, removed, target) end
                return false, "REMOVE_FAILED", removed
            end
            removed = removed + n
            remain = remain - n
        end
    end
    if remain > 0 then
        if removed > 0 then drop_item(id, removed, target) end
        return false, "REMOVE_INCOMPLETE", removed
    end
    return true, nil, removed
end

local function next_random(seed)
    seed = (seed * 48271) % 2147483647
    if seed <= 0 then seed = seed + 2147483646 end
    return seed
end

function XaouShop_Generate(day)
    day = math.floor(tonumber(day) or XaouShop_GetDay())
    local seed = math.max(1, (day + 1) * 9009 + 200009)
    local groups, categories, seen = {}, {}, {}

    local function add_available(entry)
        if type(entry) ~= "table" then return end
        local id = entry.id or entry.ID or entry.Name or entry.name
        if id == nil then return end
        id = tostring(id)
        if id == "" or id == "Item_LingStone" or seen[id] then return end
        local def = XaouShop_GetDef(id)
        if def == nil then return end
        local category = tostring(entry.cat or entry.category or "อื่น")
        if category == "vkski" then category = "อาหาร" end
        if groups[category] == nil then
            groups[category] = {}
            categories[#categories + 1] = category
        end
        groups[category][#groups[category] + 1] = {
            id=id, def=def, price=entry.price, category=category,
        }
        seen[id] = true
    end

    for _, pack in ipairs(Xaou_ItemPacks or {}) do
        local entries = type(pack) == "table" and (pack.items or pack) or nil
        if type(entries) == "table" then
            for _, entry in ipairs(entries) do add_available(entry) end
        end
    end
    for _, entry in ipairs(XaouShop_ItemPool or {}) do add_available(entry) end

    local generated = {}
    local function add_generated(selected)
        generated[#generated + 1] = {
            id=selected.id,
            stock=10,
            price=math.max(1, math.floor(tonumber(selected.price) or rate_price(selected.def))),
            category=selected.category,
        }
    end

    -- Give every available category one daily slot before filling the rest.
    local category_order = {}
    for _, category in ipairs(categories) do category_order[#category_order + 1] = category end
    while #generated < 10 and #category_order > 0 do
        seed = next_random(seed)
        local category = table.remove(category_order, (seed % #category_order) + 1)
        local list = groups[category]
        if list ~= nil and #list > 0 then
            seed = next_random(seed)
            add_generated(table.remove(list, (seed % #list) + 1))
        end
    end

    local available = {}
    for _, list in pairs(groups) do
        for _, entry in ipairs(list) do available[#available + 1] = entry end
    end
    while #generated < 10 and #available > 0 do
        seed = next_random(seed)
        add_generated(table.remove(available, (seed % #available) + 1))
    end
    local backpack = XaouShop_State and XaouShop_State.backpack or {}
    local login = XaouShop_State and XaouShop_State.login or nil
    XaouShop_State = {day=day, items=generated, backpack=backpack, login=login, poolVersion=SHOP_POOL_VERSION}
    if XaouShop_RefreshWindow then pcall(XaouShop_RefreshWindow) end
    return #generated
end

function XaouShop_EnsureDaily()
    local day = XaouShop_GetDay()
    if XaouShop_State == nil or tonumber(XaouShop_State.day) ~= day or tonumber(XaouShop_State.poolVersion) ~= SHOP_POOL_VERSION or type(XaouShop_State.items) ~= "table" or #XaouShop_State.items == 0 then
        XaouShop_Generate(day)
        return true
    end
    return false
end

function XaouShop_Buy(index, quantity, target)
    XaouShop_EnsureDaily()
    index = math.floor(tonumber(index) or 0)
    quantity = math.floor(tonumber(quantity) or 1)
    local row = XaouShop_State.items[index]
    if row == nil then return false, "ITEM_NOT_FOUND" end
    if quantity < 1 then quantity = 1 end
    if quantity > 10 then quantity = 10 end
    if quantity > (tonumber(row.stock) or 0) then return false, "OUT_OF_STOCK" end
    local total = quantity * math.max(1, tonumber(row.price) or 1)
    local paid, payError = deduct_currency(total, target)
    if not paid then return false, payError end
    local spawned, spawnError = drop_item(row.id, quantity, target)
    if not spawned then
        drop_item("Item_LingStone", total, target)
        return false, "SPAWN_FAILED: " .. tostring(spawnError)
    end
    row.stock = math.max(0, (tonumber(row.stock) or 0) - quantity)
    return true, {id=row.id, quantity=quantity, total=total, stock=row.stock}
end

function XaouShop_Sell(id, quantity, target)
    id = id and tostring(id) or ""
    quantity = math.max(1, math.min(10, math.floor(tonumber(quantity) or 1)))
    if id == "" or id == "Item_LingStone" then return false, "ITEM_NOT_SELLABLE" end

    local available, unitPrice = 0, nil
    for _, row in ipairs(XaouShop_GetSellItems()) do
        if row.id == id then available, unitPrice = row.count, row.price; break end
    end
    if available < quantity then return false, "NOT_ENOUGH_ITEMS" end
    if unitPrice == nil then return false, "ITEM_NOT_SELLABLE" end

    local removed, removeError = remove_items_by_id(id, quantity, target)
    if not removed then return false, removeError end
    local total = quantity * math.max(1, tonumber(unitPrice) or 1)
    local paid, payError = drop_item("Item_LingStone", total, target)
    if not paid then
        drop_item(id, quantity, target)
        return false, "PAYMENT_FAILED: " .. tostring(payError)
    end
    return true, {id=id, quantity=quantity, total=total, remaining=available - quantity}
end

function XaouShop_BackpackDeposit(id, quantity, target)
    id = id and tostring(id) or ""
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if id == "" or XaouShop_GetDef(id) == nil then return false, "ITEM_NOT_FOUND" end

    local available = 0
    for _, row in ipairs(XaouShop_GetMapItems()) do
        if row.id == id then available = row.count; break end
    end
    if available < quantity then return false, "NOT_ENOUGH_ITEMS" end
    local removed, removeError = remove_items_by_id(id, quantity, target)
    if not removed then return false, removeError end
    local bag = ensure_backpack()
    bag[id] = math.max(0, math.floor(tonumber(bag[id]) or 0)) + quantity
    return true, {id=id, quantity=quantity, count=bag[id]}
end

function XaouShop_BackpackWithdraw(id, quantity, target)
    id = id and tostring(id) or ""
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local bag = ensure_backpack()
    local available = math.max(0, math.floor(tonumber(bag[id]) or 0))
    if id == "" or available < quantity then return false, "NOT_ENOUGH_ITEMS" end
    local spawned, spawnError = drop_item(id, quantity, target)
    if not spawned then return false, "SPAWN_FAILED: " .. tostring(spawnError) end
    bag[id] = available - quantity
    if bag[id] <= 0 then bag[id] = nil end
    return true, {id=id, quantity=quantity, count=math.max(0, bag[id] or 0)}
end

function XaouShop_ExportState()
    local result = {day=tonumber(XaouShop_State.day) or -1, items={}, backpack={}, login=XaouShop_State.login, poolVersion=SHOP_POOL_VERSION}
    for _, row in ipairs(XaouShop_State.items or {}) do
        result.items[#result.items + 1] = {id=tostring(row.id), stock=tonumber(row.stock) or 0, price=tonumber(row.price) or 1}
    end
    for id, amount in pairs(ensure_backpack()) do
        if tonumber(amount) and tonumber(amount) > 0 then result.backpack[tostring(id)] = math.floor(tonumber(amount)) end
    end
    return result
end

function XaouShop_ImportState(data)
    if type(data) ~= "table" or type(data.items) ~= "table" then
        XaouShop_State = {day=-1, items={}, backpack={}}
        return false
    end
    XaouShop_State = {day=tonumber(data.day) or -1, items={}, backpack={}, login=type(data.login) == "table" and data.login or nil, poolVersion=tonumber(data.poolVersion)}
    for _, row in ipairs(data.items) do
        if row.id ~= nil and XaouShop_GetDef(row.id) ~= nil then
            XaouShop_State.items[#XaouShop_State.items + 1] = {
                id=tostring(row.id), stock=math.max(0, tonumber(row.stock) or 0), price=math.max(1, tonumber(row.price) or 1),
            }
        end
    end
    if type(data.backpack) == "table" then
        for id, amount in pairs(data.backpack) do
            if XaouShop_GetDef(id) ~= nil and tonumber(amount) and tonumber(amount) > 0 then
                XaouShop_State.backpack[tostring(id)] = math.floor(tonumber(amount))
            end
        end
    end
    return true
end
