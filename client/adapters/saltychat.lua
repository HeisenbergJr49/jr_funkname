-- ========================================
-- SaltyChat Adapter
-- ========================================

local Adapter = {}

-- State
local currentRadioChannel = 0
local isTransmitting = false

-- SaltyChat Integration
local function getSaltyChatExports()
    return exports['saltychat']
end

-- Adapter Interface Implementation
function Adapter.initialize()
    -- Hook into SaltyChat events
    AddEventHandler('SaltyChat_RadioTrafficStateChanged', function(name, isSending)
        isTransmitting = isSending
        if Adapter.onSpeakingStart and isSending then
            Adapter.onSpeakingStart()
        elseif Adapter.onSpeakingStop and not isSending then
            Adapter.onSpeakingStop()
        end
    end)
    
    AddEventHandler('SaltyChat_TalkStateChanged', function(isTalking)
        if isTalking and currentRadioChannel > 0 then
            isTransmitting = true
            if Adapter.onSpeakingStart then
                Adapter.onSpeakingStart()
            end
        else
            isTransmitting = false
            if Adapter.onSpeakingStop then
                Adapter.onSpeakingStop()
            end
        end
    end)
end

function Adapter.joinChannel(channelId)
    local saltyChat = getSaltyChatExports()
    if not saltyChat then
        return false
    end
    
    local oldChannel = currentRadioChannel
    currentRadioChannel = channelId
    
    -- Join radio channel in SaltyChat
    saltyChat:SetRadioChannel(('Channel_%d'):format(channelId), true)
    
    -- Notify about channel change
    if Adapter.onChannelChanged then
        Adapter.onChannelChanged(oldChannel, channelId)
    end
    
    return true
end

function Adapter.leaveChannel(channelId)
    local saltyChat = getSaltyChatExports()
    if not saltyChat then
        return false
    end
    
    if currentRadioChannel == channelId then
        local oldChannel = currentRadioChannel
        currentRadioChannel = 0
        
        -- Leave radio channel in SaltyChat
        saltyChat:SetRadioChannel('', false)
        
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
    local saltyChat = getSaltyChatExports()
    if saltyChat and saltyChat.SetRadioVolume then
        saltyChat:SetRadioVolume(volume)
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