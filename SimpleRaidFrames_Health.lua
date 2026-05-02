local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local isFrameInRaidContainer = M.IsFrameInRaidContainer
local getFrameUnit = M.GetFrameUnit
local setStatusBarColorCached = M.SetStatusBarColorCached
local setTextureColorCached = M.SetTextureColorCached
local isSecretValue = M.IsSecretValue or issecretvalue or function() return false end
local BORDER_DARKNESS = 0.85
local HEAL_ABSORB_FILL_SUBLEVEL = -8
local HEAL_ABSORB_EDGE_SUBLEVEL = -7

local function shouldUseClassColor(unit)
	if not unit then return false end
	local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
	if okPlayer and not isSecretValue(isPlayer) and isPlayer then return true end
	if type(UnitTreatAsPlayerForDisplay) == "function" then
		local okTreat, treat = pcall(UnitTreatAsPlayerForDisplay, unit)
		if okTreat and not isSecretValue(treat) and treat then return true end
	end
	return false
end

local function getUnitClassColor(unit)
	if not shouldUseClassColor(unit) then return nil end
	local okClass, _, class = pcall(UnitClass, unit)
	return okClass and not isSecretValue(class) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or nil
end

local function getDarkClassHealthColor(frame)
	local classColor = getUnitClassColor(getFrameUnit(frame))
	if classColor then
		local darkness = tonumber(M.DB and M.DB.healthColorClassColorDarkness) or 0.65
		if darkness < 0 then darkness = 0 elseif darkness > 1 then darkness = 1 end
		local multiplier = 1 - darkness
		return classColor.r * multiplier,
			classColor.g * multiplier,
			classColor.b * multiplier,
			1
	end
	return nil
end

local function getDefaultHealthBarColor(frame)
	if not frame then return nil end
	local unit = getFrameUnit(frame)
	if shouldUseClassColor(unit) then
		if type(CompactUnitFrame_GetOptionUseClassColors) == "function" then
			local okUse, useClass = pcall(CompactUnitFrame_GetOptionUseClassColors, frame)
			if okUse and not isSecretValue(useClass) and useClass then
				local classColor = getUnitClassColor(unit)
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

local function computeHealthBgColor(frame)
	if not M.DB then return nil end
	local unit = getFrameUnit(frame)

	if unit and M.DB.healthDeadBgColorEnabled and M.DB.healthDeadBgColor then
		local okDead, deadOrGhost = pcall(UnitIsDeadOrGhost, unit)
		if okDead and not isSecretValue(deadOrGhost) and deadOrGhost == true then
			return M.DB.healthDeadBgColor
		end
	end

	if not M.DB.healthBgColorEnabled or not M.DB.healthBgColor then return nil end

	if M.DB.healthBgClassColor and shouldUseClassColor(unit) then
		local classColor = getUnitClassColor(unit)
		if classColor then
			return { r = classColor.r, g = classColor.g, b = classColor.b, a = M.DB.healthBgColor.a or 1 }
		end
	end

	return M.DB.healthBgColor
end

local function ensureHealthBorder(frame)
	if not frame or frame._srfBorder or not frame.healthBar then return end
	local anchor = frame.healthBar
	local function makeLine()
		local t = frame:CreateTexture(nil, "OVERLAY")
		return t
	end
	local top = makeLine()
	top:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", -1, 0)
	top:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 1, 0)
	top:SetHeight(1)
	local bottom = makeLine()
	bottom:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -1, 0)
	bottom:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 1, 0)
	bottom:SetHeight(1)
	local left = makeLine()
	left:SetPoint("TOPRIGHT", anchor, "TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMLEFT", 0, 0)
	left:SetWidth(1)
	local right = makeLine()
	right:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT", 0, 0)
	right:SetWidth(1)
	frame._srfBorder = { top, bottom, left, right }
end

local function getBackgroundColor(frame, computedColor)
	if computedColor then
		return computedColor.r, computedColor.g, computedColor.b
	end
	local cachedColor = frame and frame._srfHealthBgColor
	if cachedColor then
		return cachedColor.r, cachedColor.g, cachedColor.b
	end
	return 0, 0, 0
