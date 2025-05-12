--- Commands library.
-- @module ax.command

ax.command = {}
ax.command.stored = {}

--- Registers a new command.
-- @realm shared
-- @tab info The information of the command.
-- @field string Name The name of the command.
-- @field func Callback The callback of the command.
-- @field tab Prefixes The prefixes of the command.
-- @field string MinAccess The minimum access of the command.
-- @field bool AdminOnly Whether the command is admin only.
-- @field bool SuperAdminOnly Whether the command is super admin only.
-- @field string UniqueID The unique identifier of the command.
-- @usage ax.command:Register({
--     Name = "example",
--     Callback = function(info, client, arguments)
--         print("Example command executed!")
--     end,
--     Prefixes = {"example", "ex"},
--     MinAccess = "user"
-- })
function ax.command:Register(commandName, info)
    if ( !isstring(commandName) ) then
        ax.util:PrintError("Attempted to register an invalid command!")
        return
    end

    commandName = string.gsub(commandName, "%s+", " ")

    if ( !isfunction(info.Callback) ) then
        ax.util:PrintError("Attempted to register a command with no callback!")
        return
    end

    if ( !isfunction(info.GetDescription) ) then
        function info:GetDescription()
            return info.Description or "No description provided."
        end
    end

    info.UniqueID = commandName
    self.stored[commandName] = info

    if ( CAMI != nil ) then
        CAMI.RegisterPrivilege({
            Name = "Parallax - Commands - " .. commandName,
            MinAccess = ( info.SuperAdminOnly and "superadmin" ) or ( info.AdminOnly and "admin" ) or ( info.MinAccess or "user" )
        })
    end

    hook.Run("OnCommandRegistered", commandName, info)
end

--- Unregisters a command.
-- @realm shared
-- @string name The name of the command.
-- @internal
function ax.command:UnRegister(name)
    self.stored[name] = nil
    hook.Run("OnCommandUnRegistered", name)
end

--- Returns a command by its unique identifier or prefix.
-- @realm shared
-- @string identifier The unique identifier or prefix of the command.
-- @return table The command.
function ax.command:Get(identifier)
    if ( !isstring(identifier) ) then
        ax.util:PrintError("Attempted to get a command with an invalid identifier!")
        return false
    end

    if ( self.stored[identifier] ) then
        return self.stored[identifier]
    end

    for k, v in pairs(self.stored) do
        if ( string.lower(k) == string.lower(identifier) ) then
            return v
        end
    end

    for _, v in pairs(self.stored) do
        if ( !istable(v.Prefixes) ) then continue end

        for _, v2 in ipairs(v.Prefixes) do
            if ( string.lower(v2) == string.lower(identifier) ) then
                return v
            end
        end
    end

    return false
end