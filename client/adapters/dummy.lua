-- ========================================
-- Dummy Voice Adapter (Fallback)
-- ========================================

local Adapter = {}

-- State
local currentRadioChannel = 0
local isTransmitting = false

-- Dummy Implementation (for testing without voice systems)
function Adapter.initialize()
    print('[jr_funkname] Using dummy voice adapter - no voice system detected')
end

function Adapter.joinChannel(channelId)
    local oldChannel = currentRadioChannel
    currentRadioChannel = channelId
    
    -- Simulate successful join
    print(('[jr_funkname] Dummy adapter: Joined channel %d'):format(channelId))
    
    -- Notify about channel change
    if Adapter.onChannelChanged then
        Adapter.onChannelChanged(oldChannel, channelId)
    end
    
    return true
end

function Adapter.leaveChannel(channelId)
    if currentRadioChannel == channelId then
        local oldChannel = currentRadioChannel
        currentRadioChannel = 0
        
        print(('[jr_funkname] Dummy adapter: Left channel %d'):format(channelId))
        
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
    print(('[jr_funkname] Dummy adapter: Set volume to %d'):format(volume))
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