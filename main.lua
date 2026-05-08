local d = function(...) end

local addon = {
    name = 'ImmersiveDialogue',
    displayName = 'Immersive Dialogue',
    author = '@imPDA',
    verison = 1,
}

local EVENT_NAMESPACE = addon.name


local function InitializeMenu()
    local panelData = {
        type = 'panel',
        name = addon.name,
        displayName = addon.displayName,
        author = addon.author,
        version = addon.verison,
        -- registerForRefresh = true,
        -- registerForDefaults = true,
    }

    local optionsData = {}
    optionsData[#optionsData+1] = {
        type = 'checkbox',
        name = 'Disable Nameplate',
        tooltip = 'Toggle this to disable showing the nameplate.',
        getFunc = function() return ImmersiveGamePadDialogue_SavedVars.disableNameplate end,
        setFunc = function(value)
            ImmersiveGamePadDialogue_SavedVars.disableNameplate = value 
        end,
        requiresReload = false,
        default = false,
    }

    optionsData[#optionsData+1] = {
        type = 'checkbox',
        name = 'Disable Background',
        tooltip = 'Toggle this to disable showing the background.',
        getFunc = function() return ImmersiveGamePadDialogue_SavedVars.disableBackground end,
        setFunc = function(value)
            ImmersiveGamePadDialogue_SavedVars.disableBackground = value 
        end,
        requiresReload = false,
        default = false,
    }

    optionsData[#optionsData+1] = {
        type = 'checkbox',
        name = 'Disable Keybind strip',
        tooltip = 'Toggle this to disable showing the keybind strip.',
        getFunc = function() return ImmersiveGamePadDialogue_SavedVars.disableKeybindStrip end,
        setFunc = function(value)
            ImmersiveGamePadDialogue_SavedVars.disableKeybindStrip = value 
        end,
        requiresReload = false,
        default = false,
    }

    local LAM = LibAddonMenu2
    local settingsPanelName = addon.name .. 'SettingsPanel'
    LAM:RegisterAddonPanel(settingsPanelName, panelData)
    LAM:RegisterOptionControls(settingsPanelName, optionsData)
end


-- local function OnChatterBegin(_, chatterOptionCount, debugSource)
--     -- Catching a rogue event coming down that causes a UI error when a bad option count is passed down.  Root cause still unknown, this will just suppress the error.
--     -- ESO-692130
--     if internalassert(chatterOptionCount <= MAX_CHATTER_OPTIONS, string.format('Tried to begin a chatter from source type %d with %d chatter options, which is invalid. Please notify a UI engineer.', debugSource, chatterOptionCount)) then
--         self:InitializeInteractWindow(GetChatterGreeting())
--         self:UpdateChatterOptions(chatterOptionCount, HIDE_BACK_TO_TOC_OPTION)
--     end
-- end

-- EVENT_CLIENT_INTERACT_RESULT

local whitelist = {}

whitelist[CHATTER_START_TRADINGHOUSE] = true
whitelist[CHATTER_START_STABLE] = true
whitelist[CHATTER_START_SHOP] = true


local IS, IF  -- interact scene, interact fragment


function addon:ShouldHideDialogue()
    for o = 1, GetChatterOptionCount() do
        local optionString, optionType, optionalArgument, isImportant, chosenBefore, teleportNPC, dialogueTone = GetChatterOption(o)
        d(optionString, optionType)

        if self.whitelist[optionType] then
           return false
        end

        -- if optionType == CHATTER_START_SHOP then
        --     if optionString == 'Store (Pledge Master)' then  -- TODO: for other languages
        --         return false
        --     end
        -- end
    end

    return true
end

function ImmersiveDialogue_ShowDialogue()
    d('ImmersiveDialogue_ShowDialogue')
    if SCENE_MANAGER.currentScene ~= IS then return end

    IF:Show()
end

local IMMERSIVE_DIALOGUE_BUTTON_GROUP = {
    {
        name = 'Show Dialogue',
        keybind = 'UI_SHORTCUT_QUATERNARY',
        callback = ImmersiveDialogue_ShowDialogue,
    },
    alignment = KEYBIND_STRIP_ALIGN_CENTER,
}

function addon:DialogueUpdated()
    -- EVENT_CHATTER_BEGIN
    d('Chatter begin')

    if self:ShouldHideDialogue() then
        IF:Hide()

        if IsInGamepadPreferredMode() or IsConsoleUI() then
            KEYBIND_STRIP:AddKeybindButtonGroup(IMMERSIVE_DIALOGUE_BUTTON_GROUP)
        end
    end
end

-- for o = 1, GetChatterOptionCount() do
--     local optionType = select(2, GetChatterOption(o))
--     if optionType == CHATTER_START_STABLE then
--         SelectChatterOption(o)
--         break
--     end
-- end

function addon:OnVOPlayingStateChanged()
    d('VOPlayingStateChanged')

    local isPlaying = IsInteractVOPlaying()
    d(tostring(isPlaying))

    if isPlaying then return end
    if SCENE_MANAGER.currentScene ~= IS then return end

    IF:Show()
end


function addon:Initialize()
    self.whitelist = whitelist

    if IsInGamepadPreferredMode() then
        IS = SCENE_MANAGER:GetScene('gamepadInteract')
        IF = GAMEPAD_INTERACT_FRAGMENT
    else
        IS = SCENE_MANAGER:GetScene('interact')
        IF = INTERACT_FRAGMENT
    end

    -- self.hideInteractWindow = true

    -- ZO_PreHook(INTERACT_WINDOW, 'ShowInteractWindow', function()
    --     d('INTERACT_WINDOW:ShowInteractWindow')
    --     return self.hideInteractWindow
    -- end)

    -- INTERACT_FRAGMENT.alwaysAnimate = true

	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_CHATTER_BEGIN, function() self:DialogueUpdated() end )
	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_QUEST_OFFERED, function() self:DialogueUpdated() end )
	EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_CONVERSATION_UPDATED, function() self:DialogueUpdated() end )
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_INTERACT_VO_PLAYING_STATE_UPDATED, function() self:OnVOPlayingStateChanged() end)
end

-- ----------------------------------------------------------------------------

local function OnAddonLoaded(_, addonName)
    if addonName ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED)

    addon:Initialize()
end

EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED, OnAddonLoaded)