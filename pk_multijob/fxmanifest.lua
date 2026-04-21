fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'

name        'pk_multijob'
description 'Multi Job System for VORP - PK Edition'
version     '1.0.0'

dependencies {
    'vorp_core',
    'tpz_menu_base',
    'oxmysql',
}

shared_scripts {
    'shared/config.lua',
}

client_scripts {
    'client/menu.lua',
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}
