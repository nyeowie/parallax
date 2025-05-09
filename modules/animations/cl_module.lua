ax.net:Hook("animations.update", function(client, data)
    if ( !IsValid(client) or !istable(data) ) then return end

    client.axAnimations = data
    client.axLastAct = -1

    -- ew...
    client:SetIK(false)
end)