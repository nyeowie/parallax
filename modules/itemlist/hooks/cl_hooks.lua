print("[Item Viewer] Client-side loading")

-- Cache for item data we'll display
local cachedItems = {}

-- Create a global cache to track processed items
local processedItems = {}

-- Define theme colors for consistent styling
local THEME = {
    background = Color(230, 230, 230, 255),    -- Light background
    panel = Color(255, 255, 255, 255),         -- White panels
    panelHover = Color(240, 240, 255, 255),    -- Subtle hover highlight
    accent = Color(70, 130, 180, 255),         -- Steel blue accent
    text = Color(50, 50, 50, 255),             -- Dark text
    textDark = Color(100, 100, 100, 255),      -- Softer text
    textHighlight = Color(0, 0, 0, 255),       -- Black text for emphasis
    border = Color(200, 200, 200, 255),        -- Light border
    highlight = Color(70, 130, 180, 30),       -- Transparent blue highlight
    categoryBg = Color(245, 245, 245, 255)     -- Very light gray for categories
}

-- Function to refresh the item list from the ax.item system
local function RefreshItemList()
    cachedItems = {}
    
    -- Check if the ax.item system exists and has stored items
    if ax and ax.item and ax.item.stored then
        for uniqueID, itemData in pairs(ax.item.stored) do
            table.insert(cachedItems, {
                uniqueID = uniqueID,
                name = itemData.Name or uniqueID,
                description = itemData.Description or "No description available.",
                model = itemData.Model or "models/props_junk/PopCan01a.mdl",
                category = itemData.Category or "Miscellaneous",
                weight = itemData.Weight or 1
            })
        end
    else
        print("[Item Viewer] Warning: ax.item system not detected!")
    end
    
    -- Sort items alphabetically by name
    table.sort(cachedItems, function(a, b)
        return a.name < b.name
    end)
    
    print("[Item Viewer] Refreshed item list, found " .. #cachedItems .. " items")
end

-- Create a tooltip window that follows the mouse but doesn't interfere with clicks
local activeTooltip = nil

local function ShowTooltip(itemData)
    -- Remove existing tooltip if there is one
    if IsValid(activeTooltip) then
        activeTooltip:Remove()
    end
    
    -- Create tooltip panel
    local tooltip = vgui.Create("DPanel")
    tooltip:SetSize(250, 180)
    tooltip:SetZPos(9999999999) -- Put it on top of other panels
    tooltip:SetMouseInputEnabled(false) -- Prevent mouse input
    tooltip:SetKeyboardInputEnabled(false)
    
    -- Custom paint function for a prettier tooltip
    tooltip.Paint = function(self, w, h)
        -- Draw background with rounded corners
        draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50, 230))
        
        -- Draw border
        surface.SetDrawColor(Color(70, 70, 70, 255))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        -- Draw accent line at top
        surface.SetDrawColor(THEME.accent)
        surface.DrawRect(0, 0, w, 2)
    end
    
    -- Title in tooltip
    local title = vgui.Create("DLabel", tooltip)
    title:Dock(TOP)
    title:DockMargin(8, 8, 8, 2)
    title:SetText(itemData.name)
    title:SetFont("DermaLarge")
    title:SetTextColor(Color(255, 255, 255, 255))
    title:SetContentAlignment(5)
    title:SetTall(30)
    
    -- ID in tooltip
    local idLabel = vgui.Create("DLabel", tooltip)
    idLabel:Dock(TOP)
    idLabel:DockMargin(8, 0, 8, 0)
    idLabel:SetText("ID: " .. itemData.uniqueID)
    idLabel:SetFont("DermaDefaultBold")
    idLabel:SetTextColor(THEME.accent)
    idLabel:SetContentAlignment(5)
    
    -- Add divider
    local divider = vgui.Create("DPanel", tooltip)
    divider:Dock(TOP)
    divider:DockMargin(15, 5, 15, 5)
    divider:SetTall(1)
    divider.Paint = function(self, w, h)
        surface.SetDrawColor(Color(100, 100, 100, 255))
        surface.DrawRect(0, 0, w, h)
    end
    
    -- Description in tooltip
    local desc = vgui.Create("DLabel", tooltip)
    desc:Dock(TOP)
    desc:DockMargin(8, 5, 8, 5)
    desc:SetText(itemData.description)
    desc:SetFont("DermaDefault")
    desc:SetTextColor(Color(220, 220, 220, 255))
    desc:SetWrap(true)
    desc:SetAutoStretchVertical(true)
    
    -- Additional info in tooltip
    local info = vgui.Create("DLabel", tooltip)
    info:Dock(TOP)
    info:DockMargin(8, 5, 8, 8)
    info:SetText("Category: " .. itemData.category .. "\nWeight: " .. itemData.weight)
    info:SetFont("DermaDefault")
    info:SetTextColor(Color(180, 180, 180, 255))
    info:SetWrap(true)
    info:SetAutoStretchVertical(true)
    
    -- Size the tooltip based on content
    tooltip:InvalidateLayout(true)
    tooltip:SizeToChildren(false, true)
    
    -- Think function to follow mouse
    tooltip.Think = function(self)
        if not self:IsValid() then return end
        
        local x, y = gui.MousePos()
        local w, h = self:GetSize()
        local sw, sh = ScrW(), ScrH()
        
        -- Offset from cursor and adjust to keep on screen
        x = x + 15
        y = y + 5
        
        -- Ensure tooltip stays on screen
        if x + w > sw then x = x - w - 30 end
        if y + h > sh then y = sh - h - 5 end
        
        self:SetPos(x, y)
    end
    
    activeTooltip = tooltip
    return tooltip
