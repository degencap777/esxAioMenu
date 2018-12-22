local Vehicle = GetVehiclePedIsIn(ped, false)
local inVehicle = IsPedSittingInAnyVehicle(ped)
local lastCar = nil
local myIdentity = {}
local myIdentifiers = {}
local lastCar = 0

ESX                           = nil

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
		
		if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
			local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
			local job = tostring(exports['esx_policejob']:getJob())
			if job == "police" or job == "ambulance" then
				SetVehicleDoorsLocked(veh, 0)
				SetPedCanBeDraggedOut(ped2, true)
			else
				if GetVehicleClass(veh) ~= 18 and GetVehicleClass(veh) ~= 19 then
					
					if ped2 ~= 0 then	
						if lock ~= 4 then
							SetVehicleDoorsLocked(veh, 4)
							SetPedCanBeDraggedOut(ped2, false)
						end
					else
						SetVehicleDoorsLocked(veh, 4)
						SetPedCanBeDraggedOut(ped2, false)
					end
				end
			end
		end
	end
end)

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

function doToggleEngine()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 then
		if GetPedInVehicleSeat(vehicle, 0) then
			if IsVehicleEngineOn(GetVehiclePedIsIn(GetPlayerPed(-1), false)) then
				SetVehicleEngineOn(vehicle, false, false, true)
				ESX.ShowNotification('Your engine is now off.')
			else
				SetVehicleEngineOn(vehicle, true, false, true)
				ESX.ShowNotification('Your engine is now on.')
			end
		else
			ESX.ShowNotification('You must be the driver of a vehicle to use this.')
		end
	else
		ESX.ShowNotification('You must be inside of a vehicle to use this.')
    end
end

RegisterNUICallback('toggleVehicleLocks', function()
	local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
	lockStatus = GetVehicleDoorLockStatus(vehicle)
	lockStatusOutside = GetVehicleDoorLockStatus(lastCar)
	if vehicle ~= nil and vehicle ~= 0 then
		if GetPedInVehicleSeat(vehicle, 0) then
			if lockStatus == 0 or lockStatus == 1 then
				SetVehicleDoorsLocked(vehicle, 2)
				SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), true)
				SetVehicleDoorsLockedForAllPlayers(vehicle, true)
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'lock', 1.0)
				ESX.ShowNotification('Your doors are now locked.')
				lastCar = GetVehiclePedIsIn(GetPlayerPed(-1), false)
			elseif lockStatus == 2 then
				SetVehicleDoorsLocked(vehicle, 1)
				SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
				SetVehicleDoorsLockedForAllPlayers(vehicle, false)
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'unlock', 1.0)
				ESX.ShowNotification('Your doors are now unlocked.')
				lastCar = GetVehiclePedIsIn(GetPlayerPed(-1), false)
			end
		else
			ESX.ShowNotification('You must be the driver of a vehicle to use this.')
		end
	elseif vehicle == 0 and lastCar ~= 0 then
		if lockStatusOutside == 0 or lockStatusOutside == 1 then
		
			local lib = "anim@mp_player_intmenu@key_fob@"
			local anim = "fob_click"
			
			ESX.Streaming.RequestAnimDict(lib, function()
				TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
			end)
		
		
			SetVehicleDoorsLocked(lastCar, 2)
			SetVehicleDoorsLockedForPlayer(lastCar, PlayerId(), true)
			SetVehicleDoorsLockedForAllPlayers(lastCar, true)
			TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'lock', 1.0)
			ESX.ShowNotification('Your doors are now locked.')
			Wait(250)
			TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'lock2', 0.7)		
		elseif lockStatusOutside == 2 then
		
			local lib = "anim@mp_player_intmenu@key_fob@"
			local anim = "fob_click"
			
			ESX.Streaming.RequestAnimDict(lib, function()
				TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
			end)
			
			SetVehicleDoorsLocked(lastCar, 1)
			SetVehicleDoorsLockedForAllPlayers(lastCar, false)
			TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'unlock', 1.0)
			ESX.ShowNotification('Your doors are now unlocked.')
		else
			ESX.ShowNotification('There is no vehicle to lock/unlock.')
		end
	else
		ESX.ShowNotification('You must be inside of a vehicle to use this.')
	end
end)

--================================================================================================
--==                                  ESX Actions GUI                                           ==
--================================================================================================
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

RegisterNetEvent("menu:setCharacters")
AddEventHandler("menu:setCharacters", function(identity)
	myIdentity = identity
end)

RegisterNetEvent("menu:setIdentifier")
AddEventHandler("menu:setIdentifier", function(data)
	myIdentifiers = data
end)

RegisterNUICallback('NUIdeleteCharacter', function(data)
	TriggerServerEvent('menu:setChars', myIdentifiers)
	Wait(1000)
	SetNuiFocus(true, true)
	local bt  = myIdentity.character1 --- Character 1 ---
  
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

RegisterNetEvent('sendProximityMessageID')
AddEventHandler('sendProximityMessageID', function(id, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	if pid == myId then
		TriggerEvent('chatMessage', "[ID]" .. "", {0, 153, 204}, "^7 " .. message)
	elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(myId)), GetEntityCoords(GetPlayerPed(pid)), true) < 19.999 then
		TriggerEvent('chatMessage', "[ID]" .. "", {0, 153, 204}, "^7 " .. message)
	end
end)

RegisterNetEvent('sendProximityMessagePhone')
AddEventHandler('sendProximityMessagePhone', function(id, name, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	if pid == myId then
		TriggerEvent('chatMessage', "[Phone]^3(" .. name .. ")", {0, 153, 204}, "^7 " .. message)
	elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(myId)), GetEntityCoords(GetPlayerPed(pid)), true) < 19.999 then
		TriggerEvent('chatMessage', "[Phone]^3(" .. name .. ")", {0, 153, 204}, "^7 " .. message)
	end
end)

RegisterNetEvent('successfulDeleteIdentity')
AddEventHandler('successfulDeleteIdentity', function(data)
	ESX.ShowNotification('Successfully deleted ' .. data.firstname .. ' ' .. data.lastname .. '.')
end)

RegisterNetEvent('failedDeleteIdentity')
AddEventHandler('failedDeleteIdentity', function(data)
	ESX.ShowNotification('Failed to delete ' .. data.firstname .. ' ' .. data.lastname .. '. Please contact a server admin.')
end)

RegisterNetEvent('noIdentity')
AddEventHandler('noIdentity', function()
	ESX.ShowNotification('You do not have an identity.')
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
