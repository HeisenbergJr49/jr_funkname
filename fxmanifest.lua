fx_version 'cerulean'
game 'gta5'

author 'HeisenbergJr49'
description 'ESX Radio Members UI'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/**/*.lua'
}

server_scripts {
    'server/**/*.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'locales/de.lua',
    'locales/en.lua'
}

ui_page 'html/index.html'

dependencies {
    'es_extended',
    'ox_lib'
}