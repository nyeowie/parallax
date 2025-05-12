local MODULE = MODULE

function MODULE:SaveData()
    self:SaveEntities()
end

function MODULE:PostPlayerItemAction(client, actionName, item)
    self:SaveEntities()
end

function MODULE:InitPostEntity()
    self:LoadEntities()
end