local ADDON_NAME = ...
local M = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = M

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT_NAME = (LSM and LSM.GetDefault and LSM:GetDefault("font")) or "Friz Quadrata TT"
local DEFAULT_FONT_PATH = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local DEFAULT_FONT_SIZE = 11

local ICONS = {
	offline = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\connection.png",
	leader = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
	assist = "Interface\\GroupFrame\\UI-Group-AssistantIcon",
	afk = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\afk.png",
	dnd = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\dnd.png",
	dead = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\dead.png",
	ghost = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\ghost.png",
}

local OUTLINE_OPTIONS = {
	{ label = "None", value = "" },
	{ label = "Outline", value = "OUTLINE" },
	{ label = "Thick Outline", value = "THICKOUTLINE" },
	{ label = "Mono Outline", value = "MONOCHROME,OUTLINE" },
	{ label = "Mono Thick", value = "MONOCHROME,THICKOUTLINE" },
}

local INDICATOR_ANCHORS = {
	{ label = "Top", value = "TOP" },
	{ label = "Right", value = "RIGHT" },
	{ label = "Bottom", value = "BOTTOM" },
	{ label = "Left", value = "LEFT" },
	{ label = "Center", value = "CENTER" },
}

do
	local _, size = GameFontNormalSmall and GameFontNormalSmall:GetFont()
	if size then
		DEFAULT_FONT_SIZE = size
	end
end

local DEFAULTS = {
	hideRealmNames = true,
	hidePlayerInParty = false,
	showPartyWhenSolo = false,
	partyFrameWidthOverride = 0,
	maxNameLength = 4,
	nameFont = "Expressway",
	nameFontSize = 14,
	nameFontOutline = "OUTLINE",
	nameShadow = true,
	nameClassColor = true,
	roleIconStyle = "pixels",
	roleIconSize = 16,
	roleIconOffsetX = 1,
	roleIconOffsetY = -1,
	healthColorEnabled = true,
	healthColor = { r = 0.0745098039, g = 0.0745098039, b = 0.0745098039, a = 1.0 },
	healthBgColorEnabled = true,
	healthBgClassColor = true,
	healthBgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.6 },
	healthDeadBgColorEnabled = true,
	healthDeadBgColor = { r = 0.2509803922, g = 0.0431372549, b = 0.0, a = 1.0 },
	auraCooldownText = true,
	auraCooldownFont = "Expressway",
	auraCooldownFontSize = 12,
	auraCooldownFontOutline = "OUTLINE",
	auraCooldownShadow = true,
	auraGap = 1,
	privateAurasEnabled = true,
	leaderAssistEnabled = true,
	leaderAssistAnchor = "TOP",
	leaderAssistOffsetX = 0,
	leaderAssistOffsetY = -6,
	statusIndicatorsEnabled = true,
	statusIndicatorAnchor = "LEFT",
	statusIndicatorOffsetX = 0,
	statusIndicatorOffsetY = 0,
}

M.AceGUI = AceGUI
M.LSM = LSM
M.DEFAULTS = DEFAULTS
M.CONST = {
	DEFAULT_FONT_NAME = DEFAULT_FONT_NAME,
	DEFAULT_FONT_PATH = DEFAULT_FONT_PATH,
	DEFAULT_FONT_SIZE = DEFAULT_FONT_SIZE,
	OUTLINE_OPTIONS = OUTLINE_OPTIONS,
	INDICATOR_ANCHORS = INDICATOR_ANCHORS,
	ICONS = ICONS,
}

M._settingsCategoryName = "SimpleRaidFrames"
M.DB = nil
M._settingsFrame = nil
M._settingsPanel = nil
M._hooked = false
M._pendingPrivateAuraRefresh = false
M._pendingAuraLayoutRefresh = false
M._pendingRoleIconRefresh = false
M._pendingPartyVisibilityRefresh = false
M._pendingPartyFrameSizeRefresh = false
M._pendingPartySoloVisibilityRefresh = false

