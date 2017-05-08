description 'Essential Extended'

server_script 'config.lua'
server_script 'server/classes/player.lua'
server_script 'server/main.lua'

client_script 'config.lua'
client_script 'client/main.lua'

ui_page 'html/ui.html'

files {
	'html/ui.html',
	
	'html/css/app.css',
	
	'html/scripts/mustache.min.js',
	'html/scripts/app.js',
	
	'html/pdown.ttf',
	'html/bankgothic.ttf',
	
	'html/img/cursor.png',
	'html/img/keys/enter.png',
	'html/img/keys/return.png',

	'html/img/accounts/bank.png',
	'html/img/accounts/black_money.png'
}