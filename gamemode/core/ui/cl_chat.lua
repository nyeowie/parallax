local PANEL = {}

DEFINE_BASECLASS("EditablePanel")

function PANEL:Init()
    if ( IsValid(ax.gui.chatbox) ) then
        ax.gui.chatbox:Remove()
    end

    ax.gui.chatbox = self

    self:SetSize(hook.Run("GetChatboxSize"))
    self:SetPos(hook.Run("GetChatboxPos"))

    local label = self:Add("ax.text")
    label:Dock(TOP)
    label:SetTextInset(8, -2)
    label:SetFont("parallax.small")
    label:SetText(GetHostName(), true)
    label.Paint = function(this, width, height)
        surface.SetDrawColor(ax.color:Get("background.transparent"))
        surface.DrawRect(0, 0, width, height)
    end

    local bottom = self:Add("EditablePanel")
    bottom:Dock(BOTTOM)
    bottom:DockMargin(8, 8, 8, 8)

    self.chatType = bottom:Add("ax.text")
    self.chatType:Dock(LEFT)
    self.chatType:SetTextInset(8, -2)
    self.chatType:SetFont("parallax.small.bold")
    self.chatType:SetText("IC", true)
    self.chatType.Paint = function(this, width, height)
        surface.SetDrawColor(ax.color:Get("background.transparent"))
        surface.DrawRect(0, 0, width, height)
    end

    self.entry = bottom:Add("ax.text.entry")
    self.entry:Dock(FILL)
    self.entry:DockMargin(8, 0, 0, 0)
    self.entry:SetPlaceholderText("Say something...")
    self.entry:SetTextColor(color_white)
    self.entry:SetDrawLanguageID(false)

    bottom:SizeToChildren(false, true)

    -- Command suggestion panel
    self.cmdSuggestions = self:Add("DPanel")
    self.cmdSuggestions:SetZPos(999)

    self.cmdSuggestions:SetVisible(false)
    self.cmdSuggestions.Paint = function(this, w, h)
        -- Use hardcoded colors instead of color system
        surface.SetDrawColor(0, 0, 0, 200) -- Dark transparent background
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(100, 100, 100, 255) -- Light gray border
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Suggestion list
    self.suggestionList = self.cmdSuggestions:Add("DScrollPanel")
    self.suggestionList:Dock(FILL)
    self.suggestionList:DockMargin(2, 2, 2, 2)
    local scrollbar = self.suggestionList:GetVBar()
    scrollbar:SetHideButtons(true)
    scrollbar:SetWide(4)
    scrollbar.Paint = function() end
    scrollbar.btnGrip.Paint = function(_, w, h)
        surface.SetDrawColor(255, 0, 0, 100) -- Light gray scrollbar grip
        surface.DrawRect(0, 0, w, h)
    end
    

    self.activeSuggestion = 0
    self.currentSuggestions = {}

    self.entry.OnEnter = function(this)
        local text = this:GetValue()
        if ( #text > 0 ) then
            -- Hide suggestions when sending a message
            self.cmdSuggestions:SetVisible(false)
            
            -- Send the chat message
            RunConsoleCommand("say", text)
            this:SetText("")
        end

        self:SetVisible(false)
    end

    self.entry.OnTextChanged = function(this)
        local text = this:GetValue()
        if (string.sub(text, 1, 3) == ".//" ) then
            -- Check if it's a way of using local out of character chat using .// prefix
            local data = ax.command:Get("looc")
            if (data) then
                self.chatType:SetText("LOOC", true)
            end
        elseif (string.sub(text, 1, 1) == "/") then
            -- This is a command, so we need to parse it
            local command = string.sub(text, 2)
            -- Check if there's a space, which means we're past the command name
            if (string.find(command, " ")) then
                local arguments = string.Explode(" ", command)
                local commandName = arguments[1]
                local data = ax.command:Get(commandName)
                if (data) then
                    self.chatType:SetText(string.upper(data.UniqueID), true)
                else
                    -- Just revert back to IC if the command doesn't exist
                    self.chatType:SetText("IC", true)
                end
                -- Hide suggestions since we're now writing arguments
                self.cmdSuggestions:SetVisible(false)
            else
                -- We're still typing the command name, show suggestions
                self.chatType:SetText("CMD", true)
                self:UpdateCommandSuggestions(command)
            end
        else
            -- Everything else is a normal chat message
            self.chatType:SetText("IC", true)
            self.cmdSuggestions:SetVisible(false)
        end
        
        -- Always make sure the suggestions panel is positioned correctly
        if (self.cmdSuggestions:IsVisible()) then
            local entryX, entryY = self.entry:GetPos()
            local entryParentX, entryParentY = self.entry:GetParent():GetPos()
            local absoluteEntryY = entryY + entryParentY
            
            local suggestionHeight = self.cmdSuggestions:GetTall()
            self.cmdSuggestions:SetPos(8, absoluteEntryY - suggestionHeight - 4)
        end
    end

    self.entry.OnKeyCodeTyped = function(this, keyCode)
        -- Handle Enter key explicitly
        if (keyCode == KEY_ENTER) then
            this:OnEnter()
            return true
        end
    
        -- Tab completion
        if (keyCode == KEY_TAB and self.cmdSuggestions:IsVisible() and #self.currentSuggestions > 0) then
            local suggestion = self.currentSuggestions[self.activeSuggestion]
            if (suggestion) then
                this:SetText("/" .. suggestion.command)
                this:SetCaretPos(string.len("/" .. suggestion.command))
            end
            return true
        end

        -- Arrow key navigation for suggestions
        if (self.cmdSuggestions:IsVisible() and #self.currentSuggestions > 0) then
            if (keyCode == KEY_DOWN) then
                self.activeSuggestion = math.min(self.activeSuggestion + 1, #self.currentSuggestions)
                self:UpdateActiveSuggestion()
                return true
            elseif (keyCode == KEY_UP) then
                self.activeSuggestion = math.max(self.activeSuggestion - 1, 1)
                self:UpdateActiveSuggestion()
                return true
            end
        end
    end

    self.entry.OnLoseFocus = function(this)
        if ( this:GetText() == "" ) then
            self:SetVisible(false)
        end
    end

    self.history = self:Add("DScrollPanel")
    self.history:SetPos(8, label:GetTall() + 8)
    self.history:SetSize(self:GetWide() - 16, self:GetTall() - 16 - label:GetTall() - self.entry:GetTall())
    self.history:GetVBar():SetWide(0)

    self:SetVisible(false)

    chat.GetChatBoxPos = function()
        return self:GetPos()
    end

    chat.GetChatBoxSize = function()
        return self:GetSize()
    end
end

function PANEL:UpdateCommandSuggestions(typedCommand)
    self.suggestionList:Clear()
    self.currentSuggestions = {}
    self.activeSuggestion = 0
    
    if (typedCommand == "") then
        -- Show all commands
        local allCommands = table.GetKeys(ax.command.stored)
        table.sort(allCommands)
        
        for i, cmdName in ipairs(allCommands) do
            if (i > 10) then break end -- Limit to 10 suggestions
            local cmdData = ax.command.stored[cmdName]
            self:AddSuggestion(cmdName, cmdData)
        end
    else
        -- Filter commands by what's been typed
        local matchedCommands = {}
        
        -- First check exact matches with command names
        for cmdName, cmdData in pairs(ax.command.stored) do
            if (string.find(string.lower(cmdName), string.lower(typedCommand), 1, true) == 1) then
                table.insert(matchedCommands, {name = cmdName, data = cmdData, priority = 1})
            end
        end
        
        -- Then check aliases/prefixes
        for cmdName, cmdData in pairs(ax.command.stored) do
            if (istable(cmdData.Prefixes)) then
                for _, prefix in ipairs(cmdData.Prefixes) do
                    if (string.find(string.lower(prefix), string.lower(typedCommand), 1, true) == 1) then
                        -- Check if we already added this command
                        local alreadyAdded = false
                        for _, cmd in ipairs(matchedCommands) do
                            if (cmd.name == cmdName) then
                                alreadyAdded = true
                                break
                            end
                        end
                        
                        if (not alreadyAdded) then
                            table.insert(matchedCommands, {name = cmdName, data = cmdData, priority = 2})
                        end
                    end
                end
            end
        end
        
        -- Sort by priority then alphabetically
        table.sort(matchedCommands, function(a, b)
            if (a.priority == b.priority) then
                return a.name < b.name
            end
            return a.priority < b.priority
        end)
        
        -- Add the suggestions to the panel
        for i, cmd in ipairs(matchedCommands) do
            if (i > 10) then break end -- Limit to 10 suggestions
            self:AddSuggestion(cmd.name, cmd.data)
        end
    end
    
    -- Show or hide the suggestions panel
    if (#self.currentSuggestions > 0) then
        self.cmdSuggestions:SetVisible(true)
        
        local exactHeight = #self.currentSuggestions * 30 + 4
        local suggestionHeight = math.min(exactHeight, 200)
        
        local entryX, entryY = self.entry:GetPos()
        local entryParentX, entryParentY = self.entry:GetParent():GetPos()
        local absoluteEntryY = entryY + entryParentY
        
        self.cmdSuggestions:SetPos(8, absoluteEntryY - suggestionHeight - 4)
        self.cmdSuggestions:SetSize(self:GetWide() - 16, suggestionHeight)
        
        local scrollbar = self.suggestionList:GetVBar()
        if (#self.currentSuggestions <= 6) then 
            scrollbar:SetVisible(false)
            self.suggestionList:Dock(FILL)
        else
            scrollbar:SetVisible(true)
        end
        
        self.activeSuggestion = 1
        self:UpdateActiveSuggestion()
    else
        self.cmdSuggestions:SetVisible(false)
    end
end

function PANEL:AddSuggestion(commandName, commandData)
    local index = #self.currentSuggestions + 1
    
    -- Create button for suggestion
    local btn = self.suggestionList:Add("DButton")
    btn:SetTall(30) -- Slightly taller for better visual appearance
    btn:Dock(TOP)
    btn:DockMargin(2, 1, 2, 1) -- Tighter margins for cleaner look
    btn:SetText("")
    btn:SetCursor("hand") -- Change cursor to hand when hovering
    
    -- Store reference to this suggestion
    self.currentSuggestions[index] = {
        button = btn,
        command = commandName,
        data = commandData
    }
    
    -- Button styling with Mirror's Edge Catalyst inspired clean look
    btn.Paint = function(this, w, h)
        local isActive = self.activeSuggestion == index
        
        -- Clean white background with subtle hover/active states
        if isActive then
            -- Active state - subtle red accent (Mirror's Edge style)
            surface.SetDrawColor(255, 255, 255) -- White background
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(220, 60, 40, 255) -- Red accent line
            surface.DrawRect(0, 0, 3, h) -- Left border accent
        else
            if this:IsHovered() then
                -- Hover state - light gray
                surface.SetDrawColor(245, 245, 245, 255)
            else
                -- Normal state - pure white
                surface.SetDrawColor(200, 200, 200, 255)
            end
            surface.DrawRect(0, 0, w, h)
        end
        
        -- Subtle bottom separator
        surface.SetDrawColor(240, 240, 240)
        surface.DrawLine(5, h-1, w-5, h-1)
        
        -- Command name - bold and black
        draw.SimpleText(commandName, "parallax.small.bold", 12, h/2.3-4, Color(30, 30, 30, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Description (if available) - light gray
        local description = ""
        if (commandData.GetDescription and isfunction(commandData.GetDescription)) then
            description = commandData:GetDescription()
        elseif (commandData.Description) then
            description = commandData.Description
        end
        
        if (description and description ~= "") then
            -- Use smaller font for description
            draw.SimpleText(description, "parallax.small", 12, h/2+6, Color(100, 100, 100, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Draw command shortcut hint on the right
            local shortcutText = "TAB"
            local shortcutWidth = surface.GetTextSize(shortcutText)
            
            -- Shortcut key background
            surface.SetDrawColor(240, 240, 240)
            surface.DrawRect(w - shortcutWidth - 20, h/2-8, shortcutWidth + 12, 16)
            
            -- Shortcut text
            draw.SimpleText(shortcutText, "parallax.small.bold", w - 14, h/2, Color(100, 100, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Enhanced click handler with sound
    btn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav") -- Optional click sound
        self.entry:SetText("/" .. commandName)
        self.entry:SetCaretPos(string.len("/" .. commandName))
        self.cmdSuggestions:SetVisible(false)
        self.entry:RequestFocus()
    end
    
    -- Add hover animation
    btn.OnCursorEntered = function()
        btn:ColorTo(Color(245, 245, 245, 255), 0.1, 0)
    end
    
    btn.OnCursorExited = function()
        btn:ColorTo(Color(255, 255, 255, 255), 0.1, 0)
    end
end

-- Also update the command suggestions panel to match the clean white style
function PANEL:UpdateCommandSuggestions(typedCommand)
    self.suggestionList:Clear()
    self.currentSuggestions = {}
    self.activeSuggestion = 0
    
    if (typedCommand == "") then
        -- Show all commands
        local allCommands = table.GetKeys(ax.command.stored)
        table.sort(allCommands)
        
        for i, cmdName in ipairs(allCommands) do
            if (i > 10) then break end -- Limit to 10 suggestions
            local cmdData = ax.command.stored[cmdName]
            self:AddSuggestion(cmdName, cmdData)
        end
    else
        -- Filter commands by what's been typed
        local matchedCommands = {}
        
        -- First check exact matches with command names
        for cmdName, cmdData in pairs(ax.command.stored) do
            if (string.find(string.lower(cmdName), string.lower(typedCommand), 1, true) == 1) then
                table.insert(matchedCommands, {name = cmdName, data = cmdData, priority = 1})
            end
        end
        
        -- Then check aliases/prefixes
        for cmdName, cmdData in pairs(ax.command.stored) do
            if (istable(cmdData.Prefixes)) then
                for _, prefix in ipairs(cmdData.Prefixes) do
                    if (string.find(string.lower(prefix), string.lower(typedCommand), 1, true) == 1) then
                        -- Check if we already added this command
                        local alreadyAdded = false
                        for _, cmd in ipairs(matchedCommands) do
                            if (cmd.name == cmdName) then
                                alreadyAdded = true
                                break
                            end
                        end
                        
                        if (not alreadyAdded) then
                            table.insert(matchedCommands, {name = cmdName, data = cmdData, priority = 2})
                        end
                    end
                end
            end
        end
        
        -- Sort by priority then alphabetically
        table.sort(matchedCommands, function(a, b)
            if (a.priority == b.priority) then
                return a.name < b.name
            end
            return a.priority < b.priority
        end)
        
        -- Add the suggestions to the panel
        for i, cmd in ipairs(matchedCommands) do
            if (i > 10) then break end -- Limit to 10 suggestions
            self:AddSuggestion(cmd.name, cmd.data)
        end
    end
    
    -- Show or hide the suggestions panel
    if (#self.currentSuggestions > 0) then
        self.cmdSuggestions:SetVisible(true)
    
        local suggestionHeight = math.min(#self.currentSuggestions * 25 + 4, 200)
        self.cmdSuggestions:SetPos(8, self.entry:GetY() - suggestionHeight - 4)
        self.cmdSuggestions:SetSize(self:GetWide() - 16, suggestionHeight)
    
        self.activeSuggestion = 1
        self:UpdateActiveSuggestion()
    else
        self.cmdSuggestions:SetVisible(false)
    end
end

-- Update the command suggestions panel to match the clean style
function PANEL:Think()
    if (input.IsKeyDown(KEY_ESCAPE) and self:IsVisible()) then
        self:SetVisible(false)
    end
    
    -- Update suggestion panel position if it's visible
    if (self.cmdSuggestions:IsVisible()) then
        -- Calculate proper position
        local entryX, entryY = self.entry:GetPos()
        local entryParentX, entryParentY = self.entry:GetParent():GetPos()
        local absoluteEntryY = entryY + entryParentY
        
        -- Get the height of the suggestions panel
        local suggestionHeight = self.cmdSuggestions:GetTall()
        
        -- Position it above the entry field
        self.cmdSuggestions:SetPos(8, absoluteEntryY - suggestionHeight - 4)
        self.cmdSuggestions:SetSize(self:GetWide() - 16, suggestionHeight)
    end
end

function PANEL:UpdateActiveSuggestion()
    -- Ensure the active suggestion is visible in the scroll panel
    if (self.activeSuggestion > 0 and self.currentSuggestions[self.activeSuggestion]) then
        local btn = self.currentSuggestions[self.activeSuggestion].button
        self.suggestionList:ScrollToChild(btn)
    end
end

function PANEL:SetVisible(visible)
    if ( visible ) then
        input.SetCursorPos(self:LocalToScreen(self:GetWide() / 2, self:GetTall() / 2))

        self:SetAlpha(255)
        self:MakePopup()
        self.entry:RequestFocus()
        self.entry:SetVisible(true)
        self.cmdSuggestions:SetVisible(false)
    else
        self:SetAlpha(0)
        self:SetMouseInputEnabled(false)
        self:SetKeyboardInputEnabled(false)
        self.entry:SetText("")
        self.entry:SetVisible(false)
        self.cmdSuggestions:SetVisible(false)
    end
end

function PANEL:Paint(width, height)
    ax.util:DrawBlur(self)

    surface.SetDrawColor(ax.color:Get("background.transparent"))
    surface.DrawRect(0, 0, width, height)
end

vgui.Register("ax.chatbox", PANEL, "EditablePanel")

if ( IsValid(ax.gui.chatbox) ) then
    ax.gui.chatbox:Remove()

    vgui.Create("ax.chatbox")
end