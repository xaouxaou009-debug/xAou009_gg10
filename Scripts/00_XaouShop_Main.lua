-- Xaou 009 Daily Shop standalone entry point.

pcall(require, 'Scripts/05_XaouShop_I18N.lua')
pcall(require, 'Scripts/10_XaouShop_ItemPool.lua')
pcall(require, 'Scripts/11_XaouShop_AllItemPacks.lua')
pcall(require, 'Scripts/12_XaouShop_SpecialItems.lua')
pcall(require, 'Scripts/13_XaouShop_BodhiGong.lua')
pcall(require, 'Scripts/14_XaouShop_BodhiAutoCombat.lua')
pcall(require, 'Scripts/20_XaouShop_Core.lua')
pcall(require, 'Scripts/30_XaouShop_Window.lua')
pcall(require, 'Scripts/35_XaouShop_SpecialWindow.lua')
pcall(require, 'Scripts/40_XaouShop_BackpackWindow.lua')
pcall(require, 'Scripts/50_XaouShop_UpdateChecker.lua')
pcall(require, 'Scripts/60_XaouShop_DailyLogin.lua')
pcall(require, 'Scripts/71_XaouShop_NativeQuestAdapter.lua')
pcall(require, 'Scripts/70_XaouShop_QuestJournal.lua')

local XaouDailyShop = GameMain:NewMod("Xaou009DailyShop")

local function show(text)
    pcall(function() world:ShowMsgBox(XaouShop_Localize and XaouShop_Localize(text) or tostring(text)) end)
end

local function get_map()
    local map = nil
    pcall(function() map = Map end)
    if map == nil then pcall(function() map = CS.XiaWorld.World.Instance.map end) end
    return map
end

-- RemoteStorage is visible to normal NPC food jobs only while CanUse is true.
-- A real SleeveSpace building sets this itself. Without one, keep one valid NPC
-- ID in the runtime-only WorkingBuild set; the field is JsonIgnore.
function XaouDailyShop:EnsureSmartBackpackOpen(preferredNpc)
    local map = get_map()
    if map == nil or map.SpaceRing == nil then return false end
    local opened = false
    pcall(function() opened = map:IsSpaceRingOpen() == true end)
    if opened then
        if XaouShop_EnsureSmartBackpack then pcall(XaouShop_EnsureSmartBackpack) end
        return true
    end

    local npc = preferredNpc
    if npc == nil then
        local list = nil
        pcall(function() list = CS.XiaWorld.ThingMgr.Instance:GetThingList(CS.XiaWorld.g_emThingType.Npc) end)
        local n = 0
        pcall(function() n = tonumber(list.Count) or 0 end)
        for i = 0, n - 1 do
            local candidate = nil
            pcall(function() candidate = list:get_Item(i) end)
            local valid = false
            pcall(function() valid = candidate ~= nil and candidate.IsPlayerThing == true and candidate.IsDeath ~= true end)
            if valid then npc = candidate; break end
        end
    end
    local id = nil
    pcall(function() id = tonumber(npc.ID) end)
    if id == nil then return false end
    local ok = pcall(function() map.SpaceRing.WorkingBuild:Add(id) end)
    if ok then
        self._smartBackpackRuntimeId = id
        if XaouShop_EnsureSmartBackpack then pcall(XaouShop_EnsureSmartBackpack) end
    end
    return ok
end

function XaouDailyShop:CloseSmartBackpackRuntime()
    local id = self._smartBackpackRuntimeId
    local map = get_map()
    if id ~= nil and map ~= nil and map.SpaceRing ~= nil then
        pcall(function() map.SpaceRing.WorkingBuild:Remove(id) end)
    end
    self._smartBackpackRuntimeId = nil
end

function XaouDailyShop:Open(npc)
    if XaouShop_OpenWindow == nil then show("ไม่พบระบบหน้าต่าง Xaou Shop"); return false end
    local ok, result, detail = pcall(function() return XaouShop_OpenWindow(npc) end)
    if not ok or result == false then
        show("เปิด Xaou 009 Daily Shop ไม่สำเร็จ\n" .. tostring(detail or result))
        return false
    end
    return true
end

function XaouDailyShop:OpenBackpack(npc)
    self:EnsureSmartBackpackOpen(npc)
    if XaouBackpack_OpenWindow == nil then show("ไม่พบระบบหน้าต่างกระเป๋า Xaou 009"); return false end
    local ok, result, detail = pcall(function() return XaouBackpack_OpenWindow(npc) end)
    if not ok or result == false then
        show("เปิดกระเป๋า Xaou 009 ไม่สำเร็จ\n" .. tostring(detail or result))
        return false
    end
    return true
end

function XaouDailyShop:OpenQuestJournal(npc)
    if XaouQuest_OpenWindow == nil then show("ไม่พบระบบสมุดเควส Xaou 009"); return false end
    local ok, result, detail = pcall(function() return XaouQuest_OpenWindow(npc) end)
    if not ok or result == false then
        show("เปิดสมุดเควสไม่สำเร็จ\n" .. tostring(detail or result))
        return false
    end
    return true
end

