-- Shared TH/EN localization for every Xaou 009 Shop window.

XaouShop_Language = XaouShop_Language or "TH"

local EXACT_EN = {
    ["ชื้อ/ขาย"]="Buy / Sell", ["กระเป๋า"]="Backpack",
    ["ทั้งหมด"]="All", ["ของบ่มเพาะ"]="Cultivation", ["คัมภีร์"]="Manuals",
    ["วัตถุดิบ"]="Materials", ["ของกิจกรรม"]="Event Items", ["อื่น ๆ"]="Other",
    ["วิชาโพธิจิตเมตตาแห่ง Xaou"]="Xaou Bodhi Compassion Art",
    ["ซื้อครั้งเดียวเพื่อปลดล็อกวิชาบ่มเพาะให้ทั้งสำนัก เน้นฟื้นปราณหมู่ ช่วยผู้มีปราณต่ำ และสร้างเกราะให้มิตร"]="Purchase once to unlock this cultivation art for the whole sect. Restores Qi to allies, assists members with low Qi, and grants protective shields.",
    ["เบาะนั่งบ่มเพาะธาตุไม้"]="Wood Cultivation Cushion",
    ["เบาะนั่งบ่มเพาะธาตุไฟ"]="Fire Cultivation Cushion",
    ["เบาะนั่งบ่มเพาะธาตุดิน"]="Earth Cultivation Cushion",
    ["เบาะนั่งบ่มเพาะธาตุโลหะ"]="Metal Cultivation Cushion",
    ["เบาะนั่งบ่มเพาะธาตุน้ำ"]="Water Cultivation Cushion",
    ["รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุไม้"]="Qi gathering 120, range 2 tiles, Wood element.",
    ["รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุไฟ"]="Qi gathering 120, range 2 tiles, Fire element.",
    ["รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุดิน"]="Qi gathering 120, range 2 tiles, Earth element.",
    ["รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุโลหะ"]="Qi gathering 120, range 2 tiles, Metal element.",
    ["รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุน้ำ"]="Qi gathering 120, range 2 tiles, Water element.",
    ["ผู้เริ่มต้น"]="Beginner", ["ศิษย์"]="Disciple", ["ผู้อาวุโส"]="Elder", ["เซียน"]="Immortal",
    ["ไม้"]="Wood", ["หินสีเทา"]="Gray Rock", ["อิฐหินวิญญาณ"]="Spirit Stone Block",
    ["หินวิญญาณ"]="Spirit Stones", ["ไม้วิญญาณแปรรูป"]="Processed Spirit Wood",
    ["แร่เหล็ก"]="Iron Ore", ["โอสถมังกร"]="Dragon Pill", ["หยก"]="Jade",
    ["ผลึกวิญญาณ"]="Spirit Crystals", ["เขามังกรวารี"]="Water Dragon Horn",
    ["ชีพจรมังกรวารี"]="Water Dragon Tendon", ["เนื้อมังกรวารี"]="Water Dragon Meat",
    ["เกล็ดมังกรวารี"]="Water Dragon Scale",
}

