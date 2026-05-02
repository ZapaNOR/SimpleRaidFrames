local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local canMutateRaidFrames = M.CanMutateRaidFrames
local isFrameInRaidContainer = M.IsFrameInRaidContainer
local getFrameUnit = M.GetFrameUnit
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
		end
		if frame.SetAlpha then pcall(frame.SetAlpha, frame, 0) end
		if allowHard then
			if frame.SetScale then pcall(frame.SetScale, frame, HIDDEN_SCALE) end
			if frame.EnableMouse then pcall(frame.EnableMouse, frame, false) end
		end
	else
		if not frame._srfPartySelfHidden then return end
		if not allowHard then return end
		frame._srfPartySelfHidden = nil
		if frame.SetAlpha then pcall(frame.SetAlpha, frame, 1) end
		if frame.SetScale then pcall(frame.SetScale, frame, 1) end
		if frame.EnableMouse then pcall(frame.EnableMouse, frame, true) end
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
	local unit = getFrameUnit(frame)
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
