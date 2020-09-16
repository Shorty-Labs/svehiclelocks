# Synced Vehicle Locks

Version 1.0.5 - Update 16/09/2020

Version 1.0.4 - Update 20/04/2020

Version 1.0.3 - Patch 18/04/2020

Version 1.0.2 - Patch 17/04/2020

Version 1.0.1 - Patch 17/04/2020

Version 1.0.0 - Realeased 17/04/2020

Server synced lock system with lock all spawned vehicles

--[[ Features ]] --

	-- Lock and Unlock owned vehicles remotely
	-- Lock and Unlock any vehicle you are in ( Driver and Passenger seats )
	-- Double lock feature ( Lock twice while inside vehicle to lock occupants inside )
	-- Lock all NPC vehicles with a chance of being open or able to break into.
	-- Enable Emergency Vehicle locking by emergency job names
	-- Enable jobs to lock there vehicles based on No Plate
	-- Black List vehicles will always be locked
	-- Lights Flash horn sounds, and sets the default alarm when remote locking


-- [[ Config ]] --

	-- [[ Version 1.0.4 ]] --

		Config = {}

		Config.Locale      = 'en'  -- [[ Local Language en by default                          ]] --
		Config.notifca     = false -- [[ Show lock and unlock messages, false default          ]] --
		Config.lockKey     = 182   -- [[ Key to Lock / Unlock Vehicle L by default             ]] --
		Config.lockNPC     = true  -- [[ Lock all NPC cars True By Default                     ]] --
		Config.defLock     = false -- [[ Default setting for Owned vehicles false by default   ]] --
		Config.lChance     = 10    -- [[ Percent chance of vehicle being unlocked              ]] --
		Config.rDist       = 10    -- [[ Distance for vehicles in area default 10              ]] --
		Config.rentalPlate = 'RENT'-- [[ Rental Plate None Unique letters Default is RENT      ]] --

		-- [[ Names of emergency jobs for emergency vehicle locks  ]] --
		Config.emergencyJob = {
		  "police",
		  "bcso",
		  "ambulance"
		}

		-- [[ Job name and Number Plate NOTE: this removes any numbers E.G PDM 477 will read PDM  ]] --
		Config.JobsandPlates = {
		  [1] = {job = 'cardealer',           plate = 'PDM'},
		  [2] = {job = 'mechanic',            plate = 'BENNY'}
		}

		-- [[ These vehicles will always be LOCKED and cannot be Unlocked   ]] --
		Config.blacklistVehicles = {
		  "T20",
		  "RHINO"
		}

		-- [[ Vehicles wich will never be locked, great when using vehicles and no job or plate is Set  ]] --
		Config.whitelistVehicles = {
		  "burrito3",
		  "boxville"
		}
		-- [[ Same as Job plates but any vehicles with this plate can remote lock/unlock by anyone, great for jobs like ESX-Moneylaundering etc   ]] --

		Config.whitelistPlates = { 
		  "WAL"
		}
    
-- [[ Job Vehicle Lock System ]] --
	
	Ensure plate has a Max of 7 Character and at least 1 number eg: PDM 678

	The script will store the plate as PDM 678 but will strip the numbers and spaces away to authorise use eg: PDM

	ensure you only put the Letters in your plate in the Config.    

-- [[ Use table update ]] -- 

	If you have a script for handing over keys to vehicle then you will need to update the stored table this is simple to do

	-- plate = Vehicle Plate ( GetVehicleNumberPlateText(vehicle) )
	-- Owner = new owners Server ID (GetPlayerServerId(closestPlayer))
		
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		TriggerServerEvent('shorty_slocks:transferOwner', plate, owner)

-- [[ Call for Theft Systems ]] --

	-- Plate = Vehicle Plate ( GetVehicleNumberPlateText(vehicle) )

	TriggerServerEvent('shorty_slocks:breakIn', Plate)

-- [[ Call for Menu Systems ]] --
	
	TriggerClientEvent('shorty_slocks:setvehicleLockMenu', 'lock') - To Lock Vehicle Can Also Use, True or 2
	TriggerClientEvent('shorty_slocks:setvehicleLockMenu', 'unlock') - To Unlock can also use, False or 1
	TriggerClientEvent('shorty_slocks:setvehicleLockMenu', 'doubleLock') - To Lock DoubleLock, can also use 4

-- [[ Requirements ]] --

	Requires ESX

-- [[ Install ]] --

	Copy svehiclelocks folder to server resources folder

	adjust config to your liking 

	add	start svehiclelocks to server.cfg

-- [[ Patch Notes ]] --

	1.0.5
	Sync all cars plates with owner of the plates for the bug fix in
	5 min for any bug in cardelear purchase.

	1.0.4
	Added Option to call from a Menu System
	Added Rented Vehicles based on plate in Config Default 'RENT'
	
	1.0.3
	Fixed bad call when transfering owner
	Added Call for Breaking into Vehicles ( Lock Pick Script etc )

	1.0.2
	Added white listed Vehicles
	Added White Listed Plates

	1.0.1
	Fixed nil plate issue
	added SQL ready function to help with an SQL error
