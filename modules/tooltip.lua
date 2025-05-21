-- Client-side functionality
if (CLIENT) then
    -- Variables to track the current item and tooltip
    local currentItem = nil
    local tooltipPanel = nil
    
    -- Function to create and show the tooltip
    local function ShowTooltip(item, entity)
        -- Clean up old tooltip if it exists
        if (tooltipPanel and IsValid(tooltipPanel)) then
            tooltipPanel:Remove()
        end
        
        -- Define some design constants
        local TOOLTIP_WIDTH = 260
        local PADDING = 12
        local TITLE_HEIGHT = 24
        
        -- Create color variables for easy styling
        local titleColor = Color(255, 255, 255)        -- Pure white for title
        local descColor = Color(200, 200, 200)         -- Light gray for description
        
        -- Calculate height based on text content
        surface.SetFont("parallax.small")
        local descriptionText = item.Description or "No description available."
        local _, textHeight = surface.GetTextSize(descriptionText)
        local tooltipHeight = TITLE_HEIGHT + textHeight + (PADDING * 3)
        
        -- Create the tooltip panel
        tooltipPanel = vgui.Create("DPanel")
        tooltipPanel:SetSize(TOOLTIP_WIDTH, tooltipHeight)
        tooltipPanel.Entity = entity
        
        -- Position tooltip statically
        local function PositionTooltipStatically()
            if (IsValid(tooltipPanel) and IsValid(tooltipPanel.Entity)) then
                -- Get entity position in screen space for the connection line
                local pos = tooltipPanel.Entity:GetPos()
                local screenPos = pos:ToScreen()
                
                -- Position tooltip at bottom center of screen
                local tooltipW, tooltipH = tooltipPanel:GetSize()
                local centerX = ScrW() / 2 - (tooltipW / 2)  -- Center horizontally
                local bottomY = ScrH() - tooltipH - 100      -- 100 pixels from bottom of screen
                
                tooltipPanel:SetPos(centerX, bottomY)
                
                -- Store connection point data for the paint hook
                tooltipPanel.EntityScreenPos = screenPos
            end
        end
        
        -- Position tooltip immediately and keep updating position of entity for line drawing
        PositionTooltipStatically()
        tooltipPanel.Think = PositionTooltipStatically
        
        -- Custom paint function for a unique tooltip look
        tooltipPanel.Paint = function(self, w, h)
            -- Removed drawing of the line as per the request
        end
        
        -- Create a label for the item's name with custom styling
        local nameLabel = vgui.Create("DLabel", tooltipPanel)
        nameLabel:SetText(item.Name or "Unknown Item")
        nameLabel:SetFont("parallax.small.bold")
        nameLabel:SetTextColor(titleColor)
        nameLabel:SetPos(PADDING, PADDING - 2)
        nameLabel:SetSize(TOOLTIP_WIDTH - (PADDING * 2), TITLE_HEIGHT)
        nameLabel:SetContentAlignment(5) -- Center align (5 is center)

        -- Create a label for the item's description
        local descriptionLabel = vgui.Create("DLabel", tooltipPanel)
        descriptionLabel:SetText(descriptionText)
        descriptionLabel:SetFont("parallax.small")
        descriptionLabel:SetTextColor(descColor)
        local descWidth = TOOLTIP_WIDTH - (PADDING * 2)
        local descHeight = tooltipHeight - TITLE_HEIGHT - (PADDING * 2)
        descriptionLabel:SetSize(descWidth, descHeight)
        descriptionLabel:SetPos((TOOLTIP_WIDTH - descWidth) / 2, TITLE_HEIGHT + PADDING)
        descriptionLabel:SetWrap(true)
        descriptionLabel:SetContentAlignment(5)
        descriptionLabel:SetAutoStretchVertical(true)

        -- Add text alignment function
        local oldPaint = descriptionLabel.Paint
        descriptionLabel.Paint = function(self, w, h)
            if oldPaint then oldPaint(self, w, h) end
            self:SetTextInset((w - self:GetTextSize()) / 2, 0)
        end

        
    end
    
    -- Function to check what the player is looking at
    local function CheckForItemTooltip()
        -- Perform a trace to detect the entity the player is looking at
        local tr = LocalPlayer():GetEyeTrace()
        
        -- Ensure the trace is hitting a valid item entity (modify the class name as needed)
        if (IsValid(tr.Entity) and tr.Entity:GetClass() == "ax_item") then
            -- Get the item from its unique ID
            local item = ax.item:Get(tr.Entity:GetUniqueID())
            
            -- Only show the tooltip if it's a valid item and it's not the same item as last time
            if (item and item ~= currentItem) then
                -- Print out the UniqueID of the item
                print("Player is looking at item with UniqueID: " .. item.UniqueID)
                
                -- Set the current item to the one being looked at
                currentItem = item
    
                -- If you want to show a tooltip, call the ShowTooltip function
                ShowTooltip(item, tr.Entity)
            end
        else
            -- Remove the tooltip if the player is no longer looking at an item
            if (tooltipPanel and IsValid(tooltipPanel)) then
                tooltipPanel:Remove()
                tooltipPanel = nil
            end
            currentItem = nil
        end
    end
    
    -- Hook to check for items to display tooltips every frame
    hook.Add("Think", "ItemTooltipCheck", CheckForItemTooltip)
end