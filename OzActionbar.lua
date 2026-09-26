OzAb = OzAb or {}

OzAb.frame = OzAb.frame or CreateFrame("Frame")
local oz_frame = OzAb.frame
oz_frame:RegisterEvent("VARIABLES_LOADED")
oz_frame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        OzAb.actionbar:enable()
        OzAb.bags:enable()
        OzAb.microbar:enable()
        OzAb.xpbar:enable()
        OzAb.repbar:enable()
        OzAb.gryphon:enable()
    end
end)
