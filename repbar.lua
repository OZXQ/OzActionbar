if OzAb and OzAb.repbar then return end
OzAb = OzAb or {}
local _, class = UnitClass 'player'
local colour = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or { r = 0, g = 0.6, b = 1 }

local repbar = {}
OzAb.repbar = repbar
repbar.backdrop = {
    bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
    insets = { left = -1, right = -1, top = -1, bottom = -1 }
}
repbar.width = 476
repbar.height = 10

local LOCALE = GetLocale()
local L_REMAINING = LOCALE == "zhCN" and "剩余" or "remaining"

local function round(input, places)
    places = places or 0
    local pow = 10 ^ places
    return math.floor(input * pow + 0.5) / pow
end

local function abbreviate(number, eachk)
    local sign = number < 0 and -1 or 1
    number = math.abs(number)

    if number >= 1000000 then
        return round(number / 1000000 * sign, 2) .. "m"
    elseif not eachk and number >= 10000 then
        return round(number / 1000 * sign, 2) .. "k"
    elseif eachk and number >= 1000 then
        return round(number / 1000 * sign, 2) .. "k"
    end

    return tostring(number)
end

local repvalues_fallback = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }

local isRepositioning = false

function repbar:reposition()
    if isRepositioning then return end
    isRepositioning = true
    ReputationWatchBar:SetParent(UIParent)
    ReputationWatchBar:ClearAllPoints()
    if MainMenuExpBar and MainMenuExpBar:IsShown() and UnitLevel("player") < (MAX_PLAYER_LEVEL or 60) then
        ReputationWatchBar:SetPoint("BOTTOM", MainMenuExpBar, "TOP", 0, 0)
    else
        ReputationWatchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    end
    ReputationWatchBar:SetWidth(self.width)
    ReputationWatchBar:SetHeight(self.height)
    isRepositioning = false
end

function repbar:resize()
    ReputationWatchBar:SetWidth(self.width)
    ReputationWatchBar:SetHeight(self.height)

    ReputationWatchStatusBar:ClearAllPoints()
    ReputationWatchStatusBar:SetAllPoints(ReputationWatchBar)
    ReputationWatchStatusBar:SetWidth(self.width)
    ReputationWatchStatusBar:SetHeight(self.height)
end

function repbar:replaceTexture()
    ReputationWatchStatusBar:SetStatusBarTexture("Interface\\AddOns\\OzActionbar\\texture\\xpbar")
    ReputationWatchStatusBar:SetBackdrop(self.backdrop)
    ReputationWatchStatusBar:SetBackdropColor(0, 0, 0, 0.6)

    if not ReputationWatchStatusBar.spark then
        ReputationWatchStatusBar.spark = ReputationWatchStatusBar:CreateTexture(nil, 'OVERLAY', nil, 7)
        ReputationWatchStatusBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        ReputationWatchStatusBar.spark:SetWidth(35)
        ReputationWatchStatusBar.spark:SetHeight(35)
        ReputationWatchStatusBar.spark:SetBlendMode("ADD")
        ReputationWatchStatusBar.spark:SetVertexColor(colour.r * 1.3, colour.g * 1.3, colour.b * 1.3, 0.6)
    end

    -- Permanently hide default Blizzard quad art textures
    for i = 0, 3 do
        local rwb = _G['ReputationWatchBarTexture' .. i]
        if rwb then
            rwb:SetTexture('')
            rwb:Hide()
            rwb.Show = function() end
        end
        local rxp = _G['ReputationXPBarTexture' .. i]
        if rxp then
            rxp:SetTexture('')
            rxp:Hide()
            rxp.Show = function() end
        end
        local rsb = _G['ReputationWatchBarBackground' .. i]
        if rsb then
            rsb:SetTexture('')
            rsb:Hide()
            rsb.Show = function() end
        end
    end

    -- Permanently hide Blizzard's fixed-height 8px background texture
    if ReputationWatchStatusBarBackground then
        ReputationWatchStatusBarBackground:SetTexture('')
        ReputationWatchStatusBarBackground:Hide()
        ReputationWatchStatusBarBackground.Show = function() end
    end

    -- Permanently hide default overlay and text
    if ReputationWatchBarOverlayFrame then
        ReputationWatchBarOverlayFrame:Hide()
        ReputationWatchBarOverlayFrame.Show = function() end
    end
    if ReputationWatchStatusBarText then
        ReputationWatchStatusBarText:SetText("")
    end
end

function repbar:createText()
    if self.repstring then return end

    local textFrame = CreateFrame("Frame", "OzRepTextFrame", ReputationWatchBar)
    textFrame:SetAllPoints(ReputationWatchBar)
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
    self.repstring = str
    self.repstring:Show()
end

