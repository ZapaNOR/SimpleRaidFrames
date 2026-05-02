local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local LSM = M.LSM
local getFrameUnit = M.GetFrameUnit
local isFrameInRaidContainer = M.IsFrameInRaidContainer

local barPool = setmetatable({}, { __mode = "k" })
local activePools = setmetatable({}, { __mode = "k" })
local barTicker
local auraBarEventFrame
local auraBarUnitEventsRegistered
local cachedAllowedSpells
local cachedAllowedCount
local cachedColorOverrides
local cachedTextureName
local cachedTexturePath
local cachedSpellNames = {}

local TICK_INTERVAL = 0.25

local auraScratch = {}

local function clearArray(t)
	for i = #t, 1, -1 do
		t[i] = nil
	end
end

local function resolveBarTexture()
	local name = M.DB and M.DB.auraBarsTexture
	if cachedTexturePath and cachedTextureName == name then
		return cachedTexturePath
	end
	if LSM and LSM.Fetch and name then
		local path = LSM:Fetch("statusbar", name, true)
		if path then
			cachedTextureName = name
			cachedTexturePath = path
			return path
		end
	end
	cachedTextureName = name
	cachedTexturePath = "Interface\\TargetingFrame\\UI-StatusBar"
	return cachedTexturePath
end

local function getSpellName(spellID)
	if not spellID then return nil end
	local cached = cachedSpellNames[spellID]
	if cached then return cached end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if info and info.name then
			cachedSpellNames[spellID] = info.name
			return info.name
		end
	end
	if GetSpellInfo then
		local name = GetSpellInfo(spellID)
		if name then
			cachedSpellNames[spellID] = name
			return name
		end
	end
	return nil
end

local function getColorOverrides()
	if cachedColorOverrides then return cachedColorOverrides end
	local map = {}
	local list = M.DB and M.DB.auraBarsList
	if type(list) ~= "table" then
		cachedColorOverrides = map
		return map
	end
	for _, entry in ipairs(list) do
		local id = type(entry) == "table" and tonumber(entry.spellID)
		if id then
			map[id] = entry
		end
	end
	cachedColorOverrides = map
	return map
end

local function getDefaultColor()
	local c = M.DB and M.DB.auraBarsDefaultColor
	if type(c) ~= "table" then
		return 0.3, 0.9, 0.4, 1.0
	end
	return c.r or 0.3, c.g or 0.9, c.b or 0.4, c.a or 1.0
end

local function ensureBarPool(frame)
	local pool = barPool[frame]
	if not pool then
		pool = { bars = {}, frame = frame, activeCount = 0, timedCount = 0 }
		barPool[frame] = pool
	end
	return pool
end

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

local function createBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
	bar:SetFrameStrata("MEDIUM")
	bar:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)
	bar:SetBackdrop({
		bgFile = WHITE_TEXTURE,
		edgeFile = WHITE_TEXTURE,
		edgeSize = 1,
	})
	bar:SetBackdropColor(0.07, 0.07, 0.07, 0.9)
	bar:SetBackdropBorderColor(0, 0, 0, 1)
	return bar
end

local function configureBar(bar, aura, override, now)
	local r, g, b, a
	if override and override.color then
		local c = override.color
		r, g, b, a = c.r or 1, c.g or 1, c.b or 0, c.a or 1
	else
		r, g, b, a = getDefaultColor()
	end
	local texturePath = resolveBarTexture()
	local reverseFill = M.DB and M.DB.auraBarsFillDirection == "RTL" or false
	if bar._texturePath ~= texturePath
		or bar._reverseFill ~= reverseFill
		or bar._r ~= r
		or bar._g ~= g
		or bar._b ~= b
		or bar._a ~= a then
		bar:SetStatusBarTexture(texturePath)
		bar:SetStatusBarColor(r, g, b, a)
		local statusTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
		if statusTex and statusTex.SetDrawLayer then
			statusTex:SetDrawLayer("BORDER", -1)
		end
		if bar.SetReverseFill then
			bar:SetReverseFill(reverseFill)
		end
		if bar.SetBackdropColor then
			bar:SetBackdropColor(r * 0.2, g * 0.2, b * 0.2, a)
			bar:SetBackdropBorderColor(0, 0, 0, 1)
		end
		bar._texturePath = texturePath
		bar._reverseFill = reverseFill
		bar._r = r
		bar._g = g
		bar._b = b
		bar._a = a
	end
	bar._spellID = aura and aura.spellID
	bar._expirationTime = aura and aura.expirationTime or 0
	bar._duration = aura and aura.duration or 0
	if bar._duration and bar._duration > 0 then
		if bar._minMaxDuration ~= bar._duration then
			bar:SetMinMaxValues(0, bar._duration)
			bar._minMaxDuration = bar._duration
		end
		local left = bar._expirationTime - now
		if left < 0 then left = 0 end
		bar:SetValue(left)
		return true
	else
		if bar._minMaxDuration ~= 0 then
			bar:SetMinMaxValues(0, 1)
			bar._minMaxDuration = 0
		end
		bar:SetValue(1)
	end
	return false
