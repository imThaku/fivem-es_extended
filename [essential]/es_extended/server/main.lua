require "resources/[essential]/es_extended/lib/MySQL"
MySQL:open("127.0.0.1", "gta5_gamemode_essential", "root", "foo")

local Users = {}

RegisterServerEvent('esx:clientLog')
AddEventHandler('esx:clientLog', function(str)
	RconPrint('esx:clientLog => ' .. str)
end)

AddEventHandler('es:newPlayerLoaded', function(source, _user)

	TriggerEvent('es:getPlayerFromId', source, function(user)

		local accounts = {}

		local executed_query  = MySQL:executeQuery("SELECT * FROM user_accounts WHERE identifier = '@identifier'", {['@identifier'] = user.identifier})
		local result          = MySQL:getResults(executed_query, {'name', 'money'}, "id")

		for i=1, #result, 1 do
			accounts[i] = {
				name  = result[i].name,
				money = result[i].money
			}
		end

		local items          = {}
		local executed_query = MySQL:executeQuery("SELECT * FROM items")
		local result         = MySQL:getResults(executed_query, {'name', 'label'})

		for i=1, #result, 1 do
			items[result[i].name] = result[i].label
		end

		local inventory      = {}
		local executed_query = MySQL:executeQuery("SELECT * FROM user_inventory WHERE identifier = '@identifier'", {['@identifier'] = user.identifier})
		local result         = MySQL:getResults(executed_query, {'item', 'count'}, "id")

		for i=1, #result, 1 do
			table.insert(inventory, {
				item  = result[i].item,
				count = result[i].count,
				label = items[result[i].item]
			})
		end

		for k,v in pairs(items) do

			local found = false

			for j=1, #inventory, 1 do
				if inventory[j].item == k then
					found = true
					break
				end
			end

			if not found then
				
				table.insert(inventory, {
					item  = k,
					count = 0,
					label = v
				})

				MySQL:executeQuery("INSERT INTO user_inventory (identifier, item, count) VALUES ('@identifier', '@item', '@count')", {['@identifier'] = user.identifier, ['@item'] = k, ['@count'] = 0})
			end

		end

		local job = {}

		local executed_query  = MySQL:executeQuery("SELECT * FROM users WHERE identifier = '@identifier'", {['@identifier'] = user.identifier})
		local result          = MySQL:getResults(executed_query, {'skin', 'job', 'job_grade', 'loadout'})

		job['name']  = result[1].job
		job['grade'] = result[1].job_grade

		local loadout = {}

		if result[1].loadout ~= nil then
			loadout = json.decode(result[1].loadout)
		end

		local executed_query  = MySQL:executeQuery("SELECT * FROM jobs WHERE name = '@name'", {['@name'] = job.name})
		local result          = MySQL:getResults(executed_query, {'id', 'name', 'label'})

		job['id']    = result[1].id
		job['name']  = result[1].name
		job['label'] = result[1].label

		local executed_query  = MySQL:executeQuery("SELECT * FROM job_grades WHERE job_name = '@job_name' AND grade = '@grade'", {['@job_name'] = job.name, ['@grade'] = job.grade})
		local result          = MySQL:getResults(executed_query, {'name', 'label', 'salary', 'skin_male', 'skin_female'})

		job['grade_name']   = result[1].name
		job['grade_label']  = result[1].label
		job['grade_salary'] = result[1].salary

		job['skin_male']   = {}
		job['skin_female'] = {}

		if result[1].skin_male ~= nil then
			job['skin_male'] = json.decode(result[1].skin_male)
		end

		if result[1].skin_female ~= nil then
			job['skin_female'] = json.decode(result[1].skin_female)
		end

		local xPlayer         = ExtendedPlayer(user, accounts, inventory, job, loadout)
		local missingAccounts = xPlayer:getMissingAccounts()

		if #missingAccounts > 0 then

			for i=1, #missingAccounts, 1 do
				table.insert(xPlayer.accounts, {
					name  = missingAccounts[i],
					money = 0
				})
			end

			xPlayer:createAccounts(missingAccounts)
		end

		Users[source] = xPlayer

		TriggerEvent('esx:playerLoaded', source)

		TriggerClientEvent('es:activateMoney',  source, xPlayer.player.money)
		TriggerClientEvent('esx:activateMoney', source, xPlayer.accounts)
		
		TriggerClientEvent('esx:setJob', source, xPlayer.job)

	end)
end)

