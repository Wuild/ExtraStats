-- Blizzard UI reference: WoW Forever 1.60.1.70009
-- https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_GamepadSmartNavigation/SmartNavigation.lua
-- Pinned HandleScroll function for offline compatibility testing; not packaged.
function SmartNavigationMixin:HandleScroll(nextButton, buttonScrollFrame)
	-- We will try to keep the target button in the middle of the scroll frame
	-- May want to add a way to "jump" out of a scroll frame
	local _, scrollMiddile = buttonScrollFrame:GetCenter();
	local _, buttonMiddle = nextButton:GetCenter();
	local scrollOffset = scrollMiddile - buttonMiddle;
	local logicalChange = false;

	if buttonScrollFrame:IsObjectType("ScrollFrame") then
		local newScrollOffset = buttonScrollFrame:GetVerticalScroll() + scrollOffset;
		local maxScroll = buttonScrollFrame:GetVerticalScrollRange();
		if newScrollOffset < 0 then
			newScrollOffset = 0;
		elseif newScrollOffset > maxScroll then
			newScrollOffset = maxScroll;
		end

		buttonScrollFrame:SetVerticalScroll(newScrollOffset);
	else
		if buttonScrollFrame:HasScrollableExtent() or buttonScrollFrame.ScrollTarget then
			local scrollPercentageOffset = 0;
			local scrollRange = buttonScrollFrame:GetDerivedScrollRange();
			if scrollRange > 0 then
				scrollPercentageOffset = scrollOffset / scrollRange;
			end
			local oldScrollPercentage = buttonScrollFrame:CalculateScrollPercentage();

			local newScrollPercentage = scrollPercentageOffset + oldScrollPercentage;

			if newScrollPercentage < 0 then
				newScrollPercentage = 0;
			elseif newScrollPercentage > 1 then
				newScrollPercentage = 1;
			end

			local oldElementData = nil;
			-- If this a button inside of a button we need a way to track back to the button if the scrollBox is moved
			local childMap = {};
			if nextButton.GetElementData then
				oldElementData = nextButton:GetElementData();
			else
				local element = nextButton;
				while element.GetElementData == nil do
					local elementParent = element:GetParent();
					local elementChildren = { elementParent:GetChildren() };

					for i, child in ipairs(elementChildren) do
						if child == element then
							table.insert(childMap, 1, i);
							break
						end
					end

					element = elementParent;

					if element == buttonScrollFrame then
						break;
					end
				end

				if element ~= buttonScrollFrame and element.GetElementData ~= nil then
					oldElementData = element:GetElementData();
				end
			end

			buttonScrollFrame:SetScrollPercentage(newScrollPercentage);
			-- The ScrollBox frames are in a pool and can change when scrolling
			-- We have to make sure the button is the same logical button after the scroll happens
			if oldElementData and newScrollPercentage ~= oldScrollPercentage then
				local newNextButton = buttonScrollFrame:FindFrame(oldElementData);

				nextButton = newNextButton;
				-- Some buttons have buttons inside of them so when updating to the correct logical button
				-- we have to find the correct child to focus again.
				if #childMap > 0 then
					for _, childIndex in ipairs(childMap) do
						local children = { nextButton:GetChildren() };
						nextButton = children[childIndex];
					end
				end
				logicalChange = true;
			end
		end
	end

	return nextButton, logicalChange;
end
