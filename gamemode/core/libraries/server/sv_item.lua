-- server-side item logic
-- @module ax.item

function ax.item:Add(characterID, inventoryID, uniqueID, data, callback)
    if ( !characterID or !uniqueID or !self.stored[uniqueID] ) then return end

    data = data or {}

    ax.sqlite:Insert("ax_items", {
        inventory_id = inventoryID,
        character_id = characterID,
        unique_id = uniqueID,
        data = util.TableToJSON(data)
    }, function(result)
        if ( !result ) then return end

        local itemID = tonumber(result)
        if ( !itemID ) then return end

        local item = self:CreateObject({
            ID = itemID,
            UniqueID = uniqueID,
            Data = data,
            InventoryID = inventoryID,
            CharacterID = characterID
        })

        if ( !item ) then return end

        self.instances[itemID] = item

        local inventory = ax.inventory:Get(inventoryID)
        if ( inventory ) then
            local items = inventory:GetItems()
            if ( !table.HasValue(items, itemID) ) then
                table.insert(items, itemID)
            end
        end

        local receiver = ax.character:GetPlayerByCharacter(characterID)
        if ( IsValid(receiver) ) then
            ax.net:Start(receiver, "item.add", itemID, inventoryID, uniqueID, data)
        end

        if ( callback ) then
            callback(itemID, data)
        end

        hook.Run("OnItemAdded", item, characterID, uniqueID, data)
    end)
end

function ax.item:Transfer(itemID, fromInventoryID, toInventoryID, callback)
    if ( !itemID or !fromInventoryID or !toInventoryID ) then return false end

    local item = self.instances[itemID]
    if ( !item ) then return false end

    local fromInventory = ax.inventory:Get(fromInventoryID)
    local toInventory = ax.inventory:Get(toInventoryID)

    if ( toInventory and !toInventory:HasSpaceFor(item:GetWeight()) ) then
        local receiver = ax.character:GetPlayerByCharacter(item:GetOwner())
        if ( IsValid(receiver) ) then
            receiver:Notify("Inventory is too full to transfer this item.")
        end

        return false
    end

    local prevent = hook.Run("PreItemTransferred", item, fromInventoryID, toInventoryID)
    if ( prevent == false ) then
        return false
    end

    if ( fromInventory ) then
        fromInventory:RemoveItem(itemID)
    end

    if ( toInventory ) then
        toInventory:AddItem(itemID, item:GetUniqueID(), item:GetData())
    end

    item:SetInventory(toInventoryID)

    ax.sqlite:Update("ax_items", {
        inventory_id = toInventoryID
    }, "id = " .. itemID)

    if ( callback ) then
        callback(true)
    end

    hook.Run("PostItemTransferred", item, fromInventoryID, toInventoryID)

    return true
end

function ax.item:PerformAction(itemID, actionName, callback)
    local item = self.instances[itemID]
    if ( !item or !actionName ) then return false end

    local base = self.stored[item:GetUniqueID()]
    if ( !base or !base.Actions ) then return false end

    local action = base.Actions[actionName]
    if ( !action ) then return false end

    local client = ax.character:GetPlayerByCharacter(item:GetOwner())
    if ( !IsValid(client) ) then return false end

    if ( action.OnCanRun and !action:OnCanRun(item, client) ) then
        return false
    end

    local prevent = hook.Run("PrePlayerItemAction", client, actionName, item)
    if ( prevent == false ) then
        return false
    end

    if ( action.OnRun ) then
        action:OnRun(item, client)
    end

    if ( callback ) then
        callback()
    end

    local hooks = base.Hooks or {}
    if ( hooks[actionName] ) then
        for _, hookFunc in pairs(hooks[actionName]) do
            if ( hookFunc ) then
                hookFunc(item, client)
            end
        end
    end

    ax.net:Start(client, "inventory.refresh", item:GetInventory())

    hook.Run("PostPlayerItemAction", client, actionName, item)

    return true
end

