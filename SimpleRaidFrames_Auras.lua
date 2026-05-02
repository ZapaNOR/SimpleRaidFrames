local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local function shouldHideNativeBuffs()
	return M.DB and M.DB.auraBarsEnabled and true or false
end

local function getCVarValue(cvar)
	if C_CVar and C_CVar.GetCVar then
		local ok, value = pcall(C_CVar.GetCVar, cvar)
		if ok then return value end
	end
	if GetCVar then
		local ok, value = pcall(GetCVar, cvar)
		if ok then return value end
	end
	return nil
end

local function setCVarValue(cvar, value)
	if C_CVar and C_CVar.SetCVar then
		local ok = pcall(C_CVar.SetCVar, cvar, value)
		if ok then return true end
	end
	if SetCVar then
		local ok = pcall(SetCVar, cvar, value)
		if ok then return true end
	end
	return false
end

local function syncNativeBuffDisplayCVar()
	if not M.DB then return end
	local cvar = "raidFramesDisplayBuffs"
	local current = getCVarValue(cvar)
	if current == nil then return end

	if shouldHideNativeBuffs() then
		if M.DB._nativeBuffsCVarOriginal == nil then
			M.DB._nativeBuffsCVarOriginal = tostring(current)
		end
		if tostring(current) ~= "0" then
			setCVarValue(cvar, "0")
		end
		return
	end

	local original = M.DB._nativeBuffsCVarOriginal
	if original ~= nil then
		if tostring(current) ~= tostring(original) then
			setCVarValue(cvar, tostring(original))
		end
		M.DB._nativeBuffsCVarOriginal = nil
	end
end

function M:RefreshRaidAuras()
	syncNativeBuffDisplayCVar()
end

M.SyncNativeBuffDisplayCVar = syncNativeBuffDisplayCVar