local function ensureDefaults()
	SimpleRaidFramesDB = SimpleRaidFramesDB or {}
	if SimpleRaidFramesDB.hideRealmNames == nil then
		SimpleRaidFramesDB.hideRealmNames = DEFAULTS.hideRealmNames
	end
	if SimpleRaidFramesDB.hidePlayerInParty == nil then
		SimpleRaidFramesDB.hidePlayerInParty = DEFAULTS.hidePlayerInParty
	end
	if SimpleRaidFramesDB.showPartyWhenSolo == nil then
		SimpleRaidFramesDB.showPartyWhenSolo = DEFAULTS.showPartyWhenSolo
	end
	if SimpleRaidFramesDB.partyFrameWidthOverride == nil then
		SimpleRaidFramesDB.partyFrameWidthOverride = DEFAULTS.partyFrameWidthOverride
	end
	SimpleRaidFramesDB.partyFrameWidthOverride = tonumber(SimpleRaidFramesDB.partyFrameWidthOverride)
		or DEFAULTS.partyFrameWidthOverride
	if SimpleRaidFramesDB.partyFrameWidthOriginal ~= nil then
		SimpleRaidFramesDB.partyFrameWidthOriginal = tonumber(SimpleRaidFramesDB.partyFrameWidthOriginal)
	end
	if SimpleRaidFramesDB.maxNameLength == nil then
		SimpleRaidFramesDB.maxNameLength = DEFAULTS.maxNameLength
	end
	if SimpleRaidFramesDB.nameFont == nil then
		SimpleRaidFramesDB.nameFont = DEFAULTS.nameFont
	end
	if SimpleRaidFramesDB.nameFontSize == nil then
		SimpleRaidFramesDB.nameFontSize = DEFAULTS.nameFontSize
	end
	if SimpleRaidFramesDB.nameFontOutline == nil then
		SimpleRaidFramesDB.nameFontOutline = DEFAULTS.nameFontOutline
	end
	if SimpleRaidFramesDB.nameShadow == nil then
		SimpleRaidFramesDB.nameShadow = DEFAULTS.nameShadow
	end
	if SimpleRaidFramesDB.nameClassColor == nil then
		SimpleRaidFramesDB.nameClassColor = DEFAULTS.nameClassColor
	end
	if SimpleRaidFramesDB.roleIconStyle == nil then
		SimpleRaidFramesDB.roleIconStyle = DEFAULTS.roleIconStyle
	end
	SimpleRaidFramesDB.roleIconStyle = "pixels"
	if SimpleRaidFramesDB.roleIconSize == nil then
		SimpleRaidFramesDB.roleIconSize = DEFAULTS.roleIconSize
	end
	if SimpleRaidFramesDB.roleIconOffsetX == nil then
		SimpleRaidFramesDB.roleIconOffsetX = DEFAULTS.roleIconOffsetX
	end
	if SimpleRaidFramesDB.roleIconOffsetY == nil then
		SimpleRaidFramesDB.roleIconOffsetY = DEFAULTS.roleIconOffsetY
	end
	SimpleRaidFramesDB.roleIconSize = tonumber(SimpleRaidFramesDB.roleIconSize) or DEFAULTS.roleIconSize
	SimpleRaidFramesDB.roleIconOffsetX = tonumber(SimpleRaidFramesDB.roleIconOffsetX) or DEFAULTS.roleIconOffsetX
	SimpleRaidFramesDB.roleIconOffsetY = tonumber(SimpleRaidFramesDB.roleIconOffsetY) or DEFAULTS.roleIconOffsetY
	if SimpleRaidFramesDB.healthColorEnabled == nil then
		SimpleRaidFramesDB.healthColorEnabled = DEFAULTS.healthColorEnabled
	end
	if SimpleRaidFramesDB.healthBgColorEnabled == nil then
		SimpleRaidFramesDB.healthBgColorEnabled = DEFAULTS.healthBgColorEnabled
	end
	if SimpleRaidFramesDB.healthBgClassColor == nil then
		SimpleRaidFramesDB.healthBgClassColor = DEFAULTS.healthBgClassColor
	end
	if SimpleRaidFramesDB.healthDeadBgColorEnabled == nil then
		SimpleRaidFramesDB.healthDeadBgColorEnabled = DEFAULTS.healthDeadBgColorEnabled
	end
	if type(SimpleRaidFramesDB.healthColor) ~= "table" then
		SimpleRaidFramesDB.healthColor = {
			r = DEFAULTS.healthColor.r,
			g = DEFAULTS.healthColor.g,
			b = DEFAULTS.healthColor.b,
			a = DEFAULTS.healthColor.a,
		}
	end
	if type(SimpleRaidFramesDB.healthBgColor) ~= "table" then
		SimpleRaidFramesDB.healthBgColor = {
			r = DEFAULTS.healthBgColor.r,
			g = DEFAULTS.healthBgColor.g,
			b = DEFAULTS.healthBgColor.b,
			a = DEFAULTS.healthBgColor.a,
		}
	end
	if type(SimpleRaidFramesDB.healthDeadBgColor) ~= "table" then
		SimpleRaidFramesDB.healthDeadBgColor = {
			r = DEFAULTS.healthDeadBgColor.r,
			g = DEFAULTS.healthDeadBgColor.g,
			b = DEFAULTS.healthDeadBgColor.b,
			a = DEFAULTS.healthDeadBgColor.a,
		}
	end
	SimpleRaidFramesDB.healthColor.r = tonumber(SimpleRaidFramesDB.healthColor.r) or DEFAULTS.healthColor.r
	SimpleRaidFramesDB.healthColor.g = tonumber(SimpleRaidFramesDB.healthColor.g) or DEFAULTS.healthColor.g
	SimpleRaidFramesDB.healthColor.b = tonumber(SimpleRaidFramesDB.healthColor.b) or DEFAULTS.healthColor.b
	SimpleRaidFramesDB.healthColor.a = tonumber(SimpleRaidFramesDB.healthColor.a)
		or (DEFAULTS.healthColor.a or 1)
	SimpleRaidFramesDB.healthBgColor.r = tonumber(SimpleRaidFramesDB.healthBgColor.r) or DEFAULTS.healthBgColor.r
	SimpleRaidFramesDB.healthBgColor.g = tonumber(SimpleRaidFramesDB.healthBgColor.g) or DEFAULTS.healthBgColor.g
	SimpleRaidFramesDB.healthBgColor.b = tonumber(SimpleRaidFramesDB.healthBgColor.b) or DEFAULTS.healthBgColor.b
	SimpleRaidFramesDB.healthBgColor.a = tonumber(SimpleRaidFramesDB.healthBgColor.a)
		or (DEFAULTS.healthBgColor.a or 1)
	SimpleRaidFramesDB.healthDeadBgColor.r = tonumber(SimpleRaidFramesDB.healthDeadBgColor.r)
		or DEFAULTS.healthDeadBgColor.r
	SimpleRaidFramesDB.healthDeadBgColor.g = tonumber(SimpleRaidFramesDB.healthDeadBgColor.g)
		or DEFAULTS.healthDeadBgColor.g
	SimpleRaidFramesDB.healthDeadBgColor.b = tonumber(SimpleRaidFramesDB.healthDeadBgColor.b)
		or DEFAULTS.healthDeadBgColor.b
	SimpleRaidFramesDB.healthDeadBgColor.a = tonumber(SimpleRaidFramesDB.healthDeadBgColor.a)
		or (DEFAULTS.healthDeadBgColor.a or 1)
	if SimpleRaidFramesDB.auraCooldownText == nil then
		SimpleRaidFramesDB.auraCooldownText = DEFAULTS.auraCooldownText
	end
	if SimpleRaidFramesDB.auraCooldownFont == nil then
		SimpleRaidFramesDB.auraCooldownFont = DEFAULTS.auraCooldownFont
	end
	if SimpleRaidFramesDB.auraCooldownFontSize == nil then
		SimpleRaidFramesDB.auraCooldownFontSize = DEFAULTS.auraCooldownFontSize
	end
	if SimpleRaidFramesDB.auraCooldownFontOutline == nil then
		SimpleRaidFramesDB.auraCooldownFontOutline = DEFAULTS.auraCooldownFontOutline
	end
	if SimpleRaidFramesDB.auraCooldownShadow == nil then
		SimpleRaidFramesDB.auraCooldownShadow = DEFAULTS.auraCooldownShadow
	end
	if SimpleRaidFramesDB.auraGap == nil then
		SimpleRaidFramesDB.auraGap = DEFAULTS.auraGap
	end
	if SimpleRaidFramesDB.privateAurasEnabled == nil then
		SimpleRaidFramesDB.privateAurasEnabled = DEFAULTS.privateAurasEnabled
	end
	if SimpleRaidFramesDB.leaderAssistEnabled == nil then
		if SimpleRaidFramesDB.leaderIndicatorEnabled ~= nil or SimpleRaidFramesDB.assistIndicatorEnabled ~= nil then
			SimpleRaidFramesDB.leaderAssistEnabled = (SimpleRaidFramesDB.leaderIndicatorEnabled == true)
				or (SimpleRaidFramesDB.assistIndicatorEnabled == true)
		else
			SimpleRaidFramesDB.leaderAssistEnabled = DEFAULTS.leaderAssistEnabled
		end
	end
	if SimpleRaidFramesDB.leaderAssistAnchor == nil then
		SimpleRaidFramesDB.leaderAssistAnchor = DEFAULTS.leaderAssistAnchor
	end
	if SimpleRaidFramesDB.leaderAssistOffsetX == nil then
		SimpleRaidFramesDB.leaderAssistOffsetX = DEFAULTS.leaderAssistOffsetX
	end
	if SimpleRaidFramesDB.leaderAssistOffsetY == nil then
		SimpleRaidFramesDB.leaderAssistOffsetY = DEFAULTS.leaderAssistOffsetY
	end
	if SimpleRaidFramesDB.statusIndicatorsEnabled == nil then
		SimpleRaidFramesDB.statusIndicatorsEnabled = DEFAULTS.statusIndicatorsEnabled
	end
	if SimpleRaidFramesDB.statusIndicatorAnchor == nil then
		SimpleRaidFramesDB.statusIndicatorAnchor = DEFAULTS.statusIndicatorAnchor
	end
	if SimpleRaidFramesDB.statusIndicatorOffsetX == nil then
		SimpleRaidFramesDB.statusIndicatorOffsetX = DEFAULTS.statusIndicatorOffsetX
	end
	if SimpleRaidFramesDB.statusIndicatorOffsetY == nil then
		SimpleRaidFramesDB.statusIndicatorOffsetY = DEFAULTS.statusIndicatorOffsetY
	end
	if SimpleRaidFramesDB.leaderAssistAnchor ~= "TOP"
		and SimpleRaidFramesDB.leaderAssistAnchor ~= "RIGHT"
		and SimpleRaidFramesDB.leaderAssistAnchor ~= "BOTTOM"
		and SimpleRaidFramesDB.leaderAssistAnchor ~= "LEFT"
		and SimpleRaidFramesDB.leaderAssistAnchor ~= "CENTER" then
		SimpleRaidFramesDB.leaderAssistAnchor = DEFAULTS.leaderAssistAnchor
	end
	SimpleRaidFramesDB.leaderAssistOffsetX = tonumber(SimpleRaidFramesDB.leaderAssistOffsetX)
		or DEFAULTS.leaderAssistOffsetX
	SimpleRaidFramesDB.leaderAssistOffsetY = tonumber(SimpleRaidFramesDB.leaderAssistOffsetY)
		or DEFAULTS.leaderAssistOffsetY
	if SimpleRaidFramesDB.statusIndicatorAnchor ~= "TOP"
		and SimpleRaidFramesDB.statusIndicatorAnchor ~= "RIGHT"
		and SimpleRaidFramesDB.statusIndicatorAnchor ~= "BOTTOM"
		and SimpleRaidFramesDB.statusIndicatorAnchor ~= "LEFT"
		and SimpleRaidFramesDB.statusIndicatorAnchor ~= "CENTER" then
		SimpleRaidFramesDB.statusIndicatorAnchor = DEFAULTS.statusIndicatorAnchor
	end
	SimpleRaidFramesDB.statusIndicatorOffsetX = tonumber(SimpleRaidFramesDB.statusIndicatorOffsetX)
		or DEFAULTS.statusIndicatorOffsetX
	SimpleRaidFramesDB.statusIndicatorOffsetY = tonumber(SimpleRaidFramesDB.statusIndicatorOffsetY)
		or DEFAULTS.statusIndicatorOffsetY
	if LSM and LSM.HashTable then
		local fonts = LSM:HashTable("font")
		if fonts then
			if SimpleRaidFramesDB.nameFont and not fonts[SimpleRaidFramesDB.nameFont] then
				for key, path in pairs(fonts) do
					if path == SimpleRaidFramesDB.nameFont then
						SimpleRaidFramesDB.nameFont = key
						break
					end
				end
			end
			if SimpleRaidFramesDB.auraCooldownFont and not fonts[SimpleRaidFramesDB.auraCooldownFont] then
				for key, path in pairs(fonts) do
					if path == SimpleRaidFramesDB.auraCooldownFont then
						SimpleRaidFramesDB.auraCooldownFont = key
						break
					end
				end
			end
		end
	end
	M.DB = SimpleRaidFramesDB
