-- ========================================
-- PMA-Voice Adapter
-- ========================================

local Adapter = {}

-- State
local currentRadioChannel = 0
local isTransmitting = false

-- PMA-Voice Integration
local function getPMAVoiceExports()
    return exports['pma-voice']
end

-- Adapter Interface Implementation
function Adapter.initialize()
    -- Hook into pma-voice events
    AddEventHandler('pma-voice:setTalkingOnRadio', function(talking)
        isTransmitting = talking
        if Adapter.onSpeakingStart and talking then
            Adapter.onSpeakingStart()
        elseif Adapter.onSpeakingStop and not talking then
            Adapter.onSpeakingStop()
        end
    end)
    
    AddEventHandler('pma-voice:radioActive', function(radioTalking)
        isTransmitting = radioTalking
    end)
end

function Adapter.joinChannel(channelId)
    local pmaVoice = getPMAVoiceExports()
    if not pmaVoice then
        return false
    end
    
    local oldChannel = currentRadioChannel
    currentRadioChannel = channelId
    
    -- Set radio channel in pma-voice
    pmaVoice:setRadioChannel(channelId)
    
    -- Notify about channel change
    if Adapter.onChannelChanged then
        Adapter.onChannelChanged(oldChannel, channelId)
    end
    
    return true
end

function Adapter.leaveChannel(channelId)
    local pmaVoice = getPMAVoiceExports()
    if not pmaVoice then
        return false
    end
    
    if currentRadioChannel == channelId then
        local oldChannel = currentRadioChannel
        currentRadioChannel = 0
        
        -- Leave radio in pma-voice
        pmaVoice:setRadioChannel(0)
        
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
    local pmaVoice = getPMAVoiceExports()
    if pmaVoice and pmaVoice.setRadioVolume then
        pmaVoice:setRadioVolume(volume)
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