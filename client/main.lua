--================================================================================================
--==                                 Client Variables                                           ==
--================================================================================================

ESX							= nil
local lastCar 				= nil
local lastCar2 				= nil
local myIdentity 			= {}
local myIdentifiers 		= {}
local lockStatus 			= nil
local lockStatusOutside		= nil
local vehicles 				= {}

--================================================================================================
--==                                  Client Threads                                            ==
--================================================================================================

Citizen.CreateThread(function()

	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while true do
		Wait(0)

		if IsControlJustPressed(1, 10) then
			SetNuiFocus(true, true)
			SendNUIMessage({type = 'openGeneral'})
			local ped = GetPlayerPed(-1)

			if IsPedInAnyVehicle(ped, true) then 
				SendNUIMessage({type = 'showVehicleButton'})
			else 
				SendNUIMessage({type = 'hideVehicleButton'})
			end		
		end
		
		if IsControlJustPressed(1, 322) then
			SetNuiFocus(false, false)
			SendNUIMessage({type = 'close'})
		end
		
		if IsControlJustPressed(1, 121) then
			doToggleVehicleLocks()
		end
		
		if IsControlJustPressed(1, 178) then
			doToggleEngine()
		end

--		if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then	
--				local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))				
--				local lock = GetVehicleDoorLockStatus(veh)			
--				local ped2 = GetPedInVehicleSeat(veh, -1)			
--				local job = tostring(exports['esx_policejob']:getJob())	
	--			local playerPed = nil
--
--				if Config.disableStealingNpcDrivenCars == true then
--
--	   				for i = 0, 31 do
--						if(ped2 == GetPlayerPed(i)) then
--						  	playerped = GetPlayerPed(i)
--						 	 break
--						end
--					end
--
--					if ped2 ~= 0 then
--
--						if ped2 == playerPed then
--							ESX.ShowNotification('System: Found Player.')
--							SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
--						else
--
--							if job == "police" or job == "ambulance" then
--								ESX.ShowNotification('System: Found NPC. Job Accepted.')
--								SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
--								SetPedCanBeDraggedOut(ped2, true)		
--								lastCar2 = veh				
---							else
	--							ESX.ShowNotification('System: Found NPC. Job Rejected.')
	--							SetVehicleDoorsLockedForPlayer(veh, PlayerId(), true)
	--							SetPedCanBeDraggedOut(ped2, false)
--							end
--						end
--
--					else
--						if lock ~= 2 then
--							if lastCar2 == veh then
--								ESX.ShowNotification('System: Saved Vehicle Found.')
--								SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
--								SetVehicleNeedsToBeHotwired(veh, false)
--							else
--								ESX.ShowNotification('System: No NPC or Player. Saved Vehicle Not Found.')
--								SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
--								SetVehicleDoorsLocked(veh, 7)
--								SetVehicleNeedsToBeHotwired(veh, true)
--								lastCar2 = veh
--							end
--						else
--							ESX.ShowNotification('System: Player Locked Vehicle Found.')
--							SetVehicleDoorsLockedForPlayer(veh, PlayerId(), true)
--						end
--					end
--				end
--			end
	end
end)