end

local function setTextureVertexColorCached(tex, r, g, b, a)
	if not tex or not tex.SetVertexColor then return end
	if isSecretValue(r) or isSecretValue(g) or isSecretValue(b) or isSecretValue(a) then return end
	tex:SetVertexColor(r, g, b, a)
end

local function setTextureDrawLayer(tex, layer, sublevel)
	if not tex or not tex.SetDrawLayer then return end
	pcall(tex.SetDrawLayer, tex, layer, sublevel)
end

local function applyHealAbsorbDrawLayers(frame)
	if not frame or not isFrameInRaidContainer(frame) then return end
	setTextureDrawLayer(frame.myHealAbsorb, "ARTWORK", HEAL_ABSORB_FILL_SUBLEVEL)
	setTextureDrawLayer(frame.myHealAbsorbOverlay, "ARTWORK", HEAL_ABSORB_FILL_SUBLEVEL)
	setTextureDrawLayer(frame.myHealAbsorbLeftShadow, "ARTWORK", HEAL_ABSORB_EDGE_SUBLEVEL)
	setTextureDrawLayer(frame.myHealAbsorbRightShadow, "ARTWORK", HEAL_ABSORB_EDGE_SUBLEVEL)
	setTextureDrawLayer(frame.overHealAbsorbGlow, "ARTWORK", HEAL_ABSORB_EDGE_SUBLEVEL)
end

local function getHealthForegroundColor(frame)
	local healthBar = frame and frame.healthBar
	if not healthBar then return nil end
	local c = healthBar._srfBarColor
	if c then
		return c.r, c.g, c.b, c.a
	end
	return nil
end

local function applyHealAbsorbOverlayColor(frame, bgColor)
	if not M.DB or not isFrameInRaidContainer(frame) then return end
	if not frame.myHealAbsorb and not frame.myHealAbsorbOverlay then return end
	applyHealAbsorbDrawLayers(frame)

	local r, g, b
	if M.DB.healthColorEnabled and M.DB.healthColorClassColor then
		if bgColor then
			r, g, b = bgColor.r, bgColor.g, bgColor.b
		elseif frame._srfHealthBgColor then
			r, g, b = frame._srfHealthBgColor.r, frame._srfHealthBgColor.g, frame._srfHealthBgColor.b
		else
			local computedBgColor = computeHealthBgColor(frame)
			if computedBgColor then
				r, g, b = computedBgColor.r, computedBgColor.g, computedBgColor.b
			end
		end
	else
		r, g, b = getHealthForegroundColor(frame)
	end

	if isSecretValue(r) or isSecretValue(g) or isSecretValue(b) then return end
	if not r or not g or not b then return end
	setTextureVertexColorCached(frame.myHealAbsorb, r, g, b, 1)
	setTextureVertexColorCached(frame.myHealAbsorbOverlay, r, g, b, 1)
end

local function setHealthBorderColor(frame, bgColor)
	local border = frame and frame._srfBorder
	if not border then return end
	local r, g, b = getBackgroundColor(frame, bgColor)
	local multiplier = 1 - BORDER_DARKNESS
	r, g, b = r * multiplier, g * multiplier, b * multiplier
	for _, line in ipairs(border) do
		setTextureColorCached(line, r, g, b, 1)
	end
end

local function setHealthBorderShown(frame, shown, bgColor)
	if not frame then return end
	if shown then
		ensureHealthBorder(frame)
		setHealthBorderColor(frame, bgColor)
	end
	local border = frame._srfBorder
	if not border then return end
	for _, line in ipairs(border) do
		if shown then
			line:Show()
		else
			line:Hide()
		end
	end
end

local function setBackgroundAnchoredToHealthBar(frame, enabled)
	if not frame or not frame.background then return end
	if enabled then
		if frame.healthBar and not frame._srfBgReanchored then
			frame.background:ClearAllPoints()
			frame.background:SetAllPoints(frame.healthBar)
			frame._srfBgReanchored = true
		end
	elseif frame._srfBgReanchored then
		frame.background:ClearAllPoints()
		frame.background:SetAllPoints(frame)
		frame._srfBgReanchored = nil
	end
