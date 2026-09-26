if OzAb and OzAb.actionbar then return end
OzAb = OzAb or {}

local actionbar = {
  buttonPadding = 3,
  barPadding = 6,
  normalButtonSize = 36,
  smallButtonSize = 30,
  barList = {
    { name = "Action",              count = 12 },
    { name = "BonusAction",         count = 12 },
    { name = "MultiBarBottomLeft",  count = 12 },
    { name = "MultiBarBottomRight", count = 12 },
    { name = "MultiBarLeft",        count = 12, isVertical = true },
    { name = "MultiBarRight",       count = 12, isVertical = true },
    { name = "Shapeshift",          count = 10 },
    { name = "PetAction",           count = 10 },
  }
}
OzAb.actionbar = actionbar

function actionbar:restyle()
  for _, bar in ipairs(self.barList) do
    for i = 1, bar.count do
      local texture = _G[bar.name .. "Button" .. i .. "NormalTexture"]
      if texture and texture.SetPoint then
        texture:SetPoint("CENTER", 0, 0)
      end
    end
  end
end

function actionbar:layoutButtons()
  local pad = self.buttonPadding
  for _, bar in ipairs(self.barList) do
    local isVert = bar.isVertical
    local btn1 = _G[bar.name .. "Button1"]

    -- Anchor first button to its parent frame
    if btn1 then
      btn1:ClearAllPoints()
      if isVert then
        btn1:SetPoint("TOP", _G[bar.name], "TOP", 0, 0)
      elseif bar.name == "BonusAction" then
        btn1:SetPoint("BOTTOMLEFT", ActionButton1, "BOTTOMLEFT", 0, 0)
      else
        local parentBar = (bar.name == "Action" and MainMenuBar)
            or (bar.name == "PetAction" and PetActionBarFrame)
            or (bar.name == "Shapeshift" and ShapeshiftBarFrame)
            or _G[bar.name]
        if parentBar then
          btn1:SetPoint("BOTTOMLEFT", parentBar, "BOTTOMLEFT", 0, 0)
        end
      end
    end

    -- Anchor subsequent buttons sequentially
    for i = 2, bar.count do
      local btn = _G[bar.name .. "Button" .. i]
      local prev = _G[bar.name .. "Button" .. (i - 1)]
      if btn and prev then
        btn:ClearAllPoints()
        if isVert then
          btn:SetPoint("TOP", prev, "BOTTOM", 0, -pad)
        else
          btn:SetPoint("LEFT", prev, "RIGHT", pad, 0)
        end
      end
    end
  end
end

function actionbar:resize()
  local totalWidth = 12 * self.normalButtonSize + 11 * self.buttonPadding
  if MainMenuBar then MainMenuBar:SetWidth(totalWidth) end
  if MainMenuBarMaxLevelBar then MainMenuBarMaxLevelBar:SetWidth(totalWidth) end
end

function actionbar:centerAndSize()
  local bar_width = 12 * self.normalButtonSize + 11 * self.buttonPadding

  -- MainMenuBar & BonusActionBarFrame
  MainMenuBar:ClearAllPoints()
  MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 26)
  MainMenuBar:SetWidth(bar_width)
  MainMenuBar:SetHeight(self.normalButtonSize)

  if BonusActionBarFrame then
    BonusActionBarFrame:ClearAllPoints()
    BonusActionBarFrame:SetPoint("BOTTOMLEFT", MainMenuBar, "BOTTOMLEFT", 0, 0)
    BonusActionBarFrame:SetWidth(bar_width)
    BonusActionBarFrame:SetHeight(self.normalButtonSize)
  end

  -- MultiBarBottomLeft & MultiBarBottomRight
  MultiBarBottomLeft:ClearAllPoints()
  MultiBarBottomLeft:SetWidth(bar_width)
  MultiBarBottomLeft:SetHeight(self.normalButtonSize)
  MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "TOP", 0, self.barPadding)

  MultiBarBottomRight:ClearAllPoints()
  MultiBarBottomRight:SetWidth(bar_width)
  MultiBarBottomRight:SetHeight(self.normalButtonSize)
  MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft or MainMenuBar, "TOP", 0,
    self.barPadding)

  -- Top visible bottom-bar anchor
  local topAnchor = (MultiBarBottomRight:IsVisible() and MultiBarBottomRight)
      or (MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft)
      or MainMenuBar

  -- PetActionBarFrame
  PetActionBarFrame:ClearAllPoints()
  PetActionBarFrame:SetWidth(10 * self.smallButtonSize + 9 * self.buttonPadding)
  PetActionBarFrame:SetHeight(self.smallButtonSize)
  PetActionBarFrame:SetPoint("BOTTOM", topAnchor, "TOP", 0, self.barPadding)

  -- ShapeshiftBarFrame
  local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 10
  if numForms == 0 then numForms = 10 end
  local shapeAnchor = PetActionBarFrame:IsVisible() and PetActionBarFrame or topAnchor
  ShapeshiftBarFrame:ClearAllPoints()
  ShapeshiftBarFrame:SetWidth(numForms * self.normalButtonSize + (numForms - 1) * self.buttonPadding)
  ShapeshiftBarFrame:SetHeight(self.normalButtonSize)
  ShapeshiftBarFrame:SetPoint("BOTTOM", shapeAnchor, "TOP", 0, self.barPadding)

  -- Vertical right bars (MultiBarRight and MultiBarLeft)
  local vertHeight = 12 * self.normalButtonSize + 11 * self.buttonPadding
  MultiBarRight:SetWidth(self.normalButtonSize)
  MultiBarRight:SetHeight(vertHeight)
  MultiBarRight:SetPoint("RIGHT", UIParent, "RIGHT", -5, 0)

  MultiBarLeft:SetWidth(self.normalButtonSize)
  MultiBarLeft:SetHeight(vertHeight)
  MultiBarLeft:ClearAllPoints()
  MultiBarLeft:SetPoint("TOPRIGHT", MultiBarRight, "TOPLEFT", -self.buttonPadding, 0)

  -- CastingBarFrame
  local petOffset = PetActionBarFrame:IsVisible() and (self.smallButtonSize + self.barPadding) or 0
  local shapeOffset = ShapeshiftBarFrame:IsVisible() and (self.normalButtonSize + self.barPadding) or 0
  CastingBarFrame:ClearAllPoints()
  CastingBarFrame:SetPoint("BOTTOM", topAnchor, "TOP", 0, 20 + petOffset + shapeOffset)

  -- Reapply sequential button layout with custom padding
  self:layoutButtons()
