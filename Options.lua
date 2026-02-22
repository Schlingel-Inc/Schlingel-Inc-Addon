-- Options.lua
-- Manages addon settings through the WoW Settings API

SchlingelOptionsDB = SchlingelOptionsDB or {}

-- UI options configuration
-- Each option has a label, description, variable name, and default value
local UIOptions =
{
    {
        label = "PVP Warnung",
        description = "Aktiviert die PVP Warnung",
        variable = "pvp_alert",
        value = true,
    },
    {
        label = "PVP Warnung Ton",
        description = "Aktiviert den Ton für die PVP Warnung",
        variable = "pvp_alert_sound",
        value = true,
    },
    {
        label = "Todesmeldungen",
        description = "Aktiviert die Todesmeldungen",
        variable = "deathmessages",
        value = true,
    },
    {
        label = "Todesmeldungen Ton",
        description = "Aktiviert den Ton für die Todesmeldungen",
        variable = "deathmessages_sound",
        value = true,
    },
    {
        label = "Level-Up Meldungen",
        description = "Aktiviert die Level-Up Meldungen",
        variable = "levelmessages",
        value = true,
    },
    {
        label = "Level-Up Meldungen Ton",
        description = "Aktiviert den Ton für die Level-Up Meldungen",
        variable = "levelmessages_sound",
        value = true,
    },
    {
        label = "Cap-Meldungen",
        description = "Aktiviert die Level-Cap Meldungen",
        variable = "capmessages",
        value = true,
    },
    {
        label = "Cap-Meldungen Ton",
        description = "Aktiviert den Ton für die Level-Cap Meldungen",
        variable = "capmessages_sound",
        value = true,
    },
    {
        label = "Version anzeigen",
        description = "Zeigt die Versionen der Spieler:innen im Gildenchat an",
        variable = "show_version",
        value = false,
    },
    {
        label = "Duelle Ablehnen",
        description = "Lehnt automatisch alle Duell-Anfragen ab",
        variable = "auto_decline_duels",
        value = false,
    },
    {
        label = "Discord Handle im Gildenchat anzeigen",
        description = "Zeigt deinen Discord Handle im Gildenchat an",
        variable = "show_discord_handle",
        value = false,
    }
}

local category = Settings.RegisterVerticalLayoutCategory("Schlingel Inc")

local function OnSettingChanged(setting, value)
    -- This callback will be invoked whenever a setting is modified.
    local key = setting:GetVariable()
    SchlingelOptionsDB[key] = value
    SchlingelOptionsDB = SchlingelOptionsDB
end

local function GetSoundPackOptions()
    local container = Settings.CreateControlTextContainer()
    container:Add("standard", "Standard")
    container:Add("torro", "Coole Torro Sounds")
    return container:GetData()
end

function SchlingelInc:InitializeOptionsUI()
    for _, setting in ipairs(UIOptions) do
        local name = setting.label
        local variable = setting.variable
        local variableKey = setting.variable
        local variableTbl = SchlingelOptionsDB
        local defaultValue = setting.value

        -- Register the setting with the Settings API.
        local settingObj = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
            name,
            defaultValue, setting.value)

        -- Set a callback for when the setting changes.
        settingObj:SetValueChangedCallback(OnSettingChanged)

        -- Create a checkbox for the setting.
        Settings.CreateCheckbox(category, settingObj, setting.description)
    end

    -- Dropdown for sound pack selection
    local soundPackSetting = Settings.RegisterAddOnSetting(category, "sound_pack", "sound_pack", SchlingelOptionsDB,
        type(""), "Soundpaket", SchlingelOptionsDB["sound_pack"] or "standard")
    soundPackSetting:SetValueChangedCallback(OnSettingChanged)
    Settings.CreateDropdown(category, soundPackSetting, GetSoundPackOptions,
        "Wähle zwischen Standard WoW Sounds und coolen Torro Sounds")
end

Settings.RegisterAddOnCategory(category)

function SchlingelInc:InitializeOptionsDB()
    -- Initialize all options with default values if not present
    for _, setting in ipairs(UIOptions) do
        if SchlingelOptionsDB[setting.variable] == nil then
            SchlingelOptionsDB[setting.variable] = setting.value
        else
            setting.value = SchlingelOptionsDB[setting.variable]
        end
    end
    if SchlingelOptionsDB["sound_pack"] == nil then
        SchlingelOptionsDB["sound_pack"] = "standard"
    end
    SchlingelInc:InitializeOptionsUI()
end