end

local function updateBarTimer(bar, now)
	local duration = bar._duration
	local expiration = bar._expirationTime
	if duration and duration > 0 and expiration and expiration > 0 then
		local left = expiration - now
		if left <= 0 then
			bar:SetValue(0)
			return false
		end
		bar:SetValue(left)
	end
	return true
end

local VALID_ANCHORS = {
	TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
}
local VALID_GROW = { UP = true, DOWN = true, LEFT = true, RIGHT = true }

local function getChainPoints(anchor, grow)
	local hasLeft = anchor:find("LEFT") ~= nil
	local hasTop = anchor:find("TOP") ~= nil
	if grow == "DOWN" then
		local side = hasLeft and "LEFT" or "RIGHT"
		return "TOP" .. side, "BOTTOM" .. side, 0, -1
	elseif grow == "UP" then
		local side = hasLeft and "LEFT" or "RIGHT"
		return "BOTTOM" .. side, "TOP" .. side, 0, 1
	elseif grow == "RIGHT" then
		local side = hasTop and "TOP" or "BOTTOM"
		return side .. "LEFT", side .. "RIGHT", 1, 0
	else
		local side = hasTop and "TOP" or "BOTTOM"
		return side .. "RIGHT", side .. "LEFT", -1, 0
	end
end

local function layoutBars(frame, activeCount)
	if activeCount == 0 then return end
	local pool = barPool[frame]
	if not pool then return end
	local width = tonumber(M.DB.auraBarsWidth) or 80
	local height = tonumber(M.DB.auraBarsHeight) or 4
	local spacing = tonumber(M.DB.auraBarsSpacing) or 1
	local offsetX = tonumber(M.DB.auraBarsOffsetX) or 0
	local offsetY = tonumber(M.DB.auraBarsOffsetY) or 0
	local anchor = M.DB.auraBarsAnchor
	if not VALID_ANCHORS[anchor] then anchor = "TOPLEFT" end
	local grow = M.DB.auraBarsGrow
	if not VALID_GROW[grow] then grow = "DOWN" end

	if pool.layoutCount == activeCount
		and pool.layoutWidth == width
		and pool.layoutHeight == height
		and pool.layoutSpacing == spacing
		and pool.layoutOffsetX == offsetX
		and pool.layoutOffsetY == offsetY
		and pool.layoutAnchor == anchor
		and pool.layoutGrow == grow then
		return
	end
	pool.layoutCount = activeCount
	pool.layoutWidth = width
	pool.layoutHeight = height
	pool.layoutSpacing = spacing
	pool.layoutOffsetX = offsetX
	pool.layoutOffsetY = offsetY
	pool.layoutAnchor = anchor
	pool.layoutGrow = grow

	local selfPoint, prevPoint, dx, dy = getChainPoints(anchor, grow)

	for i = 1, activeCount do
		local bar = pool.bars[i]
		bar:SetSize(width, height)
		bar:ClearAllPoints()
		if i == 1 then
			bar:SetPoint(anchor, frame, anchor, offsetX, offsetY)
		else
			local prev = pool.bars[i - 1]
			bar:SetPoint(selfPoint, prev, prevPoint, dx * spacing, dy * spacing)
		end
	end
end

local function hideBars(frame, fromIndex)
	local pool = barPool[frame]
	if not pool then return end
	for i = fromIndex or 1, #pool.bars do
		pool.bars[i]:Hide()
	end
	if not fromIndex or fromIndex <= 1 then
		pool.activeCount = 0
		pool.timedCount = 0
		pool.layoutCount = nil
		activePools[pool] = nil
	end
end

