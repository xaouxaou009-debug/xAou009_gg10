-- Xaou 009 Daily Shop standalone entry point.

pcall(require, 'Scripts/10_XaouShop_ItemPool.lua')
pcall(require, 'Scripts/11_XaouShop_AllItemPacks.lua')
pcall(require, 'Scripts/12_XaouShop_SpecialItems.lua')
pcall(require, 'Scripts/20_XaouShop_Core.lua')
pcall(require, 'Scripts/30_XaouShop_Window.lua')
pcall(require, 'Scripts/35_XaouShop_SpecialWindow.lua')
pcall(require, 'Scripts/40_XaouShop_BackpackWindow.lua')
pcall(require, 'Scripts/50_XaouShop_UpdateChecker.lua')
pcall(require, 'Scripts/60_XaouShop_DailyLogin.lua')

local XaouDailyShop = GameMain:NewMod("Xaou009DailyShop")

local function show(text)
    pcall(function() world:ShowMsgBox(tostring(text)) end)
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
    if XaouBackpack_OpenWindow == nil then show("ไม่พบระบบหน้าต่างกระเป๋า Xaou 009"); return false end
    local ok, result, detail = pcall(function() return XaouBackpack_OpenWindow(npc) end)
    if not ok or result == false then
        show("เปิดกระเป๋า Xaou 009 ไม่สำเร็จ\n" .. tostring(detail or result))
        return false
    end
    return true
end

function XaouDailyShop:OnEnter()
    self._loginAutoDay = nil
    local event = GameMain:GetMod("_Event")
    if event ~= nil then
        event:RegisterEvent(g_emEvent.SelectNpc, function(evt, npc, objs)
            if npc ~= nil and npc.ThingType == g_emThingType.Npc then
                pcall(function() npc:RemoveBtnData("ชื้อ/ขาย") end)
                npc:AddBtnData(
                    "ชื้อ/ขาย",
                    "res/Sprs/ui/icon_hand",
                    "GameMain:GetMod('Xaou009DailyShop'):Open(bind)",
                    "เปิดร้านค้ารายวันของ Xaou 009",
                    nil
                )
                pcall(function() npc:RemoveBtnData("กระเป๋า") end)
                npc:AddBtnData(
                    "กระเป๋า",
                    "res/Sprs/ui/icon_hand",
                    "GameMain:GetMod('Xaou009DailyShop'):OpenBackpack(bind)",
                    "เปิดกระเป๋ากลางของ Xaou 009",
                    nil
                )
            end
        end, "Xaou009DailyShop_SelectNpc")
    end
    if XaouShop_EnsureDaily then pcall(XaouShop_EnsureDaily) end
    if XaouUpdateChecker_Start then pcall(XaouUpdateChecker_Start) end
end

function XaouDailyShop:OnStep(dt)
    self._shopTimer = (self._shopTimer or 0) + (tonumber(dt) or 0)
    if self._shopTimer < 1 then return end
    self._shopTimer = 0
    if XaouShop_EnsureDaily then pcall(XaouShop_EnsureDaily) end
    local loginDay = XaouDailyLogin_GetToday and XaouDailyLogin_GetToday() or XaouShop_GetDay()
    if self._loginAutoDay ~= loginDay then
        self._loginAutoDay = loginDay
        if XaouDailyLogin_ShouldAutoOpen and XaouDailyLogin_ShouldAutoOpen() and XaouDailyLogin_Open then
            pcall(function() XaouDailyLogin_Open(nil) end)
        end
    end
    if XaouUpdateChecker_Step then pcall(XaouUpdateChecker_Step) end
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
end

function XaouDailyShop:OnLeave()
    local event = GameMain:GetMod("_Event", true)
    if event ~= nil then pcall(function() event:UnRegisterEvent(g_emEvent.SelectNpc, "Xaou009DailyShop_SelectNpc") end) end
    if XaouShop_CloseWindow then pcall(XaouShop_CloseWindow) end
    if XaouSpecialShop_Close then pcall(XaouSpecialShop_Close) end
    if XaouBackpack_CloseWindow then pcall(XaouBackpack_CloseWindow) end
    if XaouDailyLogin_Close then pcall(XaouDailyLogin_Close) end
    if XaouUpdateChecker_Stop then pcall(XaouUpdateChecker_Stop) end
end

function XaouDailyShop:NeedSyncData() return false end
