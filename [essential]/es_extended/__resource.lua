description 'Essential Extended'

server_script 'config.lua'
server_script 'server/classes/player.lua'
server_script 'server/main.lua'

client_script 'config.lua'
client_script 'client/main.lua'

ui_page 'html/ui.html'

files {
	'html/ui.html',
	'html/pdown.ttf',
	'html/bankgothic.ttf',
	'html/img/accounts/bank.png',
	'html/img/accounts/black_money.png'
}