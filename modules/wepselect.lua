MODULE.name = "Weapon Select"
MODULE.author = "Chessnut (Reworked)"
MODULE.description = "A Half-Life 2 style weapon selection interface."

if (CLIENT) then
	MODULE.index = MODULE.index or 1
	MODULE.deltaIndex = MODULE.deltaIndex or MODULE.index
	MODULE.alpha = MODULE.alpha or 0
	MODULE.alphaDelta = MODULE.alphaDelta or MODULE.alpha
	MODULE.fadeTime = MODULE.fadeTime or 0
	MODULE.selectedTime = MODULE.selectedTime or 0
	MODULE.weaponPanels = MODULE.weaponPanels or {}
	
	-- HL2 style colors - updated to white/black style
	local HL2_DARK = Color(0, 0, 0, 210)
	local HL2_BG = Color(255, 255, 255, 40)
	local HL2_HEADER = Color(0, 0, 0, 255)
	local HL2_TEXT = Color(255, 255, 255, 255)
	local HL2_HIGHLIGHT = Color(0, 255, 0, 255)
	local HL2_SELECTED = Color(255, 0, 0, 255)

	function MODULE:HUDShouldDraw(name)
		if (name == "CHudWeaponSelection") then
			return false
		end
	end

	function MODULE:HUDPaint()
		local frameTime = FrameTime()
		self.alphaDelta = Lerp(frameTime * 10, self.alphaDelta, self.alpha)
		local fraction = self.alphaDelta
	
		if (fraction <= 0.01) then 
			-- Clean up panels when not visible
			if self.weaponPanels then
				for k, v in pairs(self.weaponPanels) do
					if IsValid(v) then
						v:Remove()
					end
				end
				self.weaponPanels = {}
			end
			return 
		end
	
		local weapons = LocalPlayer():GetWeapons()
		local weaponCount = #weapons
		
		if (weaponCount == 0) then return end
		
		self.deltaIndex = Lerp(frameTime * 12, self.deltaIndex, self.index)
		
		-- Main panel dimensions - moved to far left
		local panelWidth = ScrW() * 0.25
		local itemHeight = ScrH() * 0.05
		local panelHeight = math.min(weaponCount * itemHeight + 40, ScrH() * 0.6)
		local panelX = ScrW() * 0.01 -- Moved to far left
		local panelY = (ScrH() - panelHeight) * 0.5
		
		-- Draw main background
		surface.SetDrawColor(0, 0, 0, 160 * fraction)
		surface.DrawRect(0, 0, ScrW(), ScrH())
		
		-- Draw panel background - white/black style
		draw.RoundedBox(0, panelX, panelY, panelWidth, panelHeight, ColorAlpha(HL2_DARK, 180 * fraction))
		
		-- Draw header - white bar style
		local headerHeight = 30
		draw.RoundedBox(0, panelX, panelY, panelWidth, headerHeight, ColorAlpha(HL2_BG, fraction * 255))
		draw.SimpleText("WEAPON SELECT", "parallax.large.bold", panelX + 15, panelY + headerHeight/2, ColorAlpha(HL2_HEADER, fraction * 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		-- Calculate visible range
		local selectedIndex = math.Round(self.deltaIndex)
		local visibleItems = math.floor((panelHeight - headerHeight) / itemHeight)
		local startIndex = math.max(1, selectedIndex - math.floor(visibleItems / 2))
		local endIndex = math.min(weaponCount, startIndex + visibleItems - 1)
		
		-- Ensure we show maximum number of items
		if (endIndex - startIndex + 1 < visibleItems and weaponCount >= visibleItems) then
			if (startIndex == 1) then
				endIndex = math.min(weaponCount, startIndex + visibleItems - 1)
			else
				startIndex = math.max(1, endIndex - visibleItems + 1)
			end
		end
		
		-- Draw scroll indicators if needed (fixed for proper scroll direction)
		if (startIndex > 1) then
			draw.SimpleText("▲", "parallax.large.bold", panelX + panelWidth - 15, panelY + headerHeight + 5, ColorAlpha(HL2_TEXT, fraction * 255))
		end
		
		if (endIndex < weaponCount) then
			draw.SimpleText("▼", "parallax.large.bold", panelX + panelWidth - 15, panelY + panelHeight - 15, ColorAlpha(HL2_TEXT, fraction * 255))
		end
		
		-- Draw weapon items
		for i = startIndex, endIndex do
			local weapon = weapons[i]
			if not IsValid(weapon) then continue end
			
			local itemY = panelY + headerHeight + (i - startIndex) * itemHeight
			local isSelected = (i == selectedIndex)
			
			-- Draw selection highlight - white style
			if (isSelected) then
				draw.RoundedBox(0, panelX, itemY, panelWidth, itemHeight, ColorAlpha(HL2_HIGHLIGHT, fraction * 255))
				
				-- White highlight bar with black background
				surface.SetDrawColor(ColorAlpha(Color(255, 255, 255, 255), fraction * 255))
				surface.DrawRect(panelX, itemY, panelWidth, itemHeight)
				
				surface.SetDrawColor(ColorAlpha(HL2_SELECTED, fraction * 255))
				surface.DrawRect(panelX, itemY, 4, itemHeight)
			end
			
			-- Weapon name
			local weaponName = weapon:GetPrintName() or weapon:GetClass() or "Unknown Weapon"
			draw.SimpleText(weaponName:upper(), "parallax.large.bold", panelX + 15, itemY + itemHeight/2, 
				ColorAlpha(isSelected and Color(0, 0, 0, 255) or HL2_TEXT, fraction * 255), 
				TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			
			-- Remove any existing model panel for this weapon
			if IsValid(self.weaponPanels[i]) then
				self.weaponPanels[i]:Remove()
				self.weaponPanels[i] = nil
			end
end
		
		-- Show detailed info for selected weapon
		local selectedWeapon = weapons[selectedIndex]
		if IsValid(selectedWeapon) then
			-- Info panel dimensions - adjusted with left primary panel
			local infoPanelWidth = ScrW() * 0.3
			local infoPanelHeight = ScrH() * 0.3
			local infoPanelX = panelX + panelWidth + 20
			local infoPanelY = (ScrH() - infoPanelHeight) * 0.5
			
			-- Draw info panel background - white/black style
			draw.RoundedBox(0, infoPanelX, infoPanelY, infoPanelWidth, infoPanelHeight, ColorAlpha(HL2_DARK, 180 * fraction))
			
			-- Draw weapon header - white bar style
			local headerHeight = 30
			draw.RoundedBox(0, infoPanelX, infoPanelY, infoPanelWidth, headerHeight, ColorAlpha(HL2_BG, fraction * 255))
			
			local weaponName = selectedWeapon:GetPrintName() or selectedWeapon:GetClass() or "Unknown Weapon"
			draw.SimpleText(weaponName:upper(), "parallax.large.bold", infoPanelX + 15, infoPanelY + headerHeight/2, ColorAlpha(HL2_HEADER, fraction * 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			
			-- Create model panel for selected weapon
			if not IsValid(self.weaponPanels[selectedIndex]) then
				self.weaponPanels[selectedIndex] = vgui.Create("DModelPanel")
				local panel = self.weaponPanels[selectedIndex]
				panel:SetSize(infoPanelWidth * 0.5, infoPanelHeight - headerHeight - 40)
				panel:SetPos(infoPanelX + 10, infoPanelY + headerHeight + 10)
				panel:SetModel(selectedWeapon:GetModel() or "models/weapons/w_pistol.mdl")
				panel:SetMouseInputEnabled(false)
				panel:SetFOV(30)
				panel:SetCamPos(Vector(25, 25, 15))
				panel:SetLookAt(Vector(0, 0, 0))
				panel.LayoutEntity = function(pnl, ent)
					ent:SetAngles(Angle(0, RealTime() * 30, 0))
					return
				end
			end
			
			-- Get weapon description
			local description = ""
			if selectedWeapon.Instructions then
				description = selectedWeapon.Instructions
			elseif selectedWeapon.Purpose then
				description = selectedWeapon.Purpose
			elseif selectedWeapon.GetDescription and isfunction(selectedWeapon.GetDescription) then
				description = selectedWeapon:GetDescription()
			elseif selectedWeapon.Description then
				description = selectedWeapon.Description
			elseif selectedWeapon.ixItem then
				description = selectedWeapon.ixItem.description or ""
			end
			
			if (description == "" or not description) then
				description = "No description available."
			end
			
			-- Draw description
			local descX = infoPanelX + infoPanelWidth * 0.5 + 20
			local descY = infoPanelY + headerHeight + 20
			local descWidth = infoPanelWidth * 0.5 - 30
			
			local descriptionLines = self:WrapText(description, "parallax.small", descWidth)
			for i, line in ipairs(descriptionLines) do
				draw.SimpleText(line, "parallax.small", descX, descY + (i-1) * 18, ColorAlpha(HL2_TEXT, fraction * 255))
			end
			
			-- Draw stats/info
			local infoY = descY + (#descriptionLines + 1) * 18
			
			local stats = {}
			if selectedWeapon.Primary then
				if selectedWeapon.Primary.ClipSize and selectedWeapon.Primary.ClipSize > 0 then
					table.insert(stats, "Clip Size: " .. selectedWeapon.Primary.ClipSize)
				end
				if selectedWeapon.Primary.Damage and selectedWeapon.Primary.Damage > 0 then
					table.insert(stats, "Damage: " .. selectedWeapon.Primary.Damage)
				end
			end
			
			for i, stat in ipairs(stats) do
				draw.SimpleText(stat, "parallax.small", descX, infoY + (i-1) * 18, ColorAlpha(HL2_TEXT, fraction * 255))
			end
			
			-- Controls hint at bottom
			local hintText = "MOUSE WHEEL: Scroll • LMB/RMB: Select"
			draw.SimpleText(hintText, "parallax.small.bold", infoPanelX + infoPanelWidth/2, infoPanelY + infoPanelHeight - 20, 
				ColorAlpha(HL2_TEXT, fraction * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	-- Helper function to wrap text
	function MODULE:WrapText(text, font, maxWidth)
		local lines = {}
		surface.SetFont(font)
		
		for paragraph in text:gmatch("[^\r\n]+") do
			local line = ""
			local lineWidth = 0
			
			for word in paragraph:gmatch("%S+") do
				local wordWidth, _ = surface.GetTextSize(word .. " ")
				
				if lineWidth + wordWidth <= maxWidth then
					line = line .. (line == "" and "" or " ") .. word
					lineWidth = lineWidth + wordWidth
				else
					table.insert(lines, line)
					line = word
					lineWidth = surface.GetTextSize(word .. " ")
				end
			end
			
			if line ~= "" then
				table.insert(lines, line)
			end
		end
		
		return lines
	end

	function MODULE:OnIndexChanged(weapon)
		self.alpha = 1
		self.fadeTime = CurTime() + 5
		self.selectedTime = CurTime()

		if (IsValid(weapon)) then
			local source, pitch = hook.Run("WeaponCycleSound")
			LocalPlayer():EmitSound(source or "common/wpn_hudselect.wav", 50, pitch or 100)
		end
	end

	function MODULE:PlayerBindPress(client, bind, pressed)
		bind = bind:lower()

		if (!pressed or !bind:find("invprev") and !bind:find("invnext")
		and !bind:find("slot") and !bind:find("attack")) then
			return
		end

		local currentWeapon = client:GetActiveWeapon()
		local bValid = IsValid(currentWeapon)
		local bTool

		if (client:InVehicle() or (bValid and currentWeapon:GetClass() == "weapon_physgun" and client:KeyDown(IN_ATTACK))) then
			return
		end

		if (bValid and currentWeapon:GetClass() == "gmod_tool") then
			local tool = client:GetTool()
			bTool = tool and (tool.Scroll != nil)
		end

		local weapons = client:GetWeapons()

		if (bind:find("invprev") and !bTool) then
			local oldIndex = self.index
			self.index = math.max(self.index - 1, 1) -- Fixed direction for proper scrolling

			if (self.alpha == 0 or oldIndex != self.index) then
				self:OnIndexChanged(weapons[self.index])
			end

			return true
		elseif (bind:find("invnext") and !bTool) then
			local oldIndex = self.index
			self.index = math.min(self.index + 1, #weapons) -- Fixed direction for proper scrolling

			if (self.alpha == 0 or oldIndex != self.index) then
				self:OnIndexChanged(weapons[self.index])
			end

			return true
		elseif (bind:find("slot")) then
			self.index = math.Clamp(tonumber(bind:match("slot(%d)")) or 1, 1, #weapons)
			self:OnIndexChanged(weapons[self.index])

			return true
		elseif (bind:find("attack") and self.alpha > 0) then
			local weapon = weapons[self.index]

			if (IsValid(weapon)) then
				LocalPlayer():EmitSound(hook.Run("WeaponSelectSound", weapon) or "HL2Player.Use")

				input.SelectWeapon(weapon)
				self.alpha = 0
			end

			return true
		end
	end

	function MODULE:Think()
		local client = LocalPlayer()
		if (!IsValid(client) or !client:Alive()) then
			self.alpha = 0
		end
		
		-- Auto-fade after timeout
		if (self.fadeTime < CurTime() and self.alpha > 0) then
			self.alpha = math.Approach(self.alpha, 0, FrameTime())
		end
	end

	function MODULE:ScoreboardShow()
		self.alpha = 0
	end

	function MODULE:ShouldPopulateEntityInfo(entity)
		if (self.alpha > 0) then
			return false
		end
	end
end