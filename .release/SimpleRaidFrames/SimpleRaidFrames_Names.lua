local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local CONST = M.CONST
local DEFAULT_FONT_SIZE = CONST.DEFAULT_FONT_SIZE
local safeGetValue = M.SafeGetValue
local getFrameUnit = M.GetFrameUnit
local isFrameInRaidContainer = M.IsFrameInRaidContainer
local resolveFont = M.ResolveFont
local applyFontToFontString = M.ApplyFontToFontString
local truncateUtf8 = M.TruncateUtf8
local isSecretValue = M.IsSecretValue or issecretvalue or function() return false end

local updateName
local nameRegionHooks = setmetatable({}, { __mode = "k" })

local function usableString(value)
	if isSecretValue(value) then return false end
	return type(value) == "string" and value ~= ""
end

local function getLiveFrameUnit(frame)
	if not frame then return nil end

	local unit = frame.displayedUnit or frame.unit
	if unit then
		return unit
	end

	unit = getFrameUnit(frame)
	if unit then
		return unit
	end

	if frame.GetAttribute then
		local ok, attrUnit = pcall(frame.GetAttribute, frame, "unit")
		if ok and attrUnit then
			return attrUnit
		end
	end

	return nil
end

local function getNameRegion(frame)
	if not frame then return nil end
	return frame.name or frame.Name or safeGetValue(frame, "name") or safeGetValue(frame, "Name")
end

local function ensureNameRegionHooks(frame, nameRegion)
	if not frame or not nameRegion or nameRegionHooks[nameRegion] then return end
	if type(hooksecurefunc) ~= "function" then return end

	local function refresh()
		if nameRegion._srfNameTextUpdating or nameRegion._srfNameColorUpdating then
			return
		end
		if updateName then
			updateName(frame)
		end
	end

	local hooked
	if type(nameRegion.SetText) == "function" then
		local ok = pcall(hooksecurefunc, nameRegion, "SetText", refresh)
		hooked = hooked or ok
	end
	if type(nameRegion.SetFormattedText) == "function" then
		local ok = pcall(hooksecurefunc, nameRegion, "SetFormattedText", refresh)
		hooked = hooked or ok
	end
	if type(nameRegion.SetVertexColor) == "function" then
		local ok = pcall(hooksecurefunc, nameRegion, "SetVertexColor", refresh)
		hooked = hooked or ok
	end
	if type(nameRegion.SetTextColor) == "function" then
		local ok = pcall(hooksecurefunc, nameRegion, "SetTextColor", refresh)
		hooked = hooked or ok
	end

	if hooked then
		nameRegionHooks[nameRegion] = true
	end
end

local function applyNameFont(fontString)
	if not fontString or not fontString.SetFont or not M.DB then return end
	local font = resolveFont(M.DB.nameFont)
	local size = tonumber(M.DB.nameFontSize) or DEFAULT_FONT_SIZE
	if size < 6 then size = 6 end
	if size > 32 then size = 32 end
	local outline = M.DB.nameFontOutline or ""
	if outline == "NONE" then outline = "" end
	applyFontToFontString(fontString, font, size, outline, M.DB.nameShadow)
end

local function applyNameColor(nameRegion, unit)
	if not M.DB or not M.DB.nameClassColor then return end
	if not nameRegion or not unit then return end
	local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
	local isPlayerOrTreat = okPlayer and not isSecretValue(isPlayer) and isPlayer
	if not isPlayerOrTreat and type(UnitTreatAsPlayerForDisplay) == "function" then
		local okTreat, treat = pcall(UnitTreatAsPlayerForDisplay, unit)
		isPlayerOrTreat = okTreat and not isSecretValue(treat) and treat
	end
	if not isPlayerOrTreat then return end
	local okClass, _, class = pcall(UnitClass, unit)
	if not okClass or isSecretValue(class) then return end
	local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if not classColor then return end
	nameRegion._srfNameColorUpdating = true
	if nameRegion.SetVertexColor then
		pcall(nameRegion.SetVertexColor, nameRegion, classColor.r, classColor.g, classColor.b, 1)
	end
	if nameRegion.SetTextColor then
		pcall(nameRegion.SetTextColor, nameRegion, classColor.r, classColor.g, classColor.b, 1)
	end
	nameRegion._srfNameColorUpdating = nil
