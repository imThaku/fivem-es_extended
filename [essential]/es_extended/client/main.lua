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

local PID              = 0
local GUI              = {}
GUI.InventoryIsShowed  = false
GUI.Time               = 0
local HasLoadedLoadout = false

function Notification(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0,1)
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

RegisterNetEvent("exs:setMoneyDisplay")
AddEventHandler("esx:setMoneyDisplay", function(val)
	SendNUIMessage({
		setDisplay = true,
		display    = val
	})
end)

RegisterNetEvent('esx:responsePlayerDataForGUI')
AddEventHandler('esx:responsePlayerDataForGUI', function(data)

	SendNUIMessage({
		setInventoryDisplay = true,
		inventory           = data.inventory
	})

end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(inventory, item, count)
	SendNUIMessage({
		addInventoryItem = true,
		inventory        = inventory,
		item             = item,
		count            = count
	})
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(inventory, item, count)
	SendNUIMessage({
		removeInventoryItem = true,
		inventory           = inventory,
		item                = item,
		count               = count
	})
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

-- Menu interactions
Citizen.CreateThread(function()
	while true do

  	Wait(0)

  	if IsControlPressed(0, Keys["F5"]) and not GUI.InventoryIsShowed and (GetGameTimer() - GUI.Time) > 300 then
  		
  		TriggerServerEvent('esx:requestPlayerDataForGUI')

  		GUI.InventoryIsShowed = true
	  	GUI.Time              = GetGameTimer()
    end

  	if IsControlPressed(0, Keys["F5"]) and GUI.InventoryIsShowed and (GetGameTimer() - GUI.Time) > 300 then

			SendNUIMessage({
				setInventoryDisplay = false
			})

  		GUI.InventoryIsShowed = false
	  	GUI.Time              = GetGameTimer()
    end

  end
end)

-- Dot above head
if Config.ShowDotAbovePlayer then
	Citizen.CreateThread(function()
		while true do

			Wait(0)

			for id = 1, 32 do
				if GetPlayerPed(id) ~= GetPlayerPed(-1) then
					ped  = GetPlayerPed(id)
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

--Load unloaded ipl's
Citizen.CreateThread(function()
  LoadMpDlcMaps()
  EnableMpDlcMaps(true)
  RequestIpl("chop_props")
  RequestIpl("FIBlobby")
  RemoveIpl("FIBlobbyfake")
  RequestIpl("FBI_colPLUG")
  RequestIpl("FBI_repair")
  RequestIpl("v_tunnel_hole")
  RequestIpl("TrevorsMP")
  RequestIpl("TrevorsTrailer")
  RequestIpl("TrevorsTrailerTidy")
  RemoveIpl("farm_burnt")
  RemoveIpl("farm_burnt_lod")
  RemoveIpl("farm_burnt_props")
  RemoveIpl("farmint_cap")
  RemoveIpl("farmint_cap_lod")
  RequestIpl("farm")
  RequestIpl("farmint")
  RequestIpl("farm_lod")
  RequestIpl("farm_props")
  RequestIpl("facelobby")
  RemoveIpl("CS1_02_cf_offmission")
  RequestIpl("CS1_02_cf_onmission1")
  RequestIpl("CS1_02_cf_onmission2")
  RequestIpl("CS1_02_cf_onmission3")
  RequestIpl("CS1_02_cf_onmission4")
  RequestIpl("v_rockclub")
  RemoveIpl("hei_bi_hw1_13_door")
  RequestIpl("bkr_bi_hw1_13_int")
  RequestIpl("ufo")
  RemoveIpl("v_carshowroom")
  RemoveIpl("shutter_open")
  RemoveIpl("shutter_closed")
  RemoveIpl("shr_int")
  RemoveIpl("csr_inMission")
  RequestIpl("v_carshowroom")
  RequestIpl("shr_int")
  RequestIpl("shutter_closed")
  RequestIpl("smboat")
  RequestIpl("cargoship")
  RequestIpl("railing_start")
  RemoveIpl("sp1_10_fake_interior")
  RemoveIpl("sp1_10_fake_interior_lod")
  RequestIpl("sp1_10_real_interior")
  RequestIpl("sp1_10_real_interior_lod")
  RemoveIpl("id2_14_during_door")
  RemoveIpl("id2_14_during1")
  RemoveIpl("id2_14_during2")
  RemoveIpl("id2_14_on_fire")
  RemoveIpl("id2_14_post_no_int")
  RemoveIpl("id2_14_pre_no_int")
  RemoveIpl("id2_14_during_door")
  RequestIpl("id2_14_during1")
  RequestIpl("coronertrash")
  RequestIpl("Coroner_Int_on")
  RemoveIpl("Coroner_Int_off")
  RemoveIpl("bh1_16_refurb")
  RemoveIpl("jewel2fake")
  RemoveIpl("bh1_16_doors_shut")
  RequestIpl("refit_unload")
  RequestIpl("post_hiest_unload")
  RequestIpl("Carwash_with_spinners")
  RequestIpl("ferris_finale_Anim")
  RemoveIpl("ch1_02_closed")
  RequestIpl("ch1_02_open")
  RequestIpl("AP1_04_TriAf01")
  RequestIpl("CS2_06_TriAf02")
  RequestIpl("CS4_04_TriAf03")
  RemoveIpl("scafstartimap")
  RequestIpl("scafendimap")
  RemoveIpl("DT1_05_HC_REMOVE")
  RequestIpl("DT1_05_HC_REQ")
  RequestIpl("DT1_05_REQUEST")
  RequestIpl("FINBANK")
  RemoveIpl("DT1_03_Shutter")
  RemoveIpl("DT1_03_Gr_Closed")
  RequestIpl("ex_sm_13_office_01a")
  RequestIpl("ex_sm_13_office_01b")
  RequestIpl("ex_sm_13_office_02a")
  RequestIpl("ex_sm_13_office_02b")
end)