RegisterServerEvent('esx:getPlayerFromId')
AddEventHandler('esx:getPlayerFromId', function(source, cb)
	cb(Users[source])
end)

AddEventHandler('esx:getPlayers', function(cb)
	cb(Users)
end)

RegisterServerEvent('esx:updateLoadout')
AddEventHandler('esx:updateLoadout', function(loadout)
	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
		xPlayer.loadout = loadout
	end)
end)

RegisterServerEvent('esx:requestLoadout')
AddEventHandler('esx:requestLoadout', function()
	local _source = source
	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
		TriggerClientEvent('esx:responseLoadout', _source, xPlayer.loadout)
	end)
end)

AddEventHandler('playerDropped', function()

	if Users[source] ~= nil then
		
		local query = ''

		-- User accounts
		local itemCount = 0
		local subQuery  = '';

		for i=1, #Users[source].accounts, 1 do
			subQuery = subQuery .. "UPDATE user_accounts SET `money`='" .. Users[source].accounts[i].money .. "' WHERE identifier = '" .. Users[source].identifier .. "' AND name = '" .. Users[source].accounts[i].name .. "';"
			itemCount = itemCount + 1
		end

		if itemCount > 0 then
			query = query .. subQuery
		end

		-- Inventory items
		local subQuery  = ''
		local itemCoutn = 0

		for i=1, #Users[source].inventory, 1 do
			subQuery  = subQuery .. "UPDATE user_inventory SET `count`='" .. Users[source].inventory[i].count .. "' WHERE identifier = '" .. Users[source].identifier .. "' AND item = '" .. Users[source].inventory[i].item .. "';"
			itemCount = itemCount + 1
		end

		if itemCount > 0 then
			query = query .. subQuery
		end

		-- Job, loadout and position
		query = query .. "UPDATE users SET job = '" .. Users[source].job.name .. "', job_grade = '" .. Users[source].job.grade .. "', loadout = '" .. json.encode(Users[source].loadout) .. "', position='" .. json.encode(Users[source].player.coords) .. "' WHERE identifier = '" .. Users[source].identifier .. "';"

		Users[source] = nil

		MySQL:executeQuery(query)

	end

end)

RegisterServerEvent('esx:requestPlayerDataForGUI')
AddEventHandler('esx:requestPlayerDataForGUI', function()

	local _source = source

	TriggerEvent('esx:getPlayerFromId', _source, function(xPlayer)

		local data = {
			money     = xPlayer.player.money,
			accounts  = xPlayer.accounts,
			inventory = xPlayer.inventory
		}

		TriggerClientEvent('esx:responsePlayerDataForGUI', _source, data)

	end)
end)

RegisterServerEvent('esx:requestLastPosition')
AddEventHandler('esx:requestLastPosition', function()
	
	local _source = source

	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
		
		local executed_query  = MySQL:executeQuery("SELECT * FROM users WHERE identifier = '@identifier'", {['@identifier'] = xPlayer.identifier})
		local result          = MySQL:getResults(executed_query, {'position'})

		local position = nil

		if result[1].position ~= nil then
			position = json.decode(result[1].position)
		end

		TriggerClientEvent('esx:responseLastPosition', _source, position)

	end)
end)

TriggerEvent('es:addGroupCommand', 'tp', 'admin', function(source, args, user)

	TriggerClientEvent("esx:teleport", source, {
		x = tonumber(args[2]),
		y = tonumber(args[3]),
		z = tonumber(args[4])
	})

end, function(source, args, user)
	TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Insufficient Permissions.")
end)

TriggerEvent('es:addGroupCommand', 'setjob', 'owner', function(source, args, user)
	TriggerEvent('esx:getPlayerFromId', tonumber(args[2]), function(xPlayer)
		xPlayer:setJob(args[3], tonumber(args[4]))
	end)
end, function(source, args, user)
	TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Insufficient Permissions.")
end)

