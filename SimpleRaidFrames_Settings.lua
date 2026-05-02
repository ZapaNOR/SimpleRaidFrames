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

		local hideTooltips = AceGUI:Create("CheckBox")
		hideTooltips:SetLabel("Hide Raid Frame Unit Tooltips")
		hideTooltips:SetValue(M.DB.hideRaidFrameTooltips)
		hideTooltips:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.hideRaidFrameTooltips = val and true or false
			M:ApplySettings()
		end)
		hideTooltips:SetFullWidth(true)
		container:AddChild(hideTooltips)

		local hidePartySelf = AceGUI:Create("CheckBox")
		hidePartySelf:SetLabel("Hide Player Frame in Party (5-man)")
		hidePartySelf:SetValue(M.DB.hidePlayerInParty)
		hidePartySelf:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.hidePlayerInParty = val and true or false
			M:ApplySettings()
		end)
		hidePartySelf:SetFullWidth(true)
		container:AddChild(hidePartySelf)

		local showPartySolo = AceGUI:Create("CheckBox")
		showPartySolo:SetLabel("Show Party Frame When Solo")
		showPartySolo:SetValue(M.DB.showPartyWhenSolo)
		showPartySolo:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.showPartyWhenSolo = val and true or false
			M:ApplySettings()
		end)
		showPartySolo:SetFullWidth(true)
		container:AddChild(showPartySolo)

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

	local function buildAuraBarsTab(container)
		container:SetLayout("List")

		local function refresh()
			container:ReleaseChildren()
			buildAuraBarsTab(container)
		end

		local enable = AceGUI:Create("CheckBox")
		enable:SetLabel("Show Buffs/HoTs as Bars (replaces native buff icons)")
		enable:SetValue(M.DB.auraBarsEnabled)
		enable:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsEnabled = val and true or false
			M:ApplySettings()
			refresh()
		end)
		enable:SetFullWidth(true)
		container:AddChild(enable)

		if not M.DB.auraBarsEnabled then
			local hint = AceGUI:Create("Label")
			hint:SetFullWidth(true)
			hint:SetText("Enable to configure bars and tracked auras.")
			container:AddChild(hint)
			return
		end

		local anchorList = {
			TOPLEFT = "Top Left",
			TOPRIGHT = "Top Right",
			BOTTOMLEFT = "Bottom Left",
			BOTTOMRIGHT = "Bottom Right",
		}
		local anchor = AceGUI:Create("Dropdown")
		anchor:SetLabel("Anchor Corner")
		anchor:SetList(anchorList)
		anchor:SetValue(M.DB.auraBarsAnchor or M.DEFAULTS.auraBarsAnchor)
		anchor:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.auraBarsAnchor = val
			M:ApplySettings()
		end)
		anchor:SetFullWidth(true)
		container:AddChild(anchor)

		local growList = { UP = "Up", DOWN = "Down", LEFT = "Left", RIGHT = "Right" }
		local grow = AceGUI:Create("Dropdown")
		grow:SetLabel("Grow Direction")
		grow:SetList(growList)
		grow:SetValue(M.DB.auraBarsGrow or M.DEFAULTS.auraBarsGrow)
		grow:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.auraBarsGrow = val
			M:ApplySettings()
		end)
		grow:SetFullWidth(true)
		container:AddChild(grow)

		local fillList = { LTR = "Left to Right", RTL = "Right to Left" }
		local fill = AceGUI:Create("Dropdown")
		fill:SetLabel("Bar Fill Direction")
		fill:SetList(fillList)
		fill:SetValue(M.DB.auraBarsFillDirection or M.DEFAULTS.auraBarsFillDirection)
		fill:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.auraBarsFillDirection = val
			M:ApplySettings()
		end)
		fill:SetFullWidth(true)
		container:AddChild(fill)

		local texture = AceGUI:Create("LSM30_Statusbar")
		texture:SetLabel("Bar Texture")
		if texture.SetList then
			texture:SetList(LSM and LSM.HashTable and LSM:HashTable("statusbar") or nil)
		end
		texture:SetValue(M.DB.auraBarsTexture or M.DEFAULTS.auraBarsTexture)
		texture:SetCallback("OnValueChanged", function(_, _, val)
			if not val or val == "" then return end
			M.DB.auraBarsTexture = val
			if texture.SetValue then texture:SetValue(val) end
			M:ApplySettings()
		end)
		texture:SetFullWidth(true)
		container:AddChild(texture)

		local width = AceGUI:Create("Slider")
		width:SetLabel("Bar Width")
		width:SetSliderValues(20, 200, 1)
		width:SetValue(M.DB.auraBarsWidth or M.DEFAULTS.auraBarsWidth)
		width:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsWidth = math.floor(tonumber(val) or M.DEFAULTS.auraBarsWidth)
			M:ApplySettings()
		end)
		width:SetFullWidth(true)
		container:AddChild(width)

		local height = AceGUI:Create("Slider")
		height:SetLabel("Bar Height")
		height:SetSliderValues(2, 20, 1)
		height:SetValue(M.DB.auraBarsHeight or M.DEFAULTS.auraBarsHeight)
		height:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsHeight = math.floor(tonumber(val) or M.DEFAULTS.auraBarsHeight)
			M:ApplySettings()
		end)
		height:SetFullWidth(true)
		container:AddChild(height)

		local spacing = AceGUI:Create("Slider")
		spacing:SetLabel("Bar Spacing")
		spacing:SetSliderValues(-2, 10, 1)
		spacing:SetValue(M.DB.auraBarsSpacing or M.DEFAULTS.auraBarsSpacing)
		spacing:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsSpacing = math.floor(tonumber(val) or M.DEFAULTS.auraBarsSpacing)
			M:ApplySettings()
		end)
		spacing:SetFullWidth(true)
		container:AddChild(spacing)

		local offsetX = AceGUI:Create("Slider")
		offsetX:SetLabel("Offset X")
		offsetX:SetSliderValues(-60, 60, 1)
		offsetX:SetValue(M.DB.auraBarsOffsetX or 0)
		offsetX:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsOffsetX = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		offsetX:SetFullWidth(true)
		container:AddChild(offsetX)

		local offsetY = AceGUI:Create("Slider")
		offsetY:SetLabel("Offset Y")
		offsetY:SetSliderValues(-60, 60, 1)
		offsetY:SetValue(M.DB.auraBarsOffsetY or 0)
		offsetY:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsOffsetY = math.floor(tonumber(val) or 0)
			M:ApplySettings()
		end)
		offsetY:SetFullWidth(true)
		container:AddChild(offsetY)

		local maxBars = AceGUI:Create("Slider")
		maxBars:SetLabel("Max Bars per Frame")
		maxBars:SetSliderValues(1, 20, 1)
		maxBars:SetValue(M.DB.auraBarsMax or M.DEFAULTS.auraBarsMax)
		maxBars:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsMax = math.floor(tonumber(val) or M.DEFAULTS.auraBarsMax)
			M:ApplySettings()
		end)
		maxBars:SetFullWidth(true)
		container:AddChild(maxBars)

		local playerOnly = AceGUI:Create("CheckBox")
		playerOnly:SetLabel("Only show auras I applied")
		playerOnly:SetValue(M.DB.auraBarsPlayerOnly)
		playerOnly:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.auraBarsPlayerOnly = val and true or false
			M:ApplySettings()
		end)
		playerOnly:SetFullWidth(true)
		container:AddChild(playerOnly)

		local defaultColor = AceGUI:Create("ColorPicker")
		defaultColor:SetLabel("Default Bar Color")
		if defaultColor.SetHasAlpha then defaultColor:SetHasAlpha(true) end
		local dc = M.DB.auraBarsDefaultColor or M.DEFAULTS.auraBarsDefaultColor
		defaultColor:SetColor(dc.r, dc.g, dc.b, dc.a or 1)
		defaultColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			M.DB.auraBarsDefaultColor = { r = r, g = g, b = b, a = a }
			M:ApplySettings()
		end)
		defaultColor:SetFullWidth(true)
		container:AddChild(defaultColor)

		local trackedHeading = AceGUI:Create("Heading")
		trackedHeading:SetText("Tracked Spells")
		trackedHeading:SetFullWidth(true)
		container:AddChild(trackedHeading)

		local overrideHint = AceGUI:Create("Label")
		overrideHint:SetFullWidth(true)
		overrideHint:SetText("Only spells in this list show as bars. Each color is used for that bar. Pre-seeded with class HoTs from Cell.")
		container:AddChild(overrideHint)

		local hotDefaults = M.HOT_DEFAULTS or {}
		local CLASS_ORDER = hotDefaults.CLASS_ORDER or { "OTHER" }
		local CLASS_LABELS = hotDefaults.CLASS_LABELS or { OTHER = "Other" }

		local function classOf(entry)
			if entry and M.IsValidHoTClass and M.IsValidHoTClass(entry.class) then
				return entry.class
			end
			if entry and M.ClassForHoTSpellID then
				return M.ClassForHoTSpellID(tonumber(entry.spellID))
			end
			return "OTHER"
		end

		M.DB.auraBarsList = M.DB.auraBarsList or {}
		local list = M.DB.auraBarsList

		local grouped = {}
		for i, entry in ipairs(list) do
			local class = classOf(entry)
			grouped[class] = grouped[class] or {}
			table.insert(grouped[class], { entry = entry, originalIndex = i })
		end

		local function renderEntryRow(class, entryRef)
			local entry = entryRef.entry
			local row = AceGUI:Create("SimpleGroup")
			row:SetLayout("Flow")
			row:SetFullWidth(true)

			local name = (M.GetAuraBarSpellName and M.GetAuraBarSpellName(entry.spellID)) or ("Spell " .. tostring(entry.spellID))
			local label = AceGUI:Create("Label")
			label:SetText(("|cFFFFFFFF%s|r\n|cFF888888ID %s|r"):format(name, tostring(entry.spellID)))
			label:SetWidth(220)
			row:AddChild(label)

			local color = AceGUI:Create("ColorPicker")
			if color.SetHasAlpha then color:SetHasAlpha(true) end
			local c = entry.color or { r = 0.3, g = 0.9, b = 0.4, a = 1 }
			color:SetColor(c.r, c.g, c.b, c.a or 1)
			color:SetWidth(120)
			color:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
				entry.color = { r = r, g = g, b = b, a = a }
			M:ApplySettings()
		end)
			row:AddChild(color)

			local remove = AceGUI:Create("Button")
			remove:SetText("Remove")
			remove:SetWidth(90)
			remove:SetCallback("OnClick", function()
				for i = #M.DB.auraBarsList, 1, -1 do
					if M.DB.auraBarsList[i] == entry then
						table.remove(M.DB.auraBarsList, i)
						break
					end
				end
			M:ApplySettings()
				refresh()
		end)
			row:AddChild(remove)

			container:AddChild(row)
		end

		for _, class in ipairs(CLASS_ORDER) do
			local entries = grouped[class]
			if entries and #entries > 0 then
				local section = AceGUI:Create("Heading")
				section:SetText(CLASS_LABELS[class] or class)
				section:SetFullWidth(true)
				container:AddChild(section)
				for _, entryRef in ipairs(entries) do
					renderEntryRow(class, entryRef)
				end
			end
		end

		local addHeading = AceGUI:Create("Heading")
		addHeading:SetText("Add Spell")
		addHeading:SetFullWidth(true)
		container:AddChild(addHeading)

		local addRow = AceGUI:Create("SimpleGroup")
		addRow:SetLayout("Flow")
		addRow:SetFullWidth(true)

		local classDropdownList = {}
		for _, class in ipairs(CLASS_ORDER) do
			classDropdownList[class] = CLASS_LABELS[class] or class
		end

		local _, defaultClass = UnitClass and UnitClass("player")
		if not (defaultClass and CLASS_LABELS[defaultClass]) then
			defaultClass = "OTHER"
		end

		local classDropdown = AceGUI:Create("Dropdown")
		classDropdown:SetLabel("Class")
		classDropdown:SetList(classDropdownList, CLASS_ORDER)
		classDropdown:SetValue(defaultClass)
		classDropdown:SetWidth(160)
		addRow:AddChild(classDropdown)

		local spellInput = AceGUI:Create("EditBox")
		spellInput:SetLabel("Spell ID or Name")
		spellInput:SetWidth(220)
		addRow:AddChild(spellInput)

		local addBtn = AceGUI:Create("Button")
		addBtn:SetText("Add")
		addBtn:SetWidth(80)
		addBtn:SetCallback("OnClick", function()
			local raw = spellInput:GetText()
			if not raw or raw:match("^%s*$") then return end
			local spellID
			if M.ResolveSpellInput then
				_, spellID = M.ResolveSpellInput(raw)
			else
				spellID = tonumber(raw)
			end
			if not spellID then
				print("|cFF9CDF95SimpleRaidFrames:|r Could not resolve spell '" .. tostring(raw) .. "'. Use the exact spell name or numeric ID.")
				return
			end
			M.DB.auraBarsList = M.DB.auraBarsList or {}
			for _, existing in ipairs(M.DB.auraBarsList) do
				if tonumber(existing.spellID) == spellID then
					refresh()
					return
				end
			end
			local class = classDropdown:GetValue() or defaultClass
			if not (M.IsValidHoTClass and M.IsValidHoTClass(class)) then
				class = "OTHER"
			end
			local seedColor = M.GetHoTClassColor and M.GetHoTClassColor(class)
				or { r = 0.3, g = 0.9, b = 0.4, a = 1 }
			table.insert(M.DB.auraBarsList, {
				spellID = spellID,
				class = class,
				color = { r = seedColor.r, g = seedColor.g, b = seedColor.b, a = seedColor.a or 1 },
			})
			M:ApplySettings()
			refresh()
		end)
		addRow:AddChild(addBtn)

		container:AddChild(addRow)

		local restoreBtn = AceGUI:Create("Button")
		restoreBtn:SetText("Restore Class Defaults")
		restoreBtn:SetWidth(220)
		restoreBtn:SetCallback("OnClick", function()
			if M.RestoreAuraBarsClassDefaults then
				M:RestoreAuraBarsClassDefaults()
			M:ApplySettings()
				refresh()
			end
		end)
		container:AddChild(restoreBtn)
	end

	local function buildRoleIconTab(container)
		container:SetLayout("List")

		local style = AceGUI:Create("Dropdown")
		style:SetLabel("Icon Style")
		style:SetList({ pixels = "Pixels", blizzard = "Blizzard" }, { "pixels", "blizzard" })
		style:SetValue(M.DB.roleIconStyle or "pixels")
		style:SetCallback("OnValueChanged", function(_, _, val)
			if val ~= "pixels" and val ~= "blizzard" then return end
			M.DB.roleIconStyle = val
			M:ApplySettings()
		end)
		style:SetFullWidth(true)
		container:AddChild(style)

		local classColor = AceGUI:Create("CheckBox")
		classColor:SetLabel("Color Role Icons by Class Color (Pixels only)")
		classColor:SetValue(M.DB.roleIconClassColor)
		classColor:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.roleIconClassColor = val and true or false
			M:ApplySettings()
		end)
		classColor:SetFullWidth(true)
		container:AddChild(classColor)

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

		local leaderClassColor = AceGUI:Create("CheckBox")
		leaderClassColor:SetLabel("Color Leader/Assist Icon by Class Color")
		leaderClassColor:SetValue(M.DB.leaderAssistClassColor)
		leaderClassColor:SetDisabled(not M.DB.leaderAssistEnabled)
		leaderClassColor:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.leaderAssistClassColor = val and true or false
			M:ApplySettings()
		end)
		leaderClassColor:SetFullWidth(true)
		container:AddChild(leaderClassColor)

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

		local statusClassColor = AceGUI:Create("CheckBox")
		statusClassColor:SetLabel("Color Status Icons by Class Color")
		statusClassColor:SetValue(M.DB.statusIndicatorClassColor)
		statusClassColor:SetDisabled(not M.DB.statusIndicatorsEnabled)
		statusClassColor:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.statusIndicatorClassColor = val and true or false
			M:ApplySettings()
		end)
		statusClassColor:SetFullWidth(true)
		container:AddChild(statusClassColor)
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

		local fgClassColor = AceGUI:Create("CheckBox")
		fgClassColor:SetLabel("Use Dark Class Color")
		fgClassColor:SetValue(M.DB.healthColorClassColor)
		fgClassColor:SetDisabled(not M.DB.healthColorEnabled)
		fgClassColor:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthColorClassColor = val and true or false
			container:ReleaseChildren()
			buildHealthTab(container)
			M:ApplySettings()
		end)
		fgClassColor:SetFullWidth(true)
		container:AddChild(fgClassColor)

		local fgClassDarkness = AceGUI:Create("Slider")
		fgClassDarkness:SetLabel("Class Color Darkness")
		fgClassDarkness:SetSliderValues(0, 1, 0.05)
		fgClassDarkness:SetIsPercent(true)
		fgClassDarkness:SetValue(M.DB.healthColorClassColorDarkness or M.DEFAULTS.healthColorClassColorDarkness)
		fgClassDarkness:SetDisabled(not M.DB.healthColorEnabled or not M.DB.healthColorClassColor)
		fgClassDarkness:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthColorClassColorDarkness = tonumber(val) or M.DEFAULTS.healthColorClassColorDarkness
			M:ApplySettings()
		end)
		fgClassDarkness:SetFullWidth(true)
		container:AddChild(fgClassDarkness)

		local fg = AceGUI:Create("ColorPicker")
		fg:SetLabel("Health Bar Color")
		if fg.SetHasAlpha then fg:SetHasAlpha(true) end
		local fgColor = M.DB.healthColor or M.DEFAULTS.healthColor
		fg:SetColor(fgColor.r, fgColor.g, fgColor.b, fgColor.a or 1)
		fg:SetDisabled(not M.DB.healthColorEnabled or M.DB.healthColorClassColor)
		fg:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			M.DB.healthColor = { r = r, g = g, b = b, a = a }
			M:ApplySettings()
		end)
		fg:SetFullWidth(true)
		container:AddChild(fg)

		local darkBorders = AceGUI:Create("CheckBox")
		darkBorders:SetLabel("Dark Borders")
		darkBorders:SetValue(M.DB.healthBlackBorders)
		darkBorders:SetCallback("OnValueChanged", function(_, _, val)
			M.DB.healthBlackBorders = val and true or false
			M:ApplySettings()
		end)
		darkBorders:SetFullWidth(true)
		container:AddChild(darkBorders)

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
	frame:SetTitle("Simple Raid Frames")
	frame:SetWidth(620)
	frame:SetHeight(560)
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
		{ text = "Aura Bars", value = "aura_bars" },
		{ text = "Indicators", value = "indicators" },
	})
	tabs:SetLayout("List")
	tabs:SetTitle(" ") -- add a bit of top padding so tabs don't overlap the close button
	tabs:SetCallback("OnGroupSelected", function(container, _, group)
		container:ReleaseChildren()
		container:SetLayout("Fill")
		local scroll = AceGUI:Create("ScrollFrame")
		scroll:SetLayout("List")
		scroll:SetFullWidth(true)
		scroll:SetFullHeight(true)
		container:AddChild(scroll)
		if group == "role" then
			buildRoleIconTab(scroll)
		elseif group == "health" then
			buildHealthTab(scroll)
		elseif group == "aura_bars" then
			buildAuraBarsTab(scroll)
		elseif group == "indicators" then
			buildIndicatorsTab(scroll)
		else
			buildNameTab(scroll)
		end
	end)
	frame:AddChild(tabs)
	tabs:SelectTab("name")

	if frame.frame and frame.closebutton then
		local resetBtn = CreateFrame("Button", nil, frame.frame, "UIPanelButtonTemplate")
		resetBtn:SetSize(140, 22)
		resetBtn:SetPoint("RIGHT", frame.closebutton, "LEFT", -8, 0)
		resetBtn:SetText("Reset All Settings")
		resetBtn:SetScript("OnClick", function()
			StaticPopup_Show("SRF_RESET_CONFIRM")
		end)
		frame._srfResetButton = resetBtn
	end

	M._settingsFrame = frame
	return frame
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["SRF_RESET_CONFIRM"] = {
	text = "Reset all SimpleRaidFrames settings to defaults?",
	button1 = "Reset",
	button2 = "Cancel",
	OnAccept = function()
		SimpleRaidFramesDB = {}
		M.EnsureDefaults()
		M:ApplySettings()
		local existing = M._settingsFrame
		M._settingsFrame = nil
		if existing and AceGUI then
			AceGUI:Release(existing)
		end
		M:OpenSettings()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

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
