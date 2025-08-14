-- ========================================
-- ESX Radio Members UI - Client Main
-- Author: HeisenbergJr49
-- ========================================

ESX = exports['es_extended']:getSharedObject()

-- State Management
local currentChannel = nil
local channelData = {}
local isUIVisible = false
local isMiniMode = false
local voiceAdapter = nil

-- Initialize ox_lib
local lib = exports.ox_lib

-- Voice System Detection
local function detectVoiceSystem()
    if Config.VoiceSystem ~= 'auto' and not Config.AutoDetectVoiceSystem then
        return Config.VoiceSystem
    end
    
    -- Auto-detection logic
    if GetResourceState('pma-voice') == 'started' then
        return 'pma-voice'
    elseif GetResourceState('saltychat') == 'started' then
        return 'saltychat'  
    elseif GetResourceState('tokovoip') == 'started' then
        return 'toko'
    end
    
    return 'pma-voice' -- Default fallback
end

-- Voice Adapter Factory
local function createVoiceAdapter(system)
    if system == 'pma-voice' then
        return dofile(GetResourcePath(GetCurrentResourceName()) .. '/client/adapters/pma-voice.lua')
    elseif system == 'saltychat' then
        return dofile(GetResourcePath(GetCurrentResourceName()) .. '/client/adapters/saltychat.lua')
    elseif system == 'toko' then
        return dofile(GetResourcePath(GetCurrentResourceName()) .. '/client/adapters/toko.lua')
    end
    
    -- Fallback to dummy adapter
    return dofile(GetResourcePath(GetCurrentResourceName()) .. '/client/adapters/dummy.lua')
end

-- NUI Management
local function toggleUI()
    isUIVisible = not isUIVisible
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'setVisible',
        visible = isUIVisible
    })
end

local function toggleMiniMode()
    isMiniMode = not isMiniMode
    SendNUIMessage({
        type = 'setMiniMode',
        miniMode = isMiniMode
    })
end

local function updateUIData(data)
    SendNUIMessage({
        type = 'updateChannelData',
        data = data
    })
end

local function updateMemberSpeaking(playerId, isSpeaking)
    SendNUIMessage({
        type = 'updateMemberSpeaking',
        playerId = playerId,
        isSpeaking = isSpeaking
    })
end

-- Channel Management
local function joinChannel(channelId)
    if voiceAdapter and voiceAdapter.joinChannel then
        local success = voiceAdapter.joinChannel(channelId)
        if success then
            currentChannel = channelId
            TriggerServerEvent('jr_funkname:playerJoinedChannel', channelId)
            
            lib:notify({
                type = 'success',
                description = ('Joined channel %d'):format(channelId)
            })
        else
            lib:notify({
                type = 'error',
                description = 'Failed to join channel'
            })
        end
    end
end

local function leaveChannel()
    if currentChannel and voiceAdapter and voiceAdapter.leaveChannel then
        voiceAdapter.leaveChannel(currentChannel)
        TriggerServerEvent('jr_funkname:playerLeftChannel', currentChannel)
        currentChannel = nil
        channelData = {}
        
        lib:notify({
            type = 'info',
            description = 'Left channel'
        })
        
        updateUIData({})
    end
end

-- Voice Events Handler
local function onSpeakingStart()
    if currentChannel then
        TriggerServerEvent('jr_funkname:updateSpeakingStatus', true)
    end
end

local function onSpeakingStop()
    if currentChannel then
        TriggerServerEvent('jr_funkname:updateSpeakingStatus', false)
    end
end

local function onChannelChanged(oldChannel, newChannel)
    if oldChannel and oldChannel ~= 0 then
        TriggerServerEvent('jr_funkname:playerLeftChannel', oldChannel)
    end
    
    if newChannel and newChannel ~= 0 then
        currentChannel = newChannel
        TriggerServerEvent('jr_funkname:playerJoinedChannel', newChannel)
    else
        currentChannel = nil
        channelData = {}
        updateUIData({})
    end
end

-- Server Events
RegisterNetEvent('jr_funkname:updateChannelData')
AddEventHandler('jr_funkname:updateChannelData', function(data)
    channelData = data
    updateUIData(data)
end)

RegisterNetEvent('jr_funkname:updateMemberSpeaking')
AddEventHandler('jr_funkname:updateMemberSpeaking', function(playerId, isSpeaking)
    updateMemberSpeaking(playerId, isSpeaking)
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    toggleUI()
    cb('ok')
end)

RegisterNUICallback('joinChannel', function(data, cb)
    joinChannel(data.channelId)
    cb('ok')
end)

RegisterNUICallback('leaveChannel', function(data, cb)
    leaveChannel()
    cb('ok')
end)

-- Keybind Registration
local function registerKeybinds()
    lib:registerKeyBind({
        name = 'jr_funkname_toggle',
        description = 'Toggle Radio UI',
        defaultKey = Config.Keybinds.toggleUI,
        onPressed = function()
            toggleUI()
        end
    })
    
    lib:registerKeyBind({
        name = 'jr_funkname_mini',
        description = 'Toggle Mini Mode',
        defaultKey = Config.Keybinds.toggleMiniMode,
        onPressed = function()
            toggleMiniMode()
        end
    })
end

-- Resource Management
local function initializeResource()
    -- Detect and create voice adapter
    local detectedSystem = detectVoiceSystem()
    voiceAdapter = createVoiceAdapter(detectedSystem)
    
    if voiceAdapter then
        -- Register voice event handlers
        if voiceAdapter.onSpeakingStart then
            voiceAdapter.onSpeakingStart = onSpeakingStart
        end
        
        if voiceAdapter.onSpeakingStop then
            voiceAdapter.onSpeakingStop = onSpeakingStop
        end
        
        if voiceAdapter.onChannelChanged then
            voiceAdapter.onChannelChanged = onChannelChanged
        end
        
        -- Initialize voice adapter
        if voiceAdapter.initialize then
            voiceAdapter.initialize()
        end
    end
    
    -- Register keybinds
    registerKeybinds()
    
    -- Request initial channel data if player is in a channel
    Wait(1000) -- Wait for ESX to load
    TriggerServerEvent('jr_funkname:requestChannelData')
    
    print('[jr_funkname] Client initialized with voice system: ' .. detectedSystem)
end

-- Cleanup on resource stop
local function cleanupResource()
    if currentChannel then
        leaveChannel()
    end
    
    if voiceAdapter and voiceAdapter.cleanup then
        voiceAdapter.cleanup()
    end
end

-- Thread for periodic updates
CreateThread(function()
    while true do
        Wait(Config.Performance.updateInterval)
        
        -- Update speaking status if voice adapter supports it
        if voiceAdapter and voiceAdapter.getIsSpeaking and currentChannel then
            local isSpeaking = voiceAdapter.getIsSpeaking()
            if isSpeaking ~= nil then
                TriggerServerEvent('jr_funkname:updateSpeakingStatus', isSpeaking)
            end
        end
    end
end)

-- Resource Events
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        initializeResource()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupResource()
    end
end)

-- Initialize if resource is already started
CreateThread(function()
    Wait(100)
    if GetResourceState(GetCurrentResourceName()) == 'started' then
        initializeResource()
    end
end)