local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local isFrameInRaidContainer = M.IsFrameInRaidContainer
local canMutateRaidFrames = M.CanMutateRaidFrames

local function applyPrivateAuraAnchorBottomLeft(frame)
	if not frame or not frame.PrivateAuraAnchors or not M.DB then return end
	if not isFrameInRaidContainer(frame) then return end
	if not M.DB.privateAurasEnabled then return end

	local anchors = frame.PrivateAuraAnchors
	local target = frame.healthBar or frame
	local anchor1 = frame.PrivateAuraAnchor1 or anchors[1]
	if anchor1 then
		anchor1:ClearAllPoints()
		anchor1:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", 3, 3)
	end
end

local function applyPrivateAuraSettings(frame)
	if not frame or not frame.PrivateAuraAnchors or not M.DB then return end
	if not isFrameInRaidContainer(frame) then return end
	if not canMutateRaidFrames() then
		M._pendingPrivateAuraRefresh = true
		return
	end

	local anchors = frame.PrivateAuraAnchors

	if not M.DB.privateAurasEnabled then
		for _, anchor in ipairs(anchors) do
			if anchor.Hide then
				anchor:Hide()
			end
		end
		return
	end

	applyPrivateAuraAnchorBottomLeft(frame)

	for _, anchor in ipairs(anchors) do
		if anchor.Show then
			anchor:Show()
		end
	end
end

function M:RefreshPrivateAuras()
	if not canMutateRaidFrames() then
		M._pendingPrivateAuraRefresh = true
		return
	end
	local function refresh(frame)
		if not frame then return end
		applyPrivateAuraSettings(frame)
	end
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", refresh)
		CompactRaidFrameContainer:ApplyToFrames("mini", refresh)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", refresh)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", refresh)
	end
	M._pendingPrivateAuraRefresh = false
end

M.ApplyPrivateAuraAnchorBottomLeft = applyPrivateAuraAnchorBottomLeft
M.ApplyPrivateAuraSettings = applyPrivateAuraSettings