Citizen.CreateThread(function()
    timer = Config.lockTimer * 1000
    time = 0
	while true do
		Wait(1000)
		time = time + 1000
	end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)

        -- If the defined key is pressed
        if IsControlJustPressed(1, 11) then

            -- Init player infos
            local ply = GetPlayerPed(-1)
            local pCoords = GetEntityCoords(ply, true)
            local px, py, pz = table.unpack(GetEntityCoords(ply, true))
            isInside = false

            -- Retrieve the local ID of the targeted vehicle
            if(IsPedInAnyVehicle(ply, true))then
                -- by sitting inside him
                localVehId = GetVehiclePedIsIn(GetPlayerPed(-1), false)
                isInside = true
            else
                -- by targeting the vehicle
                localVehId = GetTargetedVehicle(pCoords, ply)
            end

            -- Get targeted vehicle infos
            if(localVehId and localVehId ~= 0)then
                local localVehPlateTest = GetVehicleNumberPlateText(localVehId)
                if localVehPlateTest ~= nil then
                    local localVehPlate = string.lower(localVehPlateTest)
                    local localVehLockStatus = GetVehicleDoorLockStatus(localVehId)
                    local hasKey = false

                    -- If the vehicle appear in the table (if this is the player's vehicle or a locked vehicle)
                    for plate, vehicle in pairs(vehicles) do
                        if(string.lower(plate) == localVehPlate)then
                            -- If the vehicle is not locked (this is the player's vehicle)
                            if(vehicle ~= "locked")then
                                hasKey = true
                                if(time > timer)then
                                    -- update the vehicle infos (Useful for hydrating instances created by the /givekey command)
                                    vehicle.update(localVehId, localVehLockStatus)
                                    -- Lock or unlock the vehicle
                                    vehicle.lock()
                                    time = 0
                                else
                                    TriggerEvent("aiomenu:notify", _U("lock_cooldown", (timer / 1000)))
                                end
                            else
                                TriggerEvent("aiomenu:notify", _U("keys_not_inside"))
                            end
                        end
                    end

                    -- If the player doesn't have the keys
                    if(not hasKey)then
                        -- If the player is inside the vehicle
                        if(isInside)then
                            -- If the player find the keys
                            if(canSteal())then
                                -- Check if the vehicle is already owned.
                                -- And send the parameters to create the vehicle object if this is not the case.
                                TriggerServerEvent('aiomenu:checkOwner', localVehId, localVehPlate, localVehLockStatus)
                            else
                                -- If the player doesn't find the keys
                                -- Lock the vehicle (players can't try to find the keys again)
                                vehicles[localVehPlate] = "locked"
                                TriggerServerEvent("aiomenu:lockTheVehicle", localVehPlate)
                                TriggerEvent("aiomenu:notify", _U("keys_not_inside"))
                            end
                        end
                    end
                else
                    TriggerEvent("aiomenu:notify", _U("could_not_find_plate"))
                end
            end
        end
    end
end)

--================================================================================================
--==                                  NUI Callbacks                                             ==
--================================================================================================

RegisterNUICallback('NUIFocusOff', function()
	SetNuiFocus(false, false)
	SendNUIMessage({type = 'closeAll'})
end)

RegisterNUICallback('NUIShowGeneral', function()
  SetNuiFocus(true, true)
  SendNUIMessage({type = 'openGeneral'})
end)

RegisterNUICallback('NUIShowInteractions', function()
  SetNuiFocus(true, true)
  SendNUIMessage({type = 'openInteractions'})
end)

RegisterNUICallback('toggleid', function(data)
	TriggerServerEvent('menu:id', myIdentifiers, data)
end)

RegisterNUICallback('togglephone', function(data)
	TriggerServerEvent('menu:phone', myIdentifiers, data)
end)

RegisterNUICallback('toggleEngineOnOff', function()
	doToggleEngine()
end)

RegisterNUICallback('toggleVehicleLocks', function()
	doToggleVehicleLocks()
end)

RegisterNUICallback('NUIESXActions', function(data)
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openESX'})
	SendNUIMessage({type = 'showInventoryButton'})
	SendNUIMessage({type = 'showPhoneButton'})
	SendNUIMessage({type = 'showBillingButton'})
	SendNUIMessage({type = 'showAnimationsButton'})
end)

RegisterNUICallback('NUIopenInventory', function()
	exports['es_extended']:openInventory()
end)

RegisterNUICallback('NUIopenPhone', function()
	exports['esx_phone']:openESXPhone()
end)

RegisterNUICallback('NUIopenBilling', function()
	exports['esx_billing']:openBilling()
end)

RegisterNUICallback('NUIsetVoice', function()
	exports['esx_voice']:setVoice()
end)

RegisterNUICallback('NUIopenAnimations', function()
	exports['esx_animations']:openAnimations()
end)

RegisterNUICallback('NUIJobActions', function(data)
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openJobs'})
	local job = tostring(exports['esx_policejob']:getJob())
	if job == 'police' then
		SendNUIMessage({type = 'showPoliceButton'})
		SendNUIMessage({type = 'hideAmbulanceButton'})
		SendNUIMessage({type = 'hideTaxiButton'})
		SendNUIMessage({type = 'hideMechanicButton'})
		SendNUIMessage({type = 'hideFireButton'})
	elseif job == 'ambulance' then
		SendNUIMessage({type = 'showAmbulanceButton'})
		SendNUIMessage({type = 'hidePoliceButton'})
		SendNUIMessage({type = 'hideTaxiButton'})
		SendNUIMessage({type = 'hideMechanicButton'})
		SendNUIMessage({type = 'hideFireButton'})
	elseif job == 'taxi' then
		SendNUIMessage({type = 'showTaxiButton'})
		SendNUIMessage({type = 'hidePoliceButton'})
		SendNUIMessage({type = 'hideAmbulanceButton'})
		SendNUIMessage({type = 'hideMechanicButton'})
		SendNUIMessage({type = 'hideFireButton'})
	elseif job == 'mecano' then
		SendNUIMessage({type = 'showMechanicButton'})
		SendNUIMessage({type = 'hidePoliceButton'})
		SendNUIMessage({type = 'hideAmbulanceButton'})
		SendNUIMessage({type = 'hideTaxiButton'})
		SendNUIMessage({type = 'hideFireButton'})
	elseif job == 'fire' then
		SendNUIMessage({type = 'showFireButton'})  
		SendNUIMessage({type = 'hideMechanicButton'})
		SendNUIMessage({type = 'hidePoliceButton'})
		SendNUIMessage({type = 'hideAmbulanceButton'})
		SendNUIMessage({type = 'hideTaxiButton'})
	else
		SendNUIMessage({type = 'hidePoliceButton'})
		SendNUIMessage({type = 'hideAmbulanceButton'})
		SendNUIMessage({type = 'hideTaxiButton'})
		SendNUIMessage({type = 'hideMechanicButton'})
		SendNUIMessage({type = 'hideFireButton'})
	end
end)

RegisterNUICallback('NUIopenAmbulance', function()
	exports['esx_ambulancejob']:openAmbulance()
end)

RegisterNUICallback('NUIopenPolice', function()
	exports['esx_policejob']:openPolice()
end)

RegisterNUICallback('NUIopenMechanic', function()
	exports['esx_mecanojob']:openMechanic()
end)

RegisterNUICallback('NUIopenTaxi', function()
	exports['esx_taxijob']:openTaxi()
end)

RegisterNUICallback('NUIopenFire', function()
	exports['esx_firejob']:openFire()
end)

RegisterNUICallback('NUIShowVehicleControls', function()
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openVehicleControls'})
end)

RegisterNUICallback('NUIShowDoorControls', function()
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openDoorControls'})
end)

RegisterNUICallback('NUIShowIndividualDoorControls', function()
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openIndividualDoorControls'})
end)

RegisterNUICallback('toggleAllOpenables', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		if GetVehicleDoorAngleRatio(vehicle, 0) > 0.0 then 
			SetVehicleDoorShut(vehicle, 0, false)
			SetVehicleDoorShut(vehicle, 1, false)
			SetVehicleDoorShut(vehicle, 2, false)	
			SetVehicleDoorShut(vehicle, 3, false)	
			SetVehicleDoorShut(vehicle, 4, false)	
			SetVehicleDoorShut(vehicle, 5, false)				
		else
			SetVehicleDoorOpen(vehicle, 0, false) 
			SetVehicleDoorOpen(vehicle, 1, false)   
			SetVehicleDoorOpen(vehicle, 2, false)   
			SetVehicleDoorOpen(vehicle, 3, false)   
			SetVehicleDoorOpen(vehicle, 4, false)   
			SetVehicleDoorOpen(vehicle, 5, false)               
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleFrontLeftDoor', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontLeftDoor = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'door_dside_f')
		if frontLeftDoor ~= -1 then
			if GetVehicleDoorAngleRatio(vehicle, 0) > 0.0 then 
				SetVehicleDoorShut(vehicle, 0, false)            
			else
				SetVehicleDoorOpen(vehicle, 0, false)             
			end
		else
			ESX.ShowNotification('This vehicle does not have a front driver-side door.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleFrontRightDoor', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontRightDoor = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'door_pside_f')
		if frontRightDoor ~= -1 then
			if GetVehicleDoorAngleRatio(vehicle, 1) > 0.0 then 
				SetVehicleDoorShut(vehicle, 1, false)            
			else
				SetVehicleDoorOpen(vehicle, 1, false)             
			end
		else
			ESX.ShowNotification('This vehicle does not have a front passenger-side door.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleRearLeftDoor', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearLeftDoor = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'door_dside_r')
		if rearLeftDoor ~= -1 then
			if GetVehicleDoorAngleRatio(vehicle, 2) > 0.0 then 
				SetVehicleDoorShut(vehicle, 2, false)            
			else
				SetVehicleDoorOpen(vehicle, 2, false)             
			end
		else
			ESX.ShowNotification('This vehicle does not have a rear driver-side door.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleRearRightDoor', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearRightDoor = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'door_pside_r')
		if rearRightDoor ~= -1 then
			if GetVehicleDoorAngleRatio(vehicle, 3) > 0.0 then 
				SetVehicleDoorShut(vehicle, 3, false)            
			else
				SetVehicleDoorOpen(vehicle, 3, false)             
			end
		else
			ESX.ShowNotification('This vehicle does not have a rear passenger-side door.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleHood', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local bonnet = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'bonnet')
		if bonnet ~= -1 then
			if GetVehicleDoorAngleRatio(vehicle, 4) > 0.0 then 
				SetVehicleDoorShut(vehicle, 4, false)            
			else
				SetVehicleDoorOpen(vehicle, 4, false)             
			end
		else
			ESX.ShowNotification('This vehicle does not have a hood.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleTrunk', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local boot = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'boot')
		if boot ~= -1 then
			if GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 then 
				SetVehicleDoorShut(vehicle, 5, false)            
			else
				SetVehicleDoorOpen(vehicle, 5, false)             
			end
		else
			ESX.ShowNotification('This vehicle does not have a trunk.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
    end
end)

RegisterNUICallback('toggleWindowsUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lf')
		local frontRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rf')
		local rearLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lr')
		local rearRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rr')
		local frontMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lm')
		local rearMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rm')
		if frontLeftWindow ~= -1 or frontRightWindow ~= -1 or rearLeftWindow ~= -1 or rearRightWindow ~= -1 or frontMiddleWindow ~= -1 or rearMiddleWindow ~= -1 then
			RollUpWindow(vehicle, 0)
			RollUpWindow(vehicle, 1)
			RollUpWindow(vehicle, 2)
			RollUpWindow(vehicle, 3)
			RollUpWindow(vehicle, 4)
			RollUpWindow(vehicle, 5)
		else
			ESX.ShowNotification('This vehicle has no windows.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleWindowsDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lf')
		local frontRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rf')
		local rearLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lr')
		local rearRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rr')
		local frontMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lm')
		local rearMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rm')
		if frontLeftWindow ~= -1 or frontRightWindow ~= -1 or rearLeftWindow ~= -1 or rearRightWindow ~= -1 or frontMiddleWindow ~= -1 or rearMiddleWindow ~= -1 then
			RollDownWindow(vehicle, 0)
			RollDownWindow(vehicle, 1)
			RollDownWindow(vehicle, 2)
			RollDownWindow(vehicle, 3)
			RollDownWindow(vehicle, 4)
			RollDownWindow(vehicle, 5)
		else
			ESX.ShowNotification('This vehicle has no windows.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleFrontLeftWindowUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lf')
		if frontLeftWindow ~= -1 then
			RollUpWindow(vehicle, 0)
		else
			ESX.ShowNotification('This vehicle has no front left window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleFrontLeftWindowDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lf')
		if frontLeftWindow ~= -1 then
			RollDownWindow(vehicle, 0)
		else
			ESX.ShowNotification('This vehicle has no front left window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleFrontRightWindowUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rf')
		if frontRightWindow ~= -1 then
			RollUpWindow(vehicle, 1)
		else
			ESX.ShowNotification('This vehicle has no front right window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleFrontRightWindowDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rf')
		if frontRightWindow ~= -1 then
			RollDownWindow(vehicle, 1)
		else
			ESX.ShowNotification('This vehicle has no front right window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleRearLeftWindowUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lr')
		if rearLeftWindow ~= -1 then
			RollUpWindow(vehicle, 2)
		else
			ESX.ShowNotification('This vehicle has no rear left window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleRearLeftWindowDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearLeftWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lr')
		if rearLeftWindow ~= -1 then
			RollDownWindow(vehicle, 2)
		else
			ESX.ShowNotification('This vehicle has no rear left window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleRearRightWindowUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rr')
		if rearRightWindow ~= -1 then
			RollUpWindow(vehicle, 3)
		else
			ESX.ShowNotification('This vehicle has no rear right window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleRearRightWindowDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearRightWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rr')
		if rearRightWindow ~= -1 then
			RollDownWindow(vehicle, 3)
		else
			ESX.ShowNotification('This vehicle has no rear right window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleFrontMiddleWindowUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lm')
		if frontMiddleWindow ~= -1 then
			RollUpWindow(vehicle, 4)
		else
			ESX.ShowNotification('This vehicle has no front middle window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleFrontMiddleWindowDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local frontMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_lm')
		if frontMiddleWindow ~= -1 then
			RollDownWindow(vehicle, 4)
		else
			ESX.ShowNotification('This vehicle has no front middle window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleRearMiddleWindowUp', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rm')
		if rearMiddleWindow ~= -1 then
			RollUpWindow(vehicle, 5)
		else
			ESX.ShowNotification('This vehicle has no rear middle window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('toggleRearMiddleWindowDown', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		local rearMiddleWindow = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'window_rm')
		if rearMiddleWindow ~= -1 then
			RollDownWindow(vehicle, 5)
		else
			ESX.ShowNotification('This vehicle has no rear middle window.')
		end
	else
		ESX.ShowNotification('You must be the driver of a vehicle to use this.')
	end
end)

RegisterNUICallback('NUIShowWindowControls', function()
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openWindowControls'})
end)

RegisterNUICallback('NUIShowIndividiualWindowControls', function()
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openIndividualWindowControls'})
end)

RegisterNUICallback('NUIShowCharacterControls', function()
	SetNuiFocus(true, true)
	SendNUIMessage({type = 'openCharacter'})
end)

RegisterNUICallback('NUIdeleteCharacter', function(data)
	TriggerServerEvent('menu:setChars', myIdentifiers)
	Wait(1000)
	SetNuiFocus(true, true)
	local bt  = myIdentity.character1
  
	SendNUIMessage({
		type = "deleteCharacter",
		char1    = bt,
		backBtn  = "Back",
		exitBtn  = "Exit"
	}) 
end)

RegisterNUICallback('NUInewCharacter', function(data)
	if myIdentity.character1 == "No Character" then
		exports['esx_identity']:openRegistry()
	else
		ESX.ShowNotification('You can only have one character.')
	end
end)

RegisterNUICallback('NUIDelChar', function(data)
	TriggerServerEvent('menu:deleteCharacter', myIdentifiers, data)
	cb(data)
end)

--================================================================================================
--==                                      Client Events                                         ==
--================================================================================================

RegisterNetEvent("aiomenu:updateVehiclePlate")
AddEventHandler("aiomenu:updateVehiclePlate", function(oldPlate, newPlate)
    local oldPlate = string.lower(oldPlate)
    local newPlate = string.lower(newPlate)

    if(vehicles[oldPlate])then
        vehicles[newPlate] = vehicles[oldPlate]
        vehicles[oldPlate] = nil

        TriggerServerEvent("aiomenu:updateServerVehiclePlate", oldPlate, newPlate)
    end
end)

RegisterNetEvent("aiomenu:getHasOwner")
AddEventHandler("aiomenu:getHasOwner", function(hasOwner, localVehId, localVehPlate, localVehLockStatus)
    if(not hasOwner)then
        TriggerEvent("aiomenu:newVehicle", localVehPlate, localVehId, localVehLockStatus)
        TriggerServerEvent("aiomenu:addOwner", localVehPlate)

        TriggerEvent("aiomenu:notify", getRandomMsg())
    else
        TriggerEvent("aiomenu:notify", _U("vehicle_not_owned"))
    end
end)

RegisterNetEvent("aiomenu:newVehicle")
AddEventHandler("aiomenu:newVehicle", function(plate, id, lockStatus)
    if(plate)then
        local plate = string.lower(plate)
        if(not id)then id = nil end
        if(not lockStatus)then lockStatus = nil end
        vehicles[plate] = newVehicle()
        vehicles[plate].__construct(plate, id, lockStatus)
    else
        print("Can't create the vehicle instance. Missing argument PLATE")
    end
end)

RegisterNetEvent("aiomenu:giveKeys")
AddEventHandler("aiomenu:giveKeys", function(plate)
    local plate = string.lower(plate)
    TriggerEvent("aiomenu:newVehicle", plate, nil, nil)
end)

AddEventHandler("playerSpawned", function()
    TriggerServerEvent("aiomenu:retrieveVehiclesOnconnect")
end)

RegisterNetEvent("aiomenu:notify")
AddEventHandler("aiomenu:notify", function(text, duration)
	Notify(text, duration)
end)

RegisterNetEvent("menu:setCharacters")
AddEventHandler("menu:setCharacters", function(identity)
	myIdentity = identity
end)

RegisterNetEvent("menu:setIdentifier")
AddEventHandler("menu:setIdentifier", function(data)
	myIdentifiers = data
end)

RegisterNetEvent("sendProximityMessageID")
AddEventHandler("sendProximityMessageID", function(id, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	if pid == myId then
		TriggerEvent('chatMessage', "[ID]" .. "", {0, 153, 204}, "^7 " .. message)
	elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(myId)), GetEntityCoords(GetPlayerPed(pid)), true) < 19.999 then
		TriggerEvent('chatMessage', "[ID]" .. "", {0, 153, 204}, "^7 " .. message)
	end
end)

RegisterNetEvent("sendProximityMessagePhone")
AddEventHandler("sendProximityMessagePhone", function(id, name, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	if pid == myId then
		TriggerEvent('chatMessage', "[Phone]^3(" .. name .. ")", {0, 153, 204}, "^7 " .. message)
	elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(myId)), GetEntityCoords(GetPlayerPed(pid)), true) < 19.999 then
		TriggerEvent('chatMessage', "[Phone]^3(" .. name .. ")", {0, 153, 204}, "^7 " .. message)
	end
end)

RegisterNetEvent("successfulDeleteIdentity")
AddEventHandler("successfulDeleteIdentity", function(data)
	ESX.ShowNotification('Successfully deleted ' .. data.firstname .. ' ' .. data.lastname .. '.')
end)

RegisterNetEvent("failedDeleteIdentity")
AddEventHandler("failedDeleteIdentity", function(data)
	ESX.ShowNotification('Failed to delete ' .. data.firstname .. ' ' .. data.lastname .. '. Please contact a server admin.')
end)

RegisterNetEvent("noIdentity")
AddEventHandler("noIdentity", function()
	ESX.ShowNotification('You do not have an identity.')
end)

RegisterNetEvent('esx_aiomenu:SuccessfulCheckPlates')
AddEventHandler('esx_aiomenu:SuccessfulCheckPlates', function(myIdentifiers, listPlates)
	ESX.ShowNotification('Return Successful: ' .. listPlates.plates1)
end)

RegisterNetEvent('esx_aiomenu:FailedCheckPlates')
AddEventHandler('esx_aiomenu:FailedCheckPlates', function(myIdentifiers, data)
	ESX.ShowNotification('Return failed.')
end)

RegisterNetEvent('InteractSound_CL:PlayOnOne')
AddEventHandler('InteractSound_CL:PlayOnOne', function(soundFile, soundVolume)
    SendNUIMessage({
        transactionType     = 'playSound',
        transactionFile     = soundFile,
        transactionVolume   = soundVolume
    })
end)

RegisterNetEvent('InteractSound_CL:PlayOnAll')
AddEventHandler('InteractSound_CL:PlayOnAll', function(soundFile, soundVolume)
    SendNUIMessage({
        transactionType     = 'playSound',
        transactionFile     = soundFile,
        transactionVolume   = soundVolume
    })
end)

RegisterNetEvent('InteractSound_CL:PlayWithinDistance')
AddEventHandler('InteractSound_CL:PlayWithinDistance', function(playerNetId, maxDistance, soundFile, soundVolume)
    local lCoords = GetEntityCoords(GetPlayerPed(-1))
    local eCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerNetId)))
    local distIs  = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
    if(distIs <= maxDistance) then
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = soundVolume
        })
    end
