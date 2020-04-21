local ESX 			= nil
local busy 			= false
local hasExited 		= false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(500)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

	    local ped = GetPlayerPed(-1)
	    local pedExist = DoesEntityExist(ped)
	    local pedinVeh = IsPedInAnyVehicle(ped, false)

		if IsControlJustReleased(0, Config.lockKey) and IsInputDisabled(0) then
			if busy == false then
				busy = true
				getVehicle(nil, nil)
			end
		end

        if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
        	local vehicle = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
        	local doorAngle = GetVehicleDoorAngleRatio(vehicle, 0)
        	TriggerServerEvent('shorty_slocks:getLockStatus', GetVehicleNumberPlateText(vehicle), doorAngle, GetEntityModel(vehicle), GetVehicleDoorLockStatus(vehicle), GetVehicleClass(vehicle), 'outside')
        	Wait(2500)
        end

        if pedExist and not pedinVeh then
        	if not hasExited then
        		hasExited = true
	        	local lastvehicle = GetPlayersLastVehicle()
	        	if lastvehicle then
        			local doorAngle = GetVehicleDoorAngleRatio(lastvehicle, 0)
	        		TriggerServerEvent('shorty_slocks:getLockStatus', GetVehicleNumberPlateText(lastvehicle), doorAngle, GetEntityModel(lastvehicle), GetVehicleDoorLockStatus(lastvehicle), GetVehicleClass(lastvehicle), 'exiting')
	        		lastvehicle = nil
	        	end
	        end
	    elseif pedExist and pedinVeh then
	    	if hasExited then
	    		hasExited = false
	    	end
        end

	end
end)

getVehicle = function(ismenu, lockstatus)
	local player = PlayerPedId()
	local coords = GetEntityCoords(player)
	local lockStatus
	local vehicle = nil

	if IsPedInAnyVehicle(player, false) then
		vehicle = GetVehiclePedIsIn(player, false)
		if vehicle then
			if isaVehicle(vehicle) then 
				if GetPedInVehicleSeat(vehicle, -1) == player or GetPedInVehicleSeat(vehicle, 0) == player then
					local doorAngle = GetVehicleDoorAngleRatio(vehicle, 0)
					if ismenu then
						lockStatus = lockstatus
					else
						lockStatus =  GetVehicleDoorLockStatus(vehicle)
					end
					TriggerServerEvent('shorty_slocks:getLockStatus', GetVehicleNumberPlateText(vehicle), doorAngle, GetEntityModel(vehicle), lockStatus, GetVehicleClass(vehicle), 'inside', ismenu)
				end
			end
		end
		busy = false
		return
	else
		local entityWorld = GetOffsetFromEntityInWorldCoords(player, 0.0, Config.rDist, 0.0)
		local rayHandle = CastRayPointToPoint(coords["x"], coords["y"], coords["z"], entityWorld.x, entityWorld.y, entityWorld.z, 10, ply, 0)
		local a, b, c, d, targetVehicle = GetRaycastResult(rayHandle)

		if (targetVehicle ~= nil and targetVehicle ~= 0) then
			vehicle = targetVehicle
		else
			vehicle = ESX.Game.GetClosestVehicle(coords)
		end

		if not vehicle then
			busy = false
			return
		elseif not GetVehicleNumberPlateText(vehicle) then
			busy = false
			return
		else
			if isaVehicle(vehicle) then
				local doorAngle = GetVehicleDoorAngleRatio(vehicle, 0)
				if ismenu then
					lockStatus = lockstatus
				else
					lockStatus =  GetVehicleDoorLockStatus(vehicle)
				end					
				TriggerServerEvent('shorty_slocks:getLockStatus', GetVehicleNumberPlateText(vehicle), doorAngle, GetEntityModel(vehicle), lockStatus, GetVehicleClass(vehicle), 'remote', ismenu)
			end
		end		
	end
end

