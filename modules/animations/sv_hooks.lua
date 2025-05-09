local MODULE = MODULE

function MODULE:PostEntitySetModel(ent, model)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    local client = ent
    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return end

    holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

    local animTable = ax.animations.stored[ax.animations:GetModelClass(model)]
    if ( animTable and animTable[holdType] ) then
        client.axAnimations = animTable[holdType]
    else
        client.axAnimations = {}
    end

    ax.net:Start(nil, "animations.update", client, client.axAnimations)
end

function MODULE:PlayerSpawn(client)
    if ( !IsValid(client) ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return end

    holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

    local animTable = ax.animations.stored[ax.animations:GetModelClass(client:GetModel())]
    if ( animTable and animTable[holdType] ) then
        client.axAnimations = animTable[holdType]
    else
        client.axAnimations = {}
    end

    ax.net:Start(nil, "animations.update", client, client.axAnimations)
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    if ( !IsValid(client) ) then return end
    if ( !IsValid(newWeapon) ) then return end

    local holdType = newWeapon:GetHoldType()
    if ( !holdType ) then return end

    holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

    local animTable = ax.animations.stored[ax.animations:GetModelClass(client:GetModel())]
    if ( animTable and animTable[holdType] ) then
        client.axAnimations = animTable[holdType]
    else
        client.axAnimations = {}
    end

    ax.net:Start(nil, "animations.update", client, client.axAnimations)
end