function ax.item:Cache(characterID)
    if ( !ax.character:Get(characterID) ) then return false end

    local items = ax.sqlite:Select("ax_items", nil, "character_id = " .. characterID .. " OR character_id = 0")
    if ( !items ) then return false end

    for _, row in pairs(items) do
        local itemID = tonumber(row.id)
        local uniqueID = row.unique_id

        if ( self.stored[uniqueID] ) then
            local item = self:CreateObject(row)
            if ( !item ) then
                ax.util:PrintError("Failed to create object for item #" .. itemID .. ", skipping")
                continue
            end

            if ( item:GetOwner() == 0 ) then
                local inv = ax.inventory:Get(item:GetInventory())
                if ( inv ) then
                    local newCharID = inv:GetOwner()
                    item:SetOwner(newCharID)

                    ax.sqlite:Update("ax_items", {
                        character_id = newCharID
                    }, "id = " .. itemID)
                else
                    ax.util:PrintError("Invalid orphaned item #" .. itemID .. " (no inventory)")
                    ax.sqlite:Delete("ax_items", "id = " .. itemID)
                    continue
                end
            end

            self.instances[itemID] = item

            if ( item.OnCache ) then
                item:OnCache()
            end
        else
            ax.util:PrintError("Unknown item unique ID '" .. tostring(uniqueID) .. "' in DB, skipping")
        end
    end

    local instanceList = {}
    for _, item in pairs(self.instances) do
        if ( item:GetOwner() == characterID ) then
            table.insert(instanceList, {
                ID = item:GetID(),
                UniqueID = item:GetUniqueID(),
                Data = item:GetData(),
                InventoryID = item:GetInventory()
            })
        end
    end

    local client = ax.character:GetPlayerByCharacter(characterID)
    if ( IsValid(client) ) then
        ax.net:Start(client, "item.cache", instanceList)
    end

    return true
end

function ax.inventory:AddItem(inventoryID, itemID, uniqueID, data)
    if ( !inventoryID or !itemID or !uniqueID ) then return end

    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    local inventory = self:Get(inventoryID)
    if ( !inventory ) then return end

    local receivers = inventory:GetReceivers()
    if ( !receivers or !istable(receivers) ) then receivers = {} end

    local items = inventory:GetItems()
    if ( !items or !istable(items) ) then items = {} end

    if ( !table.HasValue(items, itemID) ) then
        table.insert(items, itemID)
    end

    item:SetInventory(inventoryID)

    if ( SERVER ) then
        data = data or {}

        ax.sqlite:Update("ax_items", {
            inventory_id = inventoryID,
            data = util.TableToJSON(data)
        }, "id = " .. itemID)

        ax.net:Start(receivers, "inventory.item.add", inventoryID, itemID, uniqueID, data)
    end
end

function ax.inventory:RemoveItem(inventoryID, itemID)
    if ( !inventoryID or !itemID ) then return end

    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    local inventory = self:Get(inventoryID)
    if ( !inventory ) then return end

    local items = inventory:GetItems()
    if ( table.HasValue(items, itemID) ) then
        table.RemoveByValue(items, itemID)
    end

    item:SetInventory(0)

    if ( SERVER ) then
        ax.sqlite:Update("ax_items", {
            inventory_id = 0
        }, "id = " .. itemID)

        local receivers = inventory:GetReceivers()
        if ( istable(receivers) ) then
            ax.net:Start(receivers, "inventory.item.remove", inventoryID, itemID)
        end
    end
end

function ax.item:Spawn(itemID, uniqueID, position, angles, callback, data)
    if ( !uniqueID or !position or !self.stored[uniqueID] ) then return nil end

    local entity = ents.Create("ax_item")
    if ( !IsValid(entity) ) then return nil end

    entity:SetPos(position)
    entity:SetAngles(angles or angle_zero)
    entity:Spawn()
    entity:Activate()
    entity:SetItem(itemID, uniqueID)
    entity:SetData(data or {})

    if ( callback ) then
        callback(entity)
    end

    return entity
end

concommand.Add("ax_item_add", function(client, cmd, args)
    if ( !client:IsAdmin() ) then return end

    local uniqueID = args[1]
    if ( !uniqueID or !ax.item.stored[uniqueID] ) then return end

    local characterID = client:GetCharacterID()
    local inventories = ax.inventory:GetByCharacterID(characterID)
    if ( #inventories == 0 ) then return end

    local inventoryID = inventories[1]:GetID()

    ax.item:Add(characterID, inventoryID, uniqueID, nil, function(itemID)
        client:Notify("Item " .. uniqueID .. " added to inventory " .. inventoryID .. ".")
    end)
end)

concommand.Add("ax_item_spawn", function(client, cmd, args)
    if ( !client:IsAdmin() ) then return end

    local uniqueID = args[1]
    if ( !uniqueID ) then return end

    local pos = client:GetEyeTrace().HitPos + vector_up * 10

    ax.item:Spawn(nil, uniqueID, pos, nil, function(ent)
        if ( IsValid(ent) ) then
            client:Notify("Item " .. uniqueID .. " spawned.")
        else
            client:Notify("Failed to spawn item " .. uniqueID .. ".")
        end
    end)
end)