end

local function isFrameInPreview(frame)
	if not frame then return false end
	local previewFrame = _G and _G.RaidFrameSettingsPreviewFrame
	if not previewFrame then return false end
	local parent = frame
	while parent do
		if parent == previewFrame then
			return true
		end
		if not parent.GetParent then
			break
		end
		local ok, nextParent = pcall(parent.GetParent, parent)
		if not ok then
			break
		end
		parent = nextParent
	end
	return false
end

local function isFrameInRaidContainer(frame)
	if not frame then return false end
	local unit = frame.displayedUnit or frame.unit
	if type(unit) == "string" then
		if unit ~= "player" and not unit:find("^raid") and not unit:find("^party") then
			return false
		end
	end
	if isFrameInPreview(frame) then
		return true
	end
	local parent = frame
	while parent do
		if parent == CompactRaidFrameContainer or parent == CompactPartyFrame then
			return true
		end
		if not parent.GetParent then
			return false
		end
		local ok, nextParent = pcall(parent.GetParent, parent)
		if not ok then
			return false
		end
		parent = nextParent
	end
	return false
end

local function isInCombatLockdown()
	return InCombatLockdown and InCombatLockdown()
end

local function canMutateRaidFrames(frame, allowCombat)
	if not allowCombat and isInCombatLockdown() then
		return false
	end
	if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive then
		if EditModeManagerFrame:IsEditModeActive() then
			if frame and isFrameInPreview(frame) then
				return true
			end
			return false
		end
	end
	return true