local REPLACE_EN = {
    {"ร้านค้าสำหรับผู้เริ่มต้น เปลี่ยนสินค้าทุกวัน", "Beginner-friendly shop. Stock changes every in-game day."},
    {"สินค้าแต่ละชนิดซื้อได้สูงสุด 10 ชิ้นต่อวัน", "Each item can be purchased up to 10 times per day."},
    {"เลือกของที่มีบนแผนที่เพื่อขาย รับเป็นหินวิญญาณ", "Select an item on the map to sell for Spirit Stones."},
    {"ของพิเศษแบบคงที่ โควตารีเซ็ตทุกเดือนในเกม", "Fixed special stock. Purchase limits reset every in-game month."},
    {"ซื้อได้ธาตุละ 50 ชิ้น โควตารีเซ็ตทุก 28 วันเกม", "Up to 50 per element. Limits reset every 28 in-game days."},
    {"จัดเก็บและนำสิ่งของออกใกล้ NPC ที่เลือก", "Store items or withdraw them near the selected NPC."},
    {"แสดงเฉพาะไอเทมซ้อนได้ที่อยู่บนแผนที่จริง", "Shows stackable items currently present on the map."},
    {"เลือกของในกระเป๋าเพื่อนำออกใกล้ NPC", "Select an item to withdraw near the NPC."},
    {"รางวัล 7 วันตามระดับสมาชิก ของหายากมีจำนวนลดลงและออกในวันท้าย ๆ", "Seven-day rewards scale with membership. Rare rewards appear later in smaller amounts."},
    {"พลาดวันใดจะรับย้อนหลังไม่ได้ • ระดับสมาชิกและวัตถุดิบผูกกับเซฟนี้", "Missed days cannot be reclaimed. Membership and materials are tied to this save."},
    {"วันนี้รับรางวัลแล้ว กลับมาใหม่วันพรุ่งนี้", "Today's reward has been claimed. Come back tomorrow."},
    {"วันที่เครื่องย้อนกลับ ระบบระงับการรับรางวัลชั่วคราว", "The date moved backward. Rewards are temporarily suspended."},
    {"รับไม่ได้: วันที่เครื่องถูกปรับย้อนหลัง", "Cannot claim: the date was moved backward."},
    {"กำลังปลดล็อกวิชาให้สำนัก...", "Unlocking the cultivation art for the sect..."},
    {"ปลดล็อกวิชาโพธิจิตเมตตาแห่ง Xaou สำเร็จแล้ว", "Xaou Bodhi Compassion Art unlocked successfully."},
    {"ไม่พบข้อมูลวิชา กรุณาตรวจไฟล์ Settings", "Cultivation art data was not found. Check the Settings files."},
    {"สำนักปลดล็อกวิชานี้แล้ว", "This cultivation art is already unlocked."},
    {"เกมไม่ยอมปลดล็อกวิชา", "The game rejected the cultivation art unlock."},
    {"เฟอร์นิเจอร์ซื้อและวางได้ครั้งละ 1 ชิ้น", "Furniture can be purchased and placed one at a time."},
    {"ซื้อครั้งเดียว ปลดล็อกให้ทั้งสำนัก", "One purchase unlocks it for the whole sect."},
    {"ซื้อและวางครั้งละ 1 ชิ้น", "Buy and place one at a time."},
    {"ซื้อสำเร็จ แต่เปิดโหมดวางอาคารไม่ได้: ", "Purchased, but placement mode failed: "},
    {"ซื้อสินค้านี้ครบจำนวนจำกัดแล้ว", "The purchase limit for this item has been reached."},
    {"เปิดร้านค้ารายวันของ Xaou 009", "Open the Xaou 009 Daily Shop"},
    {"เปิดกระเป๋ากลางของ Xaou 009", "Open the Xaou 009 shared backpack"},
    {"ไม่พบระบบหน้าต่างกระเป๋า Xaou 009", "Xaou 009 backpack window is unavailable"},
    {"ไม่พบระบบหน้าต่าง Xaou Shop", "Xaou Shop window is unavailable"},
    {"เปิด Xaou 009 Daily Shop ไม่สำเร็จ", "Could not open Xaou 009 Daily Shop"},
    {"เปิดกระเป๋า Xaou 009 ไม่สำเร็จ", "Could not open Xaou 009 Backpack"},
    {"สินค้าประจำวันที่ ", "Daily stock: day "}, {"หินวิญญาณ: ", "Spirit Stones: "},
    {"▶ ซื้อสินค้า", "▶ Buy"}, {"ซื้อสินค้า", "Buy"}, {"▶ ขายของ", "▶ Sell"}, {"ขายของ", "Sell"},
    {"เช็กอิน 7 วัน", "7-Day Login"}, {"ของพิเศษ", "Special Shop"},
    {"เลือกสินค้า", "Select an item"}, {"เลือกของพิเศษ", "Select a special item"},
    {"แตะสินค้าเพื่อดูรายละเอียด", "Tap an item to view details."},
    {"ราคา: -", "Price: -"}, {"ราคา: ", "Price: "}, {"ราคา ", "Price "},
    {" / ชิ้น  |  รวม ", " each  |  Total "},
    {"คงเหลือ: -", "Stock: -"}, {"คงเหลือ: ", "Stock: "}, {"คงเหลือ ", "Stock "},
    {"มีอยู่: -", "Owned: -"}, {"มีอยู่: ", "Owned: "}, {"มีอยู่ ", "Owned "},
    {"จำนวนที่เลือก: ", "Selected: "}, {"จำนวน: -", "Quantity: -"}, {"จำนวน: ", "Quantity: "},
    {"กำลังดำเนินการซื้อ...", "Processing purchase..."}, {"กำลังขายของ...", "Selling..."},
    {"กรุณาเลือกสินค้า", "Please select an item."}, {"กรุณาเลือกของพิเศษ", "Please select a special item."},
    {"หินวิญญาณไม่เพียงพอ", "Not enough Spirit Stones."}, {"สินค้าเหลือไม่พอ", "Not enough stock."},
    {"ไม่พบสินค้า", "Item not found."}, {"ของที่เลือกมีไม่เพียงพอ", "Not enough of the selected item."},
    {"ไอเทมนี้ไม่สามารถขายได้", "This item cannot be sold."}, {"หักหินวิญญาณไม่สำเร็จ", "Could not deduct Spirit Stones."},
    {"ซื้อไม่สำเร็จ: ", "Purchase failed: "}, {"ขายไม่สำเร็จ: ", "Sale failed: "},
    {"ปลดล็อกวิชาไม่สำเร็จ: ", "Unlock failed: "}, {"ยังไม่มีสินค้าในหมวดนี้", "There are no items in this category."},
    {"ซื้อของพิเศษ", "Purchase"}, {"สิทธิ์คงเหลือ: -", "Allowance: -"}, {"สิทธิ์คงเหลือ: ", "Allowance: "},
    {"หมวด: ", "Category: "}, {"กำลังซื้อสินค้า...", "Purchasing..."},
    {"กระเป๋า Xaou 009", "Xaou 009 Backpack"}, {"▶ ในกระเป๋า", "▶ Backpack"}, {"ในกระเป๋า", "Backpack"},
    {"▶ บนแผนที่", "▶ On Map"}, {"บนแผนที่", "On Map"}, {"สิ่งของในกระเป๋า", "Backpack Items"},
    {"ไอเทมบนแผนที่", "Map Items"}, {"เลือกสิ่งของ", "Select an item"}, {"แตะสิ่งของเพื่อดูรายละเอียด", "Tap an item to view details."},
    {"จัดการ: -", "Amount: -"}, {"จัดการ: ", "Amount: "}, {"ทั้งหมด", "All"},
    {"นำออกใกล้ NPC", "Withdraw near NPC"}, {"เก็บเข้ากระเป๋า", "Store in Backpack"},
    {"กำลังนำของออก...", "Withdrawing items..."}, {"กำลังเก็บของ...", "Storing items..."},
    {"กรุณาเลือกสิ่งของ", "Please select an item."}, {"จำนวนไอเทมไม่เพียงพอ", "Not enough items."},
    {"ไม่พบไอเทม", "Item not found."}, {"นำไอเทมออกจากแผนที่ไม่สำเร็จ", "Could not remove the item from the map."},
    {"ดำเนินการไม่สำเร็จ: ", "Action failed: "}, {" รายการ", " items"},
    {"สมาชิก: ", "Membership: "}, {"เช็กอิน ", "Check-ins "}, {" วัน", " days"},
    {"Xaou 009 เช็กอินรายวัน", "Xaou 009 Daily Login"}, {"รับรางวัลวันนี้", "Claim Today's Reward"},
    {"รับแล้ว", "Claimed"}, {"รับได้วันนี้", "Available Today"}, {"รอรับ", "Upcoming"}, {"พลาด", "Missed"},
    {"รางวัลวันนี้พร้อมรับแล้ว", "Today's reward is ready."}, {"วันนี้รับรางวัลแล้ว", "Today's reward has been claimed."},
    {"วันนี้ไม่อยู่ในรอบเช็กอิน", "Today is outside the current login cycle."}, {"ไม่พบข้อมูลรางวัล", "Reward data was not found."},
    {"รับรางวัลไม่สำเร็จ: ", "Could not claim reward: "}, {"กำลังเตรียมรอบเช็กอินใหม่", "Preparing a new login cycle."},
    {"ระดับสมาชิกสูงสุดแล้ว", "Maximum membership level reached."}, {"ระดับสูงสุด", "Maximum Level"},
    {"ยืนยันอัปเกรด", "Confirm Upgrade"}, {"อัปเกรดสมาชิก", "Upgrade Membership"},
    {"ใช้วัตถุดิบเพื่อขึ้นเป็น ", "Use materials to advance to "}, {"อัปเกรดไม่สำเร็จ: ", "Upgrade failed: "},
    {"อัปเกรดสมาชิกเป็น ", "Membership upgraded to "}, {"เช็กอินสะสม ", "Cumulative check-ins "},
    {"ไม้วิญญาณแปรรูป", "Processed Spirit Wood"}, {"อิฐหินวิญญาณ", "Spirit Stone Block"},
    {"ผลึกวิญญาณ", "Spirit Crystals"}, {"หินวิญญาณ", "Spirit Stones"},
    {"เขามังกรวารี", "Water Dragon Horn"}, {"ชีพจรมังกรวารี", "Water Dragon Tendon"},
    {"เนื้อมังกรวารี", "Water Dragon Meat"}, {"เกล็ดมังกรวารี", "Water Dragon Scale"},
    {"หินสีเทา", "Gray Rock"}, {"แร่เหล็ก", "Iron Ore"}, {"โอสถมังกร", "Dragon Pill"},
    {"ผู้เริ่มต้น", "Beginner"}, {"ผู้อาวุโส", "Elder"}, {"ศิษย์", "Disciple"}, {"เซียน", "Immortal"},
    {"หยก", "Jade"}, {"ไม้", "Wood"},
    {"วันที่เกม ", "Game Day "}, {"วันที่ ", "Day "}, {"วันที่ไม่ถูกต้อง", "Invalid date"},
    {" (มี ", " (owned "}, {" ไม่เพียงพอ", " insufficient"}, {" จำนวน ", " x"},
    {" รับ ", " Received "}, {"ซื้อ ", "Bought "}, {"ขาย ", "Sold "}, {"เก็บ ", "Stored "}, {"นำออก ", "Withdrew "},
    {" สำเร็จ", " successfully"}, {"ไม่ทราบสาเหตุ", "Unknown error"},
}

table.sort(REPLACE_EN, function(a, b) return #a[1] > #b[1] end)

function XaouShop_GetLanguage()
    local value = XaouShop_Language
    if type(XaouShop_State) == "table" and XaouShop_State.language ~= nil then value = XaouShop_State.language end
    value = string.upper(tostring(value or "TH"))
    return value == "EN" and "EN" or "TH"
end

function XaouShop_SetLanguage(language)
    XaouShop_Language = string.upper(tostring(language or "TH")) == "EN" and "EN" or "TH"
    if type(XaouShop_State) == "table" then XaouShop_State.language = XaouShop_Language end
    return XaouShop_Language
end

function XaouShop_ToggleLanguage()
    return XaouShop_SetLanguage(XaouShop_GetLanguage() == "TH" and "EN" or "TH")
end

function XaouShop_Localize(value)
    local text = tostring(value or "")
    if XaouShop_GetLanguage() ~= "EN" then return text end
    if EXACT_EN[text] ~= nil then return EXACT_EN[text] end
    for _, pair in ipairs(REPLACE_EN) do
        local from, to, start = pair[1], pair[2], 1
        while true do
            local first, last = string.find(text, from, start, true)
            if first == nil then break end
            text = string.sub(text, 1, first - 1) .. to .. string.sub(text, last + 1)
            start = first + #to
        end
    end
    return EXACT_EN[text] or text
end
