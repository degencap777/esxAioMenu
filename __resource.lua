resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX AIOMenu'

version '1.6'

client_scripts({
	'config.lua',
	'client/main.lua'
})

server_scripts({
	'config.lua',
	'@mysql-async/lib/MySQL.lua',
	'server/main.lua',
	'server/commands.lua'
})

dependency 'es_extended'

ui_page('client/html/index.html')

files({
    'client/html/index.html',
	'client/html/style.css',
	'client/html/script.js',
	'client/html/sounds/lock.ogg',
	'client/html/sounds/lock2.ogg',
	'client/html/sounds/unlock.ogg',
	'client/html/sounds/unlock2.ogg'
})