end

-- Function to hide the current tooltip
local function HideTooltip()
    if IsValid(activeTooltip) then
        activeTooltip:Remove()
        activeTooltip = nil
    end
end

-- Function to create our item content icon (similar to the second document)
-- Function to create our item content icon (similar to the second document)
local function CreateItemIcon(parent, itemData)
    -- Check if this item has already been processed
    local itemKey = itemData.uniqueID .. parent:GetName()
    if processedItems[itemKey] then return end
    processedItems[itemKey] = true
    
    -- Create the ContentIcon with fixed size
    local icon = vgui.Create("ContentIcon", parent)
    
    icon:SetContentType("ax_item")
    icon:SetSpawnName(itemData.uniqueID)
    icon:SetName(itemData.name)
    
    -- Set consistent size for all icons - fixed size to prevent layout issues
    icon:SetSize(128, 128)
    icon:SetWide(128)
    icon:SetTall(128)
    
    -- Override the model image with our own
    icon.model = vgui.Create("ModelImage", icon)
    icon.model:SetMouseInputEnabled(false)
    icon.model:SetKeyboardInputEnabled(false)
    icon.model:StretchToParent(16, 16, 16, 36) -- Adjusted bottom margin for label
    
    -- Ensure model is set properly with correct parameters
    local modelPath = itemData.model or "models/props_junk/PopCan01a.mdl"
    icon.model:SetModel(modelPath, 0)
    
    -- Fix z-ordering
    if icon.Image then
        icon.model:MoveToBefore(icon.Image)
    end
    
    -- Make sure Label exists and is properly formatted
    if not icon.Label then
        icon.Label = vgui.Create("DLabel", icon)
    end
    
    -- Configure the label for better appearance
    icon.Label:Dock(BOTTOM)
    icon.Label:SetText(itemData.name)
    icon.Label:SetFont("DermaDefaultBold")
    icon.Label:SetTextColor(THEME.text)
    icon.Label:SetContentAlignment(5) -- Center alignment
    icon.Label:DockMargin(4, 0, 4, 4)
    icon.Label:SetHeight(18)
    icon.Label:SetVisible(false)
    
    -- Handle click interactions
    function icon:DoClick()
        surface.PlaySound("ui/buttonclickrelease.wav") 
    end
    
    -- Add tooltip behavior
    icon.OnCursorEntered = function(self)
        ShowTooltip(itemData)
        surface.PlaySound("ui/buttonrollover.wav")
    end
    
    icon.OnCursorExited = function(self)
        HideTooltip()
    end
    
    -- Handle menu functionality
    function icon:OpenMenu()
        local menu = DermaMenu()
        
        menu:AddOption("Copy Item ID to Clipboard", function()
            SetClipboardText(itemData.uniqueID)
            notification.AddLegacy("Copied: " .. itemData.uniqueID, NOTIFY_GENERIC, 2)
        end)
        
        menu:AddSpacer()
        
        menu:AddOption("Give Item (Admin)", function()
            if LocalPlayer():IsAdmin() then
                RunConsoleCommand("ax_item_add", itemData.uniqueID)
                notification.AddLegacy("Giving item: " .. itemData.uniqueID, NOTIFY_GENERIC, 2)
                surface.PlaySound("items/ammo_pickup.wav")
            else
                notification.AddLegacy("Admin only command!", NOTIFY_ERROR, 2)
                surface.PlaySound("buttons/button10.wav")
            end
        end)
        
        menu:AddOption("Spawn Item (Admin)", function()
            if LocalPlayer():IsAdmin() then
                RunConsoleCommand("ax_item_spawn", itemData.uniqueID)
                notification.AddLegacy("Spawning item: " .. itemData.uniqueID, NOTIFY_GENERIC, 2)
                surface.PlaySound("items/ammopickup.wav")
            else
                notification.AddLegacy("Admin only command!", NOTIFY_ERROR, 2)
                surface.PlaySound("buttons/button10.wav")
            end
        end)
        
        menu:Open()
        
        -- Style the menu items
        for _, v in pairs(menu:GetChildren()[1]:GetChildren()) do
            if v:GetClassName() == "Label" then
                v:SetFont("DermaDefault")
            end
        end
    end
    
    -- Ensure the icon is properly added to the parent
    if IsValid(parent) then
        parent:Add(icon)
    end
    
    return icon
