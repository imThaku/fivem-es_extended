-- Constructor
ExtendedPlayer = {}
ExtendedPlayer.__index = ExtendedPlayer

-- Meta table for users
setmetatable(ExtendedPlayer, {
	__call = function(self, player, accounts, inventory, job, loadout)
		
		local xpl = {}

		xpl.player     = player
		xpl.accounts   = accounts
		xpl.identifier = player.identifier
		xpl.inventory  = inventory
		xpl.job        = job
		xpl.loadout    = loadout

		return setmetatable(xpl, ExtendedPlayer)
	end
})

-- Getting permissions
function ExtendedPlayer:getPermissions()
	return self.player:getPermissions()
end

-- Setting them
function ExtendedPlayer:setPermissions(p)
	return self.player:setPermissions(p)
end

-- No need to ever call this (No, it doesn't teleport the player)
function ExtendedPlayer:setCoords(x, y, z)
	return self.player:setCoords(x, y, z)
end

-- Kicks a player with specified reason
function ExtendedPlayer:kick(reason)
	return self.player:kick(reason)
end

-- Sets the player money (required to call this from now)
function ExtendedPlayer:setMoney(m)
	return self.player:setMoney(m)
end

-- Adds to player money (required to call this from now)
function ExtendedPlayer:addMoney(m)
	return self.player:addMoney(m)
end

-- Removes from player money (required to call this from now)
function ExtendedPlayer:removeMoney(m)
	return self.player:removeMoney(m)
end

-- Player session variables
function ExtendedPlayer:setSessionVar(key, value)
	return self.player:setSessionVar(key, value)
end

function ExtendedPlayer:getSessionVar(key)
	return self.player:getSessionVar(key)
end

function ExtendedPlayer:getAccount(a)
	for i=1, #self.accounts, 1 do
		if self.accounts[i].name == a then
			return self.accounts[i]
		end
	end
end

function ExtendedPlayer:getMissingAccounts()
	
	local executed_query  = MySQL:executeQuery("SELECT * FROM user_accounts WHERE identifier = '@identifier'", {['@identifier'] = self.player.identifier})
	local result          = MySQL:getResults(executed_query, {'identifier', 'name', 'money'}, "id")
	local missingAccounts = {};

	for i=1, #Config.accounts, 1 do

		local found = false

		for j=1, #result, 1 do
			if Config.accounts[i] == result[j].name then
				found = true
			end
		end

		if not found then
			table.insert(missingAccounts, Config.accounts[i])
		end

	end

	return missingAccounts

end

function ExtendedPlayer:createAccounts(missingAccounts)

	for i=1, #missingAccounts, 1 do
		MySQL:executeQuery("INSERT INTO user_accounts (identifier, name) VALUES ('@identifier', '@name')", {['@identifier'] = self.player.identifier, ['@name'] = Config.accounts[i]})
	end

end

function ExtendedPlayer:setAccountMoney(account, m)
	
	local account           = self:getAccount(account)
	local prevMoney         = account.money
	local newMoney : double = m

	account.money = newMoney

	if prevMoney - newMoney < 0 then
		TriggerClientEvent("esx:addedMoney", self.player.source, account, math.abs(prevMoney - newMoney))
	else
		TriggerClientEvent("esx:removedMoney", self.player.source, account, math.abs(prevMoney - newMoney))
	end

	TriggerClientEvent('esx:activateMoney', self.player.source, self.accounts)
end

function ExtendedPlayer:addAccountMoney(account, m)

	local account           = self:getAccount(account)
	local newMoney : double = account.money + m

	account.money = newMoney

	TriggerClientEvent("esx:addedMoney", self.player.source, account, m)
	TriggerClientEvent('esx:activateMoney', self.player.source, self.accounts)
end

function ExtendedPlayer:removeAccountMoney(account, m)
	local account           = self:getAccount(account)
	local newMoney : double = account.money - m

	account.money = newMoney

	TriggerClientEvent("esx:removedMoney", self.player.source, account, m)
	TriggerClientEvent('esx:activateMoney', self.player.source, self.accounts)
end

function ExtendedPlayer:getInventoryItem(name)
	
	for i=1, #self.inventory, 1 do
		if self.inventory[i].item == name then
			return self.inventory[i]
		end
	end

	-- Item does not exist, so we create it

	local newItem = {
		item  = name,
		count = 0
	}

	table.insert(self.inventory, newItem)

	return newItem

end

function ExtendedPlayer:addInventoryItem(name, count)

	local item     = self:getInventoryItem(name)
	local newCount = item.count + count
	item.count     = newCount

	TriggerClientEvent("esx:addInventoryItem", self.player.source, self.inventory, item, count)

end

function ExtendedPlayer:removeInventoryItem(name, count)
	
	local item     = self:getInventoryItem(name)
	local newCount = item.count - count
	item.count     = newCount

	TriggerClientEvent("esx:removeInventoryItem", self.player.source, self.inventory, item, count)

end

function ExtendedPlayer:setJob(name, grade)
	
	local executed_query  = MySQL:executeQuery("SELECT * FROM jobs WHERE name = '@name'", {['@name'] = name})
	local result          = MySQL:getResults(executed_query, {'id', 'name', 'label'})

	self.job['id']    = result[1].id
	self.job['name']  = result[1].name
	self.job['label'] = result[1].label

	local executed_query  = MySQL:executeQuery("SELECT * FROM job_grades WHERE job_name = '@job_name' AND grade = '@grade'", {['@job_name'] = self.job['name'], ['@grade'] = grade})
	local result          = MySQL:getResults(executed_query, {'name', 'label', 'salary', 'skin_male', 'skin_female'})

	self.job['grade_name']   = result[1].name
	self.job['grade_label']  = result[1].label
	self.job['grade_salary'] = result[1].salary

	self.job['skin_male']    = nil
	self.job['skin_female']  = nil

	if result[1].skin_male ~= nil then
		self.job['skin_male'] = json.decode(result[1].skin_male)
	end

	if result[1].skin_female ~= nil then
		self.job['skin_female'] = json.decode(result[1].skin_female)
	end

	TriggerClientEvent("esx:setJob", self.player.source, self.job)

end

function ExtendedPlayer:removeJob()
	
	local executed_query  = MySQL:executeQuery("UPDATE users SET job = 'unemployed', job_grade = '0' WHERE identifier = '@identifier'", {['@identifier'] = self.identifier})

	self.job['id'  ] = -1
	self.job['name'] = -1

	TriggerClientEvent("esx:removeJob", self.player.source)

end