resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX AIOMenu'

version '1.5.0'

server_scripts({
	'server/main.lua',
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'config.lua'
})

client_scripts({
	'client/main.lua',
	'@es_extended/locale.lua',
	'config.lua'
})

dependency 'es_extended'

ui_page('client/html/UI.html') --THIS IS IMPORTENT

--[[The following is for the files which are need for you UI (like, pictures, the HTML file, css and so on) ]]--
files({
    'client/html/UI.html',
    'client/html/style.css'
})
