-- ========================================
-- TokoVOIP Adapter
-- ========================================

local Adapter = {}

-- State
local currentRadioChannel = 0
local isTransmitting = false

-- TokoVOIP Integration
local function getTokoExports()
    return exports['tokovoip_script']
end

-- Adapter Interface Implementation
function Adapter.initialize()
    -- Hook into TokoVOIP events
    AddEventHandler('tokovoip:onTalkingStart', function(channel, mode)
        if mode == 'radio' then
            isTransmitting = true
            if Adapter.onSpeakingStart then
                Adapter.onSpeakingStart()
            end
        end
    end)
    
    AddEventHandler('tokovoip:onTalkingStop', function(channel, mode)
        if mode == 'radio' then
            isTransmitting = false
            if Adapter.onSpeakingStop then
                Adapter.onSpeakingStop()
            end
        end
    end)
end

function Adapter.joinChannel(channelId)
    local toko = getTokoExports()
    if not toko then
        return false
    end
    
    local oldChannel = currentRadioChannel
    currentRadioChannel = channelId
    
    -- Set radio channel in TokoVOIP
    toko:addPlayerToRadio(channelId)
    
    -- Notify about channel change
    if Adapter.onChannelChanged then
        Adapter.onChannelChanged(oldChannel, channelId)
    end
    
    return true
end

function Adapter.leaveChannel(channelId)
    local toko = getTokoExports()
    if not toko then
        return false
    end
    
    if currentRadioChannel == channelId then
        local oldChannel = currentRadioChannel
        currentRadioChannel = 0
        
        -- Remove from radio channel in TokoVOIP
        toko:removePlayerFromRadio(channelId)
        
        -- Notify about channel change
        if Adapter.onChannelChanged then
            Adapter.onChannelChanged(oldChannel, 0)
        end
    end
    
    return true
end

function Adapter.getCurrentChannel()
    return currentRadioChannel
end

function Adapter.getIsSpeaking()
    return isTransmitting
end

function Adapter.setVolume(volume)
    local toko = getTokoExports()
    if toko and toko.setPlayerRadioVolume then
        toko:setPlayerRadioVolume(volume)
    end
end

function Adapter.cleanup()
    currentRadioChannel = 0
    isTransmitting = false
end

-- Event handlers (to be set by main client)
Adapter.onSpeakingStart = nil
Adapter.onSpeakingStop = nil
Adapter.onChannelChanged = nil

return Adapter