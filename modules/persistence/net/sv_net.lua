local MODULE = MODULE

ax.net:Hook("persistence.mark", function(client, ent)
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    if ( ent:GetRelay("persistent") == true ) then
        client:Notify("This entity is already marked for persistence.")
        return
    end

    ent:SetRelay("persistent", true)
    ax.log:Send(ax.log:Format(client) .. " marked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Marked entity " .. tostring(ent) .. " as persistent.")

    MODULE:SaveEntities()
end)

ax.net:Hook("persistence.unmark", function(client, ent)
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    if ( ent:GetRelay("persistent") != true ) then
        client:Notify("This entity is not marked for persistence.")
        return
    end

    ent:SetRelay("persistent", false)
    ax.log:Send(ax.log:Format(client) .. " unmarked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Unmarked entity " .. tostring(ent) .. " as persistent.")

    MODULE:SaveEntities()
end)