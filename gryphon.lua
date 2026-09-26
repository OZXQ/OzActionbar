if OzAb and OzAb.gryphon then return end
OzAb = OzAb or {}

local gryphon = {}
OzAb.gryphon = gryphon

function gryphon:enable()
    MainMenuBarLeftEndCap:Hide()
    MainMenuBarRightEndCap:Hide()
    MainMenuBarLeftEndCap.Show = function() end
    MainMenuBarRightEndCap.Show = function() end
end
