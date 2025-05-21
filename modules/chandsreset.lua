local MODULE = MODULE or {}
MODULE.name = "Hands Reset"
MODULE.author = "Setsuna"
MODULE.description = "Adds a command to reset character hands models."

--[[ix.command.Add("ResetHands", {
    description = "Resets your character's hands model.",
    OnRun = function(self, client)
        if (!IsValid(client)) then return end
        
        local character = client:GetCharacter()
        if (!character) then
            return "You need to have a character selected!"
        end

        -- Get model information
        local model = client:GetModel()
        local modelName = string.lower(string.gsub(model, "%.mdl$", ""))
        modelName = string.gsub(modelName, "models/", "")
        modelName = string.gsub(modelName, "/", "")

        -- Add valid hands based on model type
        if string.find(model, "group02") then
            player_manager.AddValidHands(modelName, "models/weapons/c_arms_citizen.mdl", 1, "0000000")
        elseif string.find(model, "group03") or string.find(model, "group03m") then
            player_manager.AddValidHands(modelName, "models/weapons/c_arms_refugee.mdl", 1, "0000000")
        elseif string.find(model, "police") then
            player_manager.AddValidHands(modelName, "models/weapons/c_arms_combine.mdl", 1, "0000000")
        else
            player_manager.AddValidHands(modelName, "models/weapons/c_arms_citizen.mdl", 1, "0000000")
        end

        -- Setup hands
        client:SetupHands()

        return "Your hands have been reset."
    end
})]]

if (SERVER) then
    function MODULE:PlayerLoadedCharacter(client, character, lastChar)
        timer.Simple(0.1, function()
            if (IsValid(client)) then
                local model = client:GetModel()
                local modelName = string.lower(string.gsub(model, "%.mdl$", ""))
                modelName = string.gsub(modelName, "models/", "")
                modelName = string.gsub(modelName, "/", "")

                if string.find(model, "group02") then
                    player_manager.AddValidHands(modelName, "models/weapons/c_arms_citizen.mdl", 1, "0000000")
                elseif string.find(model, "group03") or string.find(model, "group03m") then
                    player_manager.AddValidHands(modelName, "models/weapons/c_arms_refugee.mdl", 1, "0000000")
                elseif string.find(model, "police") then
                    player_manager.AddValidHands(modelName, "models/weapons/c_arms_combine.mdl", 1, "0000000")
                else
                    player_manager.AddValidHands(modelName, "models/weapons/c_arms_citizen.mdl", 1, "0000000")
                end

                client:SetupHands()
            end
        end)
    end

    function MODULE:CharacterLoaded(character)
        local client = character:GetPlayer()
        
        if (IsValid(client)) then
            timer.Simple(0.1, function()
                if (IsValid(client)) then
                    client:SetupHands()
                end
            end)
        end
    end
end