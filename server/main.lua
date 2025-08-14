-- ========================================
-- ESX Radio Members UI - Server Main
-- Author: HeisenbergJr49
-- ========================================

ESX = exports['es_extended']:getSharedObject()

-- Server State Management
local RadioChannels = {}
local PlayerChannels = {}
local PlayerNames = {}
local RateLimiting = {}

-- Security & Performance
local function isRateLimited(playerId)
    if not Config.Security.enableRateLimit then return false end
    
    local currentTime = GetGameTimer()
    local playerData = RateLimiting[playerId]
    
    if not playerData then
        RateLimiting[playerId] = { count = 1, lastReset = currentTime }
        return false
    end
    
    -- Reset counter every second
    if currentTime - playerData.lastReset > 1000 then
        playerData.count = 1
        playerData.lastReset = currentTime
        return false
    end
    
    playerData.count = playerData.count + 1
    return playerData.count > Config.Security.maxEventsPerSecond
end

-- Player Name Resolution
local function getPlayerDisplayName(playerId)
    if PlayerNames[playerId] then
        return PlayerNames[playerId]
    end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return "Unknown" end
    
    local displayName = ""
    
    if Config.NameResolution.method == 'esx' then
        displayName = xPlayer.getName()
    elseif Config.NameResolution.method == 'ox_identity' then
        -- ox_identity integration
        local identity = exports.ox_inventory and exports.ox_inventory:GetCharacter(playerId)
        if identity then
            displayName = ("%s %s"):format(identity.firstName or "", identity.lastName or "")
        else
            displayName = xPlayer.getName()
        end
    elseif Config.NameResolution.method == 'steam' then
        displayName = GetPlayerName(playerId)
    end
    
    -- Add callsign if enabled
    if Config.NameResolution.showCallsigns and xPlayer.job then
        local callsign = xPlayer.job.grade_name or ""
        if callsign ~= "" then
            displayName = ("[%s] %s"):format(callsign, displayName)
        end
    end
    
    -- Add job title if enabled
    if Config.NameResolution.showJobTitle and xPlayer.job then
        displayName = ("%s - %s"):format(displayName, xPlayer.job.label or "")
    end
    
    -- Cache the name
    PlayerNames[playerId] = displayName
    return displayName
end

-- Channel Management
local function getChannelData(channelId)
    if not RadioChannels[channelId] then
        RadioChannels[channelId] = {
            id = channelId,
            name = ("Channel %d"):format(channelId),
            members = {},
            memberCount = 0,
            created = os.time()
        }
    end
    return RadioChannels[channelId]
end

local function removePlayerFromChannel(playerId, channelId)
    if not channelId then return end
    
    local channel = RadioChannels[channelId]
    if not channel then return end
    
    if channel.members[playerId] then
        channel.members[playerId] = nil
        channel.memberCount = channel.memberCount - 1
        PlayerChannels[playerId] = nil
        
        -- Notify remaining channel members
        for memberId, _ in pairs(channel.members) do
            TriggerClientEvent('jr_funkname:updateChannelData', memberId, channel)
        end
        
        -- Clean up empty channels (except default)
        if channel.memberCount == 0 and channelId ~= Config.Channels.defaultChannel then
            RadioChannels[channelId] = nil
        end
    end
end

