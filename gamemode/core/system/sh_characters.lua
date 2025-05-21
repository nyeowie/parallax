ax.character:RegisterVariable("steamid", {
    Type = ax.types.string,
    Field = "steamid",
    Default = ""
})

ax.character:RegisterVariable("schema", {
    Type = ax.types.string,
    Field = "schema",
    Default = "parallax"
})

ax.character:RegisterVariable("data", {
    Type = ax.types.string,
    Field = "data",
    Default = "[]",

    OnGet = function(self, character, value)
        if ( !value or value == "" ) then
            return "[]"
        end

        local data = util.JSONToTable(value)
        if ( !data ) then
            data = {}
        end

        return data
    end,

    OnSet = function(self, character, value)
        if ( !value ) then
            value = {}
        end

        local data = util.TableToJSON(value)
        if ( !data ) then
            data = "[]"
        end

        character:SetData(data)
    end
})

ax.character:RegisterVariable("name", {
    Type = ax.types.string,
    Field = "name",
    Default = "John Doe",

    Editable = true,
    ZPos = -3,
    Name = "Name",

    AllowNonAscii = false,
    Numeric = false,

    OnValidate = function(self, parent, payload, client)
        if ( string.len(payload.name) < 3 ) then
            return false, "Name must be at least 3 characters long!"
        elseif ( string.len(payload.name) > 32 ) then
            return false, "Name must be at most 32 characters long!"
        end

        if ( string.find(payload.name, "[^%a%d%s]") ) then
            return false, "Name can only contain letters, numbers and spaces!"
        end

        if ( string.find(payload.name, "%s%s") ) then
            return false, "Name cannot contain multiple spaces in a row!"
        end

        return true
    end
})

ax.character:RegisterVariable("description", {
    Type = ax.types.text,
    Field = "description",
    Default = "A mysterious person.",

    Editable = true,
    ZPos = 0,
    Name = "Description",

    OnValidate = function(self, parent, payload, client)
        if ( string.len(payload.description) < 10 ) then
            return false, "Description must be at least 10 characters long!"
        end

        return true
    end
})

ax.character:RegisterVariable("model", {
    Type = ax.types.string,
    Field = "model",
    Default = "models/player/kleiner.mdl",

    Editable = true,
    ZPos = 0,
    Name = "Model",

    OnValidate = function(self, parent, payload, client)
        local faction = ax.faction:Get(payload.faction)
        if ( faction and faction.Models ) then
            local found = false
            for _, v in SortedPairs(faction.Models) do
                if ( v == payload.model ) then
                    found = true
                    break
                end
            end

            if ( !found ) then
                return false, "Model is not valid for this faction!"
            end
        end

        return true
    end,

    OnPopulate = function(self, parent, payload, client)
        local label = parent:Add("ax.text")
        label:Dock(TOP)
        label:SetFont("parallax.button")
        label:SetText(self.Name or k)

        local scroller = parent:Add("DScrollPanel")
        scroller:Dock(TOP)
        scroller:DockMargin(0, 0, 0, ScreenScale(16))
        scroller:SetTall(256)

        local layout = scroller:Add("DIconLayout")
        layout:Dock(FILL)

        local faction = ax.faction:Get(payload.faction)
        if ( faction and faction.Models ) then
            for _, v in SortedPairs(faction.Models) do
                local icon = layout:Add("SpawnIcon")
                icon:SetModel(v)
                icon:SetSize(64, 128)
                icon:SetTooltip(v)
                icon.DoClick = function()
                    ax.client:Notify("You have selected " .. v .. " as your model!")
                    payload.model = v
                end
            end
        end
    end,

    OnSet = function(self, character, value)
        local client = character:GetPlayer()
        if ( IsValid(client) ) then
            client:SetModel(value)
        end
    end
})

ax.character:RegisterVariable("money", {
    Type = ax.types.number,
    Field = "money",
    Default = 0
})

ax.character:RegisterVariable("faction", {
    Type = ax.types.number,
    Field = "faction",
    Default = 0,

    Editable = true,

    OnValidate = function(self, parent, payload, client)
        local canSwitch, reason = ax.faction:CanSwitchTo(client, payload.faction)
        if ( !canSwitch ) then
            return false, reason or "You cannot switch to this faction!"
        end
    end,

    OnSet = function(this, character, value)
        local faction = ax.faction:Get(value)
        if ( faction and faction.OnSet ) then
            faction:OnSet(character, value)
        end

        local client = character:GetPlayer()
        if ( IsValid(client) ) then
            client:SetTeam(value)
        end
    end
})

ax.character:RegisterVariable("class", {
    Type = ax.types.number,
    Field = "class",
    Default = 0
})

ax.character:RegisterVariable("flags", {
    Type = ax.types.string,
    Field = "flags",
    Default = "",
})

ax.character:RegisterVariable("play_time", {
    Type = ax.types.number,
    Field = "play_time",
    Alias = "PlayTime",
    Default = 0
})

ax.character:RegisterVariable("last_played", {
    Type = ax.types.number,
    Field = "last_played",
    Alias = "LastPlayed",
    Default = 0
})