end

function actionbar:removeTextures()
  -- Strip multi-part background textures (0..3)
  local quadPrefixes = {
    "MainMenuXPBarTexture", "ReputationXPBarTexture", "ReputationWatchBarTexture",
    "MainMenuBarTexture", "MainMenuMaxLevelBar",
  }
  for _, prefix in ipairs(quadPrefixes) do
    for i = 0, 3 do
      local tex = _G[prefix .. i]
      if tex then
        tex:SetTexture(""); tex:Hide()
      end
    end
  end

  -- Strip individual frame background textures
  local staticTextures = {
    BonusActionBarTexture0, BonusActionBarTexture1, BonusActionBarTexture2,
    SlidingActionBarTexture0, SlidingActionBarTexture1,
    ShapeshiftBarLeft, ShapeshiftBarMiddle, ShapeshiftBarRight,
  }
  for _, tex in ipairs(staticTextures) do
    if tex then
      tex:SetTexture(""); tex:Hide()
    end
  end

  for i = 1, 10 do
    local btn = _G["ShapeshiftButton" .. i]
    if btn and btn.SetNormalTexture then
      btn:SetNormalTexture("")
    end
  end
end

function actionbar:hideWidget()
  if ActionBarUpButton then ActionBarUpButton:Hide() end
  if ActionBarDownButton then ActionBarDownButton:Hide() end
  if MainMenuBarPerformanceBarFrame then MainMenuBarPerformanceBarFrame:Hide() end
  if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide() end
end

function actionbar:coloringButton()
  if not OzHook or not OzHook.hook then return end

  OzHook:hook("ActionButton_OnUpdate", nil, function(elapsed)
    local dt = elapsed or arg1 or 0

    if this and this.rangeTimer then
      this.rangeTimer = this.rangeTimer - dt

      if this.rangeTimer <= 0.2 then
        local action = this.action or (ActionButton_GetPagedID and ActionButton_GetPagedID(this))

        if action and HasAction(action) then
          local name = this:GetName()
          local icon = _G[name .. "Icon"]
          local hotkey = _G[name .. "HotKey"]

          if icon then
            if IsActionInRange(action) == 0 then
              -- Out of range: Red
              icon:SetVertexColor(1.0, 0.1, 0.1, 1.0)
            elseif IsUsableAction(action) then
              -- Usable and in range: Normal white
              icon:SetVertexColor(1.0, 1.0, 1.0, 1.0)
              if hotkey then hotkey:SetTextColor(0.6, 0.6, 0.6) end
            else
              -- Out of mana / unusable: Dark gray
              icon:SetVertexColor(0.4, 0.4, 0.4, 1.0)
            end
          end
        end

        this.rangeTimer = TOOLTIP_UPDATE_TIME
      end
    end
  end)
end

function actionbar:enable()
  self:removeTextures()
  self:hideWidget()
  self:restyle()
  self:resize()
  PetActionBarFrame:SetScript("OnUpdate", nil)
  self:centerAndSize()
  self:coloringButton()

  local hookUIParent_ManageFramePositions = UIParent_ManageFramePositions
  UIParent_ManageFramePositions = function(a1, a2, a3)
    hookUIParent_ManageFramePositions(a1, a2, a3)
    OzAb.actionbar:centerAndSize()
  end

  if ShapeshiftBar_Update then
    local hook = ShapeshiftBar_Update
    ShapeshiftBar_Update = function()
      hook()
      OzAb.actionbar:centerAndSize()
    end
  end

  if ShowBonusActionBar then
    local hook = ShowBonusActionBar
    ShowBonusActionBar = function()
      hook()
      OzAb.actionbar:layoutButtons()
    end
  end

  if ShowPetActionBar then
    local hook = ShowPetActionBar
    ShowPetActionBar = function()
      hook()
      OzAb.actionbar:centerAndSize()
    end
  end
end
