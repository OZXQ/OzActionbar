if OzAb and OzAb.repbar then return end
OzAb = OzAb or {}
local function get_bar_color(standing)
    if standing and FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing] then
        return FACTION_BAR_COLORS[standing]
    end
    local _, englishClass = UnitClass("player")
    if englishClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[englishClass] then
        return RAID_CLASS_COLORS[englishClass]
    end
    return { r = 0, g = 0.6, b = 1 }
end

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

    local playerlevel = UnitLevel("player") or 0
    local maxLevel = MAX_PLAYER_LEVEL or 60

    if playerlevel > 0 and playerlevel < maxLevel and MainMenuExpBar and MainMenuExpBar:IsShown() then
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
        local c = get_bar_color()
        ReputationWatchStatusBar.spark = ReputationWatchStatusBar:CreateTexture(nil, 'OVERLAY', nil, 7)
        ReputationWatchStatusBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        ReputationWatchStatusBar.spark:SetWidth(35)
        ReputationWatchStatusBar.spark:SetHeight(35)
        ReputationWatchStatusBar.spark:SetBlendMode("ADD")
        ReputationWatchStatusBar.spark:SetVertexColor(c.r * 1.3, c.g * 1.3, c.b * 1.3, 0.6)
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

    -- Permanently silence max level bar frames if present
    if MainMenuBarMaxLevelBar then
        MainMenuBarMaxLevelBar:Hide()
        MainMenuBarMaxLevelBar.Show = function() end
        MainMenuBarMaxLevelBar:SetAlpha(0)
    end
end

function repbar:createText()
    if self.repstring then return end

    local textFrame = CreateFrame("Frame", "OzRepTextFrame", ReputationWatchStatusBar)
    textFrame:SetAllPoints(ReputationWatchStatusBar)
    textFrame:SetFrameStrata("HIGH")
    textFrame:SetFrameLevel(ReputationWatchStatusBar:GetFrameLevel() + 5)

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

    local mouseFrame = CreateFrame("Frame", "OzRepMouseFrame", ReputationWatchStatusBar)
    mouseFrame:SetAllPoints(ReputationWatchStatusBar)
    mouseFrame:SetFrameStrata("HIGH")
    mouseFrame:SetFrameLevel(ReputationWatchStatusBar:GetFrameLevel() + 6)
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
            self.repstring:SetText(
                "|cffffd200" .. name .. "|r " ..
                "|cffffffff(" .. standingName .. ")|r " ..
                "|cff00ff00" .. percent .. "%|r " ..
                "|cffffffff-|r |cffffffff" .. remStr .. " " .. L_REMAINING .. "|r"
            )
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

        local barColor = get_bar_color(standing)

        if min and max and max > min and v then
            ReputationWatchStatusBar:SetMinMaxValues(min, max)
            ReputationWatchStatusBar:SetValue(v)
            local x = ((v - min) / (max - min)) * ReputationWatchBar:GetWidth()
            if ReputationWatchStatusBar.spark then
                ReputationWatchStatusBar.spark:SetPoint('CENTER', ReputationWatchStatusBar, 'LEFT', x, 0)
                ReputationWatchStatusBar.spark:SetVertexColor(barColor.r * 1.3, barColor.g * 1.3, barColor.b * 1.3, 0.8)
                ReputationWatchStatusBar.spark:Show()
            end
        else
            if ReputationWatchStatusBar.spark then
                ReputationWatchStatusBar.spark:Hide()
            end
        end

        ReputationWatchStatusBar:SetStatusBarColor(barColor.r, barColor.g, barColor.b, 1)
        if repbar.textFrame and ReputationWatchStatusBar then
            repbar.textFrame:SetFrameLevel(ReputationWatchStatusBar:GetFrameLevel() + 5)
        end
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

        local retryTimer = 0
        local totalWait = 0
        self.frame:SetScript("OnEvent", function()
            if event == "PLAYER_ENTERING_WORLD" then
                if ReputationWatchBar_Update then
                    ReputationWatchBar_Update()
                end
                repbar:resize()
                repbar:reposition()
                repbar:updateRep()

                local name = GetWatchedFactionInfo()
                if not name then
                    retryTimer = 0
                    totalWait = 0
                    repbar.frame:SetScript("OnUpdate", function()
                        local dt = arg1 or 0.1
                        retryTimer = retryTimer + dt
                        totalWait = totalWait + dt
                        if retryTimer >= 0.3 then
                            retryTimer = 0
                            local tracked = GetWatchedFactionInfo()
                            if tracked or totalWait >= 5 then
                                repbar.frame:SetScript("OnUpdate", nil)
                                if ReputationWatchBar_Update then
                                    ReputationWatchBar_Update()
                                end
                                repbar:resize()
                                repbar:reposition()
                                repbar:updateRep()
                            end
                        end
                    end)
                end
            elseif event == "UPDATE_FACTION" then
                if ReputationWatchBar_Update then
                    ReputationWatchBar_Update()
                end
                repbar:resize()
                repbar:reposition()
                repbar:updateRep()
            end
        end)
    end

    ReputationWatchBar_Update()
end
