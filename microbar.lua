if OzAb and OzAb.microbar then return end
OzAb = OzAb or {}

local microbar = {}
OzAb.microbar = microbar
local micro_buttons = {
    CharacterMicroButton,
    SpellbookMicroButton,
    TalentMicroButton,
    QuestLogMicroButton,
    SocialsMicroButton,
    WorldMapMicroButton,
    MainMenuMicroButton,
    HelpMicroButton,
}
local function set_microbar_alpha(alpha)
    if microbar.frame then
        microbar.frame:SetAlpha(alpha)
    end
    for _, button in ipairs(micro_buttons) do
        if button then
            button:SetAlpha(alpha)
            button:EnableMouse(alpha > 0)
        end
    end
end

function microbar:enable()
    local microbar_frame = microbar.frame or CreateFrame("Frame", "OzmicrobarFrame", UIParent)
    microbar_frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    microbar_frame:SetWidth(210)
    microbar_frame:SetHeight(50)
    microbar_frame:EnableMouse(true)

    for id, button in ipairs(micro_buttons) do
        if button then
            local anchor = micro_buttons[id - 1] or microbar_frame
            button:ClearAllPoints()
            button:SetPoint("RIGHT", anchor, id == 1 and "RIGHT" or "LEFT", id == 1 and 1 or 0, 0)
            button:SetParent(microbar_frame)
            button:SetScale(0.8)
            button:Show()
        end
    end

    microbar.frame = microbar_frame
    set_microbar_alpha(0)

    local hover_timer = 0
    microbar_frame:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0
        hover_timer = hover_timer + elapsed
        if hover_timer < 0.08 then return end
        hover_timer = 0

        if MouseIsOver(microbar_frame) then
            set_microbar_alpha(1)
        else
            set_microbar_alpha(0)
        end
    end)
end
