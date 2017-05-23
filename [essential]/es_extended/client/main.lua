local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local PID                       = 0
local GUI                       = {}
GUI.InventoryIsShowed           = false
GUI.RemoveInventoryItemIsShowed = false
GUI.GiveInventoryItemIsShowed   = false
GUI.Time                        = 0
local HasLoadedLoadout          = false
local TimeoutCallbacks          = {}
local CurrentItemToGive         = nil

function _SetTimeout(msec, cb)
	table.insert(TimeoutCallbacks, {
		time = GetGameTimer() + msec,
		cb   = cb
	})
end

AddEventHandler('esx:setTimeout', function(msec, cb)
	_SetTimeout(msec, cb)
end)

function Notification(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0,1)
end

function GetClosestPlayerInArea(positions, radius)

	local playerPed             = GetPlayerPed(-1)
	local playerServerId        = GetPlayerServerId(PlayerId())
	local playerCoords          = GetEntityCoords(playerPed)
	local closestPlayer         = -1
	local closestDistance       = math.huge

	for k, v in pairs(positions) do

   if tonumber(k) ~= playerServerId then
      
      local otherPlayerCoords = positions[k]
      local distance          = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, otherPlayerCoords.x, otherPlayerCoords.y, otherPlayerCoords.z, true)

      if distance <= radius and distance < closestDistance then
      	closestPlayer   = tonumber(k)
      	closestDistance = distance
      end
   	end
  end

  return closestPlayer

end

function showInventory(inventory, money, accounts)

	local items = {}

	table.insert(items, {
		label  = 'Cash',
		value  = 'money',
		type   = 'item_money',
		count  = money,
		usable = false
	})

	for i=1, #accounts, 1 do
		table.insert(items, {
			label  = Config.accountLabels[i],
			value  = accounts[i].name,
			type   = 'item_account',
			count  = accounts[i].money,
			usable = false
		})
	end

	for i=1, #inventory, 1 do
		if inventory[i].count > 0 then
			table.insert(items, {
				label  = inventory[i].label .. ' x' .. inventory[i].count,
				value  = inventory[i].item,
				type   = 'item_standard',
				count  = inventory[i].count,
				usable = inventory[i].usable
			})
		end
	end

	SendNUIMessage({
		showMenu = true,
		menu     = 'inventory',
		items    = items
	})

	SendNUIMessage({
		showControls = false
	})

end

RegisterNetEvent('esx:showNotification')
AddEventHandler('esx:showNotification', function(notify)
	Notification(notify)
end)

AddEventHandler('onClientMapStart', function()
	NetworkSetTalkerProximity(5.0)
end)

AddEventHandler('playerSpawned', function(spawn)
	HasLoadedLoadout = false
	PID = GetPlayerServerId(PlayerId())
	TriggerServerEvent('esx:requestLoadout')
	TriggerServerEvent('esx:requestLastPosition')
end)

AddEventHandler('skinchanger:modelLoaded', function()
	HasLoadedLoadout = false
	TriggerServerEvent('esx:requestLoadout')
end)

RegisterNetEvent('esx:activateMoney')
AddEventHandler('esx:activateMoney', function(a)
	SendNUIMessage({
		setmoney = true,
		accounts = a
	})
end)

RegisterNetEvent("esx:addedMoney")
AddEventHandler("esx:addedMoney", function(a, m)
	SendNUIMessage({
		addcash = true,
		account = a,
		money   = m
	})
end)

RegisterNetEvent("esx:removedMoney")
AddEventHandler("esx:removedMoney", function(a, m)
	SendNUIMessage({
		removecash = true,
		account    = a,
		money      = m
	})
end)

RegisterNetEvent("esx:setMoneyDisplay")
AddEventHandler("esx:setMoneyDisplay", function(val)
	SendNUIMessage({
		setMoneyDisplay = true,
		display         = val
	})
end)

RegisterNetEvent("esx:setJobDisplay")
AddEventHandler("esx:setJobDisplay", function(val)
	SendNUIMessage({
		setJobDisplay = true,
		display       = val
	})
end)

RegisterNetEvent('esx:responsePlayerDataForGUI')
AddEventHandler('esx:responsePlayerDataForGUI', function(data)
	showInventory(data.inventory, data.money, data.accounts)
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(inventory, money, accounts, item, count)
	
	SendNUIMessage({
		addInventoryItem = true,
		item             = item,
		count            = count
	})

	if GUI.InventoryIsShowed then
		showInventory(inventory, money, accounts)
	end

end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(inventory, money, accounts, item, count)
	
	SendNUIMessage({
		removeInventoryItem = true,
		item                = item,
		count               = count
	})

	if GUI.InventoryIsShowed then
		showInventory(inventory, money, accounts)
	end

end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	SendNUIMessage({
		setJob = true,
		job    = job
	})
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(pos)

	pos.x = pos.x + 0.0
	pos.y = pos.y + 0.0
	pos.z = pos.z + 0.0

	RequestCollisionAtCoord(pos.x, pos.y, pos.z)
	while not HasCollisionLoadedAroundEntity(GetPlayerPed(-1)) do
		RequestCollisionAtCoord(pos.x, pos.y, pos.z)
		Citizen.Wait(0)
	end

	SetEntityCoords(GetPlayerPed(-1), pos.x, pos.y, pos.z)

end)

