local ADDON_NAME = ...
local M = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = M

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT_NAME = (LSM and LSM.GetDefault and LSM:GetDefault("font")) or "Friz Quadrata TT"
local DEFAULT_FONT_PATH = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local DEFAULT_FONT_SIZE = 11

local OFFLINE_ICON_PATH = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\connection.png"
local LEADER_ICON_PATH = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
local ASSIST_ICON_PATH = "Interface\\GroupFrame\\UI-Group-AssistantIcon"
local AFK_ICON_PATH = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\afk.png"
local DND_ICON_PATH = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\dnd.png"
local DEAD_ICON_PATH = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\dead.png"
local GHOST_ICON_PATH = "Interface\\AddOns\\SimpleRaidFrames\\media\\icons\\ghost.png"
do
	local _, size = GameFontNormalSmall and GameFontNormalSmall:GetFont()
	if size then
		DEFAULT_FONT_SIZE = size
	end
end

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

local DEFAULTS = {
	hideRealmNames = true,
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

M._settingsCategoryName = "SimpleRaidFrames"
M.DB = nil
M._settingsFrame = nil
M._settingsPanel = nil
M._hooked = false
M._pendingPrivateAuraRefresh = false
M._pendingAuraLayoutRefresh = false
M._pendingRoleIconRefresh = false

local function ensureDefaults()
	SimpleRaidFramesDB = SimpleRaidFramesDB or {}
	if SimpleRaidFramesDB.hideRealmNames == nil then
		SimpleRaidFramesDB.hideRealmNames = DEFAULTS.hideRealmNames
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

local function isFrameInRaidContainer(frame)
	if not frame then return false end
	local unit = frame.displayedUnit or frame.unit
	if type(unit) == "string" then
		if unit ~= "player" and not unit:find("^raid") and not unit:find("^party") then
			return false
		end
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

local function canMutateRaidFrames()
	if isInCombatLockdown() then
		return false
	end
	if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive then
		if EditModeManagerFrame:IsEditModeActive() then
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
	if not frame or not frame.unit or not M.DB then return end
	if not isFrameInRaidContainer(frame) then return end

	local unit = frame.displayedUnit or frame.unit
	if not unit then return end

	local inGroup = (IsInGroup and IsInGroup()) or false
	local okLeader, isLeader = pcall(UnitIsGroupLeader, unit)
	local okAssist, isAssist = pcall(UnitIsGroupAssistant, unit)
	local showLeader = inGroup and okLeader and isLeader and M.DB.leaderAssistEnabled
	local showAssist = inGroup and okAssist and isAssist and M.DB.leaderAssistEnabled

	local leaderIcon = frame._srfLeaderIcon
	if not leaderIcon then
		leaderIcon = frame:CreateTexture(nil, "OVERLAY", nil, 6)
		leaderIcon:SetTexture(LEADER_ICON_PATH)
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
		assistIcon:SetTexture(ASSIST_ICON_PATH)
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
	if frame.name and frame.name.GetFont then
		_, size = frame.name:GetFont()
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
		placeIndicatorIcon(frame, leaderIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		leaderIcon:Show()
	elseif showAssist then
		assistIcon:SetSize(iconSize, iconSize)
		placeIndicatorIcon(frame, assistIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		assistIcon:Show()
	end
end

local function updateOfflineIndicator(frame)
	if not frame or not frame.statusText or not frame.unit or not M.DB then return end
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
	local ok, connected = pcall(UnitIsConnected, frame.unit)
	if ok and connected == false then
		isOffline = true
	end
	local isAfk = false
	local okAfk, afk = pcall(UnitIsAFK, frame.unit)
	if okAfk and afk == true then
		isAfk = true
	end
	local isDnd = false
	local okDnd, dnd = pcall(UnitIsDND, frame.unit)
	if okDnd and dnd == true then
		isDnd = true
	end
	local isGhost = false
	local okGhost, ghost = pcall(UnitIsGhost, frame.unit)
	if okGhost and ghost == true then
		isGhost = true
	end
	local isDead = false
	local okDead, deadOrGhost = pcall(UnitIsDeadOrGhost, frame.unit)
	if okDead and deadOrGhost == true and not isGhost then
		isDead = true
	end

	local icon = frame._srfOfflineIcon
	if not icon then
		icon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		icon:SetTexture(OFFLINE_ICON_PATH)
		icon:SetTexCoord(0, 1, 0, 1)
		frame._srfOfflineIcon = icon
	end
	local afkIcon = frame._srfAfkIcon
	if not afkIcon then
		afkIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		afkIcon:SetTexture(AFK_ICON_PATH)
		afkIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfAfkIcon = afkIcon
	end
	local dndIcon = frame._srfDndIcon
	if not dndIcon then
		dndIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		dndIcon:SetTexture(DND_ICON_PATH)
		dndIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfDndIcon = dndIcon
	end
	local deadIcon = frame._srfDeadIcon
	if not deadIcon then
		deadIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		deadIcon:SetTexture(DEAD_ICON_PATH)
		deadIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfDeadIcon = deadIcon
	end
	local ghostIcon = frame._srfGhostIcon
	if not ghostIcon then
		ghostIcon = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		ghostIcon:SetTexture(GHOST_ICON_PATH)
		ghostIcon:SetTexCoord(0, 1, 0, 1)
		frame._srfGhostIcon = ghostIcon
	end

	local _, size
	if frame.name and frame.name.GetFont then
		_, size = frame.name:GetFont()
	end
	if not size and frame.statusText.GetFont then
		_, size = frame.statusText:GetFont()
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
		if frame.statusText.Hide then frame.statusText:Hide() end
		icon:SetSize(iconSize, iconSize)
		placeIndicatorIcon(frame, icon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		icon:Show()
		return
	end

	if isDead or isGhost then
		if frame.statusText.Hide then frame.statusText:Hide() end
	end

	if isAfk then
		afkIcon:SetSize(iconSize, iconSize)
		placeIndicatorIcon(frame, afkIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		afkIcon:Show()
	end

	if isDead or isGhost then
		local tex = isGhost and ghostIcon or deadIcon
		tex:SetSize(iconSize, iconSize)
		local index = isAfk and 2 or 1
		placeIndicatorIcon(frame, tex, anchor, index, iconSize, spacing, offsetX, offsetY)
		tex:Show()
	end

	if not isAfk and not isDead and not isGhost and isDnd then
		dndIcon:SetSize(iconSize, iconSize)
		placeIndicatorIcon(frame, dndIcon, anchor, 1, iconSize, spacing, offsetX, offsetY)
		dndIcon:Show()
	end
end

local function applyRoleIconLayout(frame)
	if not frame or not frame.roleIcon then return end
	if not isFrameInRaidContainer(frame) then return end
	if not M.DB then return end
	if frame.optionTable and frame.optionTable.displayRoleIcon == false then return end
	if not canMutateRaidFrames() then
		M._pendingRoleIconRefresh = true
		return
	end

	local roleIcon = frame.roleIcon
	if not roleIcon:IsShown() then return end

	if not roleIcon._srfBasePoint then
		local point, relTo, relPoint, x, y = roleIcon:GetPoint(1)
		roleIcon._srfBasePoint = {
			point = point,
			relTo = relTo,
			relPoint = relPoint,
			x = x or 0,
			y = y or 0,
			size = roleIcon:GetHeight(),
		}
	end

	local base = roleIcon._srfBasePoint
	local offsetX = tonumber(M.DB.roleIconOffsetX) or 0
	local offsetY = tonumber(M.DB.roleIconOffsetY) or 0
	if base.point then
		roleIcon:ClearAllPoints()
		roleIcon:SetPoint(base.point, base.relTo or roleIcon:GetParent(), base.relPoint or base.point, base.x + offsetX, base.y + offsetY)
	end

	local size = tonumber(M.DB.roleIconSize) or 0
	if size <= 0 then
		size = base.size or roleIcon:GetHeight()
	end
	if size and size > 0 then
		roleIcon:SetSize(size, size)
	end
	if frame._srfRoleIcon then
		frame._srfRoleIcon:Hide()
	end
end

local function applyRoleIconStyle(frame)
	if not M.DB or not frame or not frame.roleIcon or not isFrameInRaidContainer(frame) then return end
	local unit = frame.unit or frame.displayedUnit
	if not unit then return end
	if frame.optionTable and frame.optionTable.displayRoleIcon == false then return end

	local roleStyle = M.DB.roleIconStyle
	if roleStyle == "flat" or roleStyle == "pixels" then
		if UnitInVehicle(unit) and UnitHasVehicleUI(unit) then
			applyRoleIconLayout(frame)
			return
		end
		if frame.optionTable and frame.optionTable.displayRaidRoleIcon and type(GetUnitFrameRaidRole) == "function" then
			local raidRole = GetUnitFrameRaidRole(frame)
			if raidRole then
				applyRoleIconLayout(frame)
				return
			end
		end
		local role
		if type(GetUnitFrameRole) == "function" then
			role = GetUnitFrameRole(frame)
		else
			role = UnitGroupRolesAssigned(unit)
		end
		if role and role ~= "NONE" then
			local icon
			local roleFolder = roleStyle
			if role == "TANK" then
				icon = "Interface\\AddOns\\SimpleRaidFrames\\media\\roles\\"
					.. roleFolder .. "\\tank.png"
			elseif role == "HEALER" then
				icon = "Interface\\AddOns\\SimpleRaidFrames\\media\\roles\\"
					.. roleFolder .. "\\healer.png"
			elseif role == "DAMAGER" then
				icon = "Interface\\AddOns\\SimpleRaidFrames\\media\\roles\\"
					.. roleFolder .. "\\dps.png"
			end
			if icon then
				frame.roleIcon:SetTexture(icon)
				frame.roleIcon:SetTexCoord(0, 1, 0, 1)
				if frame.roleIcon.SetVertexColor then
					frame.roleIcon:SetVertexColor(1, 1, 1, 1)
				end
				if frame.roleIcon.SetDesaturated then
					frame.roleIcon:SetDesaturated(false)
				end
				frame.roleIcon:Show()
				frame.roleIcon._srfIcon = icon
			end
		end
	end

	applyRoleIconLayout(frame)
end

local function getDefaultHealthBarColor(frame)
	if not frame then return nil end
	local unit = frame.unit or frame.displayedUnit
	if unit and UnitIsPlayer(unit) then
		if type(CompactUnitFrame_GetOptionUseClassColors) == "function" then
			local okUse, useClass = pcall(CompactUnitFrame_GetOptionUseClassColors, frame)
			if okUse and useClass then
				local _, class = UnitClass(unit)
				local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
				if classColor then
					return classColor.r, classColor.g, classColor.b, 1
				end
			end
		end
	end
	if type(CompactUnitFrame_GetOptionCustomHealthBarColors) == "function" then
		local okColor, color = pcall(CompactUnitFrame_GetOptionCustomHealthBarColors, frame)
		if okColor and color and color.GetRGB then
			local okRGB, r, g, b = pcall(color.GetRGB, color)
			if okRGB and type(r) == "number" and type(g) == "number" and type(b) == "number" then
				return r, g, b, 1
			end
		end
	end
	return 0, 1, 0, 1
end

local function applyHealthColors(frame)
	if not M.DB or not isFrameInRaidContainer(frame) then return end
	local healthBar = frame.healthBar
	if healthBar then
		if M.DB.healthColorEnabled and M.DB.healthColor then
			local c = M.DB.healthColor
			setStatusBarColorCached(healthBar, c.r, c.g, c.b, c.a or 1)
		else
			local r, g, b, a = getDefaultHealthBarColor(frame)
			if r and g and b then
				setStatusBarColorCached(healthBar, r, g, b, a or 1)
			end
		end
	end
	if healthBar then
		local unit = frame.displayedUnit or frame.unit
		local useDeadBg = false
		if unit and M.DB.healthDeadBgColorEnabled and M.DB.healthDeadBgColor then
			local okDead, deadOrGhost = pcall(UnitIsDeadOrGhost, unit)
			if okDead and deadOrGhost == true then
				useDeadBg = true
			end
		end

		if useDeadBg or (M.DB.healthBgColorEnabled and M.DB.healthBgColor) then
			local c
			if useDeadBg then
				c = M.DB.healthDeadBgColor
			else
				c = M.DB.healthBgColor
				if M.DB.healthBgClassColor then
					if unit and UnitIsPlayer(unit) then
						local _, class = UnitClass(unit)
						local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
						if classColor then
							c = { r = classColor.r, g = classColor.g, b = classColor.b, a = c.a or 1 }
						end
					end
				end
			end
			local bg = frame._srfHealthBg
			if not bg then
				bg = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
				bg:SetAllPoints(healthBar)
				frame._srfHealthBg = bg
			end
			local alpha = c.a or 1
			setTextureColorCached(bg, c.r, c.g, c.b, alpha)
			bg:Show()
		else
			if frame._srfHealthBg then
				frame._srfHealthBg:Hide()
			end
		end
	end
end

local function hideAggroHighlight(frame)
	if not frame or not isFrameInRaidContainer(frame) then return end
	if frame.aggroHighlight and frame.aggroHighlight.Hide then
		frame.aggroHighlight:Hide()
	end
end

local function applyAuraCooldownSettings(cooldown)
	if not cooldown or not M.DB then return end
	if cooldown.SetHideCountdownNumbers then
		local hide = not M.DB.auraCooldownText
		if cooldown._srfHideCountdown ~= hide then
			cooldown:SetHideCountdownNumbers(hide)
			cooldown._srfHideCountdown = hide
		end
	end
	if not M.DB.auraCooldownText then
		return
	end

	local fontPath = resolveFont(M.DB.auraCooldownFont)
	local size = tonumber(M.DB.auraCooldownFontSize) or DEFAULT_FONT_SIZE
	if size < 6 then size = 6 end
	if size > 32 then size = 32 end
	local outline = M.DB.auraCooldownFontOutline or ""
	if outline == "NONE" then outline = "" end
	local shadow = M.DB.auraCooldownShadow
	local fontKey = buildFontKey(fontPath, size, outline, shadow)

	local fontName = "SimpleRaidFrames_AuraCooldownFont"
	if not M._auraCooldownFont then
		M._auraCooldownFont = _G[fontName] or CreateFont(fontName)
	end
	if M._auraCooldownFont and M._auraCooldownFont.SetFont and M._auraCooldownFontKey ~= fontKey then
		M._auraCooldownFont:SetFont(fontPath, size, outline)
		if shadow then
			M._auraCooldownFont:SetShadowColor(0, 0, 0, 1)
			M._auraCooldownFont:SetShadowOffset(1, -1)
		else
			M._auraCooldownFont:SetShadowColor(0, 0, 0, 0)
			M._auraCooldownFont:SetShadowOffset(0, 0)
		end
		M._auraCooldownFontKey = fontKey
	end

	if cooldown.SetCountdownFont then
		if not cooldown._srfCountdownFontSet then
			cooldown:SetCountdownFont(fontName)
			cooldown._srfCountdownFontSet = true
		end
	else
		local fs = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
		if fs and fs.SetFont then
			applyFontToFontString(fs, fontPath, size, outline, shadow)
		end
	end

	local fs = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if fs and fs.SetPoint then
		local anchorTarget = cooldown
		local parent = cooldown.GetParent and cooldown:GetParent() or nil
		if parent and parent.icon then
			anchorTarget = parent.icon
		end
		if cooldown._srfCountdownAnchorTarget ~= anchorTarget then
			fs:ClearAllPoints()
			fs:SetPoint("CENTER", anchorTarget, "CENTER", 0, 0)
			cooldown._srfCountdownAnchorTarget = anchorTarget
		end
	end

	if cooldown.SetMinimumCountdownDuration and not cooldown._srfMinDurationSet then
		cooldown:SetMinimumCountdownDuration(0)
		cooldown._srfMinDurationSet = true
	end
end

local AURA_LAYOUTS = {
	[Enum.RaidAuraOrganizationType.Legacy] = {
		Buffs = {
			direction = GridLayoutMixin.Direction.BottomRightToTopLeft,
			stride = 3,
			anchorPoint = "BOTTOMRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Debuffs = {
			direction = GridLayoutMixin.Direction.BottomLeftToTopRight,
			stride = 3,
			useChainLayout = true,
			anchorPoint = "BOTTOMLEFT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return 3 + dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Dispel = {
			direction = GridLayoutMixin.Direction.RightToLeft,
			stride = 3,
			anchorPoint = "TOPRIGHT",
			getOffsets = function()
				return -3, -2
			end,
		},
	},
	[Enum.RaidAuraOrganizationType.BuffsTopDebuffsBottom] = {
		Buffs = {
			direction = GridLayoutMixin.Direction.TopRightToBottomLeft,
			stride = 6,
			anchorPoint = "TOPRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, -3 - dispelOffset
			end,
		},
		Debuffs = {
			direction = GridLayoutMixin.Direction.BottomRightToTopLeft,
			stride = 3,
			useChainLayout = true,
			anchorPoint = "BOTTOMRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Dispel = {
			direction = GridLayoutMixin.Direction.BottomLeftToTopRight,
			stride = 3,
			anchorPoint = "BOTTOMLEFT",
			getOffsets = function(frame)
				return 3, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight
			end,
		},
	},
	[Enum.RaidAuraOrganizationType.BuffsRightDebuffsLeft] = {
		Buffs = {
			direction = GridLayoutMixin.Direction.BottomRightToTopLeft,
			stride = 3,
			anchorPoint = "BOTTOMRIGHT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return -3 - dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Debuffs = {
			direction = GridLayoutMixin.Direction.BottomLeftToTopRight,
			stride = 3,
			useChainLayout = true,
			anchorPoint = "BOTTOMLEFT",
			getOffsets = function(frame)
				local dispelOffset = frame.DispelOverlayAuraOffset or 0
				return 3 + dispelOffset, CUF_AURA_BOTTOM_OFFSET + frame.powerBarUsedHeight + dispelOffset
			end,
		},
		Dispel = {
			direction = GridLayoutMixin.Direction.LeftToRight,
			stride = 3,
			anchorPoint = "TOPLEFT",
			getOffsets = function()
				return 3, -2
			end,
		},
	},
}

local function applyAuraGapLayout(frame)
	if not frame or not M.DB or not AnchorUtil or not GridLayoutMixin then return end
	if not canMutateRaidFrames() then
		M._pendingAuraLayoutRefresh = true
		return
	end
	local gap = tonumber(M.DB.auraGap) or 0
	local auraOrganizationType = Enum and Enum.RaidAuraOrganizationType and Enum.RaidAuraOrganizationType.Legacy
	if EditModeManagerFrame and EditModeManagerFrame.GetRaidFrameAuraOrganizationType then
		auraOrganizationType = EditModeManagerFrame:GetRaidFrameAuraOrganizationType(frame.groupType)
	end
	auraOrganizationType = auraOrganizationType or Enum.RaidAuraOrganizationType.Legacy

	local layoutSet = AURA_LAYOUTS[auraOrganizationType] or AURA_LAYOUTS[Enum.RaidAuraOrganizationType.Legacy]
	if not layoutSet then return end

	local function layoutContainer(container, layoutData)
		if not container or not layoutData then return end
		for _, containedFrame in pairs(container) do
			containedFrame:ClearAllPoints()
		end
		local anchor = AnchorUtil.CreateAnchor(layoutData.anchorPoint, frame, layoutData.anchorPoint, 0, 0)
		if layoutData.getOffsets then
			anchor:SetOffsets(layoutData.getOffsets(frame))
		end
		local layout = AnchorUtil.CreateGridLayout(layoutData.direction, layoutData.stride, gap, gap)
		if layoutData.useChainLayout then
			layout.horizontalSpacing = gap
			layout.verticalSpacing = gap
			AnchorUtil.ChainLayout(container, anchor, layout, true)
		else
			AnchorUtil.GridLayout(container, anchor, layout)
		end
	end

	layoutContainer(frame.buffFrames, layoutSet.Buffs)
	layoutContainer(frame.debuffFrames, layoutSet.Debuffs)
	layoutContainer(frame.dispelDebuffFrames, layoutSet.Dispel)
end

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

local function onBuffSet(buffFrame)
	if not buffFrame then return end
	local parent = buffFrame:GetParent()
	if not isFrameInRaidContainer(parent) then return end
	applyAuraCooldownSettings(buffFrame.cooldown)
end

local function onDebuffSet(frame, debuffFrame)
	if not isFrameInRaidContainer(frame) then return end
	applyAuraCooldownSettings(debuffFrame and debuffFrame.cooldown)
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
	updateLeaderAssistIndicator(frame)
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

function M:RefreshRaidRoleIcons()
	if not canMutateRaidFrames() then
		M._pendingRoleIconRefresh = true
		return
	end
	local function refresh(frame)
		if not frame then return end
		if not isFrameInRaidContainer(frame) then return end
		if type(CompactUnitFrame_UpdateRoleIcon) == "function" then
			pcall(CompactUnitFrame_UpdateRoleIcon, frame)
		end
		applyRoleIconStyle(frame)
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

function M:RefreshRaidAuras()
	local function refreshAuraFrame(frame)
		if not frame or not frame.unit then return end

		if frame.buffFrames then
			for _, buffFrame in ipairs(frame.buffFrames) do
				applyAuraCooldownSettings(buffFrame.cooldown)
			end
		end

		if frame.debuffFrames then
			for _, debuffFrame in ipairs(frame.debuffFrames) do
				applyAuraCooldownSettings(debuffFrame.cooldown)
			end
		end

		applyAuraGapLayout(frame)
	end
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", refreshAuraFrame)
		CompactRaidFrameContainer:ApplyToFrames("mini", refreshAuraFrame)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", refreshAuraFrame)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", refreshAuraFrame)
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

function M:RefreshRaidHealthColors()
	local function refresh(frame)
		if not frame then return end
		if not isFrameInRaidContainer(frame) then return end
		if not M.DB then return end
		local unit = frame.displayedUnit or frame.unit
		if not unit or unit == "" then
			applyHealthColors(frame)
			return
		end
		applyHealthColors(frame)
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

function M:RefreshRaidAggro()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", hideAggroHighlight)
		CompactRaidFrameContainer:ApplyToFrames("mini", hideAggroHighlight)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", hideAggroHighlight)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", hideAggroHighlight)
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
end

local function ensureHooks()
	if type(CompactUnitFrame_UpdateName) ~= "function" then return end
	if not M._nameHooked then
		hooksecurefunc("CompactUnitFrame_UpdateName", applyNameSettings)
		M._nameHooked = true
	end
	if type(CompactUnitFrame_UpdateStatusText) == "function" and not M._statusTextHooked then
		hooksecurefunc("CompactUnitFrame_UpdateStatusText", updateOfflineIndicator)
		M._statusTextHooked = true
	end
	if type(CompactUnitFrame_UtilSetBuff) == "function" and not M._buffHooked then
		hooksecurefunc("CompactUnitFrame_UtilSetBuff", onBuffSet)
		M._buffHooked = true
	end
	if type(CompactUnitFrame_UtilSetDebuff) == "function" and not M._debuffHooked then
		hooksecurefunc("CompactUnitFrame_UtilSetDebuff", onDebuffSet)
		M._debuffHooked = true
	end
	if type(CompactUnitFrame_UpdateAuraFrameLayout) == "function" and not M._layoutHooked then
		hooksecurefunc("CompactUnitFrame_UpdateAuraFrameLayout", function(frame)
			if M and M.DB then
				applyAuraGapLayout(frame)
			end
		end)
		M._layoutHooked = true
	end
	if type(CompactUnitFrame_UpdatePrivateAuras) == "function" and not M._privateAuraHooked then
		hooksecurefunc("CompactUnitFrame_UpdatePrivateAuras", applyPrivateAuraAnchorBottomLeft)
		M._privateAuraHooked = true
	end
	if type(CompactUnitFrame_UpdateAggroHighlight) == "function" and not M._aggroHooked then
		hooksecurefunc("CompactUnitFrame_UpdateAggroHighlight", hideAggroHighlight)
		M._aggroHooked = true
	end
	if type(CompactUnitFrame_UpdateRoleIcon) == "function" and not M._roleIconHooked then
		hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", applyRoleIconStyle)
		M._roleIconHooked = true
	end
	if type(CompactUnitFrame_UpdateHealthColor) == "function" and not M._healthColorHooked then
		hooksecurefunc("CompactUnitFrame_UpdateHealthColor", applyHealthColors)
		M._healthColorHooked = true
	end
	if type(CompactUnitFrame_UpdateCenterStatusIcon) == "function" and not M._centerStatusNameHooked then
		hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", applyNameSettings)
		M._centerStatusNameHooked = true
	end
	M:RefreshRaidNames()
	M:RefreshRaidRoleIcons()
	M:RefreshRaidAuras()
	M:RefreshPrivateAuras()
	M:RefreshRaidStatusText()
	M:RefreshRaidHealthColors()
	M:RefreshRaidAggro()
end

local function createSettingsWindow()
	if M._settingsFrame then
		M._settingsFrame:Show()
		return M._settingsFrame
	end
	if not AceGUI then
		print("SimpleRaidFrames: AceGUI not available.")
		return nil
	end

	ensureDefaults()

	local outlineList = {}
	for _, opt in ipairs(OUTLINE_OPTIONS) do
		outlineList[opt.value] = opt.label
	end

	local function setMaxNameLength(value)
		value = math.floor(tonumber(value) or 0)
		if value < 0 then value = 0 end
		if value > 20 then value = 20 end
		M.DB.maxNameLength = value
		M:ApplySettings()
	end

	local function setFontSize(value, minValue, maxValue, targetKey)
		value = math.floor(tonumber(value) or DEFAULT_FONT_SIZE)
		if value < minValue then value = minValue end
		if value > maxValue then value = maxValue end
		M.DB[targetKey] = value
		M:ApplySettings()
	end

	local function buildNameTab(container)
		container:SetLayout("List")

		local hide = AceGUI:Create("CheckBox")
		hide:SetLabel("Hide Realm Names")
		hide:SetValue(M.DB.hideRealmNames)
		hide:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.hideRealmNames = val and true or false
			M:ApplySettings()
		end)
		hide:SetFullWidth(true)
		container:AddChild(hide)

		local maxLen = AceGUI:Create("Slider")
		maxLen:SetLabel("Max Name Length (0 = unlimited)")
		maxLen:SetSliderValues(0, 20, 1)
		maxLen:SetValue(M.DB.maxNameLength or 0)
		maxLen:SetCallback("OnValueChanged", function(_, _, val)
			setMaxNameLength(val)
		end)
		maxLen:SetFullWidth(true)
		container:AddChild(maxLen)

		local font = AceGUI:Create("LSM30_Font")
		font:SetLabel("Font")
		if font.SetList then
			font:SetList(LSM and LSM.HashTable and LSM:HashTable("font") or nil)
		end
		font:SetValue(M.DB.nameFont or DEFAULT_FONT_NAME)
		font:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.nameFont = val
			if font.SetValue then
				font:SetValue(val)
			end
			M:ApplySettings()
		end)
		font:SetFullWidth(true)
		container:AddChild(font)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetLabel("Font Size")
		fontSize:SetSliderValues(6, 32, 1)
		fontSize:SetValue(M.DB.nameFontSize or DEFAULT_FONT_SIZE)
		fontSize:SetCallback("OnValueChanged", function(_, _, val)
			setFontSize(val, 6, 32, "nameFontSize")
		end)
		fontSize:SetFullWidth(true)
		container:AddChild(fontSize)

		local outline = AceGUI:Create("Dropdown")
		outline:SetLabel("Outline")
		outline:SetList(outlineList)
		outline:SetValue(M.DB.nameFontOutline or "")
		outline:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.nameFontOutline = val
			M:ApplySettings()
		end)
		outline:SetFullWidth(true)
		container:AddChild(outline)

		local shadow = AceGUI:Create("CheckBox")
		shadow:SetLabel("Shadow")
		shadow:SetValue(M.DB.nameShadow)
		shadow:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.nameShadow = val and true or false
			M:ApplySettings()
		end)
		shadow:SetFullWidth(true)
		container:AddChild(shadow)

		local classColor = AceGUI:Create("CheckBox")
		classColor:SetLabel("Class Color")
		classColor:SetValue(M.DB.nameClassColor)
		classColor:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.nameClassColor = val and true or false
			M:ApplySettings()
		end)
		classColor:SetFullWidth(true)
		container:AddChild(classColor)
	end

	local function buildAurasTab(container)
		container:SetLayout("List")

		local enable = AceGUI:Create("CheckBox")
		enable:SetLabel("Enable Cooldown Text")
		enable:SetValue(M.DB.auraCooldownText)
		enable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraCooldownText = val and true or false
			container:ReleaseChildren()
			buildAurasTab(container)
			M:ApplySettings()
		end)
		enable:SetFullWidth(true)
		container:AddChild(enable)

		local gap = AceGUI:Create("Slider")
		gap:SetLabel("Aura Gap")
		gap:SetSliderValues(-10, 20, 1)
		gap:SetValue(M.DB.auraGap or 0)
		gap:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraGap = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		gap:SetFullWidth(true)
		container:AddChild(gap)

		if not M.DB.auraCooldownText then
			return
		end

		local font = AceGUI:Create("LSM30_Font")
		font:SetLabel("Cooldown Font")
		if font.SetList then
			font:SetList(LSM and LSM.HashTable and LSM:HashTable("font") or nil)
		end
		font:SetValue(M.DB.auraCooldownFont or DEFAULT_FONT_NAME)
		font:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.auraCooldownFont = val
			if font.SetValue then
				font:SetValue(val)
			end
			M:ApplySettings()
		end)
		font:SetFullWidth(true)
		container:AddChild(font)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetLabel("Cooldown Font Size")
		fontSize:SetSliderValues(6, 32, 1)
		fontSize:SetValue(M.DB.auraCooldownFontSize or DEFAULT_FONT_SIZE)
		fontSize:SetCallback("OnValueChanged", function(_, _, val)
			setFontSize(val, 6, 32, "auraCooldownFontSize")
		end)
		fontSize:SetFullWidth(true)
		container:AddChild(fontSize)

		local outline = AceGUI:Create("Dropdown")
		outline:SetLabel("Outline")
		outline:SetList(outlineList)
		outline:SetValue(M.DB.auraCooldownFontOutline or "")
		outline:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraCooldownFontOutline = val
			M:ApplySettings()
		end)
		outline:SetFullWidth(true)
		container:AddChild(outline)

		local shadow = AceGUI:Create("CheckBox")
		shadow:SetLabel("Shadow")
		shadow:SetValue(M.DB.auraCooldownShadow)
		shadow:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraCooldownShadow = val and true or false
			M:ApplySettings()
		end)
		shadow:SetFullWidth(true)
		container:AddChild(shadow)
	end

	local function buildPrivateAurasTab(container)
		container:SetLayout("List")

		local info = AceGUI:Create("Label")
		info:SetFullWidth(true)
		info:SetText("Private auras are managed automatically.")
		container:AddChild(info)
	end

	local function buildRoleIconTab(container)
		container:SetLayout("List")

		local size = AceGUI:Create("Slider")
		size:SetLabel("Icon Size (0 = default)")
		size:SetSliderValues(0, 32, 1)
		size:SetValue(M.DB.roleIconSize or 0)
		size:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.roleIconSize = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		size:SetFullWidth(true)
		container:AddChild(size)

		local offsetX = AceGUI:Create("Slider")
		offsetX:SetLabel("Offset X")
		offsetX:SetSliderValues(-20, 20, 1)
		offsetX:SetValue(M.DB.roleIconOffsetX or 0)
		offsetX:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.roleIconOffsetX = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		offsetX:SetFullWidth(true)
		container:AddChild(offsetX)

		local offsetY = AceGUI:Create("Slider")
		offsetY:SetLabel("Offset Y")
		offsetY:SetSliderValues(-20, 20, 1)
		offsetY:SetValue(M.DB.roleIconOffsetY or 0)
		offsetY:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.roleIconOffsetY = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		offsetY:SetFullWidth(true)
		container:AddChild(offsetY)
	end

	local function buildIndicatorsTab(container)
		container:SetLayout("List")

		local anchorList = {}
		for _, opt in ipairs(INDICATOR_ANCHORS) do
			anchorList[opt.value] = opt.label
		end

		local leaderHeading = AceGUI:Create("Heading")
		leaderHeading:SetText("Leader / Assist")
		leaderHeading:SetFullWidth(true)
		container:AddChild(leaderHeading)

		local leaderEnable = AceGUI:Create("CheckBox")
		leaderEnable:SetLabel("Enable Leader/Assist Icons")
		leaderEnable:SetValue(M.DB.leaderAssistEnabled)
		leaderEnable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.leaderAssistEnabled = val and true or false
			M.DB.leaderIndicatorEnabled = val and true or false
			M.DB.assistIndicatorEnabled = val and true or false
			M:ApplySettings()
			container:ReleaseChildren()
			buildIndicatorsTab(container)
		end)
		leaderEnable:SetFullWidth(true)
		container:AddChild(leaderEnable)

		local leaderPos = AceGUI:Create("Dropdown")
		leaderPos:SetLabel("Leader/Assist Position")
		leaderPos:SetList(anchorList)
		leaderPos:SetValue(M.DB.leaderAssistAnchor or DEFAULTS.leaderAssistAnchor)
		leaderPos:SetDisabled(not M.DB.leaderAssistEnabled)
		leaderPos:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.leaderAssistAnchor = val
			M:ApplySettings()
		end)
		leaderPos:SetFullWidth(true)
		container:AddChild(leaderPos)

		local leaderOffsetX = AceGUI:Create("Slider")
		leaderOffsetX:SetLabel("Leader/Assist Offset X")
		leaderOffsetX:SetSliderValues(-30, 30, 1)
		leaderOffsetX:SetValue(M.DB.leaderAssistOffsetX or 0)
		leaderOffsetX:SetDisabled(not M.DB.leaderAssistEnabled)
		leaderOffsetX:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.leaderAssistOffsetX = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		leaderOffsetX:SetFullWidth(true)
		container:AddChild(leaderOffsetX)

		local leaderOffsetY = AceGUI:Create("Slider")
		leaderOffsetY:SetLabel("Leader/Assist Offset Y")
		leaderOffsetY:SetSliderValues(-30, 30, 1)
		leaderOffsetY:SetValue(M.DB.leaderAssistOffsetY or 0)
		leaderOffsetY:SetDisabled(not M.DB.leaderAssistEnabled)
		leaderOffsetY:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.leaderAssistOffsetY = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		leaderOffsetY:SetFullWidth(true)
		container:AddChild(leaderOffsetY)

		local statusHeading = AceGUI:Create("Heading")
		statusHeading:SetText("Status Icons")
		statusHeading:SetFullWidth(true)
		container:AddChild(statusHeading)

		local statusEnable = AceGUI:Create("CheckBox")
		statusEnable:SetLabel("Enable Status Icons (AFK/DC/Dead/Ghost/DND)")
		statusEnable:SetValue(M.DB.statusIndicatorsEnabled)
		statusEnable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.statusIndicatorsEnabled = val and true or false
			M:ApplySettings()
			container:ReleaseChildren()
			buildIndicatorsTab(container)
		end)
		statusEnable:SetFullWidth(true)
		container:AddChild(statusEnable)

		local statusPos = AceGUI:Create("Dropdown")
		statusPos:SetLabel("Status Icons Position")
		statusPos:SetList(anchorList)
		statusPos:SetValue(M.DB.statusIndicatorAnchor or DEFAULTS.statusIndicatorAnchor)
		statusPos:SetDisabled(not M.DB.statusIndicatorsEnabled)
		statusPos:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.statusIndicatorAnchor = val
			M:ApplySettings()
		end)
		statusPos:SetFullWidth(true)
		container:AddChild(statusPos)

		local statusOffsetX = AceGUI:Create("Slider")
		statusOffsetX:SetLabel("Status Icons Offset X")
		statusOffsetX:SetSliderValues(-30, 30, 1)
		statusOffsetX:SetValue(M.DB.statusIndicatorOffsetX or 0)
		statusOffsetX:SetDisabled(not M.DB.statusIndicatorsEnabled)
		statusOffsetX:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.statusIndicatorOffsetX = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		statusOffsetX:SetFullWidth(true)
		container:AddChild(statusOffsetX)

		local statusOffsetY = AceGUI:Create("Slider")
		statusOffsetY:SetLabel("Status Icons Offset Y")
		statusOffsetY:SetSliderValues(-30, 30, 1)
		statusOffsetY:SetValue(M.DB.statusIndicatorOffsetY or 0)
		statusOffsetY:SetDisabled(not M.DB.statusIndicatorsEnabled)
		statusOffsetY:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.statusIndicatorOffsetY = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		statusOffsetY:SetFullWidth(true)
		container:AddChild(statusOffsetY)
	end

	local function buildHealthTab(container)
		container:SetLayout("List")

		local fgHeading = AceGUI:Create("Heading")
		fgHeading:SetText("Health Bar")
		fgHeading:SetFullWidth(true)
		container:AddChild(fgHeading)

		local fgEnable = AceGUI:Create("CheckBox")
		fgEnable:SetLabel("Override Health Bar Color")
		fgEnable:SetValue(M.DB.healthColorEnabled)
		fgEnable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthColorEnabled = val and true or false
			container:ReleaseChildren()
			buildHealthTab(container)
			M:ApplySettings()
		end)
		fgEnable:SetFullWidth(true)
		container:AddChild(fgEnable)

		local fg = AceGUI:Create("ColorPicker")
		fg:SetLabel("Health Bar Color")
		if fg.SetHasAlpha then fg:SetHasAlpha(true) end
		local fgColor = M.DB.healthColor or DEFAULTS.healthColor
		fg:SetColor(fgColor.r, fgColor.g, fgColor.b, fgColor.a or 1)
		fg:SetDisabled(not M.DB.healthColorEnabled)
		fg:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			M.DB.healthColor = { r = r, g = g, b = b, a = a }
			M:ApplySettings()
		end)
		fg:SetFullWidth(true)
		container:AddChild(fg)

		local bgHeading = AceGUI:Create("Heading")
		bgHeading:SetText("Background")
		bgHeading:SetFullWidth(true)
		container:AddChild(bgHeading)

		local bgEnable = AceGUI:Create("CheckBox")
		bgEnable:SetLabel("Override Health Background Color")
		bgEnable:SetValue(M.DB.healthBgColorEnabled)
		bgEnable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthBgColorEnabled = val and true or false
			container:ReleaseChildren()
			buildHealthTab(container)
			M:ApplySettings()
		end)
		bgEnable:SetFullWidth(true)
		container:AddChild(bgEnable)

		local bgClass = AceGUI:Create("CheckBox")
		bgClass:SetLabel("Use Class Color for Background")
		bgClass:SetValue(M.DB.healthBgClassColor)
		bgClass:SetDisabled(not M.DB.healthBgColorEnabled)
		bgClass:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthBgClassColor = val and true or false
			container:ReleaseChildren()
			buildHealthTab(container)
			M:ApplySettings()
		end)
		bgClass:SetFullWidth(true)
		container:AddChild(bgClass)

		local bg = AceGUI:Create("ColorPicker")
		bg:SetLabel("Health Background Color")
		if bg.SetHasAlpha then bg:SetHasAlpha(true) end
		local bgColor = M.DB.healthBgColor or DEFAULTS.healthBgColor
		bg:SetColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
		bg:SetDisabled(not M.DB.healthBgColorEnabled or M.DB.healthBgClassColor)
		bg:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			M.DB.healthBgColor = { r = r, g = g, b = b, a = a }
			M:ApplySettings()
		end)
		bg:SetFullWidth(true)
		container:AddChild(bg)

		local deadHeading = AceGUI:Create("Heading")
		deadHeading:SetText("Dead")
		deadHeading:SetFullWidth(true)
		container:AddChild(deadHeading)

		local deadBgEnable = AceGUI:Create("CheckBox")
		deadBgEnable:SetLabel("Override Dead Background Color")
		deadBgEnable:SetValue(M.DB.healthDeadBgColorEnabled)
		deadBgEnable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthDeadBgColorEnabled = val and true or false
			container:ReleaseChildren()
			buildHealthTab(container)
			M:ApplySettings()
		end)
		deadBgEnable:SetFullWidth(true)
		container:AddChild(deadBgEnable)

		local deadBg = AceGUI:Create("ColorPicker")
		deadBg:SetLabel("Dead Background Color")
		if deadBg.SetHasAlpha then deadBg:SetHasAlpha(true) end
		local deadBgColor = M.DB.healthDeadBgColor or DEFAULTS.healthDeadBgColor
		deadBg:SetColor(deadBgColor.r, deadBgColor.g, deadBgColor.b, deadBgColor.a or 1)
		deadBg:SetDisabled(not M.DB.healthDeadBgColorEnabled)
		deadBg:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			M.DB.healthDeadBgColor = { r = r, g = g, b = b, a = a }
			M:ApplySettings()
		end)
		deadBg:SetFullWidth(true)
		container:AddChild(deadBg)

	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("SimpleRaidFrames")
	frame:SetWidth(560)
	frame:SetHeight(420)
	frame:SetLayout("Fill")
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		M._settingsFrame = nil
	end)

	local tabs = AceGUI:Create("TabGroup")
	tabs:SetTabs({
		{ text = "Name", value = "name" },
		{ text = "Role Icon", value = "role" },
		{ text = "Health", value = "health" },
		{ text = "Auras", value = "auras" },
		{ text = "Indicators", value = "indicators" },
		{ text = "Private Auras", value = "private_auras" },
	})
	tabs:SetLayout("List")
	tabs:SetCallback("OnGroupSelected", function(container, _, group)
		container:ReleaseChildren()
		if group == "role" then
			buildRoleIconTab(container)
		elseif group == "health" then
			buildHealthTab(container)
		elseif group == "auras" then
			buildAurasTab(container)
		elseif group == "indicators" then
			buildIndicatorsTab(container)
		elseif group == "private_auras" then
			buildPrivateAurasTab(container)
		else
			buildNameTab(container)
		end
	end)
	frame:AddChild(tabs)
	tabs:SelectTab("name")

	M._settingsFrame = frame
	return frame
