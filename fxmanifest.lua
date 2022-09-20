fx_version 'cerulean'

game 'gta5'

ui_page 'html/index.html'

lua54 'yes'

files {
    'html/index.html',
    'html/main.js',
    'html/style.css',
    'html/imgs/*.jpg',
    'html/imgs/*.png'
}

client_scripts {
    'client.lua',
    'misc.lua'
}
server_scripts {
    'server.lua',
    'mm.lua'
}

data_file 'DLC_ITYP_REQUEST' 'stream/objs/house.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/objs/house.ydr'