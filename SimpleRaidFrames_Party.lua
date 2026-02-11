local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local canMutateRaidFrames = M.CanMutateRaidFrames
local isFrameInRaidContainer = M.IsFrameInRaidContainer
local HIDDEN_SCALE = 0.001

local function isEditModeActive()
	if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive then
		return EditModeManagerFrame:IsEditModeActive()
	end
	return false
end

local function shouldHidePlayerInParty()
	if not M.DB or not M.DB.hidePlayerInParty then return false end
	if isEditModeActive() then return false end
	if not IsInGroup() or IsInRaid() then return false end
	local members = GetNumGroupMembers and GetNumGroupMembers() or 0
	if members <= 1 then return false end
	return true
end

local function shouldShowPartyWhenSolo()
	if not M.DB or not M.DB.showPartyWhenSolo then return false end
	if IsInRaid and IsInRaid() then return false end
	if IsInGroup and IsInGroup() then return false end
	if ShouldShowArenaParty and ShouldShowArenaParty() then return false end
	return true
end

local function setPartyPlayerHidden(frame, hidden, allowHard)
	if not frame then return end
	if hidden then
		if not frame._srfPartySelfHidden then
			frame._srfPartySelfHidden = true
			if frame.GetAlpha then
				frame._srfPartySelfAlpha = frame:GetAlpha()
			end
			if frame.GetScale then
				frame._srfPartySelfScale = frame:GetScale()
			end
			if frame.IsMouseEnabled then
				frame._srfPartySelfMouse = frame:IsMouseEnabled()
			end
		end
		if frame.SetAlpha then frame:SetAlpha(0) end
		if allowHard then
			if frame.SetScale then frame:SetScale(HIDDEN_SCALE) end
			if frame.EnableMouse then frame:EnableMouse(false) end
		end
	else
		if not frame._srfPartySelfHidden then return end
		if not allowHard then return end
		frame._srfPartySelfHidden = nil
		if frame.SetAlpha then frame:SetAlpha(frame._srfPartySelfAlpha or 1) end
		if frame.SetScale then frame:SetScale(frame._srfPartySelfScale or 1) end
		if frame.EnableMouse and frame._srfPartySelfMouse ~= nil then
			frame:EnableMouse(frame._srfPartySelfMouse)
		end
		frame._srfPartySelfAlpha = nil
		frame._srfPartySelfScale = nil
		frame._srfPartySelfMouse = nil
	end
end

function M:ApplyPartyPlayerVisibility(frame)
	local partyFrame = frame or CompactPartyFrame
	if not partyFrame then return end
	if partyFrame.groupType and CompactRaidGroupTypeEnum
		and partyFrame.groupType ~= CompactRaidGroupTypeEnum.Party then
		return
	end
	if partyFrame.memberUnitFrames then
		for _, memberUnitFrame in ipairs(partyFrame.memberUnitFrames) do
			self:HidePartyPlayerFrameIfNeeded(memberUnitFrame)
		end
	end
end

local function applyPartySoloDriver(frame, enabled)
	if not frame or not RegisterStateDriver or not UnregisterStateDriver then return end
	if enabled then
		local driver = "[group:raid] hide; [group] show; [nogroup] show"
		RegisterStateDriver(frame, "visibility", driver)
		frame._srfPartySoloDriver = true
	else
		if frame._srfPartySoloDriver then
			UnregisterStateDriver(frame, "visibility")
			frame._srfPartySoloDriver = nil
		end
	end
end

function M:RefreshPartySoloVisibility()
	if not M.DB then return end
	if not canMutateRaidFrames() then
		M._pendingPartySoloVisibilityRefresh = true
		return
	end

	local useRaidStyle = EditModeManagerFrame
		and EditModeManagerFrame.UseRaidStylePartyFrames
		and EditModeManagerFrame:UseRaidStylePartyFrames()

	local compact = CompactPartyFrame
	if useRaidStyle and not compact and type(CompactPartyFrame_Generate) == "function" then
		compact = select(1, CompactPartyFrame_Generate())
	end

	local soloEnabled = shouldShowPartyWhenSolo()

	if useRaidStyle then
		applyPartySoloDriver(compact, soloEnabled)
		applyPartySoloDriver(PartyFrame, false)
	else
		applyPartySoloDriver(PartyFrame, soloEnabled)
		applyPartySoloDriver(compact, false)
	end

	if not soloEnabled then
		if compact and compact.UpdateVisibility then
			compact:UpdateVisibility()
		end
		if PartyFrame and PartyFrame.UpdateVisibility then
			PartyFrame:UpdateVisibility()
		end
	end
end

function M:HidePartyPlayerFrameIfNeeded(frame)
	if not frame then return end
	if isFrameInRaidContainer and not isFrameInRaidContainer(frame) then return end
	local unit = frame.unit or frame.displayedUnit
	local shouldHide = false
	if not isEditModeActive() then
		shouldHide = shouldHidePlayerInParty()
	end
	local wantsHidden = unit == "player" and shouldHide
	if unit ~= "player" and frame._srfPartySelfHidden then
		wantsHidden = false
	end
	local isHidden = frame._srfPartySelfHidden and true or false
	if not canMutateRaidFrames(frame) then
		if wantsHidden then
			setPartyPlayerHidden(frame, true, false)
		end
		if wantsHidden ~= isHidden or wantsHidden then
			M._pendingPartyVisibilityRefresh = true
		end
		return
	end
	setPartyPlayerHidden(frame, wantsHidden, true)
end

function M:RefreshPartyPlayerVisibility(frame)
	if not M.DB then return end
	local partyFrame = frame or CompactPartyFrame
	if partyFrame and partyFrame.memberUnitFrames then
		for _, memberUnitFrame in ipairs(partyFrame.memberUnitFrames) do
			self:HidePartyPlayerFrameIfNeeded(memberUnitFrame)
		end
	end
end

function M:HidePartyHeader(frame)
	local partyFrame = frame or CompactPartyFrame
	if not partyFrame then return end
	local title = partyFrame.title or partyFrame.Title
	if title and title.Hide then
		title:Hide()
	end
end
