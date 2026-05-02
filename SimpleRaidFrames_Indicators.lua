local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local DEFAULTS = M.DEFAULTS
local CONST = M.CONST
local ICONS = CONST.ICONS
local isFrameInRaidContainer = M.IsFrameInRaidContainer
local safeGetValue = M.SafeGetValue
local getFrameUnit = M.GetFrameUnit
local isSecretValue = M.IsSecretValue or issecretvalue or function() return false end

local function isTrue(value)
	return not isSecretValue(value) and value == true
end

local function getClassColor(unit)
	if not unit then return nil end
	local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
	if not okPlayer or isSecretValue(isPlayer) or not isPlayer then return nil end
	local okClass, _, class = pcall(UnitClass, unit)
	if not okClass or isSecretValue(class) or not class then return nil end
	return RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or nil
end

local function tintIndicator(tex, unit, settingKey)
	if not tex or not tex.SetVertexColor then return end
	if M.DB and M.DB[settingKey] then
		local color = getClassColor(unit)
		if color then
			tex:SetVertexColor(color.r, color.g, color.b, 1)
			return
		end
	end
	tex:SetVertexColor(1, 1, 1, 1)
end

local function getIndicatorAnchorInfo(anchor)
	if anchor == "RIGHT" then
		return "LEFT", "RIGHT", 2, 0, "X", 1
	elseif anchor == "BOTTOM" then
		return "TOP", "BOTTOM", 0, -2, "X", -1
	elseif anchor == "LEFT" then
		return "RIGHT", "LEFT", -2, 0, "X", -1
	elseif anchor == "CENTER" then
		return "CENTER", "CENTER", 0, 0, "X", -1
	end
	-- default TOP
	return "BOTTOM", "TOP", 0, 2, "X", -1
end

local function placeIndicatorIcon(frame, tex, anchor, index, iconSize, spacing, extraX, extraY)
	if not tex or not frame then return end
	local point, relPoint, baseX, baseY, axis, dir = getIndicatorAnchorInfo(anchor)
	local offsetX = baseX + (extraX or 0)
	local offsetY = baseY + (extraY or 0)
	if axis == "X" and index and index > 1 then
		offsetX = offsetX + dir * (iconSize + spacing) * (index - 1)
	elseif axis == "Y" and index and index > 1 then
		offsetY = offsetY + dir * (iconSize + spacing) * (index - 1)
	end
	tex:ClearAllPoints()
	if frame.name then
		tex:SetPoint(point, frame.name, relPoint, offsetX, offsetY)
	else
		tex:SetPoint("CENTER", frame, "CENTER", offsetX, offsetY)
	end
end

