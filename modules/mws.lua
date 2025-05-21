local MODULE = MODULE or {}
MODULE.name = "Melee Cooldown"
MODULE.author = "Rurune"
MODULE.description = "Adds a cooldown to primary attack of melee weapons and freezes player during cooldown"

MODULE.config = {
    cooldown = 1.5,
    debug = false
}

local playerCooldowns = {}

local function IsWeaponRaised(ply)
    if not IsValid(ply) then return false end
    
    if ply.IsWeaponRaised and isfunction(ply.IsWeaponRaised) then
        return ply:IsWeaponRaised()
    end
    
    return true 
end

local function IsMeleeWeapon(weapon)
    if not IsValid(weapon) then return false end
    
    if weapon.IsMelee then return true end
    if weapon.Primary and weapon.Primary.Damage and not weapon.Primary.Ammo then return true end
    if weapon.ClassName and string.find(string.lower(weapon.ClassName), "melee") then return true end
    
    local meleeClasses = {
        "weapon_crowbar",
        "weapon_stunstick",
        "ax_hands",
    }
    
    for _, class in ipairs(meleeClasses) do
        if weapon:GetClass() == class then
            return true
        end
    end
    
    return false
end

local function DebugPrint(...)
    if MODULE.config.debug then
        print("[MeleeCooldown]", ...)
    end
end

local originalAttackFunctions = {}

hook.Add("Think", "MeleeCooldown_Think", function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        
        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then continue end
        
        if not IsMeleeWeapon(weapon) then continue end
        
        if not IsWeaponRaised(ply) then continue end
        
        local steamID = ply:SteamID()
        local weaponID = weapon:EntIndex()
        
        if not originalAttackFunctions[weaponID] and weapon.PrimaryAttack then
            originalAttackFunctions[weaponID] = weapon.PrimaryAttack
            DebugPrint("Stored original attack function for weapon", weaponID)
        end

        if playerCooldowns[steamID] and playerCooldowns[steamID] > CurTime() then
            weapon.PrimaryAttack = function(self)
                DebugPrint("Attack blocked - " .. math.Round(playerCooldowns[steamID] - CurTime(), 2) .. "s cooldown remaining")
                return false
            end
            
            ply:SetMoveType(MOVETYPE_NONE)
        else
            if originalAttackFunctions[weaponID] then
                weapon.PrimaryAttack = originalAttackFunctions[weaponID]
                DebugPrint("Restored original attack function for player " .. ply:Nick())
            end
            
            ply:SetMoveType(MOVETYPE_WALK)
        end
    end
end)

hook.Add("PlayerPostThink", "MeleeCooldown_PostThink", function(ply)
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not IsMeleeWeapon(weapon) then return end
    
    if not IsWeaponRaised(ply) then return end
    
    local steamID = ply:SteamID()
    
    if ply:KeyPressed(IN_ATTACK) and (not playerCooldowns[steamID] or playerCooldowns[steamID] <= CurTime()) then
        playerCooldowns[steamID] = CurTime() + MODULE.config.cooldown
        DebugPrint("Applied cooldown to player", ply:Nick(), "for", MODULE.config.cooldown, "seconds")
        
        ply:SetMoveType(MOVETYPE_NONE)
    end
end)

hook.Add("PlayerSwitchWeapon", "MeleeCooldown_SwitchWeapon", function(ply, oldWeapon, newWeapon)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    
    if playerCooldowns[steamID] and playerCooldowns[steamID] > CurTime() then
        if IsValid(oldWeapon) and IsMeleeWeapon(oldWeapon) and IsValid(newWeapon) and IsMeleeWeapon(newWeapon) then
            DebugPrint("Transferred cooldown to new melee weapon for player", ply:Nick())
            return true 
        end
    end
end)

-- Pre-attack hook to block melee attacks during cooldown
hook.Add("StartCommand", "MeleeCooldown_Block", function(ply, cmd)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    if not playerCooldowns[steamID] or playerCooldowns[steamID] <= CurTime() then return end
    
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not IsMeleeWeapon(weapon) then return end
    
    if not IsWeaponRaised(ply) then return end
    
    if cmd:KeyDown(IN_ATTACK) then
        cmd:RemoveKey(IN_ATTACK)
        DebugPrint("Blocked primary attack for player " .. ply:Nick() .. " - in cooldown")
    end
end)

hook.Add("PlayerDisconnected", "MeleeCooldown_PlayerDisconnected", function(ply)
    local steamID = ply:SteamID()
    if playerCooldowns[steamID] then
        playerCooldowns[steamID] = nil
        DebugPrint("Cleaned up cooldown for disconnected player", ply:Nick())
    end
end)

-- Initialize
hook.Add("Initialize", "MeleeCooldown_Initialize", function()
    DebugPrint("Module initialized with cooldown time:", MODULE.config.cooldown, "seconds")
end)

return MODULE