local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local CLASS_ORDER = {
	"DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER",
	"MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE",
	"SHAMAN", "WARLOCK", "WARRIOR", "OTHER",
}

local CLASS_LABELS = {
	DEATHKNIGHT = "Death Knight",
	DEMONHUNTER = "Demon Hunter",
	DRUID = "Druid",
	EVOKER = "Evoker",
	HUNTER = "Hunter",
	MAGE = "Mage",
	MONK = "Monk",
	PALADIN = "Paladin",
	PRIEST = "Priest",
	ROGUE = "Rogue",
	SHAMAN = "Shaman",
	WARLOCK = "Warlock",
	WARRIOR = "Warrior",
	OTHER = "Other",
}

-- Source: Cell's healer spell list (Cell/Defaults/Indicator_DefaultSpells.lua)
local CLASS_HOT_SPELLS = {
	DRUID = {
		8936,   -- Regrowth
		774,    -- Rejuvenation
		155777, -- Rejuvenation (Germination)
		33763,  -- Lifebloom
		188550, -- Lifebloom (Undergrowth)
		48438,  -- Wild Growth
		102351, -- Cenarion Ward
		102352, -- Cenarion Ward (HoT)
		391891, -- Adaptive Swarm
		145205, -- Efflorescence
		383193, -- Grove Tending
		439530, -- Symbiotic Blooms
	},

	EVOKER = {
		363502, -- Dream Flight
		370889, -- Twin Guardian
		364343, -- Echo
		355941, -- Dream Breath
		376788, -- Dream Breath (Echo)
		366155, -- Reversion
		367364, -- Reversion (Echo)
		373862, -- Temporal Anomaly
		378001, -- Dream Projection (PvP)
		373267, -- Lifebind
		395296, -- Ebon Might (self)
		395152, -- Ebon Might
		360827, -- Blistering Scales
		410089, -- Prescience
		406732, -- Spatial Paradox (self)
		406789, -- Spatial Paradox
		445740, -- Enkindle
		409895, -- Spiritbloom (Reverberations)
		410263, -- Inferno's Blessing
		410686, -- Symbiotic Bloom
		413984, -- Shifting Sands
	},

	MONK = {
		119611, -- Renewing Mist
		124682, -- Enveloping Mist
		325209, -- Enveloping Breath
		406139, -- Chi Cocoon (Yu'lon)
		406220, -- Chi Cocoon (Chi-Ji)
		450769, -- Aspect of Harmony
		450805, -- Purified Spirit
		467281, -- Healing Elixir
		115175, -- Soothing Mist
	},

	PALADIN = {
		53563,   -- Beacon of Light
		223306,  -- Bestow Faith
		148039,  -- Barrier of Faith
		156910,  -- Beacon of Faith
		200025,  -- Beacon of Virtue
		287280,  -- Glimmer of Light
		156322,  -- Eternal Flame
		431381,  -- Dawnlight
		388013,  -- Blessing of Spring
		388007,  -- Blessing of Summer
		388010,  -- Blessing of Autumn
		388011,  -- Blessing of Winter
		200654,  -- Tyr's Deliverance
		1244893, -- Beacon of the Savior
	},

	PRIEST = {
		139,     -- Renew
		200829,  -- Plea
		41635,   -- Prayer of Mending
		17,      -- Power Word: Shield
		194384,  -- Atonement
		77489,   -- Echo of Light
		372847,  -- Blessed Bolt
		1253593, -- Void Shield
	},

	SHAMAN = {
		974,    -- Earth Shield
		383648, -- Earth Shield (talent)
		61295,  -- Riptide
		382024, -- Earthliving Weapon
		375986, -- Primordial Wave
		444490, -- Hydrobubble
	},
}

local function getClassColor(class)
	local colors = _G.RAID_CLASS_COLORS or _G.CLASS_COLORS
	local c = colors and colors[class]
	if c then
		return { r = c.r, g = c.g, b = c.b, a = 1.0 }
	end
	return { r = 0.3, g = 0.9, b = 0.4, a = 1.0 }
end

local function spellInfoForID(spellID)
	if not spellID then return nil end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if info then
			return info.name, info.spellID or spellID
		end
	end
	if GetSpellInfo then
		local name, _, _, _, _, _, id = GetSpellInfo(spellID)
		if name then
			return name, id or spellID
		end
	end
	return nil, nil
end

local function resolveSpell(input)
	if input == nil then return nil, nil end
	if type(input) == "number" then
		return spellInfoForID(input)
	end
	local trimmed = tostring(input):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then return nil, nil end
	local asNumber = tonumber(trimmed)
	if asNumber then
		return spellInfoForID(asNumber)
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(trimmed)
		if info and info.spellID then
			return info.name or trimmed, info.spellID
		end
	end
	if GetSpellInfo then
		local name, _, _, _, _, _, id = GetSpellInfo(trimmed)
		if id then
			return name or trimmed, id
		end
	end
	return nil, nil
end

local spellIDToClass
local function buildClassLookup()
	if spellIDToClass then return spellIDToClass end
	spellIDToClass = {}
	for class, ids in pairs(CLASS_HOT_SPELLS) do
		for _, id in ipairs(ids) do
			spellIDToClass[id] = class
		end
	end
	return spellIDToClass
end

local function classForSpellID(spellID)
	if not spellID then return "OTHER" end
	local lookup = buildClassLookup()
	return lookup[spellID] or "OTHER"
end

local function isValidClass(class)
	return class and CLASS_LABELS[class] ~= nil
end

local function buildSeedEntries()
	local entries = {}
	for class, ids in pairs(CLASS_HOT_SPELLS) do
		local color = getClassColor(class)
		for _, id in ipairs(ids) do
			entries[#entries + 1] = {
				spellID = id,
				class = class,
				color = { r = color.r, g = color.g, b = color.b, a = color.a or 1 },
			}
		end
	end
	return entries
end

function M:SeedAuraBarsClassDefaults(force)
	local db = M.DB
	if not db then return end
	db.auraBarsList = db.auraBarsList or {}

	if not db._auraBarsClassDefaultsSeeded or force then
		local existing = {}
		for _, entry in ipairs(db.auraBarsList) do
			local id = tonumber(entry and entry.spellID)
			if id then existing[id] = entry end
		end
		for _, seed in ipairs(buildSeedEntries()) do
			if not existing[seed.spellID] then
				table.insert(db.auraBarsList, seed)
				existing[seed.spellID] = seed
			end
		end
		db._auraBarsClassDefaultsSeeded = true
	end

	for _, entry in ipairs(db.auraBarsList) do
		if entry and not isValidClass(entry.class) then
			entry.class = classForSpellID(tonumber(entry.spellID))
		end
	end
end

function M:RestoreAuraBarsClassDefaults()
	M:SeedAuraBarsClassDefaults(true)
end

M.HOT_DEFAULTS = {
	CLASS_ORDER = CLASS_ORDER,
	CLASS_LABELS = CLASS_LABELS,
	CLASS_HOT_SPELLS = CLASS_HOT_SPELLS,
}
M.GetHoTClassColor = getClassColor
M.ClassForHoTSpellID = classForSpellID
M.ResolveSpellInput = resolveSpell
M.IsValidHoTClass = isValidClass