local function updateLeaderAssistIndicator(frame)
	local unit = getFrameUnit(frame)
	if not frame or not unit or not M.DB then return end
	if not isFrameInRaidContainer(frame) then return end

	local inGroup = (IsInGroup and IsInGroup()) or false
	local okLeader, isLeader = pcall(UnitIsGroupLeader, unit)
	local okAssist, isAssist = pcall(UnitIsGroupAssistant, unit)
	local showLeader = inGroup and okLeader and isTrue(isLeader) and M.DB.leaderAssistEnabled
	local showAssist = inGroup and okAssist and isTrue(isAssist) and M.DB.leaderAssistEnabled

	local leaderIcon = frame._srfLeaderIcon
	if not leaderIcon then
		leaderIcon = frame:CreateTexture(nil, "OVERLAY", nil, 6)
		leaderIcon:SetTexture(ICONS.leader)
		leaderIcon:SetTexCoord(0, 1, 0, 1)
		if leaderIcon.SetDesaturated then
			leaderIcon:SetDesaturated(false)
		end
		leaderIcon:SetVertexColor(1, 1, 1, 1)
		frame._srfLeaderIcon = leaderIcon
	end
	local assistIcon = frame._srfAssistIcon
	if not assistIcon then
		assistIcon = frame:CreateTexture(nil, "OVERLAY", nil, 6)
		assistIcon:SetTexture(ICONS.assist)
		assistIcon:SetTexCoord(0, 1, 0, 1)
		if assistIcon.SetDesaturated then
			assistIcon:SetDesaturated(false)
		end
		assistIcon:SetVertexColor(1, 1, 1, 1)
		frame._srfAssistIcon = assistIcon
	end

	leaderIcon:Hide()
	assistIcon:Hide()

	if not showLeader and not showAssist then
		return
	end

	local _, size
	local nameRegion = safeGetValue(frame, "name")
	if nameRegion and nameRegion.GetFont then
		_, size = nameRegion:GetFont()
	end
	local iconSize = tonumber(size) or 12
	if iconSize < 8 then iconSize = 8 end
	if iconSize > 20 then iconSize = 20 end

	local anchor = M.DB.leaderAssistAnchor or DEFAULTS.leaderAssistAnchor
	local offsetX = tonumber(M.DB.leaderAssistOffsetX) or 0
	local offsetY = tonumber(M.DB.leaderAssistOffsetY) or 0
	local spacing = 2

	if showLeader then
		leaderIcon:SetSize(iconSize, iconSize)
		tintIndicator(leaderIcon, unit, "leaderAssistClassColor")
		placeIndicatorIcon(frame, leaderIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		leaderIcon:Show()
	elseif showAssist then
		assistIcon:SetSize(iconSize, iconSize)
		tintIndicator(assistIcon, unit, "leaderAssistClassColor")
		placeIndicatorIcon(frame, assistIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		assistIcon:Show()
	end
end

local function updateOfflineIndicator(frame)
	local statusText = safeGetValue(frame, "statusText")
	local unit = getFrameUnit(frame)
	if not frame or not statusText or not unit or not M.DB then return end
	if not isFrameInRaidContainer(frame) then return end
	if not M.DB.statusIndicatorsEnabled then
		if frame._srfOfflineIcon then frame._srfOfflineIcon:Hide() end
		if frame._srfAfkIcon then frame._srfAfkIcon:Hide() end
		if frame._srfDndIcon then frame._srfDndIcon:Hide() end
		if frame._srfDeadIcon then frame._srfDeadIcon:Hide() end
		if frame._srfGhostIcon then frame._srfGhostIcon:Hide() end
		return
	end

	local isOffline = false
	local ok, connected = pcall(UnitIsConnected, unit)
	if ok and not isSecretValue(connected) and connected == false then
		isOffline = true
	end
	local isAfk = false
	local isDnd = false
	local chatLockedDown = false
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
		local okChat, locked = pcall(C_ChatInfo.InChatMessagingLockdown)
		if okChat and isTrue(locked) then
			chatLockedDown = true
		end
	end
	if not chatLockedDown then
		local okAfk, afk = pcall(UnitIsAFK, unit)
		if okAfk and isTrue(afk) then
			isAfk = true
		end
		local okDnd, dnd = pcall(UnitIsDND, unit)
		if okDnd and isTrue(dnd) then
			isDnd = true
		end
	end
	local isGhost = false
	local okGhost, ghost = pcall(UnitIsGhost, unit)
	if okGhost and isTrue(ghost) then
		isGhost = true
	end
	local isDead = false
	local okDead, deadOrGhost = pcall(UnitIsDeadOrGhost, unit)
	if okDead and isTrue(deadOrGhost) and not isGhost then
		isDead = true
	end

	local icon = frame._srfOfflineIcon
	if not icon then
		icon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		icon:SetTexture(ICONS.offline)
		icon:SetTexCoord(0, 1, 0, 1)
		frame._srfOfflineIcon = icon
	end
	local afkIcon = frame._srfAfkIcon
	if not afkIcon then
		afkIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		afkIcon:SetTexture(ICONS.afk)
		afkIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfAfkIcon = afkIcon
	end
	local dndIcon = frame._srfDndIcon
	if not dndIcon then
		dndIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		dndIcon:SetTexture(ICONS.dnd)
		dndIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfDndIcon = dndIcon
	end
	local deadIcon = frame._srfDeadIcon
	if not deadIcon then
		deadIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		deadIcon:SetTexture(ICONS.dead)
		deadIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfDeadIcon = deadIcon
	end
	local ghostIcon = frame._srfGhostIcon
	if not ghostIcon then
		ghostIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		ghostIcon:SetTexture(ICONS.ghost)
		ghostIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfGhostIcon = ghostIcon
	end

	local _, size
	local nameRegion = safeGetValue(frame, "name")
	if nameRegion and nameRegion.GetFont then
		_, size = nameRegion:GetFont()
	end
	if not size and statusText.GetFont then
		_, size = statusText:GetFont()
	end
	local iconSize = tonumber(size) or 12
	if iconSize < 8 then iconSize = 8 end
	if iconSize > 20 then iconSize = 20 end
	local spacing = 2
	local anchor = M.DB.statusIndicatorAnchor or DEFAULTS.statusIndicatorAnchor
	local offsetX = tonumber(M.DB.statusIndicatorOffsetX) or 0
	local offsetY = tonumber(M.DB.statusIndicatorOffsetY) or 0

	icon:Hide()
	afkIcon:Hide()
	dndIcon:Hide()
	deadIcon:Hide()
	ghostIcon:Hide()

	if isOffline then
		if statusText.Hide then statusText:Hide() end
		icon:SetSize(iconSize, iconSize)
		tintIndicator(icon, unit, "statusIndicatorClassColor")
		placeIndicatorIcon(frame, icon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		icon:Show()
		return
	end

	if isDead or isGhost then
		if statusText.Hide then statusText:Hide() end
	end

	if isAfk then
		afkIcon:SetSize(iconSize, iconSize)
		tintIndicator(afkIcon, unit, "statusIndicatorClassColor")
		placeIndicatorIcon(frame, afkIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		afkIcon:Show()
	end

	if isDead or isGhost then
		local tex = isGhost and ghostIcon or deadIcon
		tex:SetSize(iconSize, iconSize)
		tintIndicator(tex, unit, "statusIndicatorClassColor")
		local index = isAfk and 2 or 1
		placeIndicatorIcon(frame, tex, anchor, index, iconSize, spacing, offsetX, offsetY)
		tex:Show()
	end

	if not isAfk and not isDead and not isGhost and isDnd then
		dndIcon:SetSize(iconSize, iconSize)
		tintIndicator(dndIcon, unit, "statusIndicatorClassColor")
		placeIndicatorIcon(frame, dndIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		dndIcon:Show()
	end
end

function M:RefreshRaidStatusText()
	local function refresh(frame)
		if not frame then return end
		updateOfflineIndicator(frame)
		updateLeaderAssistIndicator(frame)
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

local statusRefreshPending
local statusRefreshFrame

local function scheduleStatusRefresh()
	if statusRefreshPending then return end
	statusRefreshPending = true
	local function refresh()
		statusRefreshPending = false
		if M and M.RefreshRaidStatusText then
			M:RefreshRaidStatusText()
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, refresh)
	else
		refresh()
	end
end

local function ensureStatusIndicatorRefresh()
	if statusRefreshFrame then return end
	statusRefreshFrame = CreateFrame("Frame")
	statusRefreshFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	statusRefreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	statusRefreshFrame:RegisterEvent("PARTY_LEADER_CHANGED")
	statusRefreshFrame:SetScript("OnEvent", scheduleStatusRefresh)
end

M.UpdateOfflineIndicator = updateOfflineIndicator
M.EnsureStatusIndicatorRefresh = ensureStatusIndicatorRefresh