end
local function CreateEnhancedContainer(parent)
    local container = vgui.Create("DIconLayout", parent)
    container:Dock(FILL)
    container:SetSpaceX(10) -- Set horizontal spacing between icons
    container:SetSpaceY(10) -- Set vertical spacing between icons
    container:DockMargin(410, 10, 10, 10) -- Add margin around the container
    container:SetBorder(0) -- No border around icons
    
    -- Set a fixed size for icons
    container:SetMinimumSize(128, 128)
    
    -- Add custom properties to make it compatible with ContentContainer
    container.SetTriggerSpawnlistChange = function(self, bTrigger) end
    
    -- Properly implement Clear function
    function container:Clear()
        self:InvalidateLayout(true)
        
        local children = self:GetChildren()
        for k, v in pairs(children) do
            if IsValid(v) then
                v:Remove()
            end
        end
        
        -- Reset the processed items for this container
        processedItems = {}
    end
    
    -- Add function to maintain ContentContainer compatibility
    function container:Add(panel)
        if IsValid(panel) then
            panel:SetParent(self)
        end
        self:InvalidateLayout()
        return panel
    end
    
    return container
end

-- Icons for categories
local icons = {
    ["Ammo"] = "box",
    ["Clothing"] = "user_suit",
    ["Consumeables"] = "cake", 
    ["Consumables"] = "cake",
    ["Food"] = "cake",
    ["Junk"] = "bin",
    ["Medical Items"] = "heart",
    ["Medical"] = "heart", 
    ["Medicine"] = "heart",
    ["Miscellaneous"] = "brick",
    ["misc"] = "brick",
    ["Weapons"] = "gun",
    ["Tools"] = "wrench",
    ["Equipment"] = "cog",
    ["Crafting"] = "cog_go",
    ["Resources"] = "package",
    ["Quest Items"] = "star"
}

