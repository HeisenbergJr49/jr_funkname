Config = {}

-- Voice System Configuration
Config.VoiceSystem = 'pma-voice' -- 'pma-voice', 'saltychat', 'toko'
Config.AutoDetectVoiceSystem = true

-- UI Configuration
Config.UI = {
    position = 'left', -- 'left', 'right'
    width = 320,
    maxHeight = 600,
    showHeader = true,
    showMemberCount = true,
    showChannelName = true,
    animations = true,
    theme = 'dark' -- 'dark', 'light'
}

-- Keybinds
Config.Keybinds = {
    toggleUI = 'J',
    toggleMiniMode = 'K'
}

-- Name Resolution
Config.NameResolution = {
    method = 'esx', -- 'esx', 'ox_identity', 'steam'
    showCallsigns = true,
    showJobTitle = false,
    anonymizeMode = false
}

-- Channel Settings
Config.Channels = {
    maxMembers = 50,
    allowJobRestricted = true,
    defaultChannel = 1,
    reservedChannels = {10, 11, 12} -- Police, EMS, etc.
}

-- Security
Config.Security = {
    enableRateLimit = true,
    maxEventsPerSecond = 10,
    validateChannelAccess = true,
    logSuspiciousActivity = true
}

-- Performance
Config.Performance = {
    updateInterval = 500, -- ms
    maxCachedNames = 200,
    cleanupInterval = 60000, -- ms
    enableDebugMode = false
}