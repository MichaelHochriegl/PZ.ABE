if not ABE then ABE = {} end

ABE.getImages = function(player, recipe)
	if recipe.images.any ~= nil then
		return recipe.images.any;
	end
	if recipe.images.west ~= nil then -- backwards compat
		return recipe.images;
	end
	for perk,levels in pairs(recipe.images) do
		local retVal = {};
		local perkLevel = player:getPerkLevel(Perks.FromString(perk));
		local oldLevel = -1;
		for level,images in pairs(levels) do
			if level > oldLevel and perkLevel >= level then
				retVal = images;
				level = oldLevel;
			end
		end
		return retVal;
	end
	return {}; -- huh?
end

ABE.convertTableToNumberedTable = function(tableToConvert)
	local result = { }
	if tableToConvert then
		for _, v in pairs(tableToConvert) do
			table.insert(result, v)
		end
	end

	return result
end