-- Function to create our item viewer panel with the new style
local function CreateItemViewerPanel()
    local base = vgui.Create("SpawnmenuContentPanel")
    base:Dock(FILL)
    
    -- Build the content navigation bar (left side)
    local tree = base.ContentNavBar.Tree
    
    -- Add search panel at the top
    local searchPanel = vgui.Create("DPanel", base.ContentNavBar)
    searchPanel:Dock(TOP)
    searchPanel:SetHeight(25)
    searchPanel:DockMargin(0, 0, 0, 5)
    searchPanel:SetPaintBackground(false)
    
    local searchBox = vgui.Create("DTextEntry", searchPanel)
    searchBox:Dock(FILL)
    searchBox:SetPlaceholderText("Search items...")
    
    local searchBtn = searchBox:Add("DImageButton")
    searchBtn:SetImage("icon16/magnifier.png")
    searchBtn:SetText("")
    searchBtn:Dock(RIGHT)
    searchBtn:DockMargin(4, 2, 4, 2)
    searchBtn:SetSize(16, 16)
    searchBtn:SetTooltip("Press to search")
    
    -- Create item counter label
    local itemCounter = vgui.Create("DLabel", base.ContentNavBar)
    itemCounter:Dock(TOP)
    itemCounter:SetHeight(20)
    itemCounter:SetText("0 items")
    itemCounter:SetTextColor(THEME.textDark)
    itemCounter:DockMargin(5, 0, 5, 5)
    
    -- Create a refresh button
    local refreshBtn = vgui.Create("DButton", base.ContentNavBar)
    refreshBtn:Dock(TOP)
    refreshBtn:SetHeight(28)
    refreshBtn:SetText("Refresh Items")
    refreshBtn:SetIcon("icon16/arrow_refresh.png")
    refreshBtn:DockMargin(5, 0, 5, 5)
    
    -- Content container for search results
    local searchResults = CreateEnhancedContainer(base)
    searchResults:SetVisible(false)
    searchResults:SetTriggerSpawnlistChange(false)
    
    -- Store categories and their containers
    local categories = {}
    local categoryContainers = {}
    
    -- Store the item count for display
    local totalItemCount = 0
    
    -- Handle search functionality
    local function PerformSearch()
        local text = searchBox:GetValue():lower()
        if text == "" then return end
        
        text = string.PatternSafe(text)
        searchResults:Clear()
        processedItems = {}
        
        -- Create a header for search results
        local header = vgui.Create("ContentHeader", searchResults)
        
        -- Find matching items
        local results = {}
        for _, itemData in pairs(cachedItems) do
            if (string.find(string.lower(itemData.name or ""), text) or 
                string.find(string.lower(itemData.uniqueID or ""), text) or
                string.find(string.lower(itemData.category or ""), text)) then
                table.insert(results, itemData)
            end
        end
        
        header:SetText(#results .. " Results for \"" .. searchBox:GetValue() .. "\"")
        searchResults:Add(header)
        
        -- Display matching items
        for _, itemData in SortedPairsByMemberValue(results, "name") do
            CreateItemIcon(searchResults, itemData)
        end
        
        -- Switch to the search results
        base:SwitchPanel(searchResults)
    end
    
    searchBox.OnEnter = PerformSearch
    searchBtn.DoClick = PerformSearch
    
    -- Function to refresh the UI
    local function RefreshUI()
        RefreshItemList()
        processedItems = {}
        totalItemCount = #cachedItems
        
        -- Update item counter
        itemCounter:SetText(totalItemCount .. " items")
        
        -- Clear categories
        tree:Clear()
        categoryContainers = {}
        
        -- Find all categories
        local categoryCounts = {}
        for _, itemData in pairs(cachedItems) do
            categoryCounts[itemData.category] = (categoryCounts[itemData.category] or 0) + 1
        end
        
        -- Add "All Items" category
        local allItems = tree:AddNode("All Items (" .. totalItemCount .. ")", "icon16/application_view_icons.png")
        
        allItems.Container = CreateEnhancedContainer(base)
        allItems.Container:SetVisible(false)
        allItems.Container:SetTriggerSpawnlistChange(false)
        
        local allHeader = vgui.Create("ContentHeader", allItems.Container)
        allHeader:SetText("All Items - " .. totalItemCount .. " items")
        allItems.Container:Add(allHeader)
        
        -- Style the node
        allItems.PaintOver = function(self, w, h)
            if self.Hovered then
                surface.SetDrawColor(THEME.highlight)
                surface.DrawRect(0, 0, w, h)
            end
            
            if self.m_bSelected then
                surface.SetDrawColor(THEME.accent)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
        end
        
        allItems.DoClick = function(self)
            base:SwitchPanel(self.Container)
            
            -- Always repopulate on click to ensure items show up
            self.Container:Clear()
            local header = vgui.Create("ContentHeader", self.Container)
            header:SetText("All Items - " .. totalItemCount .. " items")
            self.Container:Add(header)
            
            for _, itemData in SortedPairsByMemberValue(cachedItems, "name") do
                CreateItemIcon(self.Container, itemData)
            end
            self.Populated = true
        end
        
        -- Add other categories
        for category, count in SortedPairs(categoryCounts) do
            local categoryNode = tree:AddNode(
                category .. " (" .. count .. ")", 
                icons[category] and ("icon16/" .. icons[category] .. ".png") or "icon16/brick.png"
            )
            
            -- Style the node
            categoryNode.PaintOver = function(self, w, h)
                if self.Hovered then
                    surface.SetDrawColor(THEME.highlight)
                    surface.DrawRect(0, 0, w, h)
                end
                
                if self.m_bSelected then
                    surface.SetDrawColor(THEME.accent)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end
            
            -- Create container for this category
            categoryNode.Container = CreateEnhancedContainer(base)
            categoryNode.Container:SetVisible(false)
            categoryNode.Container:SetTriggerSpawnlistChange(false)
            
            local catHeader = vgui.Create("ContentHeader", categoryNode.Container)
            catHeader:SetText(category .. " - " .. count .. " items")
            categoryNode.Container:Add(catHeader)
            
            -- Store for later use
            categoryContainers[category] = categoryNode.Container
            
            -- Handle click to show items
            categoryNode.DoClick = function(self)
                base:SwitchPanel(self.Container)
                
                -- Always repopulate on click to ensure items show up
                self.Container:Clear()
                local header = vgui.Create("ContentHeader", self.Container)
                header:SetText(category .. " - " .. count .. " items")
                self.Container:Add(header)
                
                for _, itemData in SortedPairsByMemberValue(cachedItems, "name") do
                    if itemData.category == category then
                        CreateItemIcon(self.Container, itemData)
                    end
                end
                self.Populated = true
            end
        end
        
        -- Select the first node
        local firstNode = tree:Root():GetChildNode(0)
        if IsValid(firstNode) then
            firstNode:InternalDoClick()
        end
    end
    
    -- Set up refresh button
    refreshBtn.DoClick = function()
        RefreshUI()
        notification.AddLegacy("Item list refreshed", NOTIFY_GENERIC, 2)
        surface.PlaySound("buttons/button14.wav")
    end
    
    -- Initial refresh
    RefreshUI()
    
    -- Return the completed panel
    return base
end

-- Use a local variable to track if we've initialized
local hasInitialized = false

-- Function to add our tab to the spawnmenu
local function AddItemViewerTab()
    if hasInitialized then return end
    
    print("[Item Viewer] Adding tab to spawnmenu")
    spawnmenu.AddCreationTab("Item Viewer", CreateItemViewerPanel, "icon16/box.png", 95)
    hasInitialized = true
end

-- Add our tab when the game is ready
hook.Add("InitPostEntity", "ItemViewerInit", function()
    timer.Simple(1, AddItemViewerTab)
end)

-- This makes sure our tab appears after a map change
hook.Add("OnGamemodeLoaded", "ItemViewerGamemodeLoaded", function()
    timer.Simple(1, AddItemViewerTab)
end)

-- Add console command to force reload the tab
concommand.Add("reload_item_viewer", function()
    print("[Item Viewer] Forcing refresh")
    hasInitialized = false
    AddItemViewerTab()
    RunConsoleCommand("spawnmenu_reload")
end)

-- Clean up tooltip when game UI closes
hook.Add("OnGameUIHidden", "ItemViewerCleanupTooltip", function()
    HideTooltip()
end)

-- Hook into the OW item system if it exists
hook.Add("OnItemAdded", "ItemViewerRefresh", function()
    if hasInitialized then
        RefreshItemList()
        
        -- Find and refresh our panel if it exists
        local creationMenus = g_SpawnMenu and g_SpawnMenu.CreationMenus
        if creationMenus then
            for _, menu in pairs(creationMenus) do
                if menu.Tab:GetText() == "Item Viewer" then
                    -- Force a refresh when the tab is next selected
                    if menu.Panel.RefreshUI then
                        menu.Panel.RefreshUI()
                    end
                    break
                end
            end
        end
    end
end)

spawnmenu.AddContentType("ax_item", function(container, data)
    if (!data.name) then return end
    
    -- Check if this item has already been processed
    local itemKey = data.uniqueID .. container:GetName()
    if processedItems[itemKey] then return end
    processedItems[itemKey] = true
    
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("ax_item")
    icon:SetSpawnName(data.uniqueID)
    icon:SetName(data.name)
    
    -- Enforced fixed size
    icon:SetSize(128, 128)
    icon:SetWide(128)
    icon:SetTall(128)
    
    icon.model = vgui.Create("ModelImage", icon)
    icon.model:SetMouseInputEnabled(false)
    icon.model:SetKeyboardInputEnabled(false)
    icon.model:StretchToParent(16, 16, 16, 36) -- Adjusted bottom margin for label
    
    -- Proper model setup
    local modelPath = data.model or "models/props_junk/PopCan01a.mdl"
    icon.model:SetModel(modelPath, 0)
    
    -- Fix z-ordering if Image exists
    if icon.Image then
        icon.model:MoveToBefore(icon.Image)
    end
    
    -- Make sure Label exists and is properly formatted
    if not icon.Label then
        icon.Label = vgui.Create("DLabel", icon)
    end
    
    -- Configure the label properly
    icon.Label:Dock(BOTTOM)
    icon.Label:SetText(data.name)
    icon.Label:SetFont("DermaDefaultBold")
    icon.Label:SetTextColor(THEME.text)
    icon.Label:SetContentAlignment(5) -- Center alignment
    icon.Label:DockMargin(4, 0, 4, 4)
    icon.Label:SetHeight(18)
    icon.Label:SetVisible(true)
    
    function icon:DoClick()
        surface.PlaySound("ui/buttonclickrelease.wav")
    end
    
    -- Add tooltip behavior
    icon.OnCursorEntered = function(self)
        ShowTooltip(data)
        surface.PlaySound("ui/buttonrollover.wav")
    end
    
    icon.OnCursorExited = function(self)
        HideTooltip()
    end
    
    function icon:OpenMenu()
        local menu = DermaMenu()
        
        menu:AddOption("Copy Item ID to Clipboard", function()
            SetClipboardText(data.uniqueID)
            notification.AddLegacy("Copied: " .. data.uniqueID, NOTIFY_GENERIC, 2)
        end)
        
        menu:AddSpacer()
        
        menu:AddOption("Give Item (Admin)", function()
            if LocalPlayer():IsAdmin() then
                RunConsoleCommand("ax_item_add", data.uniqueID)
                notification.AddLegacy("Giving item: " .. data.uniqueID, NOTIFY_GENERIC, 2)
                surface.PlaySound("items/ammo_pickup.wav")
            else
                notification.AddLegacy("Admin only command!", NOTIFY_ERROR, 2)
                surface.PlaySound("buttons/button10.wav")
            end
        end)
        
        menu:AddOption("Spawn Item (Admin)", function()
            if LocalPlayer():IsAdmin() then
                RunConsoleCommand("ax_item_spawn", data.uniqueID)
                notification.AddLegacy("Spawning item: " .. data.uniqueID, NOTIFY_GENERIC, 2)
                surface.PlaySound("items/ammopickup.wav")
            else
                notification.AddLegacy("Admin only command!", NOTIFY_ERROR, 2)
                surface.PlaySound("buttons/button10.wav")
            end
        end)
        
        menu:Open()
        
        -- Style the menu items
        for _, v in pairs(menu:GetChildren()[1]:GetChildren()) do
            if v:GetClassName() == "Label" then
                v:SetFont("DermaDefault")
            end
        end
    end
    
    -- Ensure proper addition to container
    if (IsValid(container)) then
        container:Add(icon)
    end
end)

print("[Item Viewer] Setup complete")