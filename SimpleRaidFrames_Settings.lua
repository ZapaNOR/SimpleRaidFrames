local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local AceGUI = M.AceGUI
local LSM = M.LSM
local CONST = M.CONST
local DEFAULT_FONT_NAME = CONST.DEFAULT_FONT_NAME
local DEFAULT_FONT_SIZE = CONST.DEFAULT_FONT_SIZE
local OUTLINE_OPTIONS = CONST.OUTLINE_OPTIONS
local INDICATOR_ANCHORS = CONST.INDICATOR_ANCHORS

local function createSettingsWindow()
	if M._settingsFrame then
		M._settingsFrame:Show()
		return M._settingsFrame
	end
	if not AceGUI then
		print("SimpleRaidFrames: AceGUI not available.")
		return nil
	end

	M.EnsureDefaults()

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

		local hidePartySelf = AceGUI:Create("CheckBox")
		hidePartySelf:SetLabel("Hide Player Frame in Party (5-man)")
		hidePartySelf:SetValue(M.DB.hidePlayerInParty)
		hidePartySelf:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.hidePlayerInParty = val and true or false
			M:ApplySettings()
		end)
		hidePartySelf:SetFullWidth(true)
		container:AddChild(hidePartySelf)

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
		leaderPos:SetValue(M.DB.leaderAssistAnchor or M.DEFAULTS.leaderAssistAnchor)
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
		statusPos:SetValue(M.DB.statusIndicatorAnchor or M.DEFAULTS.statusIndicatorAnchor)
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
		local fgColor = M.DB.healthColor or M.DEFAULTS.healthColor
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
		local bgColor = M.DB.healthBgColor or M.DEFAULTS.healthBgColor
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
		local deadBgColor = M.DB.healthDeadBgColor or M.DEFAULTS.healthDeadBgColor
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

M.CreateSettingsWindow = createSettingsWindow