RegisterNetEvent('esx:responseLoadout')
AddEventHandler('esx:responseLoadout', function(loadout)

	local playerPed = GetPlayerPed(-1)

	for i=1, #loadout, 1 do
		local weaponHash = GetHashKey(loadout[i].name)
		GiveWeaponToPed(playerPed, weaponHash, loadout[i].ammo, false, false)
	end

	HasLoadedLoadout = true

end)

RegisterNetEvent('esx:responseLastPosition')
AddEventHandler('esx:responseLastPosition', function(pos)
	
	if pos ~= nil then
		RequestCollisionAtCoord(pos.x, pos.y, pos.z)
		while not HasCollisionLoadedAroundEntity(GetPlayerPed(-1)) do
			RequestCollisionAtCoord(pos.x, pos.y, pos.z)
			Citizen.Wait(0)
		end

		SetEntityCoords(GetPlayerPed(-1), pos.x, pos.y, pos.z)
	end

end)

RegisterNetEvent('esx:responsePlayerPositions')
AddEventHandler('esx:responsePlayerPositions', function(positions, reason)

	if reason == 'give_item' then

		local closestPlayer = GetClosestPlayerInArea(positions, 3.0)

    if closestPlayer ~= -1 then

    	if CurrentItemToGive.type == 'item_standard' then
    		TriggerServerEvent('esx:giveItem', closestPlayer, CurrentItemToGive.item, CurrentItemToGive.count)
    	elseif CurrentItemToGive.type == 'item_money' then
    		TriggerServerEvent('esx:giveCash', closestPlayer, CurrentItemToGive.count)
    	elseif CurrentItemToGive.type == 'item_account' then
				TriggerServerEvent('esx:giveAccountMoney', closestPlayer, CurrentItemToGive.item, CurrentItemToGive.count)
    	end

    else
    	TriggerEvent('esx:showNotification', 'Aucun joueur à proximité')
		end

		TriggerServerEvent('esx:requestPlayerDataForGUI')

	end

end)

RegisterNetEvent('esx:loadIPL')
AddEventHandler('esx:loadIPL', function(name)

	Citizen.CreateThread(function()
	  LoadMpDlcMaps()
	  EnableMpDlcMaps(true)
	  RequestIpl(name)
	end)

end)

RegisterNUICallback('select', function(data, cb)

		if data.menu == 'inventory' then

			local items = {
				{label = 'Donner', type = data.type, action = 'give',   value = data.val},
				{label = 'Jeter',  type = data.type, action = 'remove', value = data.val},
				{label = 'Retour', action = 'return'}
			}

			if data.usable then
				table.insert(items, 1, {label = 'Utiliser', type = data.type, action = 'use', value = data.val})
			end

			SendNUIMessage({
				showMenu = true,
				menu     = 'inventory_actions',
				items    = items
			})

			SendNUIMessage({
				showControls = false
			})

		end

		if data.menu == 'inventory_actions' then

			if data.action == 'use' then
				TriggerServerEvent('esx:useItem', data.val)
				TriggerServerEvent('esx:requestPlayerDataForGUI')
			end

			if data.action == 'give' then

				SendNUIMessage({
					showGiveInventoryItem = true,
					type                  = data.type,
					item                  = data.val
				})

				GUI.GiveInventoryItemIsShowed = true

				SetNuiFocus(true)

			end

			if data.action == 'return' then
  			TriggerServerEvent('esx:requestPlayerDataForGUI')
			end

			if data.action == 'remove' then
  			
				SendNUIMessage({
					showRemoveInventoryItem = true,
					type                    = data.type,
					item                    = data.val
				})

				GUI.RemoveInventoryItemIsShowed = true

				SetNuiFocus(true)

			end

		end

		cb('ok')

end)

RegisterNUICallback('remove_inventory_item', function(data, cb)

	local type  = data.type
	local count = tonumber(data.count)

	if count == nil then
		TriggerEvent('esx:showNotification', 'Quantité invalide')
	else

		if type == 'item_standard' then
			TriggerServerEvent('esx:removeInventoryItem', data.item, data.count)
		elseif type == 'item_money' then
			TriggerServerEvent('esx:removeCash', data.count)
		elseif type == 'item_account' then
			TriggerServerEvent('esx:removeAccountMoney', data.item, data.count)
		end

	end

	SendNUIMessage({
		showRemoveInventoryItem = false
	})

	GUI.RemoveInventoryItemIsShowed = false

	SetNuiFocus(false)

	TriggerServerEvent('esx:requestPlayerDataForGUI')
	
	cb('ok')

end)

