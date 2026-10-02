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

function bags:enable()
    local bag_frame = bags.bag_frame or CreateFrame("Frame", "OzBagsFrame", UIParent)
    bag_frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 26)
    bag_frame:SetWidth(240)
    bag_frame:SetHeight(42)
    bag_frame:SetAlpha(0.6)
    bag_frame:EnableMouse(true)

    for id, frame in ipairs(bag_buttons) do
        if frame then
            local anchor = bag_buttons[id - 1] or bag_frame
            frame:ClearAllPoints()
            frame:SetPoint("RIGHT", anchor, id == 1 and "RIGHT" or "LEFT", id == 1 and 1 or 0, 0)
            frame:SetParent(bag_frame)
            frame:SetScale(0.8)
            frame:SetAlpha(1)
            frame:EnableMouse(true)
            frame:Show()
        end
    end

    bags.bag_frame = bag_frame
end
