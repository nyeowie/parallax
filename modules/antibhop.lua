MODULE.name     = 'Anti-Bhop'
MODULE.author   = 'Bilwin (Ported from Helix)'
MODULE.description = 'Prevents players from bunny hopping by reducing their velocity when they hit the ground.'

function MODULE:OnPlayerHitGround(client)
    local vel = client:GetVelocity()
    client:SetVelocity( Vector( - ( vel.x * 0.45 ), - ( vel.y * 0.45 ), 0) )
end