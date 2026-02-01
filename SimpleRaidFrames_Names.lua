local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local CONST = M.CONST
local DEFAULT_FONT_SIZE = CONST.DEFAULT_FONT_SIZE
local isFrameInRaidContainer = M.IsFrameInRaidContainer
local resolveFont = M.ResolveFont
local applyFontToFontString = M.ApplyFontToFontString
local setTextColorCached = M.SetTextColorCached
local truncateUtf8 = M.TruncateUtf8
local safeGsub = M.SafeGsub

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

local function applyNameColor(frame)
	if not M.DB or not M.DB.nameClassColor then return end
	if not frame or not frame.unit or not UnitIsPlayer(frame.unit) then return end
	local _, class = UnitClass(frame.unit)
	local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if classColor and frame.name and frame.name.SetTextColor then
		setTextColorCached(frame.name, classColor.r, classColor.g, classColor.b, 1)
	end
end

local function applyNameSettings(frame)
	if not M.DB then return end
	if not frame or not frame.name or not frame.unit then return end
	if not isFrameInRaidContainer(frame) then return end

	local unit = frame.displayedUnit or frame.unit
	if not unit then return end
	if frame.frameType == "target" or unit:find("target", 1, true) then
		return
	end

	local maxLen = tonumber(M.DB.maxNameLength) or 0
	if M.DB.hideRealmNames or maxLen > 0 then
		local okName, name = pcall(frame.name.GetText, frame.name)
		if okName and name then
			local ok, processed = pcall(function()
				local n = name
				if M.DB.hideRealmNames then
					n = safeGsub(n, "%s*%(%*%)$", "") or n
					n = safeGsub(n, "^(.-)%-.+$", "%1") or n
				end
				if maxLen > 0 then
					n = truncateUtf8(n, maxLen)
				end
				return n
			end)
			if ok and processed and frame.name.SetText then
				if processed ~= name then
					frame.name:SetText(processed)
				end
			end
		end
	end

	applyNameFont(frame.name)
	applyNameColor(frame)
	if M.UpdateLeaderAssistIndicator then
		M.UpdateLeaderAssistIndicator(frame)
	end
	if M.HidePartyPlayerFrameIfNeeded then
		M:HidePartyPlayerFrameIfNeeded(frame)
	end
end

function M:RefreshRaidNames()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", applyNameSettings)
		CompactRaidFrameContainer:ApplyToFrames("mini", applyNameSettings)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", applyNameSettings)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", applyNameSettings)
	end
end

M.ApplyNameFont = applyNameFont
M.ApplyNameColor = applyNameColor
M.ApplyNameSettings = applyNameSettings