end)

RegisterNetEvent('InteractSound_CL:PlayOnVehicle')
AddEventHandler('InteractSound_CL:PlayOnVehicle', function(playerNetId, maxDistance, soundFile, soundVolume)
    local lCoords = GetEntityCoords(lastCar, false)
    local eCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerNetId)))
    local distIs  = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
	local farSound
    if(distIs <= maxDistance) then
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = soundVolume
        })
	elseif distIs > maxDistance and distIs < 10.0 then
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = 0.5
        })
	elseif distIs > 10.0 and distIs < 15.0 then
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = 0.25
        })
	elseif distIs > 15.0 and distIs < 20.0 then
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = 0.10
        })
    end
end)

--================================================================================================
--==                                      Functions                                             ==
--================================================================================================

function newVehicle()
    local self = {}

    self.id = nil
    self.plate = nil
    self.lockStatus = nil

    rTable = {}

    rTable.__construct = function(id, plate, lockStatus)
        if(id and type(id) == "number")then
            self.id = id
        end
        if(plate and type(plate) == "string")then
            self.plate = plate
        end
        if(lockStatus and type(lockStatus) == "number")then
            self.lockStatus = lockStatus
        end
    end

    -- Methods

    rTable.update = function(id, lockStatus)
        self.id = id
        self.lockStatus = lockStatus
    end

    -- 0, 1 = unlocked
    -- 2 = locked
    -- 4 = locked and player can't get out
    rTable.lock = function()
        lockStatus = self.lockStatus
        if(lockStatus <= 2)then
            self.lockStatus = 4
            SetVehicleDoorsLocked(self.id, self.lockStatus)
            SetVehicleDoorsLockedForAllPlayers(self.id, 1)
            TriggerEvent("aiomenu:notify", _U("vehicle_locked"))
            TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "lock", 1.0)
        elseif(lockStatus > 2)then
            self.lockStatus = 1
            SetVehicleDoorsLocked(self.id, self.lockStatus)
            SetVehicleDoorsLockedForAllPlayers(self.id, false)
            TriggerEvent("aiomenu:notify", _U("vehicle_unlocked"))
            TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "unlock", 1.0)
        end
    end

    -- Setters

    rTable.setId = function(id)
        if(type(id) == "number" and id >= 0)then
            self.id = id
        end
    end

    rTable.setPlate = function(plate)
        if(type(plate) == "string")then
            self.plate = plate
        end
    end

    rTable.setLockStatus = function(lockStatus)
        if(type(lockStatus) == "number" and lockStatus >= 0)then
            self.lockStatus = lockStatus
            SetVehicleDoorsLocked(self.id, lockStatus)
        end
    end

    -- Getters

    rTable.getId = function()
        return self.id
    end

    rTable.getPlate = function()
        return self.plate
    end

    rTable.getLockStatus = function()
        return self.lockStatus
    end

    return rTable
