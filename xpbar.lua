if OzAb and OzAb.xpbar then return end
OzAb = OzAb or {}

local xpbar = {}
OzAb.xpbar = xpbar
xpbar.width = 476
xpbar.height = 10
xpbar.backdrop = {
    bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
    insets = { left = -1, right = -1, top = -1, bottom = -1 }
}
xpbar.frame = xpbar.frame or nil

local LOCALE = GetLocale()
local L_CURRENT_XP = LOCALE == "zhCN" and "当前经验：" or "Current XP: "
local L_LEVEL_PROGRESS = LOCALE == "zhCN" and "升级进度：" or "Level Progress: "
local L_CURRENT_RESTED = LOCALE == "zhCN" and "当前双倍：" or "Current Rested: "

local isRepositioning = false

function xpbar:reposition()
    if isRepositioning then return end
    isRepositioning = true
    MainMenuExpBar:SetParent(UIParent)
    MainMenuExpBar:ClearAllPoints()
    MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    MainMenuExpBar:SetWidth(self.width)
    MainMenuExpBar:SetHeight(self.height)
    isRepositioning = false
end

function xpbar:resize()
    MainMenuExpBar:SetWidth(self.width)
    MainMenuExpBar:SetHeight(self.height)
end

function xpbar:replaceTexture()
    MainMenuExpBar:SetStatusBarTexture("Interface\\AddOns\\OzActionbar\\texture\\xpbar")
    MainMenuExpBar:SetBackdrop(self.backdrop)
    MainMenuExpBar:SetBackdropColor(0, 0, 0, 0.6)

    if not MainMenuExpBar.spark then
        MainMenuExpBar.spark = MainMenuExpBar:CreateTexture(nil, 'OVERLAY', nil, 7)
        MainMenuExpBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        MainMenuExpBar.spark:SetWidth(35)
        MainMenuExpBar.spark:SetHeight(35)
        MainMenuExpBar.spark:SetBlendMode("ADD")
    end

    -- Remove and permanently silence Blizzard quad art textures
    for i = 0, 3 do
        local tex = _G['MainMenuXPBarTexture' .. i]
        if tex then
            tex:SetTexture("")
            tex:Hide()
            tex.Show = function() end
        end
    end

    -- Permanently hide all 19 Blizzard division tick marks so they cannot force height or show
    for i = 0, 18 do
        local div = _G["MainMenuExpBarDiv" .. i]
        if div then
            div:SetTexture("")
            div:Hide()
            div.Show = function() end
        end
    end

    -- Permanently hide default ExhaustionTick and ExhaustionLevelFillBar
    if ExhaustionTick then
        ExhaustionTick:Hide()
        ExhaustionTick.Show = function() end
    end
    if ExhaustionLevelFillBar then
        ExhaustionLevelFillBar:SetTexture("")
        ExhaustionLevelFillBar:Hide()
        ExhaustionLevelFillBar.Show = function() end
    end
end

function xpbar:createText()
    if self.expstring then return end

    local textFrame = CreateFrame("Frame", "OzExpTextFrame", MainMenuExpBar)
    textFrame:SetAllPoints(MainMenuExpBar)
    textFrame:SetFrameStrata("HIGH")

    local font = STANDARD_TEXT_FONT
    local size, outline = 10, "OUTLINE"

    local str = textFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    str:SetFont(font, size, outline)
    str:ClearAllPoints()
    str:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
    str:SetJustifyH("CENTER")
    str:SetTextColor(1, 1, 1)

    self.textFrame = textFrame
    self.expstring = str
end

function xpbar:setupMouse()
    if self.mouseFrame then return end

    local mouseFrame = CreateFrame("Frame", "OzExpMouseFrame", MainMenuExpBar)
    mouseFrame:SetAllPoints(MainMenuExpBar)
    mouseFrame:SetFrameStrata("HIGH")
    mouseFrame:EnableMouse(true)
    mouseFrame:SetScript("OnEnter", function()
        xpbar:updateExp()
        if xpbar.expstring then xpbar.expstring:Show() end
    end)
    mouseFrame:SetScript("OnLeave", function()
        xpbar:updateExp()
        if xpbar.expstring then xpbar.expstring:Show() end
    end)

    self.mouseFrame = mouseFrame
end

