-- Xaou 009 update notification. This checker never downloads or replaces mod files.

local LOCAL_VERSION = "0.5"
local MANIFEST_URLS = {
    "https://raw.githubusercontent.com/xaouxaou009-debug/Mod/main/Xaou_UpdateManifest.txt",
    "https://raw.githubusercontent.com/xaouxaou009-debug/Mod/master/Xaou_UpdateManifest.txt"
}

local checker = {
    started = false,
    finished = false,
    notified = false,
    urlIndex = 0,
    request = nil,
    operation = nil,
    startedAt = 0
}

local function now()
    local ok, value = pcall(function()
        return tonumber(CS.UnityEngine.Time.realtimeSinceStartup) or 0
    end)
    return ok and value or 0
end

local function version_parts(value)
    local result = {}
    for part in string.gmatch(tostring(value or ""), "%d+") do
        result[#result + 1] = tonumber(part) or 0
    end
    return result
end

local function is_newer(remote, current)
    local a = version_parts(remote)
    local b = version_parts(current)
    local count = math.max(#a, #b)
    for i = 1, count do
        local av = a[i] or 0
        local bv = b[i] or 0
        if av ~= bv then return av > bv end
    end
    return false
end

local function dispose_request()
    if checker.request ~= nil then
        pcall(function() checker.request:Dispose() end)
    end
    checker.request = nil
    checker.operation = nil
end

local function begin_next_request()
    dispose_request()
    checker.urlIndex = checker.urlIndex + 1
    local url = MANIFEST_URLS[checker.urlIndex]
    if url == nil then
        checker.finished = true
        return false
    end

    local ok, request, operation = pcall(function()
        local req = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
        return req, req:SendWebRequest()
    end)
    if not ok or request == nil or operation == nil then
        return begin_next_request()
    end

    checker.request = request
    checker.operation = operation
    checker.startedAt = now()
    return true
end

local function request_failed(request)
    local failed = false
    pcall(function()
        if request.isNetworkError == true or request.isHttpError == true then failed = true end
    end)
    pcall(function()
        local code = tonumber(request.responseCode) or 0
        if code >= 400 then failed = true end
    end)
    return failed
end

local function parse_manifest(text)
    local id, version, message = string.match(tostring(text or ""),
        "^%s*([^|\r\n]+)|([^|\r\n]+)|([^\r\n]*)")
    if id ~= "Xaou009_DailyShop" then return nil end
    return version, message
end

function XaouUpdateChecker_Start()
    if checker.started or checker.finished then return end
    checker.started = true
    checker.urlIndex = 0
    begin_next_request()
end

function XaouUpdateChecker_Step()
    if checker.finished or checker.operation == nil then return end

    if now() - checker.startedAt > 15 then
        if not begin_next_request() then checker.finished = true end
        return
    end

    local done = false
    local ok = pcall(function() done = checker.operation.isDone == true end)
    if not ok or not done then return end

    if request_failed(checker.request) then
        begin_next_request()
        return
    end

    local okText, text = pcall(function() return checker.request.downloadHandler.text end)
    dispose_request()
    checker.finished = true
    if not okText then return end

    local remoteVersion, message = parse_manifest(text)
    if remoteVersion == nil or not is_newer(remoteVersion, LOCAL_VERSION) then return end

    checker.notified = true
    local body = "มีอัปเดตม็อดใหม่\nXaou 009 Daily Shop\nเวอร์ชัน " .. tostring(remoteVersion)
    if message ~= nil and message ~= "" then body = body .. "\n" .. message end
    pcall(function() world:ShowMsgBox(body) end)
end

function XaouUpdateChecker_Stop()
    if checker.request ~= nil then pcall(function() checker.request:Abort() end) end
    dispose_request()
end

function XaouUpdateChecker_GetLocalVersion()
    return LOCAL_VERSION
end