local function addPlayerToChannel(playerId, channelId)
    if isRateLimited(playerId) then
        if Config.Security.logSuspiciousActivity then
            print(("[jr_funkname] Rate limited player %d"):format(playerId))
        end
        return false
    end
    
    -- Validate channel access if enabled
    if Config.Security.validateChannelAccess then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if not xPlayer then return false end
        
        -- Check reserved channels
        for _, reservedChannel in ipairs(Config.Channels.reservedChannels) do
            if channelId == reservedChannel then
                -- Add job-based access control here if needed
                local hasAccess = true -- Placeholder for job checks
                if not hasAccess then
                    TriggerClientEvent('ox_lib:notify', playerId, {
                        type = 'error',
                        description = 'Access denied to reserved channel'
                    })
                    return false
                end
            end
        end
    end
    
    -- Remove from previous channel
    if PlayerChannels[playerId] then
        removePlayerFromChannel(playerId, PlayerChannels[playerId])
    end
    
    local channel = getChannelData(channelId)
    
    -- Check member limit
    if channel.memberCount >= Config.Channels.maxMembers then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Channel is full'
        })
        return false
    end
    
    -- Add player to channel
    channel.members[playerId] = {
        id = playerId,
        name = getPlayerDisplayName(playerId),
        isSpeaking = false,
        joinTime = os.time()
    }
    channel.memberCount = channel.memberCount + 1
    PlayerChannels[playerId] = channelId
    
    -- Notify all channel members
    for memberId, _ in pairs(channel.members) do
        TriggerClientEvent('jr_funkname:updateChannelData', memberId, channel)
    end
    
    return true
end

local function updateSpeakingStatus(playerId, isSpeaking)
    local channelId = PlayerChannels[playerId]
    if not channelId then return end
    
    local channel = RadioChannels[channelId]
    if not channel or not channel.members[playerId] then return end
    
    channel.members[playerId].isSpeaking = isSpeaking
    
    -- Notify all channel members about speaking status change
    for memberId, _ in pairs(channel.members) do
        TriggerClientEvent('jr_funkname:updateMemberSpeaking', memberId, playerId, isSpeaking)
    end
end

-- Events
RegisterNetEvent('jr_funkname:playerJoinedChannel')
AddEventHandler('jr_funkname:playerJoinedChannel', function(channelId)
    local playerId = source
    addPlayerToChannel(playerId, channelId)
end)

RegisterNetEvent('jr_funkname:playerLeftChannel')
AddEventHandler('jr_funkname:playerLeftChannel', function(channelId)
    local playerId = source
    removePlayerFromChannel(playerId, channelId)
end)

RegisterNetEvent('jr_funkname:updateSpeakingStatus')
AddEventHandler('jr_funkname:updateSpeakingStatus', function(isSpeaking)
    local playerId = source
    updateSpeakingStatus(playerId, isSpeaking)
end)

RegisterNetEvent('jr_funkname:requestChannelData')
AddEventHandler('jr_funkname:requestChannelData', function()
    local playerId = source
    local channelId = PlayerChannels[playerId]
    
    if channelId then
        local channel = getChannelData(channelId)
        TriggerClientEvent('jr_funkname:updateChannelData', playerId, channel)
    end
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local playerId = source
    local channelId = PlayerChannels[playerId]
    
    if channelId then
        removePlayerFromChannel(playerId, channelId)
    end
    
    -- Clean up cached data
    PlayerNames[playerId] = nil
    RateLimiting[playerId] = nil
end)

-- Performance cleanup task
CreateThread(function()
    while true do
        Wait(Config.Performance.cleanupInterval)
        
        -- Clean up old rate limiting data
        local currentTime = GetGameTimer()
        for playerId, data in pairs(RateLimiting) do
            if currentTime - data.lastReset > 60000 then -- 1 minute old
                RateLimiting[playerId] = nil
            end
        end
        
        -- Clean up disconnected players' cached names
        local activePlayers = {}
        for _, playerId in ipairs(GetPlayers()) do
            activePlayers[tonumber(playerId)] = true
        end
        
        for playerId, _ in pairs(PlayerNames) do
            if not activePlayers[playerId] then
                PlayerNames[playerId] = nil
            end
        end
        
        if Config.Performance.enableDebugMode then
            print(("[jr_funkname] Cleanup completed. Channels: %d, Cached names: %d"):format(
                #RadioChannels, #PlayerNames
            ))
        end
    end
end)

-- Initialize
print('[jr_funkname] Server initialized successfully')