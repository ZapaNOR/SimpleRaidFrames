local ADDON_NAME = ...
local M = _G[ADDON_NAME]

function M:RefreshPreviewFrame()
	local frame = _G and _G.RaidFrameSettingsPreviewFrame
	if not frame then return end

	if not frame.unit and type(CompactUnitFrame_SetUnit) == "function" then
		pcall(CompactUnitFrame_SetUnit, frame, "player")
	end

	if self.ApplyNameSettings then
		self.ApplyNameSettings(frame)
	end
	if self.ApplyRoleIconStyle then
		self.ApplyRoleIconStyle(frame)
	end
	if self.ApplyHealthColors then
		self.ApplyHealthColors(frame)
	end
	if self.UpdateOfflineIndicator then
		self.UpdateOfflineIndicator(frame)
	end
	if self.HideAggroHighlight then
		self.HideAggroHighlight(frame)
	end
	if self.ApplyPrivateAuraSettings then
		self.ApplyPrivateAuraSettings(frame)
	elseif self.ApplyPrivateAuraAnchorBottomLeft then
		self.ApplyPrivateAuraAnchorBottomLeft(frame)
	end
	if self.ApplyAuraCooldownSettings then
		if frame.buffFrames then
			for _, buffFrame in ipairs(frame.buffFrames) do
				self.ApplyAuraCooldownSettings(buffFrame.cooldown)
			end
		end
		if frame.debuffFrames then
			for _, debuffFrame in ipairs(frame.debuffFrames) do
				self.ApplyAuraCooldownSettings(debuffFrame.cooldown)
			end
		end
	end
	if self.ApplyAuraGapLayout then
		self.ApplyAuraGapLayout(frame)
	end
end

function M:ApplySettings()
	self:RefreshRaidNames()
	self:RefreshRaidRoleIcons()
	self:RefreshRaidAuras()
	self:RefreshPrivateAuras()
	self:RefreshRaidStatusText()
	self:RefreshRaidHealthColors()
	self:RefreshRaidAggro()
	if self.RefreshPartyPlayerVisibility then
		self:RefreshPartyPlayerVisibility()
	end
	if self.RefreshPartyFrameWidth then
		self:RefreshPartyFrameWidth()
	end
	if self.RefreshPartySoloVisibility then
		self:RefreshPartySoloVisibility()
	end
	if self.RefreshPreviewFrame then
		self:RefreshPreviewFrame()
	end
end

