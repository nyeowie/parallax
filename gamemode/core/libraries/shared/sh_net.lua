-- ax.net
-- Streaming data layer using sfs. NetStream-style API.
-- @realm shared

ax.net = ax.net or {}
ax.net.stored = ax.net.stored or {}

if ( SERVER ) then
    util.AddNetworkString("ax.net.msg")
end

--- Hooks a network message.
-- @string name Unique identifier.
-- @func callback Callback with player, unpacked arguments.
function ax.net:Hook(name, callback)
    self.stored[name] = callback
end

--- Starts a stream.
-- @param target Player, table, vector or nil (nil = broadcast or to server).
-- @string name Hook name.
-- @vararg Arguments to send.
if ( SERVER ) then
    function ax.net:Start(target, name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)
        if ( !isstring(encoded) or #encoded < 1 ) then return end

        local recipients = {}
        local sendPVS = false

        if ( isvector(target) ) then
            sendPVS = true
        elseif ( istable(target) ) then
            for _, v in ipairs(target) do
                if ( IsValid(v) and v:IsPlayer() ) then
                    recipients[#recipients + 1] = v
                end
            end
        elseif ( IsValid(target) and target:IsPlayer() ) then
            recipients[1] = target
        else
            recipients = select(2, player.Iterator())
        end

        net.Start("ax.net.msg")
            net.WriteString(name)
            net.WriteData(encoded, #encoded)

        if ( sendPVS ) then
            net.SendPVS(target)
        else
            net.Send(recipients)
        end

        if ( ax.config:Get("debug.networking") ) then
            ax.util:Print("[Networking] Sent '" .. name .. "' to " .. (SERVER and #recipients .. " players" or "server"))
        end
    end
else
    function ax.net:Start(name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)
        if ( !isstring(encoded) or #encoded < 1 ) then return end

        net.Start("ax.net.msg")
            net.WriteString(name)
            net.WriteData(encoded, #encoded)
        net.SendToServer()
    end
end

net.Receive("ax.net.msg", function(len, ply)
    local name = net.ReadString()
    local raw = net.ReadData(len / 8)

    local ok, decoded = pcall(sfs.decode, raw)
    if ( !ok or type(decoded) != "table" ) then
        ErrorNoHalt("[Networking] Decode failed for '" .. name .. "'\n")
        return
    end

    local callback = ax.net.stored[name]
    if ( !isfunction(callback) ) then
        ErrorNoHalt("[Networking] No handler for '" .. name .. "'\n")
        return
    end

    if ( SERVER ) then
        callback(ply, unpack(decoded))
    else
        callback(unpack(decoded))
    end

    if ( ax.config:Get("debug.networking") ) then
        ax.util:Print("[Networking] Received '" .. name .. "' from " .. (SERVER and ply:Nick() or "server"))
    end
end)

--[[
--- Example usage:
if ( SERVER ) then
    ax.net:Hook("test", function(client, val, val2)
        print(client, "sent:", val, val2)
    end)
end

if ( CLIENT ) then
    ax.net:Start(nil, "test", {89})
    ax.net:Start(nil, "test", "hello", "world")
end
]]