isaVehicle = function(vehicle)
	if not DoesEntityExist(vehicle) and not IsEntityAVehicle(vehicle) then
		return false
	end
		return true
end

hornandLights = function(vehicle, times, timer, duration)
	local vehicleHorn = GetVehicleMod(vehicle, 14)
	local count = 0
	local lights = 2

	SetVehicleMod(vehicle, 14, -1, false)

	Citizen.CreateThread(function()
		while count < times do
			StartVehicleHorn(vehicle, duration, "HELDDOWN", false)
			SetVehicleLights(vehicle, lights)
			if lights == 2 then lights = 0; elseif lights == 0 then lights = 2; end
			count = count + 1
			Wait(timer)
		end
	Wait(20)
	SetVehicleLights(vehicle, 0)
	SetVehicleMod(vehicle,14, vehicleHorn, false)
	end)
end

RegisterNetEvent('shorty_slocks:setvehicleLock')
AddEventHandler('shorty_slocks:setvehicleLock', function(plate, lockstatus, call, owner)
	
	if call == 'notauth' then
		busy = false
		return
	end

	local player = PlayerPedId()
	local coords = GetEntityCoords(player)	
	local vehicles = ESX.Game.GetVehiclesInArea(coords, Config.rDist * 2)
	local message = nil

	if lockstatus == false then	lockstatus = 1; elseif lockstatus == true then lockstatus = 2; end

 	if owner and call ~= 'outside' and call ~= 'exiting' and call ~= 'inside' then

	 	local dict = "anim@mp_player_intmenu@key_fob@"

		RequestAnimDict(dict)

		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(0)
		end	

		vehicleKeys = CreateObject(GetHashKey("prop_cuff_keys_01"), 0, 0, 0, true, true, true) -- creates object
	 	AttachEntityToEntity(vehicleKeys, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.11, 0.03, -0.03, 90.0, 0.0, 0.0, true, true, false, true, 1, true) -- object is attached to right hand
		TaskPlayAnim(PlayerPedId(), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)

		Wait(500)
	end

	for i=1, #vehicles do
		if GetVehicleNumberPlateText(vehicles[i]) == plate then
			if call ~= 'outside' and call ~= 'exiting' then
				if lockstatus == 1 then
					PlayVehicleDoorOpenSound(vehicles[i], 1)
					if call ~= 'inside' then
						hornandLights(vehicles[i], 3, 200, 10)
						SetVehicleAlarm(vehicles[i], false)
					end
						message = _U('unlocked')
				elseif lockstatus == 2 or lockstatus == 4 then
					PlayVehicleDoorCloseSound(vehicles[i], 0)
					if call ~= 'inside' then
						hornandLights(vehicles[i], 2, 200, 10)
						SetVehicleAlarm(vehicles[i], true)
					end
					if lockstatus == 2 then
						message = _U('locked')
					elseif lockstatus == 4 then
						message = _U('doublelock')
					end
				end

				if owner and Config.notifca then
					ESX.ShowNotification(_U('title') ..message )
				end

			end
			SetVehicleDoorsLocked(vehicles[i], lockstatus)
		end
	end
	
	if DoesEntityExist(vehicleKeys) then
			Wait(800)

			DeleteEntity(vehicleKeys)
	end

	busy = false
end)

RegisterNetEvent('shorty_slocks:setvehicleLockMenu')
AddEventHandler('shorty_slocks:setvehicleLockMenu', function(lockStatus)
	local lowerLockStatus = string.lower(tostring(lockStatus))
	
	if lowerLockStatus == 'lock' or lockStatus == 2 then
		lockStatus = true
	elseif lowerLockStatus == 'unlock' or lockStatus == 1 then
		lockStatus = false
	elseif lowerLockStatus == 'doublelock' then
		lockStatus = 4
	end

	if busy == false then
		busy = true
		getVehicle(true, lockStatus)
	end
end)
