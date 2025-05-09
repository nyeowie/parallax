ax.data = ax.data or {}
ax.data.stored = ax.data.stored or {}

file.CreateDir("parallax")

function ax.data:Set(key, value, bGlobal, bMap)
    local directory = "parallax/" .. ( ( bGlobal and "" or SCHEMA and SCHEMA.Folder ) .. "/") .. ( !bMap and "" or game.GetMap() .. "/" )

    if ( !bGlobal ) then
        file.CreateDir("parallax/" .. SCHEMA.Folder .. "/")
    end

    file.CreateDir(directory)
    file.Write(directory .. key .. ".json", util.TableToJSON({value}))

    self.stored[key] = value

    return directory
end

function ax.data:Get(key, fallback, bGlobal, bMap, bRefresh)
    local stored = self.stored[key]
    if ( !bRefresh and stored != nil ) then
        return stored
    end

    local path = "parallax/" .. ( ( bGlobal and "" or SCHEMA and SCHEMA.Folder ) .. "/") .. ( !bMap and "" or game.GetMap() .. "/" )
    local data = file.Read(path .. key .. ".json", "DATA")
    if ( data != nil ) then
        data = util.JSONToTable(data)

        self.stored[key] = data[1]
        return data[1]
    end

    return fallback
end