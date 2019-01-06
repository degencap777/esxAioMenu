--================================================================================================
--==                                 Server Variables                                           ==
--================================================================================================

characters = {}
owners = {}
secondOwners = {}

--================================================================================================
--==                                        SQL                                                 ==
--================================================================================================
MySQL.ready(function ()
    MySQL.Async.fetchAll("SELECT `plate`, `owner` FROM `owned_vehicles`",{}, function(data)
        for _,v in pairs(data) do
            local plate = string.lower(v.plate)
            owners[plate] = v.owner
        end
    end)
end)

--================================================================================================
--==                                   Server Events                                            ==
--================================================================================================

RegisterServerEvent("aiomenu:retrieveVehiclesOnconnect")
AddEventHandler("aiomenu:retrieveVehiclesOnconnect", function()
    local src = source
    local srcIdentifier = GetPlayerIdentifiers(src)[1]
    local data = MySQL.Sync.fetchAll("SELECT `plate`, `owner` FROM owned_vehicles",{})
    for _,v in pairs(data) do
        local plate = string.lower(v.plate)
        owners[plate] = v.owner
    end
    for plate, plyIdentifier in pairs(owners) do
        if(plyIdentifier == srcIdentifier)then
            local _plate = plate
            TriggerClientEvent("aiomenu:newVehicle", src, _plate, nil, nil)
        end
    end

    for plate, identifiers in pairs(secondOwners) do
        for _, plyIdentifier in ipairs(identifiers) do
            if(plyIdentifier == srcIdentifier)then
                TriggerClientEvent("aiomenu:newVehicle", src, plate, nil, nil)
            end
        end
    end
end)

RegisterServerEvent("aiomenu:addOwner")
AddEventHandler("aiomenu:addOwner", function(plate)
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]
    local plate = string.lower(plate)

    owners[plate] = identifier
end)

RegisterServerEvent("aiomenu:addOwnerWithIdentifier")
AddEventHandler("aiomenu:addOwnerWithIdentifier", function(targetIdentifier, plate)
    local plate = string.lower(plate)

    owners[plate] = targetIdentifier
end)

RegisterServerEvent("aiomenu:addSecondOwner")
AddEventHandler("aiomenu:addSecondOwner", function(targetIdentifier, plate)
    local plate = string.lower(plate)

    if(secondOwners[plate])then
        table.insert(secondOwners[plate], targetIdentifier)
    else
        secondOwners[plate] = {targetIdentifier}
    end
end)

RegisterNetEvent("aiomenu:checkOwner")
AddEventHandler("aiomenu:checkOwner", function(localVehId, plate, lockStatus)
    local plate = string.lower(plate)
    local src = source
    local hasOwner = false
    local identifier = GetPlayerIdentifiers(src)[1]
    if(not owners[plate])then
        TriggerClientEvent("aiomenu:getHasOwner", src, nil, localVehId, plate, lockStatus)
    else
        if(owners[plate] == "locked")then
            TriggerClientEvent("aiomenu:notify", src, _U('keys_not_inside'))
        else
            if(identifier == owners[plate]) then
                TriggerClientEvent("aiomenu:getHasOwner", src, nil, localVehId, plate, lockStatus)
            else
                TriggerClientEvent("aiomenu:getHasOwner", src, true, localVehId, plate, lockStatus)
            end
        end
    end
end)

RegisterServerEvent("aiomenu:lockTheVehicle")
AddEventHandler("aiomenu:lockTheVehicle", function(plate)
    owners[plate] = "locked"
end)

RegisterServerEvent("aiomenu:haveKeys")
AddEventHandler("aiomenu:haveKeys", function(target, vehPlate, cb)
    targetIdentifier = GetPlayerIdentifiers(target)[1]
    hasKey = false

    for plate, identifier in pairs(owners) do
        if(plate == vehPlate and identifier == targetIdentifier)then
            hasKey = true
            break
        end
    end
    for plate, identifiers in pairs(secondOwners) do
        if(plate == vehPlate)then
            for _, plyIdentifier in ipairs(identifiers) do
                if(plyIdentifier == targetIdentifier)then
                    hasKey = true
                    break
                end
            end
        end
    end

    if hasKey == true then
        return true
    else
        return false
    end
end)

RegisterServerEvent("aiomenu:updateServerVehiclePlate")
AddEventHandler("aiomenu:updateServerVehiclePlate", function(oldPlate, newPlate)
    local oldPlate = string.lower(oldPlate)
    local newPlate = string.lower(newPlate)

    if(owners[oldPlate] and not owners[newPlate])then
        owners[newPlate] = owners[oldPlate]
        owners[oldPlate] = nil
    end
    if(secondOwners[oldPlate] and not secondOwners[newPlate])then
        secondOwners[newPlate] = secondOwners[oldPlate]
        secondOwners[oldPlate] = nil
    end
end)

