local ADDON_NAME = ...
local M = _G[ADDON_NAME]

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
end

local function printSlashHelp()
	print("|cFF9CDF95Simple|rRaidFrames: '|cFF9CDF95/srf|r' for in-game configuration.")
end

local function getCurrentPatchKey()
	local version, _, _, interfaceVersion = GetBuildInfo()
	if type(version) == "string" and version ~= "" then
		return version
	end
	if type(interfaceVersion) == "number" then
		return tostring(interfaceVersion)
	end
	return "unknown"
end

local function maybePrintSlashHelp()
	if type(SimpleRaidFramesDB) ~= "table" then
		printSlashHelp()
		return
	end
	local patchKey = getCurrentPatchKey()
	if SimpleRaidFramesDB.lastSlashHelpPatch ~= patchKey then
		SimpleRaidFramesDB.lastSlashHelpPatch = patchKey
		printSlashHelp()
	end
end

local LATE_HOOK_ADDONS = {
	Blizzard_CompactRaidFrames = true,
	Blizzard_CUFProfiles = true,
	Blizzard_SettingsDefinitions_Frame = true,
	Blizzard_UnitFrame = true,
}

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
			M.EnsureDefaults()
			M:CreateSettingsPanel()
			M:EnsureHooks()
		elseif LATE_HOOK_ADDONS[arg1] then
			M:EnsureHooks()
		end
	elseif event == "PLAYER_LOGIN" then
		M.EnsureDefaults()
		M:EnsureHooks()
		maybePrintSlashHelp()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if M._pendingRoleIconRefresh then
			M._pendingRoleIconRefresh = false
			M:RefreshRaidRoleIcons()
		end
		if M._pendingPartyVisibilityRefresh then
			M._pendingPartyVisibilityRefresh = false
			if M.RefreshPartyPlayerVisibility then
				M:RefreshPartyPlayerVisibility()
			end
		end
		if M._pendingPartySoloVisibilityRefresh then
			M._pendingPartySoloVisibilityRefresh = false
			if M.RefreshPartySoloVisibility then
				M:RefreshPartySoloVisibility()
			end
		end
	end
end)
