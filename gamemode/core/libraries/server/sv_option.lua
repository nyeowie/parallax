--- Options library
-- @module ax.option

ax.option.clients = {}

function ax.option:Set(client, key, value)
    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return false
    end

    if ( !IsValid(client) ) then return false end

    if ( ax.util:DetectType(value) != stored.Type ) then
        ax.util:PrintError("Attempted to set option \"" .. key .. "\" with invalid type!")
        return false
    end

    if ( isnumber(value) ) then
        if ( isnumber(stored.Min) && value < stored.Min ) then
            ax.util:PrintError("Option \"" .. key .. "\" is below minimum value!")
            return false
        end

        if ( isnumber(stored.Max) && value > stored.Max ) then
            ax.util:PrintError("Option \"" .. key .. "\" is above maximum value!")
            return false
        end
    end

    ax.net:Start(nil, "option.set", key, value)

    if ( isfunction(stored.OnChange) ) then
        stored:OnChange(value, client)
    end

    if ( !stored.NoNetworking ) then
        if ( ax.option.clients[client] == nil ) then
            ax.option.clients[client] = {}
        end

        ax.option.clients[client][key] = value
    end

    return true
end

function ax.option:Get(client, key, default)
    if ( !IsValid(client) ) then return default end

    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return default
    end

    if ( stored.NoNetworking ) then
        ax.util:PrintWarning("Option \"" .. key .. "\" is not networked!")
        return nil
    end

    local plyStored = ax.option.clients[client]
    if ( !istable(plyStored) ) then
        return stored.Value or default
    end

    return plyStored[key] or stored.Default
end