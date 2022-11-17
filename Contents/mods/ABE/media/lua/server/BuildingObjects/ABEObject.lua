require "BuildingObjects/ISBuildUtil";
require "BuildingObjects/ISWoodenWall";
require "BuildingObjects/ISDoubleTileFurniture";
require "BuildingObjects/ISDoubleDoor";
require "bcUtils";

-- Hotfixes
buildUtil.setInfo = function(javaObject, ISItem) 
	if  javaObject.setCanPassThrough     then  javaObject:setCanPassThrough(ISItem.canPassThrough or false);        end
	if  javaObject.setCanBarricade       then  javaObject:setCanBarricade(ISItem.canBarricade or false);            end
	if  javaObject.setThumpDmg           then  javaObject:setThumpDmg(ISItem.thumpDmg or false);                    end
	if  javaObject.setIsContainer        then  javaObject:setIsContainer(ISItem.isContainer or false);              end
	if  javaObject.setIsDoor             then  javaObject:setIsDoor(ISItem.isDoor or false);                        end
	if  javaObject.setIsDoorFrame        then  javaObject:setIsDoorFrame(ISItem.isDoorFrame or false);              end
	if  javaObject.setCrossSpeed         then  javaObject:setCrossSpeed(ISItem.crossSpeed or 1);                    end
	if  javaObject.setBlockAllTheSquare  then  javaObject:setBlockAllTheSquare(ISItem.blockAllTheSquare or false);  end
	if  javaObject.setName               then  javaObject:setName(ISItem.name or "Object");                         end
	if  javaObject.setIsDismantable      then  javaObject:setIsDismantable(ISItem.dismantable or false);            end
	if  javaObject.setCanBePlastered     then  javaObject:setCanBePlastered(ISItem.canBePlastered or false);        end
	if  javaObject.setIsHoppable         then  javaObject:setIsHoppable(ISItem.hoppable or false);                  end
	if  javaObject.setModData            then  javaObject:setModData(bcUtils.cloneTable(ISItem.modData));           end
	if  javaObject.setIsThumpable        then  javaObject:setIsThumpable(ISItem.isThumpable or true);               end

	if ISItem.containerType and javaObject:getContainer() then
		javaObject:getContainer():setType(ISItem.containerType);
	end
	if ISItem.canBeLockedByPadlock then
		javaObject:setCanBeLockByPadlock(ISItem.canBeLockedByPadlock);
	end

	ISItem.javaObject = javaObject;
end

ABEObject = ISBuildingObject:derive("ABEObject");
ABEObject.addWoodXpOriginal = buildUtil.addWoodXp;
buildUtil.addWoodXp = function(ISItem)
	if ISItem.recipe then
		return;
	end
	ABEObject.addWoodXpOriginal(ISItem);
end

function ABEObject:create(x, y, z, north, sprite)
	local data = { } 
	local cell = getWorld():getCell();
	self.sq = cell:getGridSquare(x, y, z);

	data.x = x;
	data.y = y;
	data.z = z;
	data.cell = cell;
	data.north = north;
	data.sprite = sprite;
	data.done = false;

	self.javaObject = IsoThumpable.new(cell, self.sq, "empty", north, self);
	buildUtil.setInfo(self.javaObject, self);
	self.javaObject:setCanPassThrough(true);
	self.javaObject:setIsThumpable(false);
	self.javaObject:setBreakSound("breakdoor");
	  self.sq:AddSpecialObject(self.javaObject);
  
	self.javaObject:transmitCompleteItemToServer();
	  self.modData = self.javaObject:getModData();
	  self.modData.recipe = bcUtils.cloneTable(self.recipe);
	  self.modData.recipe.started = true;
	  self.modData.recipe.ingredientsAdded = {};
	  self.modData.recipe.x = x;
	  self.modData.recipe.y = y;
	  self.modData.recipe.z = z;
	  self.modData.recipe.north = north;
	  self.modData.recipe.sprite = sprite;
	  self.modData.recipe.data.nSprite = self.nSprite; -- cheating ;)
	  self.modData.recipe.usesLeft = {}
	  self.modData.abe = {};
	  -- let's add some properties if any are defined for adding
	  if (self.recipe.propertyAdd) then
		for name, value in pairs(self.recipe.propertyAdd) do
				self.modData.abe[name] = value;
		end
	  end
	  
	  for k,v in pairs(self.modData.recipe.ingredients) do
		  self.modData.recipe.ingredientsAdded[k] = 0;
	  end
	  
	  if self.recipe.use then
		  for item,amount in pairs(self.recipe.use) do
			  self.modData.recipe.usesLeft[item] = amount;
		  end
	  end
  
	  self.javaObject:setOverlaySprite(self:getSprite(), 0, 1, 1, 0.6, true);
	  self.occupiedSquares[self.sq] = self.javaObject

	  triggerEvent("AbeObjectCreate", self, data)
	  
	  self.modData.occupiedSquares = self.occupiedSquares;
	  self.javaObject:setModData(self.modData)
	  self.occupiedSquares = {} -- dirty hack, needed for multiple placements
  end