end

local function truncateUtf8(text, maxLen)
	if not text or maxLen <= 0 then return text end
	local bytes = #text
	local len = 0
	local i = 1
	while i <= bytes do
		len = len + 1
		if len > maxLen then
			return text:sub(1, i - 1)
		end
		local c = text:byte(i)
		if c < 0x80 then
			i = i + 1
		elseif c < 0xE0 then
			i = i + 2
		elseif c < 0xF0 then
			i = i + 3
		else
			i = i + 4
		end
	end
	return text
end

local function safeGsub(text, pattern, replacement)
	if text == nil then return nil end
	local ok, result = pcall(string.gsub, text, pattern, replacement)
	if ok then
		return result
	end
	return nil
end

local function resolveFont(fontValue)
	if LSM and LSM.Fetch then
		local fetched = LSM:Fetch("font", fontValue, true)
		if fetched then
			return fetched
		end
	end
	if type(fontValue) == "string" then
		if fontValue:find("\\") or fontValue:lower():find("%.ttf") then
			return fontValue
		end
	end
	return DEFAULT_FONT_PATH
end

local FONT_KEY_SEPARATOR = "\31"

local function buildFontKey(fontPath, size, outline, shadow)
	return tostring(fontPath or "") .. FONT_KEY_SEPARATOR .. tostring(size or "")
		.. FONT_KEY_SEPARATOR .. tostring(outline or "")
		.. FONT_KEY_SEPARATOR .. (shadow and "1" or "0")
