Call = {}
local isLoggedIn = false

function IsInCall()
    return (Call.number ~= nil and Call.status == 1) or (Call.number ~= nil and Call.status == 0 and Call.initiator)
end

RegisterNetEvent('mythic_phone:client:CreateCall')
AddEventHandler('mythic_phone:client:CreateCall', function(number)
    Call.number = number
    Call.status = 0
    Call.initiator = true

    PhonePlayCall(false)

    local count = 0
    Citizen.CreateThread(function()
        while Call.status == 0 do
            if count >= 30 then
                TriggerServerEvent('mythic_phone:server:EndCall', securityToken)

                if isPhoneOpen then
                    PhoneCallToText()
                else
                    PhonePlayOut()
                end

                Call = {}
            else
                count = count + 1
            end
            Citizen.Wait(1000)
        end
    end)
end)

RegisterNetEvent('mythic_phone:client:AcceptCall')
AddEventHandler('mythic_phone:client:AcceptCall', function(channel, initiator)
    if Call.number ~= nil and Call.status == 0 then
        Call.status = 1
        Call.channel = channel

        exports['tokovoip_script']:addPlayerToRadio(Call.channel, false)

        if initiator then
            SendNUIMessage({
                action = 'acceptCallSender',
                number = Call.number
            })
            exports['mythic_notify']:PersistentAlert('start', 'active-call', 'inform', 'You\'re In A Call', { ['background-color'] = '#ff8555', ['color'] = '#000000' })
        else
            exports['mythic_notify']:PersistentAlert('end', Config.IncomingNotifId)
            exports['mythic_notify']:PersistentAlert('start', 'active-call', 'inform', 'You\'re In A Call', { ['background-color'] = '#ff8555', ['color'] = '#000000' })
            PhonePlayCall(false)
            SendNUIMessage({
                action = 'acceptCallReceiver',
                number = Call.number
            })
        end
    end
end)

RegisterNetEvent('mythic_phone:client:EndCall')
AddEventHandler('mythic_phone:client:EndCall', function()
    SendNUIMessage({
        action = 'endCall'
    })
    exports['mythic_notify']:SendAlert('inform', 'Call Ended', 2500, { ['background-color'] = '#ff8555', ['color'] = '#000000' })
    exports['mythic_notify']:PersistentAlert('end', Config.IncomingNotifId)
    exports['mythic_notify']:PersistentAlert('end', 'active-call')
    exports['tokovoip_script']:removePlayerFromRadio(Call.channel)

    Call = {}

    if isPhoneOpen then
        PhoneCallToText()
    else
        PhonePlayOut()
    end
end)

RegisterNetEvent('mythic_phone:client:ReceiveCall')
AddEventHandler('mythic_phone:client:ReceiveCall', function(number)
    Call.number = number
    Call.status = 0
    Call.initiator = false

    SendNUIMessage({
        action = 'receiveCall',
        number = number
    })

    local count = 0
    Citizen.CreateThread(function()
        while Call.status == 0 do
            if count >= 30 then
                TriggerServerEvent('mythic_phone:server:EndCall', securityToken)
                Call = {}
            else
                count = count + 1
            end
            Citizen.Wait(1000)
        end
    end)
end)

RegisterNUICallback( 'CreateCall', function( data, cb )
    actionCb['CreateCall'] = cb
    TriggerServerEvent('mythic_phone:server:CreateCall', securityToken, 'CreateCall', data.number, data.nonStandard)
end)

RegisterNUICallback( 'AcceptCall', function( data, cb )
    print('please?')
    TriggerServerEvent('mythic_phone:server:AcceptCall', securityToken)
end)

RegisterNUICallback( 'EndCall', function( data, cb )
    TriggerServerEvent('mythic_phone:server:EndCall', securityToken, Call)
end)

RegisterNUICallback( 'DeleteCallRecord', function( data, cb )
    actionCb['DeleteCallRecord'] = cb
    TriggerServerEvent('mythic_phone:server:DeleteCallRecord', securityToken, 'DeleteCallRecord', data.id)
end)

RegisterNetEvent('mythic_base:client:Logout')
AddEventHandler('mythic_base:client:Logout', function()
    isLoggedIn = false
end)

AddEventHandler('mythic_base:client:CharacterSpawned', function()
    isLoggedIn = true

    Citizen.CreateThread(function()
        while isLoggedIn do
            if IsInCall() then
                if not Call.OtherHold then
                    if not Call.Hold then
                        DrawUIText("~r~[E] ~s~Hold ~r~| [G] ~s~Hangup", 4, 1, 0.5, 1.0, 0.5, 255, 255, 255, 255)
                    else
                        DrawUIText("~r~[E] ~s~Resume ~r~| [G] ~s~Hangup", 4, 1, 0.5, 1.0, 0.5, 255, 255, 255, 255)
                    end
                else
                    if not Call.Hold then
                        DrawUIText("~r~[E] ~s~Hold ~r~| [G] ~s~Hangup ~r~| ~s~On Hold", 4, 1, 0.5, 1.0, 0.5, 255, 255, 255, 255)
                    else
                        DrawUIText("~r~[E] ~s~Resume ~r~| [G] ~s~Hangup ~r~| ~s~On Hold", 4, 1, 0.5, 1.0, 0.5, 255, 255, 255, 255)
                    end
                end

                if IsControlJustReleased(1, 51) then
                    Call.Hold = not Call.Hold
                elseif IsControlJustREleased(1, 47) then
                    TriggerServerEvent('mythic_phone:server:EndCall', securityToken, Call)
                end

                Citizen.Wait(1)
            else
                Citizen.Wait(250)
            end
        end
    end)
end)