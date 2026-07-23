-- Read-only adapter for ACS native quests. It never accepts, completes or removes quests.

local function cs_count(list)
    if list == nil then return 0 end
    local value = 0
    pcall(function() value = tonumber(list.Count) or 0 end)
    return value
end

local function cs_get(list, index)
    if list == nil then return nil end
    local value = nil
    pcall(function() value = list:get_Item(index) end)
    if value == nil then pcall(function() value = list[index] end) end
    return value
end

local function safe_int(value)
    if value == nil then return nil end
    if type(value) == "number" then return math.floor(value) end
    local number = nil
    pcall(function() number = tonumber(value) end)
    if number ~= nil then return math.floor(number) end
    local raw = nil
    pcall(function() raw = tostring(value) end)
    if raw ~= nil then
        number = tonumber(raw)
        if number == nil then number = tonumber(string.match(raw, "-?%d+")) end
    end
    return number and math.floor(number) or nil
end

local function each_dictionary(dict, callback)
    if dict == nil or callback == nil then return end
    local enumerator = nil
    local ok = pcall(function() enumerator = dict:GetEnumerator() end)
    if not ok or enumerator == nil then return end
    while true do
        local moved = false
        if not pcall(function() moved = enumerator:MoveNext() end) or not moved then break end
        local current = nil
        pcall(function() current = enumerator.Current end)
        if current ~= nil then
            local key, value = nil, nil
            pcall(function() key = current.Key end)
            pcall(function() value = current.Value end)
            pcall(callback, key, value)
        end
    end
end

local function string_value(value, fallback)
    local result = nil
    if value ~= nil then pcall(function() result = tostring(value) end) end
    if result == nil or result == "" then return fallback or "" end
    return result
end

local function item_name(item_id)
    local name = string_value(item_id, "?")
    pcall(function()
        local def = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item, item_id)
        if def ~= nil and def.ThingName ~= nil then name = tostring(def.ThingName) end
    end)
    return name
end

