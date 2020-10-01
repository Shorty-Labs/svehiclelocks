ESX 				= nil
local vehicle_data 		= {}
local SQLReady

TriggerEvent("esx:getSharedObject", function(library) 
	ESX = library 
end)

MySQL.ready(function ()
	SQLReady = true
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.CreateThread(function()
			while true do
				Citizen.Wait(300000)
				getvehiclesList()
			end
		end)
	end
end)

RegisterServerEvent('shorty_slocks:transferOwner')
AddEventHandler('shorty_slocks:transferOwner', function(plate, ownerID)
	if plate and ownerID then
		local plateStripped = string.gsub(plate, "%s+", "")
		local xPlayer = ESX.GetPlayerFromId(ownerID)

		if not vehicle_data[plateStripped] then
			getlockStatus(plate, nil, nil, nil, nil)
			while not vehicle_data[plateStripped] do Wait(0) end
			vehicle_data[plateStripped].owner = xPlayer.identifier
		else
			vehicle_data[plateStripped].owner = xPlayer.identifier
		end
	end
end)

RegisterServerEvent('shorty_slocks:breakIn')
AddEventHandler('shorty_slocks:breakIn', function(plate)
	if plate then
		local plateStripped = string.gsub(plate, "%s+", "")
		local xPlayer = ESX.GetPlayerFromId(ownerID)

		if not vehicle_data[plateStripped] then
			getlockStatus(plate, nil, nil, nil, nil)
			while not vehicle_data[plateStripped] do Wait(0) end
			vehicle_data[plateStripped].lockstatus = false
		else
			vehicle_data[plateStripped].lockstatus = false
		end
	end
end)

RegisterServerEvent('shorty_slocks:getLockStatus')
AddEventHandler('shorty_slocks:getLockStatus', function(plate, doorangle, modelHash, lockstatus, class, call, menu)
	if not plate then return end
	local plateStripped = string.gsub(plate, "%s+", "")
	local _source = source
	local Cclass = class

	if string.match(plate, Config.rentalPlate) then
		if not vehicle_data[plateStripped] then
			getlockStatus(plate, class, doorangle, modelHash, lockstatus)
			if string.len(vehicle_data[plateStripped].owner) < 3 then
				getrentedOwner(plate)
			end
		elseif vehicle_data[plateStripped] then
			if string.len(vehicle_data[plateStripped].owner) < 3  then
				getrentedOwner(plate)
			end
		end
	end

	if call == 'outside' then
		if not vehicle_data[plateStripped] then
			getlockStatus(plate, class, doorangle, modelHash, lockstatus)
			setvehicleLocks(plate, plateStripped, call)
		else
			setvehicleLocks(plate, plateStripped, call)
		end
	elseif call == 'inside' then
		if not vehicle_data[plateStripped] then
			getlockStatus(plate, Cclass, doorangle, modelHash, lockstatus)
			if menu then
				if lockstatus == true or lockstatus == false or lockstatus == 4 then
					vehicle_data[plateStripped].lockstatus = lockstatus
				end
			end			
			setvehicleLocks(plate, plateStripped, call)
		else
			if menu then
				if lockstatus == true or lockstatus == false or lockstatus == 4 then
					vehicle_data[plateStripped].lockstatus = lockstatus
				end
			else
				if vehicle_data[plateStripped].lockstatus == true then 
					vehicle_data[plateStripped].lockstatus = 4
				elseif vehicle_data[plateStripped].lockstatus == 4 then 
					vehicle_data[plateStripped].lockstatus = false
				elseif vehicle_data[plateStripped].lockstatus == false then
					vehicle_data[plateStripped].lockstatus = true
				end
			end
			setvehicleLocks(plate, plateStripped, call)
		end
	elseif call == 'exiting'  then
		if not vehicle_data[plateStripped] then
			getlockStatus(plate, Cclass, doorangle, modelHash, lockstatus)

			if vehicle_data[plateStripped].lockstatus == true or vehicle_data[plateStripped].lockstatus == 4 then
				vehicle_data[plateStripped].lockstatus = false
				setvehicleLocks(plate, plateStripped, call)
			end
		else
			if vehicle_data[plateStripped].lockstatus == true or vehicle_data[plateStripped].lockstatus == 4 then
				vehicle_data[plateStripped].lockstatus = false
				setvehicleLocks(plate, plateStripped, call)
			end
			setvehicleLocks(plate, plateStripped, call)
		end
	elseif call == 'remote' then
		if not vehicle_data[plateStripped] then
			getlockStatus(plate, Cclass, doorangle, modelHash, lockstatus)

			if isAuthorised(plate) then
				if menu then
					if lockstatus == true or lockstatus == false or lockstatus == 4 then
						vehicle_data[plateStripped].lockstatus = lockstatus
					end
				end				
				setvehicleLocks(plate, plateStripped, call)
			else
				setvehicleLocks(nil, nil, 'notauth')
			end
		else
			if isAuthorised(plate) then
				if menu then
					if lockstatus == true or lockstatus == false or lockstatus == 4 then
						vehicle_data[plateStripped].lockstatus = lockstatus
					end
				else			
					vehicle_data[plateStripped].lockstatus = not vehicle_data[plateStripped].lockstatus
				end
				setvehicleLocks(plate, plateStripped, call)
			else
				setvehicleLocks(nil, nil, 'notauth')			
			end
		end
	end
end)

