local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local isFrameInRaidContainer = M.IsFrameInRaidContainer
local canMutateRaidFrames = M.CanMutateRaidFrames
local getFrameUnit = M.GetFrameUnit
local isSecretValue = M.IsSecretValue or issecretvalue or function() return false end

local function isTrue(value)
	return not isSecretValue(value) and value == true
end

local function applyRoleIconLayout(frame)
	if not frame or not frame.roleIcon then return end
	if not isFrameInRaidContainer(frame) then return end
	if not M.DB then return end
	if frame.optionTable and frame.optionTable.displayRoleIcon == false then return end
	if not canMutateRaidFrames(frame) then
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

local ROLE_ICON_BASE = "Interface\\AddOns\\SimpleRaidFrames\\media\\roles\\pixels\\"

local BLIZZARD_ROLE_ATLASES = {
	TANK    = { "roleicon-tiny-tank", "groupfinder-icon-role-large-tank" },
	HEALER  = { "roleicon-tiny-healer", "groupfinder-icon-role-large-heal" },
	DAMAGER = { "roleicon-tiny-dps", "groupfinder-icon-role-large-dps" },
}

local function applyBlizzardRoleAtlas(tex, role)
	local candidates = BLIZZARD_ROLE_ATLASES[role]
	if not tex or not candidates or not tex.SetAtlas then return false end
	for _, atlas in ipairs(candidates) do
		local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
		if info then
			tex:SetAtlas(atlas)
			return true
		end
	end
	return false
end

local function getRoleIconColor(unit, style)
	if style ~= "pixels" then return 1, 1, 1 end
	if not unit or not M.DB or not M.DB.roleIconClassColor then return 1, 1, 1 end
	local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
	if not okPlayer or isSecretValue(isPlayer) or not isPlayer then return 1, 1, 1 end
	local okClass, _, class = pcall(UnitClass, unit)
	if not okClass or isSecretValue(class) or not class then return 1, 1, 1 end
	local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if not color then return 1, 1, 1 end
	return color.r, color.g, color.b
end

local function applyRoleIconStyle(frame)
	if not M.DB or not frame or not frame.roleIcon or not isFrameInRaidContainer(frame) then return end
	local unit = getFrameUnit(frame)
	if not unit then return end
	if frame.optionTable and frame.optionTable.displayRoleIcon == false then return end

	local okVehicle, inVehicle = pcall(UnitInVehicle, unit)
	local okVehicleUI, hasVehicleUI = pcall(UnitHasVehicleUI, unit)
	if okVehicle and okVehicleUI and isTrue(inVehicle) and isTrue(hasVehicleUI) then
		applyRoleIconLayout(frame)
		return
	end
	if frame.optionTable and frame.optionTable.displayRaidRoleIcon and type(GetUnitFrameRaidRole) == "function" then
		local okRaidRole, raidRole = pcall(GetUnitFrameRaidRole, frame)
		if okRaidRole and not isSecretValue(raidRole) and raidRole then
			applyRoleIconLayout(frame)
			return
		end
	end
	local role
	if type(GetUnitFrameRole) == "function" then
		local okRole, frameRole = pcall(GetUnitFrameRole, frame)
		if okRole and not isSecretValue(frameRole) then
			role = frameRole
		end
	else
		local okRole, assignedRole = pcall(UnitGroupRolesAssigned, unit)
		if okRole and not isSecretValue(assignedRole) then
			role = assignedRole
		end
	end
	if (not role or role == "NONE") and unit == "player" then
		if type(GetSpecializationRole) == "function" and type(GetSpecialization) == "function" then
			local specIndex = GetSpecialization()
			if specIndex then
				local okSpecRole, specRole = pcall(GetSpecializationRole, specIndex)
				if okSpecRole and not isSecretValue(specRole) then
					role = specRole
				end
			end
		end
	end
	if role and role ~= "NONE" then
		local style = M.DB.roleIconStyle or "pixels"
		local applied = false
		if style == "blizzard" then
			applied = applyBlizzardRoleAtlas(frame.roleIcon, role)
		end
		if not applied then
			local icon
			if role == "TANK" then
				icon = ROLE_ICON_BASE .. "tank.png"
			elseif role == "HEALER" then
				icon = ROLE_ICON_BASE .. "healer.png"
			elseif role == "DAMAGER" then
				icon = ROLE_ICON_BASE .. "dps.png"
			end
			if icon then
				frame.roleIcon:SetTexture(icon)
				frame.roleIcon:SetTexCoord(0, 1, 0, 1)
				frame.roleIcon._srfIcon = icon
			end
		end
		if frame.roleIcon.SetVertexColor then
			local r, g, b = getRoleIconColor(unit, style)
			frame.roleIcon:SetVertexColor(r, g, b, 1)
		end
		if frame.roleIcon.SetDesaturated then
			frame.roleIcon:SetDesaturated(false)
		end
		frame.roleIcon:Show()
	end

	applyRoleIconLayout(frame)
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

M.ApplyRoleIconStyle = applyRoleIconStyle