function M:EnsureHooks()
	if type(CompactUnitFrame_UpdateName) ~= "function" then return end
	if not M._nameHooked then
		hooksecurefunc("CompactUnitFrame_UpdateName", M.ApplyNameSettings)
		M._nameHooked = true
	end
	if type(CompactUnitFrame_UpdateInRange) == "function" and not M._partyRangeHooked then
		hooksecurefunc("CompactUnitFrame_UpdateInRange", function(frame)
			if M and M.HidePartyPlayerFrameIfNeeded then
				M:HidePartyPlayerFrameIfNeeded(frame)
			end
		end)
		M._partyRangeHooked = true
	end
	if type(CompactUnitFrame_UpdateStatusText) == "function" and not M._statusTextHooked then
		hooksecurefunc("CompactUnitFrame_UpdateStatusText", M.UpdateOfflineIndicator)
		M._statusTextHooked = true
	end
	if type(CompactUnitFrame_UtilSetBuff) == "function" and not M._buffHooked then
		hooksecurefunc("CompactUnitFrame_UtilSetBuff", M.OnBuffSet)
		M._buffHooked = true
	end
	if type(CompactUnitFrame_UtilSetDebuff) == "function" and not M._debuffHooked then
		hooksecurefunc("CompactUnitFrame_UtilSetDebuff", M.OnDebuffSet)
		M._debuffHooked = true
	end
	if type(CompactUnitFrame_UpdateAuraFrameLayout) == "function" and not M._layoutHooked then
		hooksecurefunc("CompactUnitFrame_UpdateAuraFrameLayout", function(frame)
			if M and M.DB then
				M.ApplyAuraGapLayout(frame)
			end
		end)
		M._layoutHooked = true
	end
	if type(CompactUnitFrame_UpdatePrivateAuras) == "function" and not M._privateAuraHooked then
		hooksecurefunc("CompactUnitFrame_UpdatePrivateAuras", M.ApplyPrivateAuraAnchorBottomLeft)
		M._privateAuraHooked = true
	end
	if type(CompactUnitFrame_UpdateAggroHighlight) == "function" and not M._aggroHooked then
		hooksecurefunc("CompactUnitFrame_UpdateAggroHighlight", M.HideAggroHighlight)
		M._aggroHooked = true
	end
	if type(CompactUnitFrame_UpdateRoleIcon) == "function" and not M._roleIconHooked then
		hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", M.ApplyRoleIconStyle)
		M._roleIconHooked = true
	end
	if type(CompactUnitFrame_UpdateHealthColor) == "function" and not M._healthColorHooked then
		hooksecurefunc("CompactUnitFrame_UpdateHealthColor", M.ApplyHealthColors)
		M._healthColorHooked = true
	end
	if type(CompactUnitFrame_UpdateCenterStatusIcon) == "function" and not M._centerStatusNameHooked then
		hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", M.ApplyNameSettings)
		M._centerStatusNameHooked = true
	end
	if type(CompactPartyFrameMixin) == "table"
		and type(CompactPartyFrameMixin.RefreshMembers) == "function"
		and not M._partyVisibilityHooked then
		hooksecurefunc(CompactPartyFrameMixin, "RefreshMembers", function(frame)
			if M and M.RefreshPartyPlayerVisibility then
				M:RefreshPartyPlayerVisibility(frame)
			end
			if M and M.RefreshPartyFrameWidth then
				M:RefreshPartyFrameWidth(frame)
			end
		end)
		M._partyVisibilityHooked = true
	end
	if type(DefaultCompactUnitFrameSetup) == "function" and not M._partyWidthHooked then
		hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
			if M and M.HidePartyPlayerFrameIfNeeded then
				M:HidePartyPlayerFrameIfNeeded(frame)
			end
			if M and M.ApplyPartyFrameWidth then
				M:ApplyPartyFrameWidth(frame)
			end
		end)
		if type(DefaultCompactMiniFrameSetup) == "function" then
			hooksecurefunc("DefaultCompactMiniFrameSetup", function(frame)
				if M and M.HidePartyPlayerFrameIfNeeded then
					M:HidePartyPlayerFrameIfNeeded(frame)
				end
				if M and M.ApplyPartyFrameWidth then
					M:ApplyPartyFrameWidth(frame)
				end
			end)
		end
		M._partyWidthHooked = true
	end
	if type(CompactPartyFrame_Generate) == "function" and not M._partyHeaderHooked then
		hooksecurefunc("CompactPartyFrame_Generate", function(frame)
			if M and M.HidePartyHeader then
				M:HidePartyHeader(frame)
			end
		end)
		M._partyHeaderHooked = true
	end
	if type(RaidFramePreviewMixin) == "table"
		and type(RaidFramePreviewMixin.OnLoad) == "function"
		and not M._previewHooked then
		hooksecurefunc(RaidFramePreviewMixin, "OnLoad", function()
			if M and M.RefreshPreviewFrame then
				M:RefreshPreviewFrame()
			end
		end)
		M._previewHooked = true
	end
	M:RefreshRaidNames()
	M:RefreshRaidRoleIcons()
	M:RefreshRaidAuras()
	M:RefreshPrivateAuras()
	M:RefreshRaidStatusText()
	M:RefreshRaidHealthColors()
	M:RefreshRaidAggro()
	if M.RefreshPartyPlayerVisibility then
		M:RefreshPartyPlayerVisibility()
	end
	if M.RefreshPartyFrameWidth then
		M:RefreshPartyFrameWidth()
	end
	if M.RefreshPartySoloVisibility then
		M:RefreshPartySoloVisibility()
	end
	if M.RefreshPreviewFrame then
		M:RefreshPreviewFrame()
	end
	if M.HidePartyHeader then
		M:HidePartyHeader()
	end
end
