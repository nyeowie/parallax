--- Character library.
-- @module ax.character

function ax.character:Create(client, query)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ErrorNoHalt("Attempted to create character for invalid player (" .. tostring(client) .. ")")
        return false, "Invalid player!"
    end

    if ( !istable(query) ) then
        ErrorNoHalt("Attempted to create character with invalid query (" .. tostring(query) .. ")")
        return false, "Invalid query!"
    end

    local insertQuery = {}
    for k, v in pairs(self.variables) do
        if ( query[k] != nil ) then
            insertQuery[k] = query[k]
        elseif ( v.Default ) then
            insertQuery[k] = v.Default
        end
    end

    insertQuery.steamid = client:SteamID64()
    insertQuery.schema = SCHEMA.Folder
    insertQuery.play_time = 0
    insertQuery.last_played = os.time()

    local characterID
    ax.sqlite:Insert("ax_characters", insertQuery, function(result)
        if ( !result ) then
            ErrorNoHalt("Failed to insert character into database for player " .. tostring(client) .. "\n")
            return false, "Failed to insert character into database!"
        end

        characterID = tonumber(result)
    end)

    if ( !characterID ) then
        ErrorNoHalt("Failed to create character: " .. query.name .. "\n")
        return false, "Failed to create character!"
    end

    local character = self:CreateObject(characterID, insertQuery, client)
    if ( !character ) then
        ErrorNoHalt("Failed to create character object for ID " .. characterID .. " for player " .. tostring(client) .. "\n")
        return false, "Failed to create character object!"
    end

    local canCreate, reason = hook.Run("PrePlayerCreatedCharacter", client, character, query)
    if ( canCreate == false ) then
        self:Delete(characterID)
        return false, reason or "Failed to create character!"
    end

    local clientTable = client:GetTable()
    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character

    self.stored[characterID] = character

    ax.net:Start(client, "character.cache", character)

    ax.inventory:Register({characterID = characterID})

    hook.Run("PostPlayerCreatedCharacter", client, character, query)

    return character
end

function ax.character:Load(client, characterID)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ErrorNoHalt("Attempted to load character for invalid player (" .. tostring(client) .. ")\n")
        return false
    end

    if ( !characterID ) then
        client:Notify("You are attempting to load a character with an invalid ID!")
        return false
    end

    local currentCharacter = client:GetCharacter()
    if ( currentCharacter ) then
        currentCharacter.Player = NULL
        --currentCharacter:Save()

        if ( currentCharacter:GetID() == characterID ) then
            client:Notify("You are already using this character!")
            return false
        end
    end

    local steamID = client:SteamID64()
    local condition = string.format("steamid = %s AND id = %s", sql.SQLStr(steamID), sql.SQLStr(characterID))
    local result = ax.sqlite:Select("ax_characters", nil, condition)

    if ( result and result[1] ) then
        local row = result[1]
        local character = self:CreateObject(characterID, row, client)
        if ( !character ) then
            client:Notify("Failed to load character!")
            return false
        end

        self.stored[characterID] = character

        hook.Run("PrePlayerLoadedCharacter", client, character, currentCharacter)

        ax.net:Start(client, "character.load", characterID)

        local clientTable = client:GetTable()
        clientTable.axCharacters = clientTable.axCharacters or {}
        clientTable.axCharacters[characterID] = character
        clientTable.axCharacter = character

        client:SetModel(character:GetModel())
        client:SetTeam(character:GetFaction())
        client:Spawn()

        ax.inventory:CacheAll(characterID)
        ax.item:Cache(characterID)

        hook.Run("PostPlayerLoadedCharacter", client, character, currentCharacter)

        return character
    else
        ErrorNoHalt("Failed to load character with ID " .. characterID .. " for player " .. tostring(client) .. "\n")
        return false
    end
end

function ax.character:Delete(characterID)
    if ( !isnumber(characterID) ) then
        ErrorNoHalt("Attempted to delete character with invalid ID (" .. tostring(characterID) .. ")")
        return false
    end

    local character = self.stored[characterID]
    if ( !character ) then
        ax.util:PrintError("Attempted to delete character that does not exist (" .. characterID .. ")")
        return false
    end

    local client = character:GetPlayer()
    if ( IsValid(client) ) then
        local clientTable = client:GetTable()
        clientTable.axCharacters[characterID] = nil
        clientTable.axCharacter = nil

        client:SetTeam(0)
        client:SetModel("models/player/kleiner.mdl")

        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:SetMoveType(MOVETYPE_NONE)

        client:KillSilent()

        ax.net:Start(client, "character.delete", characterID)
    end

    ax.sqlite:Delete("ax_characters", string.format("id = %s", sql.SQLStr(characterID)))
    self.stored[characterID] = nil

    return true
end

function ax.character:Cache(client, characterID)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ErrorNoHalt("Attempted to cache character for invalid player (" .. tostring(client) .. ")\n")
        return false
    end

    local steamID = client:SteamID64()
    local condition = string.format("steamid = %s AND id = %s", sql.SQLStr(steamID), sql.SQLStr(characterID))
    local result = ax.sqlite:Select("ax_characters", nil, condition)
    if ( !result or !result[1] ) then
        ErrorNoHalt("Failed to cache character with ID " .. characterID .. " for player " .. tostring(client) .. "\n")
        return false
    end

    characterID = tonumber(characterID)
    if ( !characterID ) then
        ErrorNoHalt("Failed to convert character ID " .. characterID .. " to number for player " .. tostring(client) .. "\n")
        return false
    end

    -- Make sure we are not loading a character from a different schema
    if ( result[1].schema != SCHEMA.Folder ) then
        return false
    end

    local clientTable = client:GetTable()
    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = result[1]
    self.stored[characterID] = result[1]

    ax.net:Start(client, "character.cache", result[1])

    return true
end

function ax.character:CacheAll(client)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ErrorNoHalt("Attempted to load characters for invalid player (" .. tostring(client) .. ")\n")
        return false
    end

    local steamID = client:SteamID64()

    local condition = string.format("steamid = %s", sql.SQLStr(steamID))
    local result = ax.sqlite:Select("ax_characters", nil, condition)

    -- Ensure the player has a table to store characters
    local clientTable = client:GetTable()
    clientTable.axCharacters = {}

    if ( result ) then
        for _, row in ipairs(result) do
            local id = tonumber(row.id)
            if ( !id ) then
                ErrorNoHalt("Failed to convert character ID " .. row.id .. " to number for player " .. tostring(client) .. "\n")
                continue
            end

            -- Make sure we are not loading a character from a different schema
            if ( row.schema != SCHEMA.Folder ) then
                continue
            end

            local character = self:CreateObject(id, row, client)
            self.stored[id] = character
            clientTable.axCharacters[id] = character
        end
    end

    ax.net:Start(client, "character.cache.all", clientTable.axCharacters)

    hook.Run("PlayerLoadedAllCharacters", client, clientTable.axCharacters)

    return clientTable.axCharacters
end

concommand.Add("ax_character_test_create", function(client, cmd, arguments)
    ax.character:Create(client, {
        name = "Test Character"
    })
end)