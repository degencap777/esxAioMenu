if(Config.enableSharingKeys)then
    RegisterCommand('givekey', function(source, args, rawCommand)
        local src = source
        local identifier = GetPlayerIdentifiers(src)[1]

        if(args[1])then
            local targetId = args[1]
            local targetIdentifier = GetPlayerIdentifiers(targetId)[1]
            if(targetIdentifier)then
                if(targetIdentifier ~= identifier)then
                    if(args[2])then
                        local plate = string.lower(args[2])
                        if(owners[plate])then
                            if(owners[plate] == identifier)then
                                alreadyHas = false
                                for k, v in pairs(secondOwners) do
                                    if(k == plate)then
                                        for _, val in ipairs(v) do
                                            if(val == targetIdentifier)then
                                                alreadyHas = true
                                            end
                                        end
                                    end
                                end

                                if(not alreadyHas)then
                                    TriggerClientEvent("aiomenu:giveKeys", targetId, plate)
                                    TriggerEvent("aiomenu:addSecondOwner", targetIdentifier, plate)

                                    TriggerClientEvent("aiomenu:notify", targetId, _U("you_received_keys", plate, GetPlayerName(src)))
                                    TriggerClientEvent("aiomenu:notify", src, _U('you_gave_keys', plate, GetPlayerName(targetId)))
                                else
                                    TriggerClientEvent("aiomenu:notify", src, _U('target_has_keys_sender'))
                                    TriggerClientEvent("aiomenu:notify", targetId, _U('target_has_keys_receiver', GetPlayerName(src)))
                                end
                            else
                                TriggerClientEvent("aiomenu:notify", src, _U('vehicle_not_owned'))
                            end
                        else
                            TriggerClientEvent("aiomenu:notify", src, _U('vehicle_not_exist'))
                        end
                    else
                        TriggerClientEvent("aiomenu:notify", src, _U('missing_argument_second'))
                    end
                else
                    TriggerClientEvent("aiomenu:notify", src, _U('player_not_found'))
                end
            else
                TriggerClientEvent("aiomenu:notify", src, _U('player_not_found'))
            end
        else
            TriggerClientEvent("aiomenu:notify", src, _U('missing_argument_first'))
        end

        CancelEvent()
    end)
end