RegisterServerEvent('menu:id')
AddEventHandler('menu:id', function(myIdentifiers)
	getID(myIdentifiers.steamidentifier, function(data)
		if data ~= nil then
			TriggerClientEvent("sendProximityMessageID", -1, myIdentifiers.playerid, data.firstname .. " " .. data.lastname)
		end
	end)
end)

RegisterNetEvent('menu:phone')
AddEventHandler('menu:phone', function(myIdentifiers)
	getID(myIdentifiers.steamidentifier, function(data)
		if data ~= nil then
			local name = data.firstname .. " " .. data.lastname
			TriggerClientEvent("sendProximityMessagePhone", -1, myIdentifiers.playerid, name, data.phonenumber)
		end
	end)
end)

AddEventHandler('es:playerLoaded', function(source)
	local steamid = GetPlayerIdentifiers(source)[1]
  
	getCharacters(source, function(data)
		if data ~= nil then
			if data.firstname ~= '' then
				local char1 = tostring(data.firstname) .. " " .. tostring(data.lastname)
		
				identification = {
					steamidentifier = steamid,
					playerid        = source
				}
		
				character = char1
		  
				TriggerClientEvent('menu:setCharacters', source, character)	
				TriggerClientEvent('menu:setIdentifier', source, identification)
		
			else
				local char1 = "No Character"
		
				identification = {
					steamidentifier = steamid,
					playerid        = source
				}
		
				character = {
					character1         = char1
				}
		  
				TriggerClientEvent('menu:setCharacters', source, character)	
				TriggerClientEvent('menu:setIdentifier', source, identification)		
		
			end
		end
	end)
end)

RegisterServerEvent('menu:setChars')
AddEventHandler('menu:setChars', function(myIdentifiers)
	getChars(myIdentifiers.steamidentifier, function(data)	
		if data ~= nil then
			if data.firstname ~= '' then
				local char1 = tostring(data.firstname) .. " " .. tostring(data.lastname)
		      	characters = {
					character1         = char1,
				}
			
				TriggerClientEvent('menu:setCharacters', myIdentifiers.playerid, characters)
			else	
				characters = {
					character1 = 'No Character',
				}
				TriggerClientEvent('menu:setCharacters', myIdentifiers.playerid, characters)  
			end
		end
	end)
end)


RegisterServerEvent('menu:deleteCharacter')
AddEventHandler('menu:deleteCharacter', function(myIdentifiers)
	getChars(myIdentifiers.steamidentifier, function(data)
		local data = {
			identifier   = data.identifier,
			firstname  = data.firstname,
			lastname  = data.lastname,
			dateofbirth  = data.dateofbirth,
			sex      = data.sex,
			height    = data.height
		}
	
		if data.firstname ~= '' then
			deleteIdentity(myIdentifiers.steamidentifier, data, function(callback)
				if callback == true then
					TriggerClientEvent('successfulDeleteIdentity', myIdentifiers.playerid, data)
				else
					TriggerClientEvent('failedDeleteIdentity', myIdentifiers.playerid, data)
				end
			end)
		else
			TriggerClientEvent('noIdentity', myIdentifiers.playerid, {})
		end
	end)
end)

RegisterServerEvent('InteractSound_SV:PlayOnOne')
AddEventHandler('InteractSound_SV:PlayOnOne', function(clientNetId, soundFile, soundVolume)
    TriggerClientEvent('InteractSound_CL:PlayOnOne', clientNetId, soundFile, soundVolume)
end)

RegisterServerEvent('InteractSound_SV:PlayOnSource')
AddEventHandler('InteractSound_SV:PlayOnSource', function(soundFile, soundVolume)
    TriggerClientEvent('InteractSound_CL:PlayOnOne', source, soundFile, soundVolume)
end)

RegisterServerEvent('InteractSound_SV:PlayOnAll')
AddEventHandler('InteractSound_SV:PlayOnAll', function(soundFile, soundVolume)
    TriggerClientEvent('InteractSound_CL:PlayOnAll', -1, soundFile, soundVolume)
end)

RegisterServerEvent('InteractSound_SV:PlayWithinDistance')
AddEventHandler('InteractSound_SV:PlayWithinDistance', function(maxDistance, soundFile, soundVolume)
    TriggerClientEvent('InteractSound_CL:PlayWithinDistance', -1, source, maxDistance, soundFile, soundVolume)
end)

RegisterServerEvent('InteractSound_SV:PlayOnVehicle')
AddEventHandler('InteractSound_SV:PlayOnVehicle', function(maxDistance, soundFile, soundVolume)
    TriggerClientEvent('InteractSound_CL:PlayOnVehicle', -1, source, maxDistance, soundFile, soundVolume)
end)

--================================================================================================
--==                                     Functions                                              ==
--================================================================================================

