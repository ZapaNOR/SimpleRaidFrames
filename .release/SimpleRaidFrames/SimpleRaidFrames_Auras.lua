local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local CONST = M.CONST
local DEFAULT_FONT_SIZE = CONST.DEFAULT_FONT_SIZE
local resolveFont = M.ResolveFont
local buildFontKey = M.BuildFontKey
local applyFontToFontString = M.ApplyFontToFontString
local canMutateRaidFrames = M.CanMutateRaidFrames
local isFrameInRaidContainer = M.IsFrameInRaidContainer

local function applyAuraCooldownSettings(cooldown)
	if not cooldown or not M.DB then return end
	if cooldown.SetHideCountdownNumbers then
		local hide = not M.DB.auraCooldownText
		if cooldown._srfHideCountdown ~= hide then
			cooldown:SetHideCountdownNumbers(hide)
			cooldown._srfHideCountdown = hide
		end
	end
	if not M.DB.auraCooldownText then
		return
	end

	local fontPath = resolveFont(M.DB.auraCooldownFont)
	local size = tonumber(M.DB.auraCooldownFontSize) or DEFAULT_FONT_SIZE
	if size < 6 then size = 6 end
	if size > 32 then size = 32 end
	local outline = M.DB.auraCooldownFontOutline or ""
	if outline == "NONE" then outline = "" end
	local shadow = M.DB.auraCooldownShadow
	local fontKey = buildFontKey(fontPath, size, outline, shadow)

	local fontName = "SimpleRaidFrames_AuraCooldownFont"
	if not M._auraCooldownFont then
		M._auraCooldownFont = _G[fontName] or CreateFont(fontName)
	end
	if M._auraCooldownFont and M._auraCooldownFont.SetFont and M._auraCooldownFontKey ~= fontKey then
		M._auraCooldownFont:SetFont(fontPath, size, outline)
		if shadow then
			M._auraCooldownFont:SetShadowColor(0, 0, 0, 1)
			M._auraCooldownFont:SetShadowOffset(1, -1)
		else
			M._auraCooldownFont:SetShadowColor(0, 0, 0, 0)
			M._auraCooldownFont:SetShadowOffset(0, 0)
		end
		M._auraCooldownFontKey = fontKey
	end

	if cooldown.SetCountdownFont then
		if not cooldown._srfCountdownFontSet then
			cooldown:SetCountdownFont(fontName)
			cooldown._srfCountdownFontSet = true
		end
	else
		local fs = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
		if fs and fs.SetFont then
			applyFontToFontString(fs, fontPath, size, outline, shadow)
		end
	end

	local fs = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if fs and fs.SetPoint then
		local anchorTarget = cooldown
		local parent = cooldown.GetParent and cooldown:GetParent() or nil
		if parent and parent.icon then
			anchorTarget = parent.icon
		end
		if cooldown._srfCountdownAnchorTarget ~= anchorTarget then
			fs:ClearAllPoints()
			fs:SetPoint("CENTER", anchorTarget, "CENTER", 0, 0)
			cooldown._srfCountdownAnchorTarget = anchorTarget
		end
	end

	if cooldown.SetMinimumCountdownDuration and not cooldown._srfMinDurationSet then
		cooldown:SetMinimumCountdownDuration(0)
		cooldown._srfMinDurationSet = true
	end
end

local AURA_LAYOUTS = {
	[Enum.RaidAuraOrganizationType.Legacy] = {
		Buffs = {
			direction = GridLayoutMixin.Direction.BottomRightToTopLeft,
			stride = 3,
			anchorPoint = "BOTTOMRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Debuffs = {
			direction = GridLayoutMixin.Direction.BottomLeftToTopRight,
			stride = 3,
			useChainLayout = true,
			anchorPoint = "BOTTOMLEFT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return 3 + dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Dispel = {
			direction = GridLayoutMixin.Direction.RightToLeft,
			stride = 3,
			anchorPoint = "TOPRIGHT",
			getOffsets = function()
				return -3, -2
			end,
		},
	},
	[Enum.RaidAuraOrganizationType.BuffsTopDebuffsBottom] = {
		Buffs = {
			direction = GridLayoutMixin.Direction.TopRightToBottomLeft,
			stride = 6,
			anchorPoint = "TOPRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, -3 - dispelOffset
			end,
		},
		Debuffs = {
			direction = GridLayoutMixin.Direction.BottomRightToTopLeft,
			stride = 3,
			useChainLayout = true,
			anchorPoint = "BOTTOMRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Dispel = {
			direction = GridLayoutMixin.Direction.BottomLeftToTopRight,
			stride = 3,
			anchorPoint = "BOTTOMLEFT",
			getOffsets = function(frame)
				return 3, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight
			end,
		},
	},
	[Enum.RaidAuraOrganizationType.BuffsRightDebuffsLeft] = {
		Buffs = {
			direction = GridLayoutMixin.Direction.BottomRightToTopLeft,
			stride = 3,
			anchorPoint = "BOTTOMRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Debuffs = {
			direction = GridLayoutMixin.Direction.BottomLeftToTopRight,
			stride = 3,
			useChainLayout = true,
			anchorPoint = "BOTTOMLEFT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return 3 + dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Dispel = {
			direction = GridLayoutMixin.Direction.LeftToRight,
			stride = 3,
			anchorPoint = "TOPLEFT",
			getOffsets = function()
				return 3, -2
			end,
		},
	},
}