function xpbar:updateExp()
    local playerlevel = UnitLevel("player")
    local maxLevel = MAX_PLAYER_LEVEL or 60

    if playerlevel >= maxLevel then
        MainMenuExpBar:Hide()
        if self.expstring then self.expstring:SetText("") end
        if MainMenuExpBar.spark then MainMenuExpBar.spark:Hide() end
        if OzAb.repbar and OzAb.repbar.reposition then
            OzAb.repbar:reposition()
        end
        return
    end

    local xp = UnitXP("player")
    local xpmax = UnitXPMax("player")
    local exh = GetXPExhaustion() or 0

    if xpmax and xpmax > 0 then
        local xp_perc = math.floor((xp / xpmax * 100) + 0.5)
        local exh_perc = math.floor((exh / xpmax * 100) + 0.5)

        if self.expstring then
            self.expstring:SetText(
                "|cffffff00" .. L_CURRENT_XP .. "|r|cffffffff" .. xp .. "/" .. xpmax .. "|r  " ..
                "|cffffff00" .. L_LEVEL_PROGRESS .. "|r|cffff0000" .. xp_perc .. "%|r  " ..
                "|cffffff00" .. L_CURRENT_RESTED .. "|r|cffffffff" .. exh_perc .. "%|r"
            )
            self.expstring:Show()
        end

        local rested = GetRestState()
        if rested == 1 then
            if exh_perc >= 150 then
                MainMenuExpBar:SetStatusBarColor(0, 1, 0.6, 1)
                if MainMenuExpBar.spark then
                    MainMenuExpBar.spark:SetVertexColor(0, 1.5, 0.9, 1)
                end
            else
                MainMenuExpBar:SetStatusBarColor(0.0, 0.39, 0.88, 1.0)
                if MainMenuExpBar.spark then
                    MainMenuExpBar.spark:SetVertexColor(0, 0.39 * 1.5, 0.88 * 1.5, 1)
                end
            end
        elseif rested == 2 then
            MainMenuExpBar:SetStatusBarColor(0.58, 0.0, 0.55, 1.0)
            if MainMenuExpBar.spark then
                MainMenuExpBar.spark:SetVertexColor(0.58 * 1.5, 0, 0.55 * 1.5, 1)
            end
        end

        if MainMenuExpBar.spark then
            local x = (xp / xpmax) * MainMenuExpBar:GetWidth()
            MainMenuExpBar.spark:SetPoint("CENTER", MainMenuExpBar, "LEFT", x, 0)
            MainMenuExpBar.spark:Show()
        end
    end
end

function xpbar:enable()
    self:replaceTexture()
    self:reposition()
    self:createText()
    self:setupMouse()

    if MainMenuBarOverlayFrame then
        MainMenuBarOverlayFrame:Hide()
        MainMenuBarOverlayFrame.Show = function() end
    end
    if MainMenuBarExpText then
        MainMenuBarExpText:SetText("")
    end

    -- Hook MainMenuExpBar.SetPoint so Blizzard cannot anchor it to MainMenuBar or stretch it
    local orig_SetPoint = MainMenuExpBar.SetPoint
    MainMenuExpBar.SetPoint = function(f, p, rel, relP, x, y)
        if isRepositioning then
            orig_SetPoint(f, p, rel, relP, x, y)
        else
            xpbar:reposition()
        end
    end

    -- Enforce custom width and height against Blizzard overrides
    local orig_SetWidth = MainMenuExpBar.SetWidth
    MainMenuExpBar.SetWidth = function(f, w)
        orig_SetWidth(f, xpbar.width)
    end

    local orig_SetHeight = MainMenuExpBar.SetHeight
    MainMenuExpBar.SetHeight = function(f, h)
        orig_SetHeight(f, xpbar.height)
    end

    -- Override Blizzard's MainMenuExpBar_SetWidth so it doesn't force 1024 or 512
    MainMenuExpBar_SetWidth = function(width)
        MainMenuExpBar:SetWidth(xpbar.width)
        MainMenuExpBar.pauseUpdates = nil
        MainMenuExpBar_Update()
    end

    self:updateExp()

    if self.frame then return end
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_XP_UPDATE")
    self.frame:RegisterEvent("UPDATE_EXHAUSTION")
    self.frame:RegisterEvent("PLAYER_LEVEL_UP")
    self.frame:RegisterEvent("PLAYER_UPDATE_RESTING")
    self.frame:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            if MainMenuBarOverlayFrame then
                MainMenuBarOverlayFrame:Hide()
            end
            if MainMenuBarExpText then
                MainMenuBarExpText:SetText("")
            end
            xpbar:reposition()
        end
        xpbar:updateExp()
    end)
end