function repbar:setupMouse()
    if self.mouseFrame then return end

    local mouseFrame = CreateFrame("Frame", "OzRepMouseFrame", ReputationWatchBar)
    mouseFrame:SetAllPoints(ReputationWatchBar)
    mouseFrame:SetFrameStrata("HIGH")
    mouseFrame:EnableMouse(true)
    mouseFrame:SetScript("OnEnter", function()
        repbar:updateRep()
        if repbar.repstring then repbar.repstring:Show() end
    end)
    mouseFrame:SetScript("OnLeave", function()
        repbar:updateRep()
        if repbar.repstring then repbar.repstring:Show() end
    end)

    self.mouseFrame = mouseFrame
end

function repbar:updateRep()
    local name, standing, min, max, value = GetWatchedFactionInfo()
    if name and standing and max and min and max > min then
        local maxRange = max - min
        local curValue = value - min
        local remaining = maxRange - curValue
        local percent = math.floor((curValue / maxRange * 100) + 0.5)
        local remStr = abbreviate(round(remaining), 1)
        local standingName = _G["FACTION_STANDING_LABEL" .. standing] or repvalues_fallback[standing] or ""

        if self.repstring then
            self.repstring:SetText(name ..
                " (" .. standingName .. ") " .. percent .. "% - " .. remStr .. " " .. L_REMAINING)
            self.repstring:Show()
        end
    else
        if self.repstring then
            self.repstring:SetText("")
        end
    end
end

function repbar:enable()
    self:replaceTexture()
    self:resize()
    self:reposition()
    self:createText()
    self:setupMouse()

    -- Hook ReputationWatchBar.SetPoint so Blizzard cannot anchor it to MainMenuBar or stretch it
    local orig_RepSetPoint = ReputationWatchBar.SetPoint
    ReputationWatchBar.SetPoint = function(f, p, rel, relP, x, y)
        if isRepositioning then
            orig_RepSetPoint(f, p, rel, relP, x, y)
        else
            repbar:reposition()
        end
    end

    -- Enforce custom width and height
    local orig_RepWidth = ReputationWatchBar.SetWidth
    ReputationWatchBar.SetWidth = function(f, w)
        orig_RepWidth(f, repbar.width)
    end

    local orig_RepHeight = ReputationWatchBar.SetHeight
    ReputationWatchBar.SetHeight = function(f, h)
        orig_RepHeight(f, repbar.height)
    end

    local orig_RepSbWidth = ReputationWatchStatusBar.SetWidth
    ReputationWatchStatusBar.SetWidth = function(f, w)
        orig_RepSbWidth(f, repbar.width)
    end

    local orig_RepSbHeight = ReputationWatchStatusBar.SetHeight
    ReputationWatchStatusBar.SetHeight = function(f, h)
        orig_RepSbHeight(f, repbar.height)
    end

    -- Replace ReputationWatchBar_Update entirely so Blizzard's buggy textures and anchors never run
    ReputationWatchBar_Update = function(newLevel)
        if not newLevel then newLevel = UnitLevel("player") end
        local name, standing, min, max, v = GetWatchedFactionInfo()

        if not name then
            ReputationWatchBar:Hide()
            return
        end

        ReputationWatchBar:Show()
        ReputationWatchBar:SetFrameStrata("LOW")
        repbar:resize()
        repbar:reposition()

        if ReputationWatchStatusBarText then
            ReputationWatchStatusBarText:SetText("")
        end

        local isMaxLevel = (newLevel == (MAX_PLAYER_LEVEL or 60))
        if isMaxLevel then
            if MainMenuExpBar and MainMenuExpBar.spark then
                MainMenuExpBar.spark:Hide()
            end
        else
            if MainMenuExpBar and MainMenuExpBar.spark and MainMenuExpBar:IsShown() then
                MainMenuExpBar.spark:Show()
            end
        end

        if min and max and max > min and v then
            ReputationWatchStatusBar:SetMinMaxValues(min, max)
            ReputationWatchStatusBar:SetValue(v)
            local x = ((v - min) / (max - min)) * ReputationWatchBar:GetWidth()
            if ReputationWatchStatusBar.spark then
                ReputationWatchStatusBar.spark:SetPoint('CENTER', ReputationWatchStatusBar, 'LEFT', x, 0)
                ReputationWatchStatusBar.spark:Show()
            end
        else
            if ReputationWatchStatusBar.spark then
                ReputationWatchStatusBar.spark:Hide()
            end
        end

        ReputationWatchStatusBar:SetStatusBarColor(colour.r, colour.g, colour.b, 1)
        repbar:updateRep()
    end

    if OzHook and OzHook.hook then
        OzHook:hook("UIParent_ManageFramePositions", nil, function()
            repbar:resize()
            repbar:reposition()
        end)
    end

    if not self.frame then
        self.frame = CreateFrame("Frame")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:RegisterEvent("UPDATE_FACTION")
        self.frame:SetScript("OnEvent", function()
            if ReputationWatchBar_Update then
                ReputationWatchBar_Update()
            end
            repbar:resize()
            repbar:reposition()
            repbar:updateRep()
        end)
    end

    ReputationWatchBar_Update()
end
