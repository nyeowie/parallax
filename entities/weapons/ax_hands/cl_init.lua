include("shared.lua")

function SWEP:CheckYaw()
    local playerPitch = self:GetOwner():EyeAngles().p
    if ( playerPitch < -20 ) then
        if ( self.axHandsReset and self.axHandsReset > CurTime() ) then return end
        self.axHandsReset = CurTime() + 0.5

        ax.net:Start("hands.reset")
    end
end

function SWEP:Think()
    if ( self:GetOwner() ) then
        self:CheckYaw()
    end
end