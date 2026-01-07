-- MiniMapIcon.lua
-- Creates and manages the minimap icon for the addon

-- Load required libraries for the minimap icon. 'true' suppresses errors if not found.
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)

-- Data object for the minimap icon
if LDB then -- Only proceeds if LibDataBroker is available
    SchlingelInc.minimapDataObject = LDB:NewDataObject(SchlingelInc.name, {
        type = "launcher",                                                 -- LDB object type: Launches a UI or function
        label = SchlingelInc.name,                                         -- Text next to icon (often only visible in LDB display addons)
        icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga", -- Path to icon
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    SchlingelInc:ToggleDeathLogWindow()
                    return
                end
                if SchlingelInc.ToggleInfoWindow then
                    SchlingelInc:ToggleInfoWindow()
                    return
                end
            elseif button == "RightButton" then
                if CanGuildInvite() then
                    if SchlingelInc.ToggleInactivityWindow then
                        SchlingelInc:ToggleInactivityWindow()
                    end
                end
            end
        end,

        -- Tooltip shown when hovering over the icon
        OnEnter = function(selfFrame)
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")                                    -- Position tooltip to the right of icon
            GameTooltip:AddLine(SchlingelInc.name, 1, 0.7, 0.9)                                -- Addon name in tooltip
            GameTooltip:AddLine("Version: " .. (SchlingelInc.version or "Unknown"), 1, 1, 1)  -- Version in tooltip
            GameTooltip:AddLine("Left-click: Show info", 1, 1, 1)                              -- Left-click hint
            GameTooltip:AddLine("Shift + Left-click: Death log", 1, 1, 1)                      -- Shift + Left-click hint
            if CanGuildInvite() then
                GameTooltip:AddLine("Right-click: Inactive members", 0.8, 0.8, 0.8)            -- Right-click hint
            end
            GameTooltip:Show()
        end,
        OnLeave = function()
            GameTooltip:Hide()
        end
    })
else
    -- Output message if LibDataBroker was not found
    SchlingelInc:Print("LibDataBroker-1.1 not found. Minimap icon will not be created.")
end

-- Initializes the minimap icon
function SchlingelInc:InitMinimapIcon()
    -- Abort if LibDBIcon or the LDB data object are not available
    if not DBIcon or not SchlingelInc.minimapDataObject then
        SchlingelInc:Print("LibDBIcon-1.0 or LDB data object not found. Minimap icon will not be initialized.")
        return
    end

    -- Register the icon only once
    if not SchlingelInc.minimapRegistered then
        -- Initialize the database for minimap settings if not present
        SchlingelInc.db = SchlingelInc.db or {}
        SchlingelInc.db.minimap = SchlingelInc.db.minimap or { hide = false } -- Not hidden by default

        -- Register the icon with LibDBIcon
        DBIcon:Register(SchlingelInc.name, SchlingelInc.minimapDataObject, SchlingelInc.db.minimap)
        SchlingelInc.minimapRegistered = true -- Mark icon as registered
        SchlingelInc:Print("Minimap icon registered.")
    end
end