getvehiclesList = function()
	MySQL.Async.fetchAll('SELECT owner, plate FROM owned_vehicles', {}, function(result)
		if #result > 0 then
			for i = 1, #result do
				local plateStripped = string.gsub(result[i].plate, "%s+", "")
				vehicle_data[plateStripped] = { owner = result[i].owner }
			end
		end
	end)

	MySQL.Async.fetchAll('SELECT owner, plate FROM rented_vehicles', {}, function(result)
		if #result > 0 then
			for i = 1, #result do
				local plateStripped = string.gsub(result[i].plate, "%s+", "")
				vehicle_data[plateStripped] = { owner = result[i].owner }
			end
		end
	end)	
end

getrentedOwner = function(plate)
	MySQL.Async.fetchAll('SELECT owner FROM rented_vehicles WHERE plate = @plate', {['@plate'] = plate}, function(result)
		if #result > 0 then
			for i = 1, #result do
				local plateStripped = string.gsub(plate, "%s+", "")
				vehicle_data[plateStripped].owner = result[i].owner
			end
		end
	end)	
end

getlockStatus = function(plate, class, doorangle, modelHash, lockstatus)
	local plateStripped = string.gsub(plate, "%s+", "")

	if vehicle_data[plateStripped] then
		return(vehicle_data[plateStripped].lockstatus)
	else

		if Config.lockNPC == true then
			LockChance = lockChance(doorangle, modelHash, lockstatus)
		else
			LockChance = false
		end
		vehicle_data[plateStripped] = {owner = class, lockstatus = LockChance}		
		return(vehicle_data[plateStripped].lockstatus)
	end
end

setvehicleLocks = function(plate, plateStripped, call)
	local _source = source

	if call == 'notauth' then
		TriggerClientEvent('shorty_slocks:setvehicleLock', _source, nil, nil, call, false)
		return
	end

	local players = nil
	local players = GetPlayers()

	TriggerClientEvent('shorty_slocks:setvehicleLock', _source, plate, vehicle_data[plateStripped].lockstatus, call, true)
	
	for _,player in pairs(players) do
		if _source ~= tonumber(player) then
			TriggerClientEvent('shorty_slocks:setvehicleLock', player, plate, vehicle_data[plateStripped].lockstatus, call, false)
		end
	end
end

lockChance = function(doorangle, modelHash, lockstatus)
	local chance = math.random(100)

	if Config.lChance > 100 then
		Config.lChance = 100
	elseif Config.lChance < 0 then
		Config.lChance = 0
	end
	
	if doorangle and doorangle > 0.0 then
		return false
	end

	if lockstatus and lockstatus == 7 then
		if chance > Config.lChance then
			return true
		else
			return lockstatus
		end
	end

	for k,v in pairs(Config.blacklistVehicles) do
		if modelHash == GetHashKey(v) then
			return true
		end
	end

	for k,v in pairs(Config.whitelistVehicles) do
		if modelHash == GetHashKey(v) then
			return false
		end
	end

	return (chance > Config.lChance)
end

isAuthorised = function(plate)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local identifier = xPlayer.identifier
	local plateStripped = string.gsub(plate, "%s+", "")
	local playerJob = xPlayer.getJob()

	if vehicle_data[plateStripped].owner == identifier then
		return true
	end

	if vehicle_data[plateStripped].owner == 18 then
		for i=1, #Config.emergencyJob do
			if playerJob.name == Config.emergencyJob[i] then
				return true
			end
		end
	end

	for i=1, #Config.JobsandPlates do
		if vehicle_data[plateStripped] then		
			jobPlate = string.gsub(plateStripped, "[0-9]", "")
			jobplateStripped = string.gsub(jobPlate, "%s+", "")
			if Config.JobsandPlates[i].job == playerJob.name and Config.JobsandPlates[i].plate == jobplateStripped then
				return true
			end
		end
	end

	for i=1, #Config.whitelistPlates do
		if vehicle_data[plateStripped] then
			whitelistedPlate = string.gsub(plateStripped, "[0-9]", "")
			whitelistedPlateStripped = string.gsub(whitelistedPlate, "%s+", "")
			if Config.whitelistPlates[i] == whitelistedPlateStripped then
				return true
			end
		end
	end

end