RegisterNUICallback('give_inventory_item', function(data, cb)

	local type  = data.type
	local count = tonumber(data.count)

	if count == nil then
		TriggerEvent('esx:showNotification', 'Quantité invalide')
	else

		CurrentItemToGive = data

		TriggerServerEvent('esx:requestPlayerPositions', 'give_item')
	end

	SendNUIMessage({
		showGiveInventoryItem = false
	})

	GUI.GiveInventoryItemIsShowed = false

	SetNuiFocus(false)
	
	cb('ok')

end)

-- Dot above head
if Config.ShowDotAbovePlayer then
	Citizen.CreateThread(function()
		while true do

			Wait(0)

			for i = 1, 32, 1 do
				if i ~= PlayerId() then
					ped    = GetPlayerPed(i)
					headId = Citizen.InvokeNative(0xBFEFE3321A3F5015, ped, ('·'), false, false, '', false)
				end
			end

		end
	end)
end

-- Save loadout
Citizen.CreateThread(function()
	while true do

		Wait(5000)

		if HasLoadedLoadout then

			local playerPed = GetPlayerPed(-1)
			local loadout   = {}

			for i=1, #Config.Weapons, 1 do
				
				local weaponHash = GetHashKey(Config.Weapons[i].name)

				if HasPedGotWeapon(playerPed,  weaponHash,  false) and Config.Weapons[i].name ~= 'WEAPON_UNARMED' then

					local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)

					table.insert(loadout, {
						name = Config.Weapons[i].name,
						ammo = ammo,
					})

				end
			end

			TriggerServerEvent('esx:updateLoadout', loadout)

		end

	end
end)

-- Pause menu disable hud display
local isPaused = false

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1)
    if IsPauseMenuActive() and not isPaused then
      isPaused = true
      TriggerEvent('es:setMoneyDisplay', 0.0)
      TriggerEvent('esx:setMoneyDisplay', 0.0)
      TriggerEvent('esx:setJobDisplay', 0.0)      
    elseif not IsPauseMenuActive() and isPaused then
      isPaused = false
      TriggerEvent('es:setMoneyDisplay', 1.0)
      TriggerEvent('esx:setMoneyDisplay', 1.0)
      TriggerEvent('esx:setJobDisplay', 1.0)   
    end
  end
end)

-- Menu interactions
Citizen.CreateThread(function()
	while true do

  	Wait(0)

    if GUI.RemoveInventoryItemIsShowed or GUI.GiveInventoryItemIsShowed then

      DisableControlAction(0, 1,   true) -- LookLeftRight
      DisableControlAction(0, 2,   true) -- LookUpDown
      DisableControlAction(0, 142, true) -- MeleeAttackAlternate
      DisableControlAction(0, 106, true) -- VehicleMouseControlOverride

      DisableControlAction(0, 12, true) -- WeaponWheelUpDown
      DisableControlAction(0, 14, true) -- WeaponWheelNext
      DisableControlAction(0, 15, true) -- WeaponWheelPrev
      DisableControlAction(0, 16, true) -- SelectNextWeapon
      DisableControlAction(0, 17, true) -- SelectPrevWeapon

      if IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
        SendNUIMessage({
          click = true
        })
      end

    else

	  	if IsControlPressed(0, Keys["F5"]) and not GUI.InventoryIsShowed and (GetGameTimer() - GUI.Time) > 300 then
	  		
	  		TriggerServerEvent('esx:requestPlayerDataForGUI')

	  		GUI.InventoryIsShowed = true
		  	GUI.Time              = GetGameTimer()
	    end

	  	if IsControlPressed(0, Keys["F5"]) and GUI.InventoryIsShowed and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					showMenu     = false,
					showControls = false
				})

	  		GUI.InventoryIsShowed = false
		  	GUI.Time              = GetGameTimer()
	    end

			if IsControlPressed(0, Keys['ENTER']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					enterPressed = true
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['BACKSPACE']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					backspacePressed = true
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['LEFT']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'LEFT'
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['RIGHT']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'RIGHT'
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['TOP']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'UP'
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['DOWN']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'DOWN'
				})

				GUI.Time = GetGameTimer()

			end

		end

  end
end)

-- _SetTimeout
Citizen.CreateThread(function()
	
	while true do

		Wait(0)

		local currTime = GetGameTimer()

		for i=1, #TimeoutCallbacks, 1 do

			if currTime >= TimeoutCallbacks[i].time then
				TimeoutCallbacks[i].cb()
				TimeoutCallbacks[i] = nil
			end

		end

	end

end)
