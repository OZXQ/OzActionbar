if OzAb and OzAb.bags then return end
OzAb = OzAb or {}

local bags = {}
OzAb.bags = bags
local bag_buttons = {
    KeyRingButton,
    CharacterBag3Slot,
    CharacterBag2Slot,
    CharacterBag1Slot,
    CharacterBag0Slot,
    MainMenuBarBackpackButton,
}
local function set_bags_alpha(alpha)
    if bags.bag_frame then
        bags.bag_frame:SetAlpha(alpha)
    end
    for _, frame in ipairs(bag_buttons) do
        if frame then
            frame:SetAlpha(alpha)
            frame:EnableMouse(alpha > 0)
        end
    end
end

function bags:enable()
    local bag_frame = bags.bag_frame or CreateFrame("Frame", "OzBagsFrame", UIParent)
    bag_frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 26)
    bag_frame:SetWidth(240)
    bag_frame:SetHeight(42)
    bag_frame:EnableMouse(true)

    for id, frame in ipairs(bag_buttons) do
        if frame then
            local anchor = bag_buttons[id - 1] or bag_frame
            frame:ClearAllPoints()
            frame:SetPoint("RIGHT", anchor, id == 1 and "RIGHT" or "LEFT", id == 1 and 1 or 0, 0)
            frame:SetParent(bag_frame)
            frame:SetScale(0.8)
            frame:Show()
        end
    end

    bags.bag_frame = bag_frame
    set_bags_alpha(0)

    local hover_timer = 0
    bag_frame:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0
        hover_timer = hover_timer + elapsed
        if hover_timer < 0.1 then return end
        hover_timer = 0

        if MouseIsOver(bag_frame) then
            set_bags_alpha(1)
        else
            set_bags_alpha(0)
        end
    end)
end
