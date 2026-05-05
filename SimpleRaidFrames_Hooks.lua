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
	if self.UpdateFrameAuraBars then
		self.UpdateFrameAuraBars(frame)
	end
end

local function refreshAllSettings(owner, includePartyHeader)
	owner:RefreshRaidNames()
	owner:RefreshRaidRoleIcons()
	owner:RefreshRaidAuras()
	owner:RefreshRaidStatusText()
	owner:RefreshRaidHealthColors()
	owner:RefreshRaidAggro()
	if owner.RefreshAuraBars then
		owner:RefreshAuraBars()
	end
	if owner.RefreshPartyPlayerVisibility then
		owner:RefreshPartyPlayerVisibility()
	end
	if owner.RefreshPartySoloVisibility then
		owner:RefreshPartySoloVisibility()
	end
	if owner.RefreshRaidFrameTooltips then
		owner:RefreshRaidFrameTooltips()
	end
	if owner.RefreshPreviewFrame then
		owner:RefreshPreviewFrame()
	end
	if includePartyHeader and owner.HidePartyHeader then
		owner:HidePartyHeader()
	end
end

function M:ApplySettings()
	refreshAllSettings(self)
end

function M:EnsureHooks()
	if M.EnsureUIDropDownMenuTaintGuard then
		M.EnsureUIDropDownMenuTaintGuard()
	end
	if M.EnsureRaidTooltipHooks then
		M:EnsureRaidTooltipHooks()
	end
	if M.EnsureAuraBarHooks then
		M.EnsureAuraBarHooks()
	end
	if M.EnsureNameRefresh then
		M.EnsureNameRefresh()
	end
	if M.EnsureStatusIndicatorRefresh then
		M.EnsureStatusIndicatorRefresh()
	end
	if type(CompactUnitFrame_UpdateName) ~= "function" then return end
	if not M._nameHooked then
		hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
			if M and M.ApplyNameSettings then
				M.ApplyNameSettings(frame)
			end
			if M and M.UpdateLeaderAssistIndicator then
				M.UpdateLeaderAssistIndicator(frame)
			end
		end)
		M._nameHooked = true
	end
	if type(CompactUnitFrame_UpdateInRange) == "function" and not M._partyVisibilityInRangeHooked then
		hooksecurefunc("CompactUnitFrame_UpdateInRange", function(frame)
			if M and M.HidePartyPlayerFrameIfNeeded then
				M:HidePartyPlayerFrameIfNeeded(frame)
			end
		end)
		M._partyVisibilityInRangeHooked = true
	end
	if type(CompactUnitFrame_UpdateStatusText) == "function" and not M._statusTextHooked then
		hooksecurefunc("CompactUnitFrame_UpdateStatusText", M.UpdateOfflineIndicator)
		M._statusTextHooked = true
	end
	if type(CompactUnitFrame_UpdateAuras) == "function" and not M._updateAurasHooked then
		hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
			if M.DB and M.DB.auraBarsEnabled and M.UpdateFrameAuraBars then
				M.UpdateFrameAuraBars(frame)
			end
		end)
		M._updateAurasHooked = true
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
	if type(CompactUnitFrame_UpdateHealPrediction) == "function" and not M._healAbsorbColorHooked then
		hooksecurefunc("CompactUnitFrame_UpdateHealPrediction", M.ApplyHealPredictionPostUpdate)
		M._healAbsorbColorHooked = true
	end
	if type(CompactUnitFrameReadyCheckMixin) == "table"
		and type(CompactUnitFrameReadyCheckMixin.SetStatus) == "function"
		and not M._readyCheckIconHooked then
		hooksecurefunc(CompactUnitFrameReadyCheckMixin, "SetStatus", function(readyCheckIcon, status)
			if M and M.ApplyReadyCheckIconStyle then
				M.ApplyReadyCheckIconStyle(readyCheckIcon, status)
			end
		end)
		M._readyCheckIconHooked = true
	end
	if type(CompactPartyFrameMixin) == "table"
		and type(CompactPartyFrameMixin.RefreshMembers) == "function"
		and not M._partyVisibilityHooked then
		hooksecurefunc(CompactPartyFrameMixin, "RefreshMembers", function(frame)
			if M and M.RefreshPartyPlayerVisibility then
				M:RefreshPartyPlayerVisibility(frame)
			end
		end)
		M._partyVisibilityHooked = true
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
	refreshAllSettings(M, true)
end