TriggerEvent('es:addGroupCommand', 'removejob', 'owner', function(source, args, user)
	TriggerEvent('esx:getPlayerFromId', tonumber(args[2]), function(xPlayer)
		xPlayer:removeJob()
	end)
end, function(source, args, user)
	TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Insufficient Permissions.")
end)

TriggerEvent('es:addCommand', 'sendmoney', function(source, args, user)

	local targetId = tonumber(args[2])
	local amount   = tonumber(args[3])

	if amount == nil or amount <= 0 or amount > user.money then

		TriggerClientEvent('chatMessage', source, 'MONEY', {255, 0, 0}, 'Montant invalide')

	else

		TriggerClientEvent('chatMessage', source, 'MONEY', {255, 255, 0}, ' (^2' .. GetPlayerName(source) .. ' | '..source..'^0) ' .. table.concat(args, ' '))

		TriggerEvent('es:getPlayerFromId', source, function(user)
			TriggerEvent('es:getPlayerFromId', targetId, function(targetUser)
				
				if targetUser == nil then

					TriggerClientEvent('chatMessage', source, 'MONEY', {255, 0, 0}, 'Aucun joueur trouvé ayant l\'id ' .. targetId)

				else

					if targetId == source then

						TriggerClientEvent('chatMessage', source, 'MONEY', {255, 0, 0}, 'Vous ne pouvez pas vous envoyer de l\'argent à vous-même')

					else

						local userName       = GetPlayerName(source  )
						local targetUserName = GetPlayerName(targetId)

						user:removeMoney(amount)
						targetUser:addMoney(amount)

						TriggerClientEvent('chatMessage', source,   'MONEY', {255, 255, 0}, 'Vous avez envoyé €' .. args[3] .. ' à ' .. targetUserName)
						TriggerClientEvent('chatMessage', targetId, 'MONEY', {255, 255, 0}, userName .. ' vous a envoyé €' .. args[3])
					
					end
				end

			end)
		end)

	end

end)


local function saveData()
	
	SetTimeout(60000, function()
		
		local query     = ''
		local userCount = 0

		for k,v in pairs(Users)do
			
			-- User accounts
			local subQuery  = ''
			local itemCount = 0

			for i=1, #v.accounts, 1 do
				subQuery = subQuery .. "UPDATE user_accounts SET `money`='" .. v.accounts[i].money .. "' WHERE identifier = '" .. v.identifier .. "' AND name = '" .. v.accounts[i].name .. "';"
				itemCount = itemCount + 1
			end

			if itemCount > 0 then
				query = query .. subQuery
			end

			-- Inventory items
			local subQuery  = ''
			local itemCount = 0

			for i=1, #v.inventory, 1 do
				subQuery  = subQuery .. "UPDATE user_inventory SET `count`='" .. v.inventory[i].count .. "' WHERE identifier = '" .. v.identifier .. "' AND item = '" .. v.inventory[i].item .. "';"
				itemCount = itemCount + 1
			end

			if itemCount > 0 then
				query = query .. subQuery
			end

			-- Job, loadout and position
			query = query .. "UPDATE users SET job = '" .. v.job.name .. "', job_grade = '" .. v.job.grade .. "', loadout = '" .. json.encode(v.loadout) .. "', position='" .. json.encode(v.player.coords) .. "' WHERE identifier = '" .. v.identifier .. "';"

			userCount = userCount + 1
		end

		if userCount > 0 then
			MySQL:executeQuery(query)
		end

		saveData()

	end)
end

saveData()

local function paycheck()

	SetTimeout(Config.PaycheckInterval, function()

		TriggerEvent('esx:getPlayers', function(players)

			for k,v in pairs(players) do
				v:addMoney(v.job.grade_salary)
				TriggerClientEvent('esx:showNotification', v.player.source, 'Vous avez recu votre salaire : ' .. '$' .. v.job.grade_salary)
			end

		end)

		paycheck()

	end)
end

paycheck()