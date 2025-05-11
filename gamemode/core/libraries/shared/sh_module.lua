--- A library for managing modules in the gamemode.
-- @module ax.module

ax.module = {}
ax.module.stored = {}
ax.module.disabled = {}

--- Returns a module by its unique identifier or name.
-- @realm shared
-- @string identifier The unique identifier or name of the module.
-- @return table The module.
function ax.module:Get(identifier)
    if ( identifier == nil or !isstring(identifier) ) then
        ax.util:PrintError("Attempted to get an invalid module!")
        return false
    end

    if ( self.stored[identifier] ) then
        return self.stored[identifier]
    end

    for k, v in pairs(self.stored) do
        if ( ax.util:FindString(v.Name, identifier) ) then
            return v
        end
    end

    return false
end

function ax.module:LoadFolder(path)
    if ( !path or path == "" ) then
        ax.util:PrintError("Attempted to load an invalid module folder!")
        return false
    end

    hook.Run("PreInitializeModules")

    ax.util:Print("Loading modules from \"" .. path .. "\"...")

    local files, folders = file.Find(path .. "/*", "LUA")
    for k, v in ipairs(folders) do
        if ( file.Exists(path .. "/" .. v .. "/sh_module.lua", "LUA") ) then
            MODULE = { UniqueID = v }
                hook.Run("PreInitializeModule", MODULE)
                ax.util:LoadFile(path .. "/" .. v .. "/sh_module.lua", "shared")
                ax.util:LoadFolder(path .. "/" .. v .. "/derma", true)
                ax.util:LoadEntities(path .. "/" .. v .. "/entities")
                self.stored[v] = MODULE
                hook.Run("PostInitializeModule", MODULE)
            MODULE = nil
        else
            ax.util:PrintError("Module " .. v .. " is missing a shared module file.")
        end
    end

    for k, v in ipairs(files) do
        local ModuleUniqueID = string.StripExtension(v)
        if ( string.sub(v, 1, 3) == "cl_" or string.sub(v, 1, 3) == "sv_" or string.sub(v, 1, 3) == "sh_" ) then
            ModuleUniqueID = string.sub(v, 4)
        end

        local realm = "shared"
        if ( string.sub(v, 1, 3) == "cl_" ) then
            realm = "client"
        elseif ( string.sub(v, 1, 3) == "sv_" ) then
            realm = "server"
        end

        MODULE = { UniqueID = ModuleUniqueID }
            hook.Run("PreInitializeModule", MODULE)
            ax.util:LoadFile(path .. "/" .. v, realm)
            self.stored[ModuleUniqueID] = MODULE
            hook.Run("PostInitializeModule", MODULE)
        MODULE = nil
    end

    ax.util:Print("Loaded " .. #files .. " files and " .. #folders .. " folders from \"" .. path .. "\", total " .. (#files + #folders) .. " modules.")

    hook.Run("PostInitializeModules")
end