function XaouDailyShop:OnEnter()
    self._loginAutoDay = nil
    local event = GameMain:GetMod("_Event")
    if event ~= nil then
        event:RegisterEvent(g_emEvent.SelectNpc, function(evt, npc, objs)
            if XaouQuest_OnNpcSelected then pcall(XaouQuest_OnNpcSelected, npc) end
            if npc ~= nil and npc.ThingType == g_emThingType.Npc then
                pcall(function() npc:RemoveBtnData("ชื้อ/ขาย") end)
                pcall(function() npc:RemoveBtnData("Buy / Sell") end)
                local shopText = XaouShop_GetLanguage and XaouShop_GetLanguage() == "EN" and "Buy / Sell" or "ชื้อ/ขาย"
                npc:AddBtnData(
                    shopText,
                    "res/Sprs/ui/icon_hand",
                    "GameMain:GetMod('Xaou009DailyShop'):Open(bind)",
                    XaouShop_Localize and XaouShop_Localize("เปิดร้านค้ารายวันของ Xaou 009") or "เปิดร้านค้ารายวันของ Xaou 009",
                    nil
                )
                pcall(function() npc:RemoveBtnData("กระเป๋า") end)
                pcall(function() npc:RemoveBtnData("Backpack") end)
                local bagText = XaouShop_GetLanguage and XaouShop_GetLanguage() == "EN" and "Backpack" or "กระเป๋า"
                npc:AddBtnData(
                    bagText,
                    "res/Sprs/ui/icon_hand",
                    "GameMain:GetMod('Xaou009DailyShop'):OpenBackpack(bind)",
                    XaouShop_Localize and XaouShop_Localize("เปิดกระเป๋ากลางของ Xaou 009") or "เปิดกระเป๋ากลางของ Xaou 009",
                    nil
                )
                pcall(function() npc:RemoveBtnData("เควส") end)
                pcall(function() npc:RemoveBtnData("Quests") end)
                local questText = XaouShop_GetLanguage and XaouShop_GetLanguage() == "EN" and "Quests" or "เควส"
                npc:AddBtnData(
                    questText,
                    "res/Sprs/ui/icon_hand",
                    "GameMain:GetMod('Xaou009DailyShop'):OpenQuestJournal(bind)",
                    XaouShop_GetLanguage and XaouShop_GetLanguage() == "EN" and "Open Xaou 009 Quest Journal" or "เปิดสมุดเควส Xaou 009",
                    nil
                )
            end
        end, "Xaou009DailyShop_SelectNpc")
        if g_emEvent.SelectItem ~= nil then
            event:RegisterEvent(g_emEvent.SelectItem, function(evt, item, objs)
                if XaouQuest_OnItemSelected then pcall(XaouQuest_OnItemSelected, item) end
            end, "Xaou009DailyShop_QuestSelectItem")
        end
        if g_emEvent.BuildingFinished ~= nil then
            event:RegisterEvent(g_emEvent.BuildingFinished, function(evt, building, objs)
                if XaouQuest_OnBuildingFinished then pcall(XaouQuest_OnBuildingFinished, building) end
            end, "Xaou009DailyShop_QuestBuilding")
        end
    end
    if XaouShop_EnsureDaily then pcall(XaouShop_EnsureDaily) end
    self:EnsureSmartBackpackOpen(nil)
    if XaouBodhi_RefreshAutoSkills then pcall(XaouBodhi_RefreshAutoSkills) end
    if XaouUpdateChecker_Start then pcall(XaouUpdateChecker_Start) end
end

function XaouDailyShop:OnStep(dt)
    if XaouShop_PlacementStep then pcall(XaouShop_PlacementStep) end
    self._shopTimer = (self._shopTimer or 0) + (tonumber(dt) or 0)
    if self._shopTimer < 1 then return end
    self._shopTimer = 0
    self:EnsureSmartBackpackOpen(nil)
    if XaouBodhi_RefreshAutoSkills then pcall(XaouBodhi_RefreshAutoSkills) end
    if XaouShop_EnsureDaily then pcall(XaouShop_EnsureDaily) end
    local loginDay = XaouDailyLogin_GetToday and XaouDailyLogin_GetToday() or XaouShop_GetDay()
    if self._loginAutoDay ~= loginDay then
        self._loginAutoDay = loginDay
        if XaouDailyLogin_ShouldAutoOpen and XaouDailyLogin_ShouldAutoOpen() and XaouDailyLogin_Open then
            pcall(function() XaouDailyLogin_Open(nil) end)
        end
    end
    if XaouUpdateChecker_Step then pcall(XaouUpdateChecker_Step) end
    if XaouQuest_Step then pcall(XaouQuest_Step) end
end

function XaouDailyShop:OnSave()
    if XaouShop_ExportState then return XaouShop_ExportState() end
    return nil
end

function XaouDailyShop:OnLoad(data)
    if XaouShop_ImportState then XaouShop_ImportState(data) end
end

function XaouDailyShop:OnAfterLoad()
    if XaouShop_EnsureDaily then pcall(XaouShop_EnsureDaily) end
    self:EnsureSmartBackpackOpen(nil)
    if XaouBodhi_RefreshAutoSkills then pcall(XaouBodhi_RefreshAutoSkills) end
end

function XaouDailyShop:OnLeave()
    self:CloseSmartBackpackRuntime()
    local event = GameMain:GetMod("_Event", true)
    if event ~= nil then pcall(function() event:UnRegisterEvent(g_emEvent.SelectNpc, "Xaou009DailyShop_SelectNpc") end) end
    if XaouShop_CloseWindow then pcall(XaouShop_CloseWindow) end
    if XaouSpecialShop_Close then pcall(XaouSpecialShop_Close) end
    if XaouBackpack_CloseWindow then pcall(XaouBackpack_CloseWindow) end
    if XaouDailyLogin_Close then pcall(XaouDailyLogin_Close) end
    if XaouUpdateChecker_Stop then pcall(XaouUpdateChecker_Stop) end
    if XaouQuest_CloseWindow then pcall(XaouQuest_CloseWindow) end
    if event ~= nil then
        pcall(function() event:UnRegisterEvent(g_emEvent.SelectItem, "Xaou009DailyShop_QuestSelectItem") end)
        pcall(function() event:UnRegisterEvent(g_emEvent.BuildingFinished, "Xaou009DailyShop_QuestBuilding") end)
    end
end

function XaouDailyShop:NeedSyncData() return false end