local function item_requirements(dict)
    local parts = {}
    each_dictionary(dict, function(key, value)
        parts[#parts + 1] = item_name(key) .. " x" .. tostring(tonumber(value) or value or 0)
    end)
    table.sort(parts)
    return table.concat(parts, ", ")
end

local function school_name(id)
    local name = "School " .. tostring(id or "?")
    pcall(function()
        local data = CS.XiaWorld.SchoolGlobleMgr.Instance:GetSchoolData(tonumber(id))
        if data ~= nil and data.Name ~= nil then name = tostring(data.Name) end
    end)
    return name
end

local function remaining_time(expire_day, day_sec)
    local now_day, now_sec = 0, 0
    pcall(function()
        now_day = tonumber(CS.XiaWorld.World.Instance.DayCount) or 0
        now_sec = tonumber(CS.XiaWorld.World.Instance.DaySecond) or 0
    end)
    local seconds = math.max(0, ((tonumber(expire_day) or now_day) - now_day) * 600
        + (tonumber(day_sec) or 0) - now_sec)
    local days = math.floor(seconds / 600)
    local hours = math.floor((seconds % 600) / 25)
    return tostring(days) .. " วัน " .. tostring(hours) .. " ชม."
end

local function reward_text(def)
    if def == nil then return "-" end
    local result = nil
    pcall(function() result = def.Success end)
    if result == nil then return "-" end
    local parts = {}
    local friend, relation = 0, 0
    pcall(function() friend = tonumber(result.FriendPoint) or 0 end)
    pcall(function() relation = tonumber(result.Relation) or 0 end)
    if friend ~= 0 then parts[#parts + 1] = "คะแนนมิตรภาพ +" .. tostring(friend) end
    if relation ~= 0 then parts[#parts + 1] = "ความสัมพันธ์ +" .. tostring(math.floor(relation)) end
    return #parts > 0 and table.concat(parts, ", ") or "-"
end

local function add_story_rows(rows, errors)
    local mgr = nil
    pcall(function() mgr = CS.XiaWorld.MapStoryMgr.Instance end)
    if mgr == nil then
        errors[#errors + 1] = "MapStoryMgr unavailable"
        return
    end
    local list = nil
    pcall(function() list = mgr.lisSecrets end)
    for index = 0, cs_count(list) - 1 do
        local data = cs_get(list, index)
        if data ~= nil then
            local id, def = nil, nil
            pcall(function() id = safe_int(data.ID) end)
            if id ~= nil then pcall(function() def = mgr:GetSecretDef(id) end) end
            local title = nil
            local desc = nil
            local place = nil
            pcall(function() title = def and def.Name end)
            pcall(function() desc = data.Desc end)
            if desc == nil or tostring(desc) == "" then pcall(function() desc = def and def.Desc end) end
            pcall(function() place = data.Place end)
            rows[#rows + 1] = {
                id="native_story_" .. tostring(id or 0) .. "_" .. tostring(index), category="story", status="active",
                title=string_value(title, "เหตุการณ์ #" .. tostring(id or index)),
                desc=string_value(desc, "เหตุการณ์หรือเนื้อเรื่องที่ค้นพบในแผนที่โลก"),
                objective=(place ~= nil and tostring(place) ~= "") and ("สถานที่: " .. tostring(place)) or "ติดตามเหตุการณ์ในแผนที่โลก",
                reward="-", native=true, source="MapStoryMgr.lisSecrets",
            }
        end
    end
end

local function add_tutorial_rows(rows, errors)
    local mgr = nil
    pcall(function() mgr = CS.XiaWorld.TeachMgr.Instance end)
    if mgr == nil then
        errors[#errors + 1] = "TeachMgr unavailable"
        return
    end
    local tasks = nil
    pcall(function() tasks = mgr.Tasks end)
    if tasks == nil then
        errors[#errors + 1] = "TeachMgr.Tasks unavailable"
        return
    end
    each_dictionary(tasks, function(key, value)
        local id = safe_int(key)
        local title = cs_get(value, 0)
        local desc = cs_get(value, 1)
        local finished = false
        if id ~= nil then pcall(function() finished = mgr:CheckTask(id) == true end) end
        local tutorial_enabled = false
        local tutorial_level = 0
        pcall(function() tutorial_enabled = CS.XiaWorld.World.Instance.NewBee == true end)
        pcall(function() tutorial_level = safe_int(mgr:GetLevel()) or 0 end)
        local task_level = id and math.floor(id / 10) or 0
        local status = "inactive"
        local objective = "ระบบบทสอนไม่ได้เปิดในเซฟนี้"
        if finished then
            status = "completed"
            objective = "ทำสำเร็จแล้ว"
        elseif tutorial_enabled and task_level <= tutorial_level then
            status = "active"
            objective = "ทำตามคำแนะนำของเกม"
        elseif tutorial_enabled then
            status = "locked"
            objective = "ทำบทสอนช่วงก่อนหน้าให้สำเร็จก่อน"
        end
        rows[#rows + 1] = {
            id="native_tutorial_" .. tostring(id or key), category="tutorial",
            status=status,
            title=string_value(title, "บทสอน #" .. tostring(id or key)),
            desc=string_value(desc, "ภารกิจแนะนำระบบของเกม"),
            objective=objective,
            reward="-", native=true, source="TeachMgr.Tasks",
        }
    end)
end

local function add_available_school_tasks(rows, task_mgr, trade_mgr)
    local list = nil
    pcall(function() list = task_mgr.SchoolWaitAccept end)
    for index = 0, cs_count(list) - 1 do
        local data = cs_get(list, index)
        if data ~= nil then
            local task_name, from_school, def = nil, nil, nil
            pcall(function() task_name = data.TaskName end)
            pcall(function() from_school = safe_int(data.FromSchool) end)
            if task_name ~= nil then pcall(function() def = trade_mgr:GetTaskDef(task_name) end) end
            local title, desc = nil, nil
            pcall(function() title = def and def.DisplayName end)
            pcall(function() desc = def and def.Desc end)
            local requirements = nil
            pcall(function() requirements = item_requirements(data.ItemNeed) end)
            if requirements == nil or requirements == "" then requirements = "ตรวจเงื่อนไขคำขอในหน้าสำนัก" end
            rows[#rows + 1] = {
                id="native_school_available_" .. tostring(from_school or 0) .. "_" .. tostring(index),
                category="school", status="available",
                title=string_value(title, "คำขอจาก " .. school_name(from_school)),
                desc=string_value(desc, "คำขอที่สามารถรับได้จาก " .. school_name(from_school)),
                objective=requirements .. " | เหลือ " .. remaining_time(data.ExpireDay, data.DaySec),
                reward=reward_text(def), native=true, source="SchoolTask.SchoolWaitAccept",
            }
        end
    end
end

local function add_active_school_tasks(rows, task_mgr, trade_mgr)
    local school_ids = nil
    pcall(function() school_ids = CS.XiaWorld.SchoolGlobleMgr.PureSchoolIds end)
    for school_index = 0, cs_count(school_ids) - 1 do
        local school_id = cs_get(school_ids, school_index)
        local school_data = nil
        pcall(function() school_data = task_mgr:GetSchoolData(safe_int(school_id)) end)
        if school_data == nil then
            pcall(function() school_data = task_mgr:GetSchoolData(safe_int(school_id), false) end)
        end
        local tasks = nil
        pcall(function() tasks = school_data and school_data.taskDatas end)
        for task_index = 0, cs_count(tasks) - 1 do
            local data = cs_get(tasks, task_index)
            if data ~= nil then
                local task_name, def = nil, nil
                pcall(function() task_name = data.TaskName end)
                if task_name ~= nil then pcall(function() def = trade_mgr:GetTaskDef(task_name) end) end
                local title, desc = nil, nil
                pcall(function() title = def and def.DisplayName end)
                pcall(function() desc = def and def.Desc end)
                local requirements = nil
                pcall(function() requirements = item_requirements(data.ItemNeed) end)
                if requirements == nil or requirements == "" then requirements = "ทำเป้าหมายคำขอของสำนัก" end
                rows[#rows + 1] = {
                    id="native_school_active_" .. tostring(school_id) .. "_" .. tostring(task_index),
                    category="school", status="active",
                    title=string_value(title, "คำขอจาก " .. school_name(school_id)),
                    desc=string_value(desc, "คำขอที่รับแล้วจาก " .. school_name(school_id)),
                    objective=requirements .. " | เหลือ " .. remaining_time(data.ExpireDay, data.DaySec),
                    reward=reward_text(def), native=true, source="SchoolTask.GetSchoolData",
                }
            end
        end
    end
end

local function add_school_rows(rows, errors)
    local trade_mgr = nil
    pcall(function() trade_mgr = CS.XiaWorld.TradeMgr.Instance end)
    if trade_mgr == nil then
        errors[#errors + 1] = "TradeMgr unavailable"
        return
    end
    local task_mgr = nil
    pcall(function() task_mgr = trade_mgr.SchoolTask end)
    if task_mgr == nil then
        errors[#errors + 1] = "TradeMgr.SchoolTask unavailable"
        return
    end
    pcall(add_available_school_tasks, rows, task_mgr, trade_mgr)
    pcall(add_active_school_tasks, rows, task_mgr, trade_mgr)
end

function XaouNativeQuest_GetRows()
    local rows, errors = {}, {}
    local ok_story, err_story = pcall(add_story_rows, rows, errors)
    if not ok_story then errors[#errors + 1] = "Story: " .. tostring(err_story) end
    local ok_school, err_school = pcall(add_school_rows, rows, errors)
    if not ok_school then errors[#errors + 1] = "School: " .. tostring(err_school) end
    local ok_tutorial, err_tutorial = pcall(add_tutorial_rows, rows, errors)
    if not ok_tutorial then errors[#errors + 1] = "Tutorial: " .. tostring(err_tutorial) end
    table.sort(rows, function(a, b)
        if a.category ~= b.category then return tostring(a.category) < tostring(b.category) end
        return tostring(a.title) < tostring(b.title)
    end)
    return rows, errors
end
