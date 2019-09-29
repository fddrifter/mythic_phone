RegisterServerEvent('mythic_base:server:CharacterSpawned')
AddEventHandler('mythic_base:server:CharacterSpawned', function()
    local src = source
    Citizen.CreateThread(function()
        exports['ghmattimysql']:execute('SELECT * FROM phone_tweets ORDER BY time DESC', {}, function(tweets) 
            TriggerClientEvent('mythic_phone:client:SetupData', src, { { name = 'tweets', data = tweets } })
        end)
    end)
end)

AddEventHandler('mythic_base:shared:ComponentsReady', function()
    while Callbacks == nil do
        Citizen.Wait(100)
    end

    Callbacks:RegisterServerCallback('mythic_phone:server:NewTweet', function(source, event, data)
        local returnVal = nil
        local tweet = {}

        Citizen.CreateThread(function()
            local returnData = nil
            local char = exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character')
            local author = char:GetData('firstName') .. '_' .. char:GetData('lastName')
            local message = data.message
            local mentions = data.mentions
            local hashtags = data.hashtags
            local users = exports['mythic_base']:FetchComponent('Fetch'):All()

            if mentions ~= nil then
                for k, v in pairs(mentions) do
                    for k2, v2 in pairs(users) do
                        local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(v2)
                        local c2 = mPlayer:GetData('character')
                        if ('@' .. c2:GetData('firstName') .. '_' .. c2:GetData('lastName')) == v then
                            TriggerClientEvent('mythic_phone:client:MentionedInTweet', mPlayer:GetData('source'), author)
                        end
                    end
                end
            end
    
            exports['ghmattimysql']:execute('INSERT INTO phone_tweets (`author_id`, `author`, `message`) VALUES(@id, @author, @message)', { ['id'] = char:GetData('id'), ['author'] = author, ['message'] = message }, function(status)
                if status.affectedRows > 0 then
                    tweet.author = author
                    tweet.message = message

                    returnVal = tweet
                else
                    returnVal = false
                end
            end)
        end)

        while returnVal == nil do
            Citizen.Wait(100)
        end

        if tweet.message ~= nil then
            TriggerClientEvent('mythic_phone:client:ReceiveNewTweet', -1, tweet)
        end

        return tweet
    end)
end)