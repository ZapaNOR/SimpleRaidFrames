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

local function setPartyPlayerHidden(frame, hidden)
	if not frame then return end
	if hidden then
		if frame._srfPartySelfHidden then return end
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
		if frame.SetAlpha then frame:SetAlpha(0) end
		if frame.SetScale then frame:SetScale(HIDDEN_SCALE) end
		if frame.EnableMouse then frame:EnableMouse(false) end
	else
		if not frame._srfPartySelfHidden then return end
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
	if not shouldHidePlayerInParty() then return end
	if not canMutateRaidFrames() then
		M._pendingPartyVisibilityRefresh = true
		return
	end
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

function M:HidePartyPlayerFrameIfNeeded(frame)
	if not frame then return end
	if isFrameInRaidContainer and not isFrameInRaidContainer(frame) then return end
	local unit = frame.unit or frame.displayedUnit
	if isEditModeActive() then
		setPartyPlayerHidden(frame, false)
		return
	end
	local shouldHide = shouldHidePlayerInParty()
	if not canMutateRaidFrames() then
		if shouldHide and unit == "player" then
			M._pendingPartyVisibilityRefresh = true
		end
		return
	end
	if unit == "player" then
		setPartyPlayerHidden(frame, shouldHide)
	elseif frame._srfPartySelfHidden then
		setPartyPlayerHidden(frame, false)
	end
end

function M:RefreshPartyPlayerVisibility(frame)
	if not M.DB then return end
	if not canMutateRaidFrames() then
		M._pendingPartyVisibilityRefresh = true
		return
	end
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
