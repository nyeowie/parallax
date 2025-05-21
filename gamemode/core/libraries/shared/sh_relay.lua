--- Relay
-- A secure value distribution system using SFS for packing and syncing values.
-- Provides shared (global), user (per-player), and entity (per-entity) scopes.
-- @module ax.relay

ax.relay = ax.relay or {}
ax.relay.shared = ax.relay.shared  or {}
ax.relay.user = ax.relay.user or {}
ax.relay.entity = ax.relay.entity or {}

local playerMeta = FindMetaTable("Player")
local entityMeta = FindMetaTable("Entity")

function ax.relay:SetRelay(key, value, recipient)
    self.shared[key] = value

    if ( SERVER ) then
        ax.net:Start(recipient, "relay.shared", key, value)
    end
end

function ax.relay:GetRelay(key, default)
    local v = self.shared[key]
    return v != nil and v or default
end

if ( CLIENT ) then
    ax.net:Hook("relay.shared", function(key, value)
        if ( value == nil ) then return end

        ax.relay.shared[key] = value
    end)
end

function playerMeta:SetRelay(key, value, recipient)
    if ( SERVER ) then
        ax.relay.user[self] = ax.relay.user[self] or {}
        ax.relay.user[self][key] = value

        ax.net:Start(recipient, "relay.user", self:EntIndex(), key, value)
    end
end

function playerMeta:GetRelay(key, default)
    local t = ax.relay.user[self]
    if ( t == nil ) then
        return default
    end

    return t[key] == nil and default or t[key]
end

if ( CLIENT ) then
    ax.net:Hook("relay.user", function(index, key, value)
        if ( value == nil ) then return end

        local client = Entity(index)
        if ( IsValid(client) ) then
            ax.relay.user[client] = ax.relay.user[client] or {}
            ax.relay.user[client][key] = value
        else
            ax.util:PrintError("Attempted to set relay for invalid client: " .. tostring(index))
            return
        end
    end)
end

function entityMeta:SetRelay(key, value, recipient)
    if ( SERVER ) then
        ax.relay.entity[self] = ax.relay.entity[self] or {}
        ax.relay.entity[self][key] = value

        ax.net:Start(recipient, "relay.entity", self:EntIndex(), key, value)
    end
end

function entityMeta:GetRelay(key, default)
    local t = ax.relay.entity[self]
    if ( t == nil ) then
        return default
    end

    return t[key] == nil and default or t[key]
end

if ( CLIENT ) then
    ax.net:Hook("relay.entity", function(index, key, value)
        if ( value == nil ) then return end

        local ent = Entity(index)
        if ( IsValid(ent) ) then
            ax.relay.entity[ent] = ax.relay.entity[ent] or {}
            ax.relay.entity[ent][key] = value
        else
            ax.util:PrintError("Attempted to set relay for invalid entity: " .. tostring(index))
            return
        end
    end)
end