ABEObject.createISDoubleFurniture = function(self, data)
	if (self.recipe.resultClass == "ISDoubleTileFurniture") then
		-- name of our 2 sprites needed for the rest of the furniture
		local spriteAName = self.northSprite2;

		local xa = data.x;
		local ya = data.y;
		local z = data.z;

		-- we get the x and y of our next tile (depend if we're placing the furniture north or not)
		if data.north then
			ya = ya - 1;
		else
			-- if we're not north we also change our sprite
			spriteAName = self.sprite2;
			xa = xa - 1;
		end

		local squareA = data.cell:getGridSquare(xa, ya, z);
		self:createAbeThumpable(data.cell, squareA, spriteAName, data.north)
	end
end

ABEObject.createISDoubleDoor = function(self, data)
	if (self.recipe.resultClass == "ISDoubleDoor") then
		local square = self.sq
		local north = data.north
		local xa, ya = self:getSquare2Pos(square, north)
		local xb, yb = self:getSquare3Pos(square, north)
		local xc, yc = self:getSquare4Pos(square, north)
		local spriteAName = self.sprite2;
		local spriteBName = self.sprite3;
		local spriteCName = self.sprite4;
		-- if we're not north we also change our sprite
		if self.north then
			spriteAName = self.northSprite2;
			spriteBName = self.northSprite3;
			spriteCName = self.northSprite4;
		end
		local squareA = data.cell:getGridSquare(xa, ya, data.z)
		local squareB = data.cell:getGridSquare(xb, yb, data.z)
		local squareC = data.cell:getGridSquare(xc, yc, data.z)
		
		--self:createAbeThumpable(data.cell, square, data.sprite, data.north)
		self:createAbeThumpable(data.cell, squareA, spriteAName, data.north)
		self:createAbeThumpable(data.cell, squareB, spriteBName, data.north)
		self:createAbeThumpable(data.cell, squareC, spriteCName, data.north)

	end
end


ABEObject.createAbeThumpable = function(self, cell, square, sprite, north)
	local thumpable = IsoThumpable.new(cell, square, "empty", north, self);
	thumpable:setCanPassThrough(true)
	thumpable:setIsThumpable(false);
	thumpable:setOverlaySprite(sprite, 0, 1, 1, 0.6, true);
	thumpable:transmitCompleteItemToServer();
	square:AddSpecialObject(thumpable);

	self.occupiedSquares[square] = thumpable
	print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("isCanPassThrough")
	print(thumpable:isCanPassThrough())
	print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
end

function ABEObject:tryBuild(x, y, z) 
	-- We're just a 'plan' thingie with little to no effect on the world.
	-- Just place the item...
	-- What could possibly go wrong?
	self:create(x, y, z, self.north, self:getSprite());
end

function ABEObject:removeSelfFromSquares()
	for sq, thump in pairs(self.occupiedSquares) do
		if isClient() then
			sq:transmitRemoveItemFromSquare(thump);
		end
		sq:RemoveTileObject(thump);
	end
end

function ABEObject:new(recipe) 
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o.recipe = recipe;
	o.occupiedSquares = {}

	local images = ABE.getImages(getPlayer(), recipe);
	o:setSprite(images.west);
	o:setNorthSprite(images.north);
	o:setEastSprite(images.east);
	o:setSouthSprite(images.south);

	o.name = o.recipe.name;

	o.canBarricade = false;
	o.canPassThrough = true;
	o.blockAllTheSquare = false;
	o.dismantable = false;
	o.renderFloorHelper = recipe.data.renderFloorHelper or false;
	o.canBeAlwaysPlaced = recipe.data.canBeAlwaysPlaced or false;
	o.needToBeAgainstWall = recipe.data.needToBeAgainstWall or false;
	o.isValid = _G[recipe.resultClass].isValid;
	o.noNeedHammer = true; -- do not need a hammer to _start_, but maybe later to _build_

	local funcOverride = o.recipe.functionOverride
	-- let's override some functions if any are defined for overriding
	if (funcOverride) then
		for func, class in pairs(funcOverride) do
			o[func] = _G[class][func];
		end
	end

	local propAdd = o.recipe.propertyAdd
	-- let's add some properties if any are defined for adding
	if (propAdd) then
		for name, value in pairs(propAdd) do
			o[name] = value;
		end
	end

	--[[ print("~ sprite object check ~")
	print(o.sprite)
	print("~ spriteIndex object check ~")
	print(o.spriteIndex) ]]
	
	if (o.recipe.resultClass == "ISWoodenStairs") then
		o.getSquare2Pos = ISWoodenStairs.getSquare2Pos; -- dirty hack :-(
		o.getSquare3Pos = ISWoodenStairs.getSquare3Pos;
	end
	return o;
end 

function ABEObject:render(x, y, z, square) 
	local data = {};
	data.x = x;
	data.y = y;
	data.z = z;
	data.square = square;
	data.done = false;

	local images = ABE.getImages(getPlayer(), self.recipe);
	for k,v in pairs(images) do
		if not self[k] then
			self[k] = v
		end
	end

	self.recipe.resultClassRender(self, x, y, z, square);
end

LuaEventManager.AddEvent("WorldCraftingRender");
Events.WorldCraftingRender.Add(ABEObject.renderISDoubleFurniture);
Events.WorldCraftingRender.Add(ABEObject.renderISWoodenStairs);
Events.WorldCraftingRender.Add(ABEObject.renderISDoubleDoor);

LuaEventManager.AddEvent("AbeObjectCreate");
Events.AbeObjectCreate.Add(ABEObject.createISDoubleFurniture);
-- Events.AbeObjectCreate.Add(ABEObject.createISWoodenStairs);
Events.AbeObjectCreate.Add(ABEObject.createISDoubleDoor);
