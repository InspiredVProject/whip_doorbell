fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'whip_doorbell'
description 'Vista Home doorbell for WHIP: inventory, phone and voice intercom'
version '2.0.7'
dependencies { 'whip_core', 'whip_phone', 'whip_voice' }
shared_scripts { '@whip_core/lib/satellite.lua', 'config.lua', 'settings.lua' }
server_scripts { 'server/bridge.lua', 'server/main.lua' }
client_script 'client/main.lua'
ui_page 'html/index.html'
data_file 'DLC_ITYP_REQUEST' 'stream/vista_doorbell.ytyp'
files { 'stream/vista_doorbell.ytyp', 'html/index.html', 'html/style.css', 'html/app.js', 'html/phone_app_v207.js', 'html/img/items/vista_doorbell.webp' }
