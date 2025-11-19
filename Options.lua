SchlingelOptionsDB = SchlingelOptionsDB or {}

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
        label = "Version anzeigen",
        description = "Zeigt die Versionen der Spieler:innen im Gildenchat an",
        variable = "show_version",
        value = false,
    },
}

local category = Settings.RegisterVerticalLayoutCategory("Schlingel Inc")

local function OnSettingChanged(setting, value)
    -- This callback will be invoked whenever a setting is modified.
    local key = setting:GetVariable()
    SchlingelOptionsDB[key] = value
    SchlingelOptionsDB = SchlingelOptionsDB
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
    SchlingelInc:InitializeOptionsUI()
end