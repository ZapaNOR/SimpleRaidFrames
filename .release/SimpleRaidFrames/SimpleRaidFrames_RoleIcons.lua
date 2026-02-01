local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local isFrameInRaidContainer = M.IsFrameInRaidContainer
local canMutateRaidFrames = M.CanMutateRaidFrames

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

M.ApplyRoleIconLayout = applyRoleIconLayout
M.ApplyRoleIconStyle = applyRoleIconStyle