local function getAllowedSpells()
	if cachedAllowedSpells then return cachedAllowedSpells, cachedAllowedCount end
	local seen = {}
	local allowed = {}
	local count = 0
	local list = M.DB and M.DB.auraBarsList
	if type(list) ~= "table" then
		cachedAllowedSpells = allowed
		cachedAllowedCount = count
		return allowed, count
	end
	for _, entry in ipairs(list) do
		local id = type(entry) == "table" and tonumber(entry.spellID)
		if id and not seen[id] then
			seen[id] = true
			count = count + 1
			allowed[count] = id
		end
	end
	cachedAllowedSpells = allowed
	cachedAllowedCount = count
	return allowed, count
end

local function getAuraBySpellID(unit, spellID, playerOnly)
	if playerOnly then
		local spellName = getSpellName(spellID)
		if spellName and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
			return C_UnitAuras.GetAuraDataBySpellName(unit, spellName, "HELPFUL|PLAYER")
		end
		return nil
	end
	if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
		return C_UnitAuras.GetUnitAuraBySpellID(unit, spellID)
	end
	local spellName = getSpellName(spellID)
	if spellName and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
		return C_UnitAuras.GetAuraDataBySpellName(unit, spellName, "HELPFUL")
	end
end

local function addTrackedAura(auras, aura, spellID)
	local count = #auras + 1
	local entry = auras[count] or {}
	entry.spellID = spellID
	entry.duration = aura.duration or 0
	entry.expirationTime = aura.expirationTime or 0
	auras[count] = entry
end

local function collectHelpfulAurasUnsafe(unit, playerOnly, auras, spellIDs, spellCount)
	for i = 1, spellCount do
		local spellID = spellIDs[i]
		local aura = getAuraBySpellID(unit, spellID, playerOnly)
		if aura then
			addTrackedAura(auras, aura, spellID)
		end
	end
end

local function collectHelpfulAuras(unit, playerOnly, auras, spellIDs, spellCount)
	local ok = pcall(collectHelpfulAurasUnsafe, unit, playerOnly, auras, spellIDs, spellCount)
	if not ok then
		clearArray(auras)
	end
end

