local ADDON_NAME = ...
local M = _G[ADDON_NAME]

local isFrameInRaidContainer = M.IsFrameInRaidContainer

local function shouldHideTooltip(frame)
	return M.DB
		and M.DB.hideRaidFrameTooltips
		and frame
		and isFrameInRaidContainer
		and isFrameInRaidContainer(frame)
end

local function hideRaidFrameTooltip(frame)
	if not shouldHideTooltip(frame) or not GameTooltip then
		return
	end

	frame.UpdateTooltip = nil
	GameTooltip:Hide()
end

function M:RefreshRaidFrameTooltips()
	if not (M.DB and M.DB.hideRaidFrameTooltips) or not GameTooltip or not GameTooltip.GetOwner then
		return
	end

	local owner = GameTooltip:GetOwner()
	if owner and shouldHideTooltip(owner) then
		GameTooltip:Hide()
	end
end

function M:EnsureRaidTooltipHooks()
	if type(UnitFrame_UpdateTooltip) == "function" and not M._unitFrameUpdateTooltipHooked then
		hooksecurefunc("UnitFrame_UpdateTooltip", hideRaidFrameTooltip)
		M._unitFrameUpdateTooltipHooked = true
	end

	if type(UnitFrame_OnEnter) == "function" and not M._unitFrameOnEnterTooltipHooked then
		hooksecurefunc("UnitFrame_OnEnter", hideRaidFrameTooltip)
		M._unitFrameOnEnterTooltipHooked = true
	end
end
