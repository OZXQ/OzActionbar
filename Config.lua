OzActionbarDB = OzActionbarDB or {
    center_bars = true,
    remove_gryphons = true,
    custom_border = true,
    range_color = true,
    reactive_glow = true,
    dock_bags = true,
    minimap_angle = 45,
}

local LOCALE = GetLocale()
local L = setmetatable({}, {
    __index = function(t, k)
        local v = tostring(k)
        rawset(t, k, v)
        return v
    end
})

if LOCALE == "zhCN" then
    L["OzActionbar"] = "OzActionbar 动作条"
    L["OzActionbar Settings"] = "OzActionbar 动作条设置"
    L["Center Action Bars"] = "居中主动作条与额外动作条"
    L["Remove Gryphons & Art"] = "移除两端狮鹫与背景石雕"
    L["Custom Button Border"] = "应用自定义动作条按钮边框"
    L["Range Red Coloring"] = "超出距离技能图标染红"
    L["Reactive Spell Glow"] = "反应性技能触发变大与高亮(压制/复仇等)"
    L["Dock Bags & MicroMenu"] = "右下角停靠背包与微型菜单(悬停显示)"
    L["Left Click: Open settings"] = "左键点击: 打开设置面板"
    L["Right Drag: Move button"] = "右键拖拽: 调整小地图图标位置"
    L["Close"] = "关闭"
end

-- 1. Compact Config Panel
local panel = CreateFrame("Frame", "OzConfigFrame", UIParent)
panel:SetWidth(360)
panel:SetHeight(320)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
panel:SetFrameStrata("DIALOG")
panel:EnableMouse(true)
panel:SetMovable(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function() this:StartMoving() end)
panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local header = panel:CreateTexture(nil, "ARTWORK")
header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
header:SetWidth(256)
header:SetHeight(64)
header:SetPoint("TOP", panel, "TOP", 0, 12)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", header, "TOP", 0, -14)
title:SetText(L["OzActionbar Settings"])

local close_x = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close_x:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)

local OPTIONS = {
    { key = "center_bars",     label = "Center Action Bars" },
    { key = "remove_gryphons",  label = "Remove Gryphons & Art" },
    { key = "custom_border",    label = "Custom Button Border" },
    { key = "range_color",      label = "Range Red Coloring" },
    { key = "reactive_glow",    label = "Reactive Spell Glow" },
    { key = "dock_bags",        label = "Dock Bags & MicroMenu" },
}

local opt_count = table.getn(OPTIONS)
local check_buttons = {}

for idx = 1, opt_count do
    local opt = OPTIONS[idx]
    local opt_key = opt.key
    local cb = CreateFrame("CheckButton", "OzCB_" .. opt_key, panel, "UICheckButtonTemplate")
    cb:SetWidth(26)
    cb:SetHeight(26)
    cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -45 - (idx - 1) * 36)

    local txt = _G[cb:GetName() .. "Text"]
    if txt then
        txt:SetText(L[opt.label])
        txt:SetFontObject("GameFontHighlight")
    end

    cb:SetScript("OnClick", function()
        OzActionbarDB[opt_key] = this:GetChecked() and true or false
    end)
    check_buttons[opt_key] = cb
end

local close_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
close_btn:SetWidth(80)
close_btn:SetHeight(22)
close_btn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 18)
close_btn:SetText(L["Close"])
close_btn:SetScript("OnClick", function() panel:Hide() end)

panel:SetScript("OnShow", function()
    for k = 1, opt_count do
        local key_name = OPTIONS[k].key
        local cb = check_buttons[key_name]
        if cb then
            cb:SetChecked(OzActionbarDB[key_name] and true or false)
        end
    end
end)
panel:Hide()

-- 2. Draggable Minimap Button
local mm_btn = CreateFrame("Button", "OzMinimapBtn", Minimap)
mm_btn:SetWidth(31)
mm_btn:SetHeight(31)
mm_btn:SetFrameStrata("LOW")
mm_btn:SetToplevel(true)
mm_btn:EnableMouse(true)
mm_btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm_btn:RegisterForDrag("RightButton")

local mm_icon = mm_btn:CreateTexture(nil, "BACKGROUND")
mm_icon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleStance")
mm_icon:SetWidth(20)
mm_icon:SetHeight(20)
mm_icon:SetPoint("CENTER", mm_btn, "CENTER", 0, 0)

local mm_border = mm_btn:CreateTexture(nil, "OVERLAY")
mm_border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mm_border:SetWidth(52)
mm_border:SetHeight(52)
mm_border:SetPoint("TOPLEFT", mm_btn, "TOPLEFT", 0, 0)

local function update_minimap_pos()
    local angle = OzActionbarDB.minimap_angle or 45
    local rad = math.rad(angle)
    mm_btn:ClearAllPoints()
    mm_btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * 80, math.sin(rad) * 80)
end

mm_btn:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        if panel:IsShown() then panel:Hide() else panel:Show() end
    end
end)

mm_btn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff00eeff" .. L["OzActionbar"] .. "|r")
    GameTooltip:AddLine(L["Left Click: Open settings"], 1, 1, 1)
    GameTooltip:AddLine(L["Right Drag: Move button"], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

mm_btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local is_dragging = false
mm_btn:SetScript("OnDragStart", function() is_dragging = true end)
mm_btn:SetScript("OnDragStop", function() is_dragging = false end)
mm_btn:SetScript("OnUpdate", function()
    if is_dragging then
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if angle < 0 then angle = angle + 360 end
        OzActionbarDB.minimap_angle = angle
        update_minimap_pos()
    end
end)

update_minimap_pos()

-- 3. Slash Command
SLASH_OZACTIONBAR1 = "/ozab"
SLASH_OZACTIONBAR2 = "/ozactionbar"
SlashCmdList["OZACTIONBAR"] = function()
    if panel:IsShown() then panel:Hide() else panel:Show() end
end
