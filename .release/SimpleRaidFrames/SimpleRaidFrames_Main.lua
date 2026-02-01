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
			M.EnsureDefaults()
			M:CreateSettingsPanel()
			M:EnsureHooks()
		else
			M:EnsureHooks()
		end
	elseif event == "PLAYER_LOGIN" then
		M.EnsureDefaults()
		M:EnsureHooks()
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
		if M._pendingPartyVisibilityRefresh then
			M._pendingPartyVisibilityRefresh = false
			if M.RefreshPartyPlayerVisibility then
				M:RefreshPartyPlayerVisibility()
			end
		end
	end
end)