end

local function applyFontToFontString(fontString, fontPath, size, outline, shadow)
	if not fontString or not fontString.SetFont then return end
	local key = buildFontKey(fontPath, size, outline, shadow)
	if fontString._srfFontKey == key then
		return
	end
	local ok = fontString:SetFont(fontPath, size, outline)
	if not ok and fontPath ~= DEFAULT_FONT_PATH then
		fontPath = DEFAULT_FONT_PATH
		key = buildFontKey(fontPath, size, outline, shadow)
		fontString:SetFont(fontPath, size, outline)
	end
	if shadow then
		fontString:SetShadowColor(0, 0, 0, 1)
		fontString:SetShadowOffset(1, -1)
	else
		fontString:SetShadowColor(0, 0, 0, 0)
		fontString:SetShadowOffset(0, 0)
	end
	fontString._srfFontKey = key
end

local function setTextColorCached(fontString, r, g, b, a)
	if not fontString or not fontString.SetTextColor then return end
	fontString:SetTextColor(r, g, b, a)
end

local function setStatusBarColorCached(statusBar, r, g, b, a)
	if not statusBar or not statusBar.SetStatusBarColor then return end
	statusBar:SetStatusBarColor(r, g, b, a)
	local c = statusBar._srfBarColor
	if not c then
		c = {}
		statusBar._srfBarColor = c
	end
	c.r, c.g, c.b, c.a = r, g, b, a
end

local function setTextureColorCached(tex, r, g, b, a)
	if not tex or not tex.SetColorTexture then return end
	local c = tex._srfTexColor
	if c and c.r == r and c.g == g and c.b == b and c.a == a then
		return
	end
	tex:SetColorTexture(r, g, b, a)
	if not c then
		c = {}
		tex._srfTexColor = c
	end
	c.r, c.g, c.b, c.a = r, g, b, a
end

M.EnsureDefaults = ensureDefaults
M.IsFrameInRaidContainer = isFrameInRaidContainer
M.CanMutateRaidFrames = canMutateRaidFrames
M.TruncateUtf8 = truncateUtf8
M.SafeGsub = safeGsub
M.ResolveFont = resolveFont
M.BuildFontKey = buildFontKey
M.ApplyFontToFontString = applyFontToFontString
M.SetTextColorCached = setTextColorCached
M.SetStatusBarColorCached = setStatusBarColorCached
M.SetTextureColorCached = setTextureColorCached