local function updateFrameAuraBars(frame)
	if not frame then return end
	if not M.DB or not M.DB.auraBarsEnabled then
		hideBars(frame)
		return
	end
	local unit = getFrameUnit(frame)
	if not unit or not isFrameInRaidContainer(frame) then
		hideBars(frame)
		return
	end

	local spellIDs, spellCount = getAllowedSpells()
	if spellCount == 0 then
		hideBars(frame)
		return
	end

	local auras = auraScratch
	clearArray(auras)
	collectHelpfulAuras(unit, M.DB.auraBarsPlayerOnly, auras, spellIDs, spellCount)

	local overrides = getColorOverrides()
	local maxBars = tonumber(M.DB.auraBarsMax) or 5
	if maxBars < 1 then maxBars = 1 end

	local pool = ensureBarPool(frame)
	local activeCount = 0
	local timedCount = 0
	local now = GetTime and GetTime() or 0
	for i = 1, math.min(#auras, maxBars) do
		local aura = auras[i]
		activeCount = activeCount + 1
		local bar = pool.bars[activeCount] or createBar(frame)
		pool.bars[activeCount] = bar
		if configureBar(bar, aura, overrides[aura.spellID], now) then
			timedCount = timedCount + 1
		end
		bar:Show()
	end

	pool.activeCount = activeCount
	pool.timedCount = timedCount
	if timedCount > 0 then
		activePools[pool] = true
	else
		activePools[pool] = nil
	end
	hideBars(frame, activeCount + 1)
	layoutBars(frame, activeCount)
	clearArray(auras)
end

local function forEachRaidFrame(fn)
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		CompactRaidFrameContainer:ApplyToFrames("normal", fn)
		CompactRaidFrameContainer:ApplyToFrames("mini", fn)
	end
	if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames and CompactPartyFrame:IsShown() then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", fn)
		CompactPartyFrame:ApplyFunctionToAllFrames("mini", fn)
	end
end

local function stopTicker()
	if barTicker then
		barTicker:Cancel()
		barTicker = nil
	end
end

local function tickerTick()
	if not M.DB or not M.DB.auraBarsEnabled then
		stopTicker()
		return
	end
	local now = GetTime and GetTime() or 0
	for pool in pairs(activePools) do
		local expired = false
		for i = 1, pool.activeCount or 0 do
			local bar = pool.bars[i]
			if bar:IsShown() then
				if not updateBarTimer(bar, now) then
					expired = true
				end
			end
		end
		if expired and pool.frame then
			updateFrameAuraBars(pool.frame)
		elseif (pool.timedCount or 0) == 0 then
			activePools[pool] = nil
		end
	end
	for _ in pairs(activePools) do
		return
	end
	stopTicker()
end

local function updateTickerState()
	if not M.DB or not M.DB.auraBarsEnabled then
		stopTicker()
		return
	end
	for _ in pairs(activePools) do
		if not barTicker and C_Timer and C_Timer.NewTicker then
			barTicker = C_Timer.NewTicker(TICK_INTERVAL, tickerTick)
		end
		return
	end
	stopTicker()
end

local function invalidateCaches()
	cachedAllowedSpells = nil
	cachedAllowedCount = nil
	cachedColorOverrides = nil
	cachedTextureName = nil
	cachedTexturePath = nil
	for _, pool in pairs(barPool) do
		pool.layoutCount = nil
		for _, bar in ipairs(pool.bars) do
			bar._texturePath = nil
			bar._reverseFill = nil
			bar._r = nil
			bar._g = nil
			bar._b = nil
			bar._a = nil
			bar._minMaxDuration = nil
		end
	end
end

local function hideAllBars()
	for frame in pairs(barPool) do
		hideBars(frame)
	end
	stopTicker()
end

local function registerUnitAuraEvents()
	if not auraBarEventFrame or auraBarUnitEventsRegistered then return end
	auraBarEventFrame:RegisterEvent("UNIT_AURA")
	auraBarUnitEventsRegistered = true
end

local function unregisterUnitAuraEvents()
	if not auraBarEventFrame or not auraBarUnitEventsRegistered then return end
	auraBarEventFrame:UnregisterEvent("UNIT_AURA")
	auraBarUnitEventsRegistered = false
end

local function updateUnitAuraBars(unit)
	local updated
	forEachRaidFrame(function(frame)
		local frameUnit = getFrameUnit(frame)
		if frameUnit == unit then
			updateFrameAuraBars(frame)
			updated = true
		end
	end)
	if updated then
		updateTickerState()
	end
end

local pendingUnits = {}
local unitUpdateScheduled

local function flushPendingUnits()
	unitUpdateScheduled = false
	for unit in pairs(pendingUnits) do
		pendingUnits[unit] = nil
		updateUnitAuraBars(unit)
	end
end

local function queueUnitUpdate(unit)
	if type(unit) ~= "string" then return end
	if unit ~= "player" and not unit:find("^party%d+$") and not unit:find("^raid%d+$") then
		return
	end
	pendingUnits[unit] = true
	if unitUpdateScheduled then return end
	unitUpdateScheduled = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0.05, flushPendingUnits)
	else
		flushPendingUnits()
	end
end

local function handleAuraBarsDisabled()
	unregisterUnitAuraEvents()
	hideAllBars()
	if M.SyncNativeBuffDisplayCVar then
		M.SyncNativeBuffDisplayCVar()
	end
end

local function handleAuraBarsEnabled()
	registerUnitAuraEvents()
	if M.SyncNativeBuffDisplayCVar then
		M.SyncNativeBuffDisplayCVar()
	end
	forEachRaidFrame(function(frame)
		updateFrameAuraBars(frame)
	end)
	updateTickerState()
end

local function maybeRefreshAuraBars()
	if not M.DB or not M.DB.auraBarsEnabled then
		handleAuraBarsDisabled()
	else
		handleAuraBarsEnabled()
	end
end

local function onUnitAura(unit)
	if not M.DB or not M.DB.auraBarsEnabled then return end
	queueUnitUpdate(unit)
end

local function ensureAuraBarHooks()
	if not auraBarEventFrame then
		auraBarEventFrame = CreateFrame("Frame")
		auraBarEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
		auraBarEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		auraBarEventFrame:SetScript("OnEvent", function(_, event, unit)
			if event == "UNIT_AURA" then
				onUnitAura(unit)
			else
				if M.RefreshAuraBars then M:RefreshAuraBars() end
			end
		end)
	end
end

function M:RefreshAuraBars()
	ensureAuraBarHooks()
	invalidateCaches()
	maybeRefreshAuraBars()
end

M.UpdateFrameAuraBars = updateFrameAuraBars
M.EnsureAuraBarHooks = ensureAuraBarHooks
M.GetAuraBarSpellName = getSpellName
