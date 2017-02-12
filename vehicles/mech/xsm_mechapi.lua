if xsm_mechapi == nil then
xsm_mechapi = "loaded"
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--
-- mech API
-- 
-- some useful functions for mech tech.
--
--
--
--
--
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Get sign of number
-- @param x real number input
-- @returns -1 for negative number, 1 for positive
function math.sign(x)
  if x < 0 then
    return -1
  else
    return 1
  end
end

--- Find target in list
-- @param target
-- @param list
-- @returns true if in list, false if not
function table.exists(target, list)
  for _, v in ipairs(list) do
    if v == target then
	  return true
	end
  end
  return false
end

--- Find target in list
-- @param target
-- @param list
-- @returns index of target
function table.find(target, list)
  for _, v in ipairs(list) do
    if v == target then
	  return _
	end
  end
  return nil
end

--- Adds target to list, if target is not already in list. Does not work for sparse arrays.
-- @param target
-- @param list
-- @returns true if target was added, false otherwise
function table.nrAdd(target, list)
  if not table.exists(target, list) then
	list[#list + 1] = target
	return true
  end
  return false	
end

--- Remove target in list, shifting down any remaining keys
-- @param target
-- @param list
-- @returns true if deletion successful, false if otherwise
function table.delete(target, list)
  local u = table.find(target, list)
  if u ~= nil then
    table.remove(list, u)
	return true
  end
  return false
end

--- Find distance between two points
-- @param Coord1 (array) {x, y}
-- @param Coord1 (array) {x, y}
-- @returns distance, a positive value
function math.distance(coordA, coordB)
  return math.abs(math.sqrt((coordA[1]-coordB[1])^2 + (coordA[2]-coordB[2])^2))
end

--- Find the midpoint of two coords
-- @param coordA (array) {x, y}
-- @param coordB (array) {x, y}
-- @returns (array) {x, y} at midpoint between coordA and coordB
function math.midPoint(coordA, coordB)
  local u = { 0.5 * (coordB[1] + coordA[1]), 0.5 * (coordB[2] + coordA[2]) }
  return u
end

--- Find the direction from coordA to coordB
-- @param coordA (array) {x, y}
-- @param coordB (array) {x, y}
-- @returns (array) {x, y} a normalized vector
function math.getDir(coordA, coordB)
  local dist = math.distance(coordA, coordB)
  local u = {(coordB[1] - coordA[1])/dist,(coordB[2] - coordA[2])/dist}
  return u
end

--- Adds two vectors of size 2
-- @param vecA (array) {x, y}
-- @param vecB (array) {x, y}
-- @returns (array) {x, y} vector
function vec_add(vecA, vecB) -- ex vec.add
  u = {vecA[1] + vecB[1], vecA[2] + vecB[2]}
  return u
end

--- Finds dot product of two vectors of size 2
-- @param vecA (array) {x, y}
-- @param vecB (array) {x, y}
-- @returns scalar
function vec_dot(vecA, vecB) -- ex vec.dot
  u = vecA[1]*vecB[1] + vecA[2]*vecB[2]
  return u
end

-- Finds where a projection from startPoint to endPoint collides with an object
-- @param startPoint (array) {x, y}
-- @param endPoint (array) {x, y}
-- @param stepSize (float) how long collision steps are. 
-- @param projectile (string) (optional) what projectile to spawn at each successful step.
-- @returns (array) at collision {x, y} location, or endPoint if endPoint reached without resolution.
function progressiveLineCollision(startPoint, endPoint, stepSize, projectile)
  local dist = math.distance(startPoint, endPoint)
  local steps = math.floor(dist / stepSize)
  local normX = (endPoint[1] - startPoint[1]) / dist
  local normY = (endPoint[2] - startPoint[2]) / dist
  for i = 0, steps do
    local p1 = { normX * i * stepSize + startPoint[1], normY * i * stepSize + startPoint[2]}
	local p2 = { normX * (i + 1) * stepSize + startPoint[1], normY * (i + 1) * stepSize + startPoint[2]}
	if projectile ~= nil then            
	  world.spawnProjectile(projectile, math.midPoint(p1, p2), entity.id(), {normX, normY}, false,{speed=0})
	end
	if world.lineTileCollision(p1, p2, {"Null","Block","Dynamic"}) then
	  return math.midPoint(p1, p2)
	end
  end
  return endPoint
end

--- Swap left and right
-- @param side (string) "left" or "right"
-- @returns (string) "left" or "right" whichever is opposite
function otherSide(side)
  if side == "right" then
    return "left"
  else
    return "right"
  end
end

--- To copy tables
-- @param obj (table)
-- @param seen
-- @returns (table) copy of obj
function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end
end
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--
-- XSM mech framework
-- 
-- As a template for new mechs.
--
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--[[
-- Initialize. Sets up some important global variables.
function init()
  -- Basic Globals
  self.active = false -- Includes self.mechState values of "turningOn", "on", "turningOff"
  tech.setVisible(false)
  tech.rotateGroup("guns", 0, true)
  self.mechFlipped = false -- Keeps track of mech orientation
  self.mechState = "off" -- Possible values "off" "turningOn" "on" "turningOff"
  self.mechStateTimer = 0
  self.movementStatusEffects = {} -- Possible values: "immobile", "forceWalk", "grounded"
  
  -- Input Globals
  self.holdingJump = false
  self.holdingUp = false
  self.holdingDown = false
  self.holdingLeft = false
  self.holdingRight = false
  self.holdingFire = false
  self.holdingAltFire = false
  
  
end

function input()
  -- Input function here
end

--]]