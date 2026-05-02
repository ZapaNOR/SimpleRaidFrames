local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local function ensureUIDropDownMenuTaintGuard()
	if M._uidropDownMenuTaintGuarded then return end
	if type(hooksecurefunc) ~= "function" then return end
	if type(UIDropDownMenu_InitializeHelper) ~= "function" then return end
	if type(issecurevariable) ~= "function" then return end
	if (UIDROPDOWNMENU_OPEN_PATCH_VERSION or 0) >= 1 then
		M._uidropDownMenuTaintGuarded = true
		return
	end

	UIDROPDOWNMENU_OPEN_PATCH_VERSION = 1
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function(frame)
		if UIDROPDOWNMENU_OPEN_PATCH_VERSION ~= 1 then return end
		if UIDROPDOWNMENU_OPEN_MENU
			and UIDROPDOWNMENU_OPEN_MENU ~= frame
			and not issecurevariable(UIDROPDOWNMENU_OPEN_MENU, "displayMode") then
			UIDROPDOWNMENU_OPEN_MENU = nil
			local env, isSecure, prefix, i = _G, issecurevariable, " \0", 1
			repeat
				i, env[prefix .. i] = i + 1
			until isSecure("UIDROPDOWNMENU_OPEN_MENU")
		end
	end)

	M._uidropDownMenuTaintGuarded = true
end

M.EnsureUIDropDownMenuTaintGuard = ensureUIDropDownMenuTaintGuard
