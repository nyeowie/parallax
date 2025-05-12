local MODULE = MODULE

function MODULE:SaveData()
    self:SaveEntities()
end

function MODULE:InitPostEntity()
    timer.Simple(1, function()
        self:LoadEntities()
    end)
end