local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local isFrameInRaidContainer = M.IsFrameInRaidContainer
local setStatusBarColorCached = M.SetStatusBarColorCached
local setTextureColorCached = M.SetTextureColorCached

local function getDefaultHealthBarColor(frame)
	if not frame then return nil end
	local unit = frame.unit or frame.displayedUnit
	if unit and UnitIsPlayer(unit) then
		if type(CompactUnitFrame_GetOptionUseClassColors) == "function" then
			local okUse, useClass = pcall(CompactUnitFrame_GetOptionUseClassColors, frame)
			if okUse and useClass then
				local _, class = UnitClass(unit)
				local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
				if classColor then
					return classColor.r, classColor.g, classColor.b, 1
				end
			end
		end
	end
	if type(CompactUnitFrame_GetOptionCustomHealthBarColors) == "function" then
		local okColor, color = pcall(CompactUnitFrame_GetOptionCustomHealthBarColors, frame)
		if okColor and color and color.GetRGB then
			local okRGB, r, g, b = pcall(color.GetRGB, color)
			if okRGB and type(r) == "number" and type(g) == "number" and type(b) == "number" then
				return r, g, b, 1
			end
		end
	end
	return 0, 1, 0, 1
end

local function applyHealthColors(frame)
	if not M.DB or not isFrameInRaidContainer(frame) then return end
	local healthBar = frame.healthBar
	if healthBar then
		if M.DB.healthColorEnabled and M.DB.healthColor then
			local c = M.DB.healthColor
			setStatusBarColorCached(healthBar, c.r, c.g, c.b, c.a or 1)
		else
			local r, g, b, a = getDefaultHealthBarColor(frame)
			if r and g and b then
				setStatusBarColorCached(healthBar, r, g, b, a or 1)
			end
		end
	end
	if healthBar then
		local unit = frame.displayedUnit or frame.unit
		local useDeadBg = false
		if unit and M.DB.healthDeadBgColorEnabled and M.DB.healthDeadBgColor then
			local okDead, deadOrGhost = pcall(UnitIsDeadOrGhost, unit)
			if okDead and deadOrGhost == true then
				useDeadBg = true
			end
		end

		if useDeadBg or (M.DB.healthBgColorEnabled and M.DB.healthBgColor) then
			local c
			if useDeadBg then
				c = M.DB.healthDeadBgColor
			else
				c = M.DB.healthBgColor
				if M.DB.healthBgClassColor then
					if unit and UnitIsPlayer(unit) then
						local _, class = UnitClass(unit)
						local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
						if classColor then
							c = { r = classColor.r, g = classColor.g, b = classColor.b, a = c.a or 1 }
						end
					end
				end
			end
			local bg = frame._srfHealthBg
			if not bg then
				bg = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
				bg:SetAllPoints(healthBar)
				frame._srfHealthBg = bg
			end
			local alpha = c.a or 1
			setTextureColorCached(bg, c.r, c.g, c.b, alpha)
			bg:Show()
		else
			if frame._srfHealthBg then
				frame._srfHealthBg:Hide()
			end
		end
	end
end

local function hideAggroHighlight(frame)
	if not frame or not isFrameInRaidContainer(frame) then return end
	if frame.aggroHighlight and frame.aggroHighlight.Hide then
		frame.aggroHighlight:Hide()
	end
end

function M:RefreshRaidHealthColors()
	local function refresh(frame)
		if not frame then return end
		if not isFrameInRaidContainer(frame) then return end
		if not M.DB then return end
		local unit = frame.displayedUnit or frame.unit
		if not unit or unit == "" then
			applyHealthColors(frame)
			return
		end
		applyHealthColors(frame)
	end
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", refresh)
		CompactRaidFrameContainer:ApplyToFrames("mini", refresh)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", refresh)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", refresh)
	end
end

function M:RefreshRaidAggro()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", hideAggroHighlight)
		CompactRaidFrameContainer:ApplyToFrames("mini", hideAggroHighlight)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", hideAggroHighlight)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", hideAggroHighlight)
	end
end

M.ApplyHealthColors = applyHealthColors
M.HideAggroHighlight = hideAggroHighlight