function getIdentity(source, callback)
	local identifier = GetPlayerIdentifiers(source)[1]
	MySQL.Async.fetchAll("SELECT * FROM `users` WHERE `identifier` = @identifier",
	{
		['@identifier'] = identifier
	},
	function(result)
		if result[1] ~= nil then
			local data = {
				identifier	= identifier,
				firstname	= result[1]['firstname'],
				lastname	= result[1]['lastname'],
				dateofbirth	= result[1]['dateofbirth'],
				sex			= result[1]['sex'],
				height		= result[1]['height'],
				phonenumber = result[1]['phone_number']
			}
			
			callback(data)
		else	
			local data = {
				identifier 	= '',
				firstname 	= '',
				lastname 	= '',
				dateofbirth = '',
				sex 		= '',
				height 		= '',
				phonenumber = ''
			}
			
			callback(data)
		end
	end)
end

function getCharacters(source, callback)
	local identifier = GetPlayerIdentifiers(source)[1]
	MySQL.Async.fetchAll("SELECT * FROM `users` WHERE `identifier` = @identifier",
	{
		['@identifier'] = identifier
	},
	function(result)
		if result[1] then
			local data = {
				identifier    = result[1]['identifier'],
				firstname    = result[1]['firstname'],
				lastname    = result[1]['lastname'],
				dateofbirth  = result[1]['dateofbirth'],
				sex      = result[1]['sex'],
				height     = result[1]['height']
			}

			callback(data)
		else
			local data = {
				identifier    = '',
				firstname    = '',
				lastname    = '',
				dateofbirth  = '',
				sex      = '',
				height      = ''
			}

			callback(data)
		end
	end)
end

function getChars(steamid, callback)
	MySQL.Async.fetchAll("SELECT * FROM `users` WHERE `identifier` = @identifier",
	{
		['@identifier'] = steamid
	},
	function(result)
		if result[1] then
			local data = {
				identifier    = result[1]['identifier'],
				firstname    = result[1]['firstname'],
				lastname    = result[1]['lastname'],
				dateofbirth  = result[1]['dateofbirth'],
				sex      = result[1]['sex'],
				height      = result[1]['height']
			}

			callback(data)
		else
			local data = {
				identifier    = '',
				firstname     = '',
				lastname    = '',
				dateofbirth  = '',
				sex     = '',
				height      = ''
			}

			callback(data)
		end
	end)
end

function getID(steamid, callback)
	MySQL.Async.fetchAll("SELECT * FROM `users` WHERE `identifier` = @identifier",
	{
		['@identifier'] = steamid
	},
	function(result)
		if result[1] ~= nil then
			local data = {
				identifier	= identifier,
				firstname	= result[1]['firstname'],
				lastname	= result[1]['lastname'],
				dateofbirth	= result[1]['dateofbirth'],
				sex			= result[1]['sex'],
				height		= result[1]['height'],
				phonenumber = result[1]['phone_number']
			}
			
			callback(data)
		else	
			local data = {
				identifier 	= '',
				firstname 	= '',
				lastname 	= '',
				dateofbirth = '',
				sex 		= '',
				height 		= '',
				phonenumber = ''
			}
			
			callback(data)
		end
	end)
end

function updateIdentity(identifier, data, callback)
	MySQL.Async.execute('UPDATE `users` SET `firstname` = @firstname, `lastname` = @lastname, `dateofbirth` = @dateofbirth, `sex` = @sex, `height` = @height WHERE identifier = @identifier', {
		['@identifier']		= identifier,
		['@firstname']		= data.firstname,
		['@lastname']		= data.lastname,
		['@dateofbirth']	= data.dateofbirth,
		['@sex']			= data.sex,
		['@height']			= data.height
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function deleteIdentity(identifier, data, callback)
	MySQL.Async.execute('UPDATE `users` SET `firstname` = @firstname, `lastname` = @lastname, `dateofbirth` = @dateofbirth, `sex` = @sex, `height` = @height WHERE identifier = @identifier', {
		['@identifier']		= identifier,
		['@firstname']		= '',
		['@lastname']		= '',
		['@dateofbirth']	= '',
		['@sex']			= '',
		['@height']			= ''
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function getPlayerID(source)
	local identifiers = GetPlayerIdentifiers(source)
	local player = getIdentifiant(identifiers)
	return player
end

function getIdentifiant(id)
	for _, v in ipairs(id) do
		return v
	end
end

--================================================================================================
--==                                   VersionChecker                                           ==
--================================================================================================

if Config.versionChecker == true then
    PerformHttpRequest("https://github.com/ArkSeyonet/esx_aiomenu/blob/master/VERSION", function(err, rText, headers)
		if rText then
			if tonumber(rText) > tonumber(_VERSION) then
				print("\n---------------------------------------------------")
				print("ESX AIOMenu: Update Available!")
				print("---------------------------------------------------")
				print("Current : " .. _VERSION)
				print("Latest  : " .. rText .. "\n")
			end
		else
			print("\n---------------------------------------------------")
			print("Unable to find ESX AIOMenu version.")
			print("---------------------------------------------------\n")
		end
	end, "GET", "", {what = 'this'})
end