local function applyAuraGapLayout(frame)
	if not frame or not M.DB or not AnchorUtil or not GridLayoutMixin then return end
	if not canMutateRaidFrames(frame) then
		M._pendingAuraLayoutRefresh = true
		return
	end
	local gap = tonumber(M.DB.auraGap) or 0
	local auraOrganizationType = Enum and Enum.RaidAuraOrganizationType and Enum.RaidAuraOrganizationType.Legacy
	if EditModeManagerFrame and EditModeManagerFrame.GetRaidFrameAuraOrganizationType then
		auraOrganizationType = EditModeManagerFrame:GetRaidFrameAuraOrganizationType(frame.groupType)
	end
	auraOrganizationType = auraOrganizationType or Enum.RaidAuraOrganizationType.Legacy

	local layoutSet = AURA_LAYOUTS[auraOrganizationType] or AURA_LAYOUTS[Enum.RaidAuraOrganizationType.Legacy]
	if not layoutSet then return end

	local function layoutContainer(container, layoutData)
		if not container or not layoutData then return end
		for _, containedFrame in pairs(container) do
			containedFrame:ClearAllPoints()
		end
		local anchor = AnchorUtil.CreateAnchor(layoutData.anchorPoint, frame, layoutData.anchorPoint, 0, 0)
		if layoutData.getOffsets then
			anchor:SetOffsets(layoutData.getOffsets(frame))
		end
		local layout = AnchorUtil.CreateGridLayout(layoutData.direction, layoutData.stride, gap, gap)
		if layoutData.useChainLayout then
			layout.horizontalSpacing = gap
			layout.verticalSpacing = gap
			AnchorUtil.ChainLayout(container, anchor, layout, true)
		else
			AnchorUtil.GridLayout(container, anchor, layout)
		end
	end

	layoutContainer(frame.buffFrames, layoutSet.Buffs)
	layoutContainer(frame.debuffFrames, layoutSet.Debuffs)
	layoutContainer(frame.dispelDebuffFrames, layoutSet.Dispel)
end

local function onBuffSet(buffFrame)
	if not buffFrame then return end
	local parent = buffFrame:GetParent()
	if not isFrameInRaidContainer(parent) then return end
	applyAuraCooldownSettings(buffFrame.cooldown)
end

local function onDebuffSet(frame, debuffFrame)
	if not isFrameInRaidContainer(frame) then return end
	applyAuraCooldownSettings(debuffFrame and debuffFrame.cooldown)
end

function M:RefreshRaidAuras()
	local function refreshAuraFrame(frame)
		if not frame or not frame.unit then return end

		if frame.buffFrames then
			for _, buffFrame in ipairs(frame.buffFrames) do
				applyAuraCooldownSettings(buffFrame.cooldown)
			end
		end

		if frame.debuffFrames then
			for _, debuffFrame in ipairs(frame.debuffFrames) do
				applyAuraCooldownSettings(debuffFrame.cooldown)
			end
		end

		applyAuraGapLayout(frame)
	end
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", refreshAuraFrame)
		CompactRaidFrameContainer:ApplyToFrames("mini", refreshAuraFrame)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", refreshAuraFrame)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", refreshAuraFrame)
	end
end

M.ApplyAuraCooldownSettings = applyAuraCooldownSettings
M.ApplyAuraGapLayout = applyAuraGapLayout
M.OnBuffSet = onBuffSet
M.OnDebuffSet = onDebuffSet