end

function canSteal()
    nb = math.random(1, 100)
    percentage = Config.percentage
    if(nb < percentage)then
        return true
    else
        return false
    end
end

function getRandomMsg()
    msgNb = math.random(1, #Config.randomMsg)
    return Config.randomMsg[msgNb]
end

function GetVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

function GetTargetedVehicle(pCoords, ply)
    for i = 1, 200 do
        coordB = GetOffsetFromEntityInWorldCoords(ply, 0.0, (6.281)/i, 0.0)
        targetedVehicle = GetVehicleInDirection(pCoords, coordB)
        if(targetedVehicle ~= nil and targetedVehicle ~= 0)then
            return targetedVehicle
        end
    end
    return
end

function Notify(text, duration)
	if(Config.notification)then
		if(Config.notification == 1)then
			if(not duration)then
				duration = 0.080
			end
			SetNotificationTextEntry("STRING")
			AddTextComponentString(text)
			Citizen.InvokeNative(0x1E6611149DB3DB6B, "CHAR_LIFEINVADER", "CHAR_LIFEINVADER", true, 1, "ESX AIOMenu " .. _VERSION, "By Deediezi", duration)
			DrawNotification_4(false, true)
		elseif(Config.notification == 2)then
			TriggerEvent('chatMessage', '^1ESX AIOMenu' .. _VERSION, {255, 255, 255}, text)
		else
			return
		end
	else
		return
	end
end

function checkForKey(source, vehPlate)
	if vehPlate ~= nil then
		TriggerServerEvent('aiomenu:haveKeys', source, vehPlate, function(callback)
			if callback ~= nil then
				if callback == true then
					return true
				elseif callback == false then
					return false
				else
					local text = "There was an error"
					return text
				end
			else
					local text = "Callback was nil"
					return text
			end
	else
		ESX.ShowNotification('No Vehicle Plates.')
	end
end

function doToggleEngine()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 then
		if GetPedInVehicleSeat(vehicle, 0) then
			if IsVehicleEngineOn(GetVehiclePedIsIn(GetPlayerPed(-1), false)) then
				SetVehicleEngineOn(vehicle, false, false, true)
			else
				SetVehicleEngineOn(vehicle, true, false, true)
			end
		else
			ESX.ShowNotification('You must be the driver of a vehicle to use this.')
		end
	else
		ESX.ShowNotification('You must be inside of a vehicle to use this.')
    end
end

function doToggleVehicleLocks()
	local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
	lockStatus = GetVehicleDoorLockStatus(vehicle)
	lockStatusOutside = GetVehicleDoorLockStatus(lastCar)
	
	if vehicle ~= nil and vehicle ~= 0 then
		if GetPedInVehicleSeat(vehicle, 0) then			
			if lockStatus ~= 7 then
				SetVehicleDoorsLocked(vehicle, 2)
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.2, 'lock', 1.0)
				ESX.ShowNotification('Your doors are now locked.')
				lastCar = GetVehiclePedIsIn(GetPlayerPed(-1), false)
			elseif lockStatus ~= 1 then
				SetVehicleDoorsLocked(vehicle, 1)
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.2, 'unlock', 1.0)
				ESX.ShowNotification('Your doors are now unlocked.')
				lastCar = GetVehiclePedIsIn(GetPlayerPed(-1), false)
			end
		else
			ESX.ShowNotification('You must be the driver of a vehicle to use this.')
		end
	elseif vehicle == 0 and lastCar ~= nil then
		if lockStatusOutside ~= 7 then
		
			local lib = "anim@mp_player_intmenu@key_fob@"
			local anim = "fob_click"
			
			ESX.Streaming.RequestAnimDict(lib, function()
				TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
			end)
		
		
			SetVehicleDoorsLocked(lastCar, 2)
			Wait(250)
			ESX.ShowNotification('Your doors are now locked.')
			TriggerServerEvent('InteractSound_SV:PlayOnVehicle', 5.0, 'lock2', 0.7)		
		elseif lockStatusOutside ~= 1 then
		
			local lib = "anim@mp_player_intmenu@key_fob@"
			local anim = "fob_click"
			
			ESX.Streaming.RequestAnimDict(lib, function()
				TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
			end)
			
			SetVehicleDoorsLocked(lastCar, 1)
			TriggerServerEvent('InteractSound_SV:PlayOnVehicle', 5.0, 'unlock2', 0.9)
			ESX.ShowNotification('Your doors are now unlocked.')
		else
			ESX.ShowNotification('There is no vehicle to lock/unlock.')
		end
	else
		ESX.ShowNotification('You must be inside of a vehicle to use this.')
	end
end