end

local function getRegionNumber(region, method)
	local fn = region and region[method]
	if type(fn) ~= "function" then return nil end
	local ok, value = pcall(fn, region)
	if ok and not isSecretValue(value) and type(value) == "number" then
		return value
	end
	return nil
end

local function isRegionShown(region)
	if not region or type(region.IsShown) ~= "function" then return false end
	local ok, shown = pcall(region.IsShown, region)
	return ok and not isSecretValue(shown) and shown == true
end

local function hidePredictionBar(bar)
	if bar and bar.Hide then
		bar:Hide()
	end
	if bar and bar.overlay and bar.overlay.Hide then
		bar.overlay:Hide()
	end
end

local function clampPredictionBar(bar, rightEdge)
	if not isRegionShown(bar) then return end
	local left = getRegionNumber(bar, "GetLeft")
	local right = getRegionNumber(bar, "GetRight")
	local width = getRegionNumber(bar, "GetWidth")
	if not left or not right or not width then return end

	if left >= rightEdge then
		hidePredictionBar(bar)
		return
	end

	if right > rightEdge then
		local newWidth = width - (right - rightEdge)
		if newWidth > 0 then
			bar:SetWidth(newWidth)
		else
			hidePredictionBar(bar)
		end
	end
end

local function applyHealPredictionClamp(frame)
	if not frame or not isFrameInRaidContainer(frame) or not frame.healthBar then return end
	local rightEdge = getRegionNumber(frame.healthBar, "GetRight")
	if not rightEdge then return end
	clampPredictionBar(frame.myHealPrediction, rightEdge)
	clampPredictionBar(frame.otherHealPrediction, rightEdge)
end

local function applyHealPredictionPostUpdate(frame)
	applyHealAbsorbOverlayColor(frame)
	applyHealPredictionClamp(frame)
end

local function applyHealthColors(frame)
	if not M.DB or not isFrameInRaidContainer(frame) then return end
	local showDarkBorders = M.DB.healthBlackBorders == true
	local bgColor = computeHealthBgColor(frame)
	setHealthBorderShown(frame, showDarkBorders, bgColor)
	local healthBar = frame.healthBar
	if healthBar then
		if M.DB.healthColorEnabled and M.DB.healthColor then
			if M.DB.healthColorClassColor then
				local r, g, b, a = getDarkClassHealthColor(frame)
				if r and g and b then
					setStatusBarColorCached(healthBar, r, g, b, a or 1)
				else
					local c = M.DB.healthColor
					setStatusBarColorCached(healthBar, c.r, c.g, c.b, c.a or 1)
				end
			else
				local c = M.DB.healthColor
				setStatusBarColorCached(healthBar, c.r, c.g, c.b, c.a or 1)
			end
		else
			local r, g, b, a = getDefaultHealthBarColor(frame)
			if r and g and b then
				setStatusBarColorCached(healthBar, r, g, b, a or 1)
			end
		end
	end
	if frame.background then
		setBackgroundAnchoredToHealthBar(frame, showDarkBorders)
		if bgColor then
			if not frame._srfBgVertexCaptured and frame.background.GetVertexColor then
				local okGet, r, g, b, a = pcall(frame.background.GetVertexColor, frame.background)
				if okGet and not isSecretValue(r) then
					frame._srfOriginalBgColor = { r = r or 1, g = g or 1, b = b or 1, a = a or 1 }
				else
					frame._srfOriginalBgColor = { r = 1, g = 1, b = 1, a = 1 }
				end
				frame._srfBgVertexCaptured = true
			end
			frame.background:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
		elseif frame._srfBgVertexCaptured then
			local oc = frame._srfOriginalBgColor
			frame.background:SetVertexColor(oc.r, oc.g, oc.b, oc.a or 1)
		end
	end
	frame._srfHealthBgColor = bgColor
	applyHealAbsorbOverlayColor(frame, bgColor)
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
M.ApplyHealPredictionPostUpdate = applyHealPredictionPostUpdate
M.HideAggroHighlight = hideAggroHighlight
