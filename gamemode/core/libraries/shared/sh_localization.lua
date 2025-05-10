--- Localization library
-- @module ax.localization

ax.localization = {}
ax.localization.stored = {}

--- Register a new language.
-- @realm shared
-- @param language The language code.
-- @param data The language data.
function ax.localization:Register(languageName, data)
    if ( !isstring(languageName) ) then
        ax.util:PrintError("Attempted to register a language without a language code!")
        return false
    end

    if ( !istable(data) ) then
        ax.util:PrintError("Attempted to register a language without data!")
        return false
    end

    local stored = self.stored[languageName]
    if ( stored == nil ) then
        self.stored[languageName] = {}
    end

    self.stored[languageName] = table.Merge(table.Copy(self.stored[languageName]), data)
    hook.Run("OnLanguageRegistered", languageName, data)
end

--- Get a language.
-- @realm shared
-- @param language The language code.
-- @return The language data.
function ax.localization:Get(languageName)
    local stored = self.stored[languageName]
    if ( !istable(stored) ) then
        ax.util:PrintError("Attempted to get localisation data that doesn't exist! Language: " .. languageName)
        return false
    end

    return self.stored[languageName]
end

--- Get a localized string.
-- @realm shared
-- @param key The key of the string.
-- @param language The language code.
-- @return The localized string.
if ( CLIENT ) then
    local gmod_language = GetConVar("gmod_language")
    function ax.localization:GetPhrase(key, languageName)
        languageName = languageName or ( gmod_language and gmod_language:GetString() ) or "en"

        local data = self:Get(languageName)
        if ( !istable(data) ) then
            return key
        end

        local value = data[key]
        if ( !isstring(value) ) then
            return key
        end

        return value
    end
end