end

local function isActiveCompactUnitFrame(frame)
	local unitExists = safeGetValue(frame, "unitExists")
	if unitExists == false then return false end

	local inUse = safeGetValue(frame, "inUse")
	if inUse == false then return false end

	return true
end

local function isRaidFrameByName(frame)
	if not frame or not frame.GetName then return false end
	local ok, name = pcall(frame.GetName, frame)
	if not ok or type(name) ~= "string" then return false end
	return name:find("^CompactRaidGroup%d+Member%d+$")
		or name:find("^CompactPartyFrameMember%d+$")
		or name:find("^CompactRaidFrame%d+$")
end

local function isNameFrame(frame, unit)
	if not frame then return false end

	local frameType = safeGetValue(frame, "frameType")
	if frameType == "target" then
		return false
	end

	if type(unit) == "string" and not isSecretValue(unit) then
		local isTarget = false
		local okTarget, targetMatch = pcall(string.find, unit, "target", 1, true)
		if okTarget and targetMatch then
			isTarget = true
		end
		if isTarget then
			return false
		end

		if unit == "player" then
			return true
		end
		local okRaid, raidMatch = pcall(string.find, unit, "^raid")
		local okParty, partyMatch = pcall(string.find, unit, "^party")
		if (okRaid and raidMatch) or (okParty and partyMatch) then
			return true
		end
	end

	if isFrameInRaidContainer and isFrameInRaidContainer(frame) then
		return true
	end

	return isRaidFrameByName(frame)
end

local function getNameText(unit)
	if not unit then return nil end
	local name = UnitName(unit)

	if usableString(name) then
		if Ambiguate then
			name = Ambiguate(name, "short") or name
		end
		name = name:match("^([^%-]+)") or name
	end

	local maxLen = tonumber(M.DB.maxNameLength) or 0
	if maxLen > 0 and usableString(name) then
		name = truncateUtf8(name, maxLen)
	end

	return name
end

local function setNameText(nameRegion, name)
	if not nameRegion then return end
	nameRegion._srfNameTextUpdating = true
	if nameRegion.SetText then
		nameRegion:SetText(name)
	end
	nameRegion._srfNameTextUpdating = nil
end

updateName = function(frame)
	if not M.DB then return end
	if not isActiveCompactUnitFrame(frame) then return end
	local nameRegion = getNameRegion(frame)
	local unit = getLiveFrameUnit(frame)
	if not frame or not nameRegion then return end
	if not isNameFrame(frame, unit) then return end
	ensureNameRegionHooks(frame, nameRegion)

	if unit then
		local name = getNameText(unit)
		setNameText(nameRegion, name)
	end

	applyNameFont(nameRegion)
	if unit then
		applyNameColor(nameRegion, unit)
	end
	return true
end

local function applyNameSettings(frame)
	updateName(frame)
end

function M:RefreshRaidNames()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", applyNameSettings)
		CompactRaidFrameContainer:ApplyToFrames("mini", applyNameSettings)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", applyNameSettings)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", applyNameSettings)
	end
end

local nameRefreshPending
local nameRefreshFrame

local function namesNeedRefresh()
	return M.DB ~= nil
end

local function scheduleNameRefresh()
	if nameRefreshPending then return end
	nameRefreshPending = true
	local function refresh()
		nameRefreshPending = false
		if namesNeedRefresh() and M.RefreshRaidNames then
			M:RefreshRaidNames()
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, refresh)
	else
		refresh()
	end
end

local function ensureNameRefresh()
	if nameRefreshFrame then return end
	nameRefreshFrame = CreateFrame("Frame")
	nameRefreshFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	nameRefreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	nameRefreshFrame:RegisterEvent("UNIT_NAME_UPDATE")
	nameRefreshFrame:SetScript("OnEvent", scheduleNameRefresh)
end

M.ApplyNameSettings = applyNameSettings
M.EnsureNameRefresh = ensureNameRefresh