end

function M:OpenSettings()
	local frame = createSettingsWindow()
	if not frame then return end
	if frame.Show then
		frame:Show()
	end
	if frame.frame and frame.frame.Raise then
		frame.frame:Raise()
	end
end

function M:CreateSettingsPanel()
	if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
	local panel = CreateFrame("Frame")
	panel.name = M._settingsCategoryName

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("SimpleRaidFrames")

	local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	desc:SetWidth(520)
	desc:SetJustifyH("LEFT")
	desc:SetText("Settings open in a separate window. Use the button below or type /srf.")

	local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	btn:SetSize(200, 24)
	btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
	btn:SetText("Open Settings")
	btn:SetScript("OnClick", function() M:OpenSettings() end)

	local category = Settings.RegisterCanvasLayoutCategory(panel, M._settingsCategoryName)
	Settings.RegisterAddOnCategory(category)
	M._settingsPanel = panel
end

local function printSlashHelp()
	print("|cFF9CDF95Simple|rRaidFrames: '|cFF9CDF95/srf|r' for in-game configuration.")
end

SLASH_SIMPLERAIDFRAMES1 = "/srf"
SLASH_SIMPLERAIDFRAMES2 = "/simpleraidframes"
SlashCmdList["SIMPLERAIDFRAMES"] = function(msg)
	msg = (msg or ""):lower()
	if msg == "" or msg == "settings" or msg == "config" or msg == "options" then
		M:OpenSettings()
		return
	end
	printSlashHelp()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			ensureDefaults()
			M:CreateSettingsPanel()
			ensureHooks()
		else
			ensureHooks()
		end
	elseif event == "PLAYER_LOGIN" then
		ensureDefaults()
		ensureHooks()
		printSlashHelp()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if M._pendingPrivateAuraRefresh then
			M._pendingPrivateAuraRefresh = false
			M:RefreshPrivateAuras()
		end
		if M._pendingAuraLayoutRefresh then
			M._pendingAuraLayoutRefresh = false
			M:RefreshRaidAuras()
		end
		if M._pendingRoleIconRefresh then
			M._pendingRoleIconRefresh = false
			M:RefreshRaidRoleIcons()
		end
	end
end)
