function widget:GetInfo()
	return {
		name      = "Resolution Scale Set",
		desc      = "Handles automatic detection of resolution scale.",
		author    = "Damgam",
		date      = "2026",
		layer     = -100000,
		enabled   = true,  --  loaded by default?
		handler   = true,
	}
end

local oldResolutionScale = 1
local refreshRate = 0
function widget:Update()
    refreshRate = refreshRate + 1
    if ((not done) or refreshRate%10 == 0)  then
        if (Spring.GetConfigInt("YResolution", 0) > 0 or Spring.GetConfigInt("YResolutionWindowed", 0) > 0) then
            if Spring.GetConfigInt("Fullscreen", 0) == 1 and Spring.GetConfigInt("WindowBorderless", 0) == 0 then
                local resolutionScale = Spring.GetConfigInt("YResolution", 1080)/1080 * Spring.GetConfigFloat("ChobbyAutomaticUIScaleMultiplier", 1)
                if resolutionScale ~= oldResolutionScale or (not done) then
                    oldResolutionScale = resolutionScale + 0
                    WG.Chobby.Configuration:SetUiScale(resolutionScale)
                    done = true
                end
            else
                local resolutionScale = Spring.GetConfigInt("YResolutionWindowed", 1080)/1080 * Spring.GetConfigFloat("ChobbyAutomaticUIScaleMultiplier", 1)
                if resolutionScale ~= oldResolutionScale or (not done) then
                    oldResolutionScale = resolutionScale + 0
                    WG.Chobby.Configuration:SetUiScale(resolutionScale)
                    done = true
                end
            end
        end
        refreshRate = 0
    end
end