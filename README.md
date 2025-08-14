# ESX Radio Members UI

A comprehensive ESX script that provides a live display of radio participants with modern NUI interface and multi-voice system support.

## Features

- **Live Radio Participant Display**: Real-time view of all players in your radio channel
- **Multi-Voice System Support**: Compatible with pma-voice, SaltyChat, and TokoVOIP
- **Modern NUI Interface**: Sleek, animated UI panel positioned on the left side of the screen
- **Authoritative Server Management**: Server-side channel state management with anti-spoofing
- **Real-time Updates**: Instant join/leave/speaking status updates without polling
- **ESX Integration**: Full integration with ESX framework and ox_identity
- **Security Features**: Rate limiting, access validation, and suspicious activity logging
- **Multi-language Support**: German and English localization included
- **Configurable Settings**: Extensive configuration options for customization

## Dependencies

- [ESX Framework](https://github.com/esx-framework/esx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- Voice system (pma-voice, SaltyChat, or TokoVOIP)

## Installation

1. Download the latest release
2. Extract to your resources folder as `jr_funkname`
3. Add `ensure jr_funkname` to your server.cfg
4. Configure the script in `config.lua`
5. Restart your server

## Configuration

The script is highly configurable through `config.lua`:

### Voice System Configuration
```lua
Config.VoiceSystem = 'pma-voice' -- 'pma-voice', 'saltychat', 'toko'
Config.AutoDetectVoiceSystem = true
```

### UI Configuration
```lua
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
```

### Keybinds
```lua
Config.Keybinds = {
    toggleUI = 'J',
    toggleMiniMode = 'K'
}
```

### Name Resolution
```lua
Config.NameResolution = {
    method = 'esx', -- 'esx', 'ox_identity', 'steam'
    showCallsigns = true,
    showJobTitle = false,
    anonymizeMode = false
}
```

### Security Settings
```lua
Config.Security = {
    enableRateLimit = true,
    maxEventsPerSecond = 10,
    validateChannelAccess = true,
    logSuspiciousActivity = true
}
```

## Usage

### Default Keybinds
- **J**: Toggle Radio UI
- **K**: Toggle Mini Mode
- **ESC**: Close UI (when open)

### Joining a Channel
1. Press J to open the radio UI
2. Enter a channel number (1-999)
3. Click "Join" or press Enter
4. The UI will display all members in the channel

### Leaving a Channel
- Click "Leave Channel" button in the UI
- Or disconnect from your radio in the voice system

## Voice System Support

### pma-voice (Primary)
- Full integration with pma-voice events
- Automatic speaking status detection
- Volume control support

### SaltyChat
- Compatible with SaltyChat radio system
- Speaking state monitoring
- Channel management integration

### TokoVOIP  
- Support for TokoVOIP radio functionality
- Event-based speaking detection
- Channel switching support

### Fallback Mode
- Dummy adapter for testing without voice systems
- Basic functionality for development purposes

## API Events

### Client Events
```lua
-- Update channel data
TriggerClientEvent('jr_funkname:updateChannelData', playerId, channelData)

-- Update member speaking status
TriggerClientEvent('jr_funkname:updateMemberSpeaking', playerId, memberId, isSpeaking)
```

### Server Events
```lua
-- Player joins channel
TriggerServerEvent('jr_funkname:playerJoinedChannel', channelId)

-- Player leaves channel  
TriggerServerEvent('jr_funkname:playerLeftChannel', channelId)

-- Update speaking status
TriggerServerEvent('jr_funkname:updateSpeakingStatus', isSpeaking)

-- Request channel data
TriggerServerEvent('jr_funkname:requestChannelData')
```

## File Structure

```
jr_funkname/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Configuration file
├── server/
│   └── main.lua            # Server-side logic
├── client/
│   ├── main.lua            # Client-side logic
│   └── adapters/           # Voice system adapters
│       ├── pma-voice.lua   # pma-voice adapter
│       ├── saltychat.lua   # SaltyChat adapter
│       ├── toko.lua        # TokoVOIP adapter
│       └── dummy.lua       # Fallback adapter
├── html/
│   ├── index.html          # NUI interface
│   ├── style.css           # UI styles
│   └── script.js           # UI functionality
├── locales/
│   ├── de.lua              # German translations
│   └── en.lua              # English translations
└── README.md               # This file
```

## Performance

- **Optimized Updates**: Diff-based updates without polling
- **Memory Efficient**: Automatic cleanup of disconnected players
- **Rate Limited**: Protection against spam and abuse
- **Configurable Intervals**: Adjustable update frequencies

## Security

- **Anti-Spoofing**: Server-side validation of all actions
- **Rate Limiting**: Prevents abuse and spam
- **Access Control**: Configurable channel restrictions
- **Activity Logging**: Optional logging of suspicious activity

## Troubleshooting

### Common Issues

1. **UI not appearing**
   - Check if ox_lib is installed and running
   - Verify keybind configuration
   - Check F8 console for errors

2. **Voice system not detected**
   - Ensure your voice system is running
   - Check Config.AutoDetectVoiceSystem setting
   - Verify voice system name in config

3. **Names not showing correctly**
   - Check Config.NameResolution.method setting
   - Verify ESX/ox_identity is working
   - Check database permissions

### Debug Mode

Enable debug mode in config.lua:
```lua
Config.Performance = {
    enableDebugMode = true
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and issues:
- Create an issue on GitHub
- Join our Discord server
- Check the documentation wiki

## Credits

- **Author**: HeisenbergJr49
- **Framework**: ESX Framework
- **UI Library**: ox_lib
- **Voice Systems**: pma-voice, SaltyChat, TokoVOIP

## Version History

### v1.0.0
- Initial release
- Multi-voice system support
- Modern NUI interface
- Complete ESX integration
- Security features
- Multi-language support