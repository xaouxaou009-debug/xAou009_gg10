-- Fixed special-item catalog for Xaou 009 Shop.
-- Add custom items here later; this list is never randomized.

XaouShop_SpecialCategories = {
    {id="all", text="ทั้งหมด"},
    {id="cultivation", text="ของบ่มเพาะ"},
    {id="manual", text="คัมภีร์"},
    {id="material", text="วัตถุดิบ"},
    {id="event", text="ของกิจกรรม"},
    {id="other", text="อื่น ๆ"},
}

XaouShop_SpecialItems = {
    {id="Item_Xaou_OtherworldOre_Wood",  category="cultivation", price=2000, limit=50},
    {id="Item_Xaou_OtherworldOre_Fire",  category="cultivation", price=2000, limit=50},
    {id="Item_Xaou_OtherworldOre_Earth", category="cultivation", price=2000, limit=50},
    {id="Item_Xaou_OtherworldOre_Metal", category="cultivation", price=2000, limit=50},
    {id="Item_Xaou_OtherworldOre_Water", category="cultivation", price=2000, limit=50},

    -- Five elemental cultivation cushions. IDs stay unchanged for save compatibility.
    {id="Building_Xaou_OtherworldFengShui_Wood", kind="building", category="other", price=2000, limit=10, displayName="เบาะนั่งบ่มเพาะธาตุไม้", description="รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุไม้", icon="res\\Sprs\\buildingnew\\building_fazuo01"},
    {id="Building_Xaou_OtherworldFengShui_Fire", kind="building", category="other", price=2000, limit=10, displayName="เบาะนั่งบ่มเพาะธาตุไฟ", description="รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุไฟ", icon="res\\Sprs\\buildingnew\\building_fazuo01"},
    {id="Building_Xaou_OtherworldFengShui_Earth", kind="building", category="other", price=2000, limit=10, displayName="เบาะนั่งบ่มเพาะธาตุดิน", description="รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุดิน", icon="res\\Sprs\\buildingnew\\building_fazuo01"},
    {id="Building_Xaou_OtherworldFengShui_Metal", kind="building", category="other", price=2000, limit=10, displayName="เบาะนั่งบ่มเพาะธาตุโลหะ", description="รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุโลหะ", icon="res\\Sprs\\buildingnew\\building_fazuo01"},
    {id="Building_Xaou_OtherworldFengShui_Water", kind="building", category="other", price=2000, limit=10, displayName="เบาะนั่งบ่มเพาะธาตุน้ำ", description="รวบรวมปราณ 120 ระยะ 2 ช่อง ธาตุน้ำ", icon="res\\Sprs\\buildingnew\\building_fazuo01"},
}
