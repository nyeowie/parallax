function GM:CanDrive(client, entity)
    return false
end

function GM:CanPlayerJoinFaction(client, factionID)
    return true
end

function GM:PrePlayerHandsPickup(client, ent)
    return true
end

function GM:PrePlayerHandsPush(client, ent)
    return true
end

function GM:GetMainMenuMusic()
    return ax.config:Get("mainmenu.music", "music/hl2_song20_submix0.mp3")
end

function GM:PlayerGetToolgun(client)
    local character = client:GetCharacter()
    return CAMI.PlayerHasAccess(client, "Parallax - Toolgun", nil) or character and character:HasFlag("t")
end

function GM:PlayerGetPhysgun(client)
    return CAMI.PlayerHasAccess(client, "Parallax - Physgun", nil)
end

function GM:PlayerCanCreateCharacter(client, character)
    return true
end

function GM:PlayerCanDeleteCharacter(client, character)
    return true
end

function GM:PlayerCanLoadCharacter(client, character, currentCharacter)
    return true
end

function GM:CanPlayerTakeItem(client, item)
    return true
end

function GM:ItemCanBeDestroyed(item, damageInfo)
    return true
end

function GM:GetPlayerPainSound(client)
end

function GM:GetPlayerDeathSound(client)
end

function GM:PreOptionChanged(client, key, value)
end

function GM:PostOptionChanged(client, key, value)
end

function GM:PlayerCanHearChat(client, listener, uniqueID, text)
    local canHear = ax.chat:Get(uniqueID).CanHear
    if ( isbool(canHear) ) then
        return canHear
    elseif ( isfunction(canHear) ) then
        return ax.chat:Get(uniqueID):CanHear(client, listener, text)
    end

    return true
end

function GM:PreConfigChanged(key, value, oldValue, client)
end

function GM:PostConfigChanged(key, value, oldValue, client)
end

function GM:SetupMove(client, mv, cmd)
end

local KEY_SHOOT = IN_ATTACK + IN_ATTACK2
function GM:StartCommand(client, cmd)
    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) or !weapon:IsWeapon() ) then return end

    if ( !weapon.FireWhenLowered and !client:IsWeaponRaised() ) then
        cmd:RemoveKey(KEY_SHOOT)
    end
end

function GM:KeyPress(client, key)
    if ( SERVER and key == IN_RELOAD ) then
        timer.Create("ax.weapon.raise." .. client:SteamID64(), ax.config:Get("weapon.raise.time", 1), 1, function()
            if ( IsValid(client) ) then
                client:ToggleWeaponRaise()
            end
        end)
    end
end

function GM:KeyRelease(client, key)
    if ( SERVER and key == IN_RELOAD ) then
        timer.Remove("ax.weapon.raise." .. client:SteamID64())
    end
end

function GM:PlayerSwitchWeapon(client, hOldWeapon, hNewWeapon)
    if ( SERVER ) then
        timer.Simple(0.1, function()
            if ( IsValid(client) and IsValid(hNewWeapon) ) then
                client:SetWeaponRaised(false)
            end
        end)
    end
end

function GM:PreSpawnClientRagdoll(client)
end

function GM:GetGameDescription()
    return "Parallax: " .. (SCHEMA and SCHEMA.Name or "Unknown")
end