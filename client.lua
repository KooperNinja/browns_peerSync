comms = { 
    told = {},
    hear = {} 
}

function tell(commsName, ...) 
    comms.told[commsName] = false  
    TriggerServerEvent('peer:server:listen', commsName, table.unpack({...})) 
    local i = 0
    while not comms.told[commsName] do 
        Citizen.Wait(1) 
        i += 1
        if i > 500 then 
            error("Could not receive data from the server", 2) 
            return
        end
    end  
    return table.unpack(comms.told[commsName]) 
end

RegisterNetEvent('peer:client:tell', function(commsName, data) 
    comms.told[commsName] = data
end)

function listen(commsName, cb) 
    comms.hear[commsName] = cb 
end

RegisterNetEvent('peer:client:listen', function(commsName, ...) 
    if comms.hear[commsName] then 
        comms.hear[commsName](table.unpack({...}))
    end
end)

peer = { 

    client = {
        id = nil, 
        name = nil, 
        license = nil 
    },

    peers = {}, 

    nets = {}, 

    data = {},

    new = function () 
        local id, name, license = tell('peer:server:new')
        peer.client.id = id
        peer.client.name = name 
        peer.client.license = license
    end,


    trigger = function (includeSelf, channels, eventName, ...) 
        local result = tell('peer:server:trigger', includeSelf, channels, eventName, ...)
        if result then return end
    end,

    drop = function () 
        local result = tell('peer:server:drop')
        if result then return end
    end,

    get = function ()
        local data = {}
        for key in pairs(peer.peers) do 
            if key then 
                data[key] = peer.peers[key]
            end
        end
        return data 
    end,

    setmetadata = function(key, value)
        local result = tell('peer:server:setmetadata', key, value)
        if result then return end
    end,

    getmetadata = function(key, serverId)
        if not peer.peers[tostring(GetPlayerServerId(PlayerId()))] then return end 
        if not key then return end 
        if serverId then 
            if peer.peers[tostring(serverId)] and peer.peers[tostring(serverId)].metadata[key] then  
                return peer.peers[tostring(serverId)].metadata[key]
            end
        end
        if not serverId then 
            if peer.peers[tostring(GetPlayerServerId(PlayerId()))].metadata[key] then  
                return peer.peers[tostring(GetPlayerServerId(PlayerId()))].metadata[key]
            end
        end
    end,

    channel = {
        add = function(channelName)
            local result = tell('peer:server:channel', 'add', channelName)
            if result then return end
        end,
        remove = function(channelName)
            if channelName == 'all' then return end 
            local result = tell('peer:server:channel', 'remove', channelName)
            if result then return end
        end
    },

    net = function(includeSelf, commsId, channels, ...)
        local result = tell('peer:server:net', includeSelf, commsId, channels, ...)
        if result then return end
    end,

    direct = function(commsId, serverId, ...)
        local result = tell('peer:server:direct', commsId, serverId, ...)
        if result then return end
    end,

    on = function(commsId, cb)
        peer.nets[commsId] = cb
    end,

    setdata = function(key, value)
        local result = tell('peer:server:setdata', key, value)
        if result then return end 
    end,

    getdata = function(key)
        if not peer.peers[tostring(GetPlayerServerId(PlayerId()))] then return end 
        if peer.data[key] then 
            return peer.data[key]
        end
    end

}

listen('peer:client:new', function(serverId, pedNetHandle, name, license)
    peer.peers[tostring(serverId)] = {
        entity = NetToPed(pedNetHandle),
        metadata = {},
        id = serverId, 
        name = name,
        license = license
    }
end)

listen('peer:client:setmetadata', function(serverId, key, value)
    peer.peers[tostring(serverId)].metadata[key] = value
end)

listen('peer:client:drop', function(serverId)
    peer.peers[tostring(serverId)] = nil
end)

listen('peer:client:on', function(commsId, ...)
    if peer.nets[commsId] then 
        peer.nets[commsId](table.unpack({...}))
    end
end)

listen('peer:client:setdata', function(key, value)
    peer.data[key] = value
end)

return peer
