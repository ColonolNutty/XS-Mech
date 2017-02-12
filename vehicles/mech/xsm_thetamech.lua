require "/vehicles/mech/xsm_mechapi.lua"
require "/vehicles/mech/xsm_mechdamage.lua"

--lpk: wrapper func for reading config params formats: glad vs cheerful
-- keep local lua copy for less overhead 
function configParameter(name,default)
  if vehicle.configParameter then
    return vehicle.configParameter(name,default)--Glad
  end
  return config.getParameter(name,default)--Cheerful
end

function projectilePowerAdjust(pPower)
  if vehicle.configParameter then return root.evalFunction("gunDamageLevelMultiplier", self.level) * pPower end
  local rv = root.evalFunction("weaponDamageLevelMultiplier", self.level) * pPower
--  sb.logInfo("Lv:%s pP:%s rv:%s",self.level,pPower,rv)
  return rv
end

function mechLevelAdjust(hp_or_armor)
  return root.evalFunction("shieldLevelMultiplier", self.level) * hp_or_armor
end

function init()
  self.active = false
  self.fireTimer = 0
  self.altFireTimer = 0
  self.altFireIntervalTimer = 0
  self.altFireCount = 0
--  tech.setVisible(false)
  animator.rotateGroup("guns", 0, true)
  self.mechFlipped = storage.mechFlipped or false
--  storage.mechFlipped = self.mechFlipped
  
  -- Activate/Deactivate
  self.mechState = "off" -- Possible values "off" "turningOn" "on" "turningOff"
  self.mechStateTimer = 0
  
  -- Init input variables
  self.holdingJump = false
  self.holdingUp = false
  self.holdingDown = false
  self.holdingAltFire = false
  
  -- Init boost variables
  self.boostPower = 0
  self.boostTimer = 0
  self.boostFireTimer = 0
  self.boostCharging = false
  self.boostFiring = false
  self.boostRecharging = false
	animator.setParticleEmitterActive("boostParticles1", false)
	animator.setParticleEmitterActive("boostParticles2", false)
	animator.setParticleEmitterActive("boostParticles3", false)
	animator.setParticleEmitterActive("boostParticles4", false)
	animator.setParticleEmitterActive("emergencyBoostParticles", false)
	animator.setParticleEmitterActive("hardLandingParticles", false)
	animator.setParticleEmitterActive("veryHardLandingParticles", false)
  self.boostEmergency = false
  
  -- Init landing variables
  self.fastDrop = false
  self.veryFastDrop = false
  self.movementSuppressed = false
  self.immobileTimer = 0
  
  -- Energy Usage
 self.energyCostPerSecond = 0--configParameter("energyCostPerSecond")
 self.energyCostPerPrimaryShot = configParameter("energyCostPerPrimaryShot")
 self.energyCostPerAltShot = configParameter("energyCostPerAltShot")
 self.energyCostPerBoost = configParameter("energyCostPerBoost")
 self.energyCostPerSecondEmergencyJets = configParameter("energyCostPerSecondEmergencyJets")
  
  -- Misc
--  local statusEffects = configParameter("statusEffects")
--  local mechCustomMovementParameters = configParameter("mechCustomMovementParameters")
--  local mechCustomTurningOnOffMovementParameters = copy(configParameter("mechCustomMovementParameters"))
--  mechCustomTurningOnOffMovementParameters.runSpeed = 0.0
--  mechCustomTurningOnOffMovementParameters.walkSpeed = 0.0
--  local mechTransformPositionChange = configParameter("mechTransformPositionChange")
--  local parentOffset = configParameter("parentOffset")
--  local mechCollisionTest = configParameter("mechCollisionTest")
  self.mechAimLimit = configParameter("mechAimLimit") * math.pi / 180
--  local mechFrontRotationPoint = configParameter("mechFrontRotationPoint")
--  local mechFrontFirePosition = configParameter("mechFrontFirePosition")
--  local mechBackRotationPoint = configParameter("mechBackRotationPoint")
--  local mechBackFirePosition = configParameter("mechBackFirePosition")
  self.mechLandingProjectile = configParameter("mechLandingProjectile")
  self.mechStartupTime = configParameter("mechStartupTime")
  self.mechShutdownTime = configParameter("mechShutdownTime")
  
  -- Primary Fire
  self.mechFireCycle = configParameter("mechFireCycle")
  self.mechFireAnimTime = configParameter("mechFireAnimTime")
  self.mechGunOffsetFront = configParameter("mechGunOffsetFront")
  self.mechGunOffsetBack = configParameter("mechGunOffsetBack")
  self.mechBeamProjectile = configParameter("mechBeamProjectile")  
  self.mechBeamLongProjectile = configParameter("mechBeamLongProjectile")  
  self.mechBeamEndProjectile = configParameter("mechBeamEndProjectile")
  self.mechBeamProjectileConfig = configParameter("mechBeamProjectileConfig")  
  self.mechBeamProjectilePower = configParameter("mechBeamProjectileConfig.power")  
  self.mechBeamEndProjectileConfig = configParameter("mechBeamEndProjectileConfig")
  self.mechBeamEndProjectilePower = configParameter("mechBeamEndProjectileConfig.power")
  
  self.mechBeamRange = configParameter("mechBeamRange")
  self.mechBeamPen = configParameter("mechBeamPen")
  self.mechBeamStep = configParameter("mechBeamStep")
  self.mechBeamLongStep = configParameter("mechBeamLongStep")
  self.mechBeamWidth = configParameter("mechBeamWidth")
  self.mechRecoilSpeed = configParameter("mechRecoilSpeed")
  self.mechRecoilPower = configParameter("mechRecoilPower")
  
  -- Alt Fire
  self.mechAltFireCycle = configParameter("mechAltFireCycle") 
  self.mechAltProjectile = configParameter("mechAltProjectile")
  self.mechAltProjectileConfig = configParameter("mechAltProjectileConfig")
  self.mechAltProjectileConfigPower = configParameter("mechAltProjectileConfig.power")
  self.mechAltFireShotInterval = configParameter("mechAltFireShotInterval")
  
  -- Boost parameters
  self.mechBoostPower = configParameter("mechBoostPower")
  self.mechBoostSpeed = configParameter("mechBoostSpeed")
  self.mechBoostDuration = configParameter("mechBoostDuration")
  self.mechBoostChargeCoefficient = configParameter("mechBoostChargeCoefficient")
  self.mechBoostChargeInterval = configParameter("mechBoostChargeInterval")
  self.mechBoostRechargeTime = configParameter("mechBoostRechargeTime")
  self.mechBoostAngle1 = configParameter("mechBoostAngle1") * math.pi / 180
  self.mechBoostAngle2 = configParameter("mechBoostAngle2") * math.pi / 180
  self.mechBoostAngle3 = configParameter("mechBoostAngle3") * math.pi / 180
  self.mechBoostAngle4 = configParameter("mechBoostAngle4") * math.pi / 180 
  self.mechEmergencyBoostSpeed = configParameter("mechEmergencyBoostSpeed")
  self.mechEmergencyBoostPower = configParameter("mechEmergencyBoostPower")
  
  self.level = math.max(1,world.threatLevel()) or configParameter("mechLevel",6)
  self.maxHealth = mechLevelAdjust(configParameter("maxHealth",1000))
  self.protection = mechLevelAdjust(configParameter("protection",50))
  self.materialKind = configParameter("materialKind")
  self.healthBarY = configParameter("healthBarYAdjust",0)
  
  --this comes in from the controller.
  self.ownerKey = configParameter("ownerKey")
  vehicle.setPersistent(self.ownerKey)

  --assume maxhealth
  if (storage.health) then
    animator.setAnimationState("torso", "open")--o
  else
    local startHealthFactor = configParameter("startHealthFactor")

    if (startHealthFactor == nil) then
        storage.health = self.maxHealth or 1
    else
       storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
    end    
    animator.setAnimationState("torso", "turnOff")--tof
  end
  animator.setAnimationState("movement", "sit")     
	animator.setAnimationState("emergencyJets", "off")	
	animator.setAnimationState("frontFiring", "off")	
	animator.setAnimationState("backFiring", "off")	
	animator.setAnimationState("boost", "off")	
	animator.setAnimationState("grenadeBox", "idle")

  --setup the store functionality  
  message.setHandler("store",
    function(_, _, ownerKey)
      if (self.ownerKey and self.ownerKey == ownerKey and self.driver == nil and animator.animationState("movement") == "sit") then
        animator.setAnimationState("torso", "turnOn")
        animator.setAnimationState("movement", "stand")
        self.mechState = "despawn"
        self.mechStateTimer = configParameter("mechShutdownTime")
--vehicle.destroy()
        return {storable = true, healthFactor = storage.health / self.maxHealth}
      else
        return {storable = false, healthFactor = storage.health / self.maxHealth}
      end
    end
  )

  -- setup energy
  self.energyToUse = {} -- <seatname : val> use val energy from seatname
  self.energyLocked = {} -- <seatname : bool> true when seat out of energy til regenerated

  message.setHandler("vehicle_setEnergyLocked",
    function(_,_,args) 
      local seats = {"seat"} -- rename to your seatname, add more seats if needed
      local ent = nil
      for _,s in ipairs(seats) do
        ent = vehicle.entityLoungingIn(s)
        if ent and world.entityUniqueId(ent) == args.ownerUid then 
          self.energyLocked[s] = args.block 
          return
        end
      end
    end
  )
    
  self.useSeatEnergy = function (seat, amountToUse) -- usage: self.useSeatEnergy("seat",9001)
    if amountToUse <= 0 then return end
    local ent = vehicle.entityLoungingIn(seat)
    if not ent then return end
    world.sendEntityMessage(ent,"vehicle_useSeatEnergy",{ownerUid = world.entityUniqueId(ent),amount = amountToUse})
  end
  
  local configseats = configParameter("loungePositions",{})
  for _,s in ipairs(configseats) do
    if not self.energyToUse[s] then self.energyToUse[s] = 0 end 
  end
  
  -- player armor & health extra
  -- dont forget update line at entityInSeat check
  self.baseProtection = self.protection
  self.baseMaxHealth = self.maxHealth
  self.damageMulti = 1
  
  message.setHandler("vehicle_setProtection",
    function(_,_,args)
      local seats = {"seat"}
      local ent = nil
      for _,s in ipairs(seats) do
        ent = vehicle.entityLoungingIn(s)
        if ent and world.entityUniqueId(ent) == args.ownerUid then 
--sb.logInfo("%s %s %s",args.pv,args.mh, args.dm)
          self.protection = math.min(99.9,math.max(args.pv, self.baseProtection))--pv:player protection value
          self.damageMulti = math.max(args.dm,1)--dm: (player damage multiplier - 1)/2
          local hpratio = storage.health/self.maxHealth
          self.maxHealth = math.max(args.mh*self.baseMaxHealth,self.baseMaxHealth)--mh:player maxhealth/100
          storage.health = self.maxHealth * hpratio
          return
        end
      end
    end
  )
  
  self.mechPilotProtection = function(entityInSeat)
    if entityInSeat then -- piloted, query player values
    world.sendEntityMessage(entityInSeat,"vehicle_queryProtection",{ownerUid = world.entityUniqueId(entityInSeat),vId=entity.id()})
    else -- unpiloted, reset values
    local hpr = storage.health/self.maxHealth
    self.maxHealth = self.baseMaxHealth
    storage.health = self.baseMaxHealth * hpr
    self.protection = self.baseProtection
    self.damageMulti = 1
    end
  end
  
end
--[[
function uninit()
  if self.active then
    local mechTransformPositionChange = configParameter("mechTransformPositionChange")
    mcontroller.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
    tech.setParentOffset({0, 0})
    self.active = false
    tech.setVisible(false)
    tech.setParentState()
    tech.setToolUsageSuppressed(false)
    mcontroller.controlFace(nil)
	
	-- Anims, particles
	animator.setParticleEmitterActive("boostParticles1", false)
	animator.setParticleEmitterActive("boostParticles2", false)
	animator.setParticleEmitterActive("boostParticles3", false)
	animator.setParticleEmitterActive("boostParticles4", false)
	animator.setParticleEmitterActive("emergencyBoostParticles", false)
	animator.setParticleEmitterActive("hardLandingParticles", false)
	animator.setParticleEmitterActive("veryHardLandingParticles", false)
	animator.setAnimationState("emergencyJets", "off")	
	animator.setAnimationState("frontFiring", "off")	
	animator.setAnimationState("backFiring", "off")	
	animator.setAnimationState("boost", "off")	
	animator.setAnimationState("torso", "idle")	
	animator.setAnimationState("grenadeBox", "idle")
	animator.setAnimationState("movement", "idle")
  end
end
]]
function input(args)

  -- Check if player is holding jump first
  if vehicle.controlHeld("seat", "jump") then
    self.holdingJump = true
  else
    self.holdingJump = false
  end
  
  -- Checks if jump was released
  if not self.jumpReleased then
    if self.holdingJump and not self.jumpPressed and not self.jumpReleased then
	  self.jumpPressed = true
    elseif not self.holdingJump and self.jumpPressed and not self.jumpReleased then
	  self.jumpReleased = true
	  self.jumpPressed = false
    if mcontroller.onGround() then 
      mcontroller.setYVelocity(30) -- jump velocity
      -- play jump sound
    end 
    end
  end
  
  if vehicle.controlHeld("seat", "up") then
    self.holdingUp = true
  else
    self.holdingUp = false
  end
  
  if vehicle.controlHeld("seat", "down") then
    self.holdingDown = true
    if self.holdingJump and mcontroller.onGround() then
      mcontroller.applyParameters({ignorePlatformCollision=true})
    end
  else
    self.holdingDown = false
    if mcontroller.parameters().ignorePlatformCollision then
      mcontroller.applyParameters({ignorePlatformCollision=false})
    end
  end

  if vehicle.controlHeld("seat", "left") and not self.boostFiring and not self.movementSuppressed then
    local mechHorizontalMovement = configParameter("mechHorizontalMovement")
    if not self.mechFlipped then -- backwalking
      mechHorizontalMovement = configParameter("mechHorizontalBackMovement")
    end
    if mcontroller.onGround() then 
    mcontroller.setXVelocity(-mechHorizontalMovement)
    else 
    mcontroller.approachXVelocity(-mechHorizontalMovement,500)
    end
    self.moving = true
    self.movingDirection = -1
  elseif vehicle.controlHeld("seat", "right") and not self.boostFiring and not self.movementSuppressed then
    local mechHorizontalMovement = configParameter("mechHorizontalMovement")
    if self.mechFlipped then -- backwalking
      mechHorizontalMovement = configParameter("mechHorizontalBackMovement")
    end
    if mcontroller.onGround() then 
    mcontroller.setXVelocity(mechHorizontalMovement)
    else 
    mcontroller.approachXVelocity(mechHorizontalMovement,500)
    end
    self.moving = true
    self.movingDirection = 1
  else
    self.moving = false
    mcontroller.approachXVelocity(0,100)
  end
 
  if vehicle.controlHeld("seat", "altFire") then
    self.holdingAltFire = true
  else
    self.holdingAltFire = false
  end

  if vehicle.controlHeld("seat", "primaryFire") then
    self.holdingPrimaryFire = true
  else
    self.holdingPrimaryFire = false
  end

  return nil
end

function spawnPenetratingBeam(startPoint, endPoint, penetration, stepSize, projectile, projectileConfig, projectilePen, projectilePenConfig)
  local dist = math.distance(startPoint, endPoint)
  local steps = math.floor(dist / stepSize)
  local normX = (endPoint[1] - startPoint[1]) / dist
  local normY = (endPoint[2] - startPoint[2]) / dist
  local penSteps = math.floor(penetration / stepSize)
  local pen = 0
  for i = 0, steps do
    local p1 = { normX * i * stepSize + startPoint[1], normY * i * stepSize + startPoint[2]}
	local p2 = { normX * (i + 1) * stepSize + startPoint[1], normY * (i + 1) * stepSize + startPoint[2]}
	if projectile ~= nil then            
    projectileConfig.speed = 1
	  world.spawnProjectile(projectile, math.midPoint(p1, p2), entity.id(), {normX, normY}, false, projectileConfig)
	end
	if world.lineTileCollision(p1, p2, {"Null","Block","Dynamic"}) then
	  pen = pen + 1
	  world.spawnProjectile(projectilePen, math.midPoint(p1, p2), entity.id(), {normX, normY}, false, projectilePenConfig)
	end
	if pen >= penSteps then
	  return math.midPoint(p1, p2)
	end	
  end
  world.spawnProjectile(projectilePen, endPoint, entity.id(), {normX, normY}, false, projectilePenConfig)
  return endPoint
end

function spawnDamageBeam(startPoint, endPoint, beamWidth, damageProjectile, damageProjectileConfig)
  local queryStart = startPoint
  local queryEnd = endPoint
  if startPoint[1] > endPoint[1] then
	queryStart = {endPoint[1], queryStart[2]}
	queryEnd = {startPoint[1], queryEnd[2]}
  end
  if startPoint[2] > endPoint[2] then
	queryStart = {queryStart[1], endPoint[2]}
	queryEnd = {queryEnd[1], startPoint[2]}
  end  
  local entityTable = world.entityQuery(queryStart, queryEnd)
  local enemiesHit = 0
  for _, v in ipairs(entityTable) do
	if world.entityType(v) == "player" or world.entityType(v) == "npc" or world.entityType(v) == "monster" then
	  local pos = world.entityPosition(v)
	  local distdX = startPoint[1] - endPoint[1]
	  local distdY = startPoint[2] - endPoint[2]
	  local d = math.abs( distdY * pos[1] - distdX * pos[2] + startPoint[1] * endPoint[2] - startPoint[2] * endPoint[1] ) / math.sqrt( (distdX)^2 + (distdY)^2 )
	  if d <= beamWidth / 2 then
		world.spawnProjectile(damageProjectile, pos, entity.id(), {0, 0}, false, damageProjectileConfig)
		enemiesHit = enemiesHit + 1
	  end
	end
  end
  return enemiesHit
end

function update(args)
  if self.mechState == "despawn" and self.mechStateTimer <= 0 then 
    vehicle.destroy() 
    return
  end

  local primaryShotsFired = 0
  local altShotsFired = 0
  local boostShotsFired = 0   
  
  local entityInSeat = vehicle.entityLoungingIn("seat")
  if entityInSeat then
    vehicle.setDamageTeam(world.entityDamageTeam(entityInSeat))
    input()
  else
    vehicle.setDamageTeam({type = "passive"})
    animator.rotateGroup("guns", 0, true)
  end
  if entityInSeat ~= self.driver then
    self.driver = entityInSeat
    self.mechPilotProtection(entityInSeat)
  end
    
--  if not self.active and args.actions["mechActivate"] and self.mechState == "off" and mcontroller.onGround() then
  if not self.active and self.driver ~= nil and self.mechState == "off" then
    -- mechCollisionTest[1] = mechCollisionTest[1] + mcontroller.position()[1]
    -- mechCollisionTest[2] = mechCollisionTest[2] + mcontroller.position()[2]
    -- mechCollisionTest[3] = mechCollisionTest[3] + mcontroller.position()[1]
    -- mechCollisionTest[4] = mechCollisionTest[4] + mcontroller.position()[2]
--    if (not world.rectCollision(mechCollisionTest)) then
      -- animator.burstParticleEmitter("mechActivateParticles")
      -- mcontroller.translate(mechTransformPositionChange)
      -- tech.setVisible(true)
	  -- animator.setAnimationState("movement", "idle")
      -- tech.setParentState("sit")
      -- tech.setToolUsageSuppressed(true)
	  
	  self.mechState = "turningOn"
	  self.mechStateTimer = self.mechStartupTime
	  self.immobileTimer = self.mechStartupTime
	  self.movementSuppressed = true
	  self.active = true
	  animator.playSound("mechStartupSound")
	  
	  local diff = world.distance(vehicle.aimPosition("seat"), mcontroller.position())
	  local aimAngle = math.atan(diff[2], diff[1])
	  self.mechFlipped = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2  
	  if self.mechFlipped then  
	    self.mechFlipped = true
	    animator.setAnimationState("arms", "gunBack")
	    animator.setAnimationState("armsAlt", "gunBack")  
	  else
	    self.mechFlipped = false
	    animator.setAnimationState("arms", "gunFront")
	    animator.setAnimationState("armsAlt", "gunFront")
	  end
--	  storage.mechFlipped = self.mechFlipped
--    else
      -- Make some kind of error noise
--    end
  elseif self.mechState == "turningOn" and self.mechStateTimer <= 0 then
    self.mechState = "on"
	self.mechStateTimer = 0
  elseif (self.active and self.driver == nil and self.mechState == "on") then
	self.mechState = "turningOff"
	self.mechStateTimer = self.mechShutdownTime
	animator.playSound("mechShutdownSound")
  elseif self.mechState == "turningOff" and self.mechStateTimer <= 0 then 
    -- animator.burstParticleEmitter("mechDeactivateParticles")
    -- mcontroller.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
    -- tech.setVisible(false)
    -- tech.setParentState()
    -- tech.setToolUsageSuppressed(false)
    -- tech.setParentOffset({0, 0})
	
	-- Input
	self.holdingJump = false
	
	-- Boost
	self.boostPower = 0
	self.boostTimer = 0
	self.boostCharging = false
	self.boostFiring = false
	self.boostFireTimer = 0
	self.boostRecharging = false
	self.boostEmergency = false	
	
	-- Landing
	self.fastDrop = false
	self.veryFastDrop = false
	self.movementSuppressed = false
	self.immobileTimer = 0
	
	-- Anims, particles
	animator.setParticleEmitterActive("boostParticles1", false)
	animator.setParticleEmitterActive("boostParticles2", false)
	animator.setParticleEmitterActive("boostParticles3", false)
	animator.setParticleEmitterActive("boostParticles4", false)
	animator.setParticleEmitterActive("emergencyBoostParticles", false)
	animator.setParticleEmitterActive("hardLandingParticles", false)
	animator.setParticleEmitterActive("veryHardLandingParticles", false)
	animator.setAnimationState("emergencyJets", "off")	
	animator.setAnimationState("frontFiring", "off")	
	animator.setAnimationState("backFiring", "off")	
	animator.setAnimationState("boost", "off")	
	animator.setAnimationState("torso", "open")	
	animator.setAnimationState("grenadeBox", "idle")
	animator.setAnimationState("movement", "sit")
	
	-- Weapons
	self.altFireIntervalTimer = 0
	self.altFireCount = 0
	
	self.mechState = "off"
	self.mechStateTimer = 0		
    self.active = false
  end
  
--  mcontroller.controlFace(nil)
  
  if self.mechStateTimer > 0 then
	self.mechStateTimer = self.mechStateTimer - script.updateDt()
  end

  local diff = world.distance(vehicle.aimPosition("seat"), mcontroller.position())
  local aimAngle = math.atan(diff[2], diff[1])
  local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2  
  local gunPosition = {0, 0}
  if flip then
	gunPosition = { mcontroller.position()[1] - self.mechGunOffsetBack[1], mcontroller.position()[2] + self.mechGunOffsetBack[2] }
  else
	gunPosition = { mcontroller.position()[1] + self.mechGunOffsetFront[1], mcontroller.position()[2] + self.mechGunOffsetFront[2] }
  end
  local diffCorrected = world.distance(vehicle.aimPosition("seat"), gunPosition)
  local gunAngle = math.atan(diffCorrected[2], diffCorrected[1])
	
  -- Basic animation
  if self.active then
--    mcontroller.controlParameters(mechCustomMovementParameters)

	if not self.boostFiring and self.fireTimer <= self.mechFireCycle - self.mechFireAnimTime and self.mechState == "on" then
		if flip then  
		  self.mechFlipped = true
		  animator.setAnimationState("arms", "gunBack")
		  animator.setAnimationState("armsAlt", "gunBack")  
		else
		  self.mechFlipped = false
		  animator.setAnimationState("arms", "gunFront")
		  animator.setAnimationState("armsAlt", "gunFront")
		end
	end	
--	storage.mechFlipped = self.mechFlipped
	if self.mechFlipped then
	  animator.setFlipped(true)
	  -- local nudge = tech.appliedOffset()
	  -- tech.setParentOffset({-parentOffset[1] - nudge[1], parentOffset[2] + nudge[2]})
	  -- mcontroller.controlFace(-1)

	  if gunAngle > 0 then
		gunAngle = math.max(gunAngle, math.pi - self.mechAimLimit)
	  else
		gunAngle = math.min(gunAngle, -math.pi + self.mechAimLimit)
	  end
	  
	  if self.mechState == "on" then
	    animator.rotateGroup("guns", math.pi - gunAngle)
	  else
	    animator.rotateGroup("guns", 0)
	  end
	  
	else
	  animator.setFlipped(false)
	  -- local nudge = tech.appliedOffset()
	  -- tech.setParentOffset({parentOffset[1] + nudge[1], parentOffset[2] + nudge[2]})
	  -- mcontroller.controlFace(1)

	  if gunAngle > 0 then
		gunAngle = math.min(gunAngle, self.mechAimLimit)
	  else
		gunAngle = math.max(gunAngle, -self.mechAimLimit)
	  end
	  
	  if self.mechState == "on" then
	    animator.rotateGroup("guns", gunAngle)
	  else
	    animator.rotateGroup("guns", 0)
	  end
	  
	end  
  end 
  
  -- Startup, shutdown, and active
  if self.mechState == "turningOn" then
--	mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)
	animator.setAnimationState("movement", "stand")
	animator.setAnimationState("torso", "turnOn")   
  elseif self.mechState == "turningOff" then
--	mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)
	animator.setAnimationState("movement", "sit")
	animator.setAnimationState("torso", "turnOff")	   
  elseif self.active and self.mechState == "on" then   
    
	-- Hard landings and very hard landings suppress movement temporarily
    if not mcontroller.onGround() then
      if mcontroller.velocity()[2] > 0 then
        animator.setAnimationState("movement", "jump")
		animator.setAnimationState("torso", "jump")
		self.fastDrop = false
	    self.veryFastDrop = false
      elseif not self.movementSuppressed then
        animator.setAnimationState("movement", "fall")
		animator.setAnimationState("torso", "jump")
		if mcontroller.velocity()[2] < -20 and mcontroller.velocity()[2] > -42 then
		  self.fastDrop = true
		elseif mcontroller.velocity()[2] <= -42 then
		  self.fastDrop = false
		  self.veryFastDrop = true
		end	
      end
	elseif self.fastDrop and mcontroller.onGround() then
      -- Hard landing
	  self.immobileTimer = 0.33 -- Temp
	  self.movementSuppressed = true
	  animator.setAnimationState("movement", "land")
	  animator.setAnimationState("torso", "land")
	  animator.burstParticleEmitter("hardLandingParticles")
    elseif self.veryFastDrop and mcontroller.onGround() then
      -- Very hard landing	  
	  self.immobileTimer = 0.66 -- Temp
	  self.movementSuppressed = true
	  animator.setAnimationState("movement", "landHard")
	  animator.setAnimationState("torso", "landHard")
	  animator.burstParticleEmitter("veryHardLandingParticles")
	  world.spawnProjectile(self.mechLandingProjectile, vec_add(mcontroller.position(), animator.partPoint("frontLeg","frontLegFoot")), entity.id(), {0, 0}, false)
	  world.spawnProjectile(self.mechLandingProjectile, vec_add(mcontroller.position(), animator.partPoint("backLeg","backLegFoot")), entity.id(), {0, 0}, false)
--    elseif (mcontroller.walking() or mcontroller.running()) and not self.fastDrop and not self.veryFastDrop and not self.movementSuppressed then
    elseif self.moving and not self.fastDrop and not self.veryFastDrop and not self.movementSuppressed then
	  self.fastDrop = false
	  self.veryFastDrop = false
      if self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1 then
        animator.setAnimationState("movement", "backWalk")
        animator.setAnimationState("torso", "backWalk")
      else
        animator.setAnimationState("movement", "walk")
        animator.setAnimationState("torso", "walk")
      end
	elseif self.fastDrop or self.veryFastDrop or self.movementSuppressed then
	  -- do nothing
    else
	  self.fastDrop = false
	  self.veryFastDrop = false
	  if self.holdingDown then
      animator.setAnimationState("movement", "sit")
	  else
      animator.setAnimationState("movement", "idle")
	  end
	  animator.setAnimationState("torso", "idle")
    end
	
	-- Landing Movement Suppression
	if self.immobileTimer > 0 then
	  self.immobileTimer = self.immobileTimer - script.updateDt()
	  -- world.callScriptedEntity(entity.id(), "mcontroller.setVelocity", {0,0})
	  mcontroller.approachXVelocity(0, 3000, true)
	  self.fastDrop = false
	  self.veryFastDrop = false
--	  mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)
	elseif self.movementSuppressed and self.immobileTimer <= 0 then
	  self.movementSuppressed = false
	  self.immobileTimer = 0
	  self.fastDrop = false
	  self.veryFastDrop = false
	end
	
	-- Emergency Jets fire automatically when falling too fast (for later: integrate energy usage?)
	if not mcontroller.onGround() and mcontroller.velocity()[2] <= -70 and not self.boostEmergency then
	  self.boostEmergency = true
	  animator.setParticleEmitterActive("emergencyBoostParticles", true)
	  animator.playSound("mechBoostIgniteSound")
	end
	if self.boostEmergency and mcontroller.velocity()[2] <= -40 then
	  animator.setAnimationState("emergencyJets", "on")
	  local eDiagX = math.cos(self.mechBoostAngle1 + math.pi/2)
	  local eDiagY = math.sin(self.mechBoostAngle1 + math.pi/2)
	  self.boostDirection = math.sign(math.cos(aimAngle))
	  mcontroller.approachVelocity({self.boostDirection * self.mechEmergencyBoostSpeed * eDiagX, self.mechEmergencyBoostSpeed * eDiagY}, self.mechEmergencyBoostPower, true, true)
	else
	  animator.setAnimationState("emergencyJets", "off")
	  self.boostEmergency = false
	  animator.setParticleEmitterActive("emergencyBoostParticles", false)
	end	
		
	-- Mech Boost
	-- Charges while holding alt fire, from level 1 to level 4.
	if self.holdingJump and not self.holdingDown and not self.boostFiring and not self.boostRecharging then
	  if not self.boostCharging then
	    -- Begin charging
--		if status.resource("energy") > self.energyCostPerBoost then
		if not self.energyLocked["seat"] then
		  self.boostCharging = true
		  self.boostPower = 1
		  self.boostTimer = self.mechBoostChargeInterval
		  animator.playSound("mechBoostChargeSound")
          boostShotsFired = boostShotsFired + 1		  
		end
      elseif self.boostTimer > 0 then
	    self.boostTimer = self.boostTimer - script.updateDt()
	  elseif self.boostTimer <= 0 and self.boostPower < 4 --and status.resource("energy") > self.energyCostPerBoost then
      and not self.energyLocked["seat"] then
    self.boostPower = self.boostPower + 1
		self.boostTimer = self.mechBoostChargeInterval
		animator.playSound("mechBoostChargeSound")
		boostShotsFired = boostShotsFired + 1
      end

	  -- Handle charging animation
	  if self.boostPower == 1 then
	    animator.setAnimationState("boost", "charge1")
	  elseif self.boostPower == 2 then
	    animator.setAnimationState("boost", "charge2")
	  elseif self.boostPower == 3 then
	    animator.setAnimationState("boost", "charge3")
	  elseif self.boostPower == 4 then
	    animator.setAnimationState("boost", "charge4")
	  end	  
	  
	elseif self.boostCharging and not self.holdingJump and not self.boostRecharging then
	  -- Ignite boosters
	  self.boostFireTimer = self.mechBoostDuration * ( self.boostPower + self.boostPower * self.mechBoostChargeCoefficient )
	  self.boostCharging = false
	  self.boostFiring = true
	  animator.playSound("mechBoostIgniteSound")
	  self.boostDirection = math.sign(math.cos(aimAngle))
	  
	  self.immobileTimer = 0
	  
	  if self.boostPower == 1 then
	    animator.setParticleEmitterActive("boostParticles1", true)
	  elseif self.boostPower == 2 then
	    animator.setParticleEmitterActive("boostParticles2", true)
	  elseif self.boostPower == 3 then
	    animator.setParticleEmitterActive("boostParticles3", true)
	  elseif self.boostPower == 4 then
	    animator.setParticleEmitterActive("boostParticles4", true)
	  end	  
	  
	elseif self.boostFiring and self.boostFireTimer > 0 and not self.boostRecharging then
	  -- Fire boosters
	  self.boostFireTimer = self.boostFireTimer - script.updateDt()
	  	  
	  local modifiedBoostSpeed = self.mechBoostSpeed * ( self.boostPower + self.boostPower * self.mechBoostChargeCoefficient )
	  local modifiedBoostPower = self.mechBoostPower * ( self.boostPower + self.boostPower * self.mechBoostChargeCoefficient )
	  
	  if self.boostPower == 1 then
	    local diagX = math.cos(self.mechBoostAngle1)
		local diagY = math.sin(self.mechBoostAngle1)
	    mcontroller.approachVelocity({self.boostDirection * self.mechBoostSpeed * diagX, self.mechBoostSpeed * diagY}, modifiedBoostPower, true, true)
		animator.setAnimationState("boost", "fire1")
	  elseif self.boostPower == 2 then
	    local diagX = math.cos(self.mechBoostAngle2)
		local diagY = math.sin(self.mechBoostAngle2)
	    mcontroller.approachVelocity({self.boostDirection * self.mechBoostSpeed * diagX, self.mechBoostSpeed * diagY}, modifiedBoostPower, true, true)
		animator.setAnimationState("boost", "fire2")
	  elseif self.boostPower == 3 then
	    local diagX = math.cos(self.mechBoostAngle3)
		local diagY = math.sin(self.mechBoostAngle3)
	    mcontroller.approachVelocity({self.boostDirection * self.mechBoostSpeed * diagX, self.mechBoostSpeed * diagY}, modifiedBoostPower, true, true)
		animator.setAnimationState("boost", "fire3")
	  elseif self.boostPower == 4 then
	    local diagX = math.cos(self.mechBoostAngle4)
		local diagY = math.sin(self.mechBoostAngle4)
	    mcontroller.approachVelocity({self.boostDirection * self.mechBoostSpeed * diagX, self.mechBoostSpeed * diagY}, modifiedBoostPower, true, true)
		animator.setAnimationState("boost", "fire4")
	  end	  
	  
	elseif self.boostFiring and self.boostFireTimer <= 0 and not self.boostRecharging then
	  -- Disable boosters, begin recharge period
	  self.boostFireTimer = self.mechBoostRechargeTime * ( 1 + self.boostPower * self.mechBoostChargeCoefficient )
	  self.boostFiring = false
	  self.boostRecharging = true 
	  animator.setParticleEmitterActive("boostParticles1", false)
	  animator.setParticleEmitterActive("boostParticles2", false)
	  animator.setParticleEmitterActive("boostParticles3", false)
	  animator.setParticleEmitterActive("boostParticles4", false)
	  
	  animator.playSound("mechBoostRechargeSound")
	  
	elseif self.boostRecharging and self.boostFireTimer > 0 then
	  -- Manage recharge timer, also set animation
	  self.boostFireTimer = self.boostFireTimer - script.updateDt()
	  if self.boostPower == 1 then
	    animator.setAnimationState("boost", "charge1")
	  elseif self.boostPower == 2 then
	    animator.setAnimationState("boost", "charge2")
	  elseif self.boostPower == 3 then
	    animator.setAnimationState("boost", "charge3")
	  elseif self.boostPower == 4 then
	    animator.setAnimationState("boost", "charge4")
	  end	  
	  
	elseif self.boostRecharging and self.boostFireTimer <= 0 then
	  -- Reset all and clean up
	  if self.boostPower == 1 then
		animator.setAnimationState("boost", "recharge1")
	  elseif self.boostPower == 2 then
		animator.setAnimationState("boost", "recharge2")
	  elseif self.boostPower == 3 then
		animator.setAnimationState("boost", "recharge3")
	  elseif self.boostPower == 4 then
		animator.setAnimationState("boost", "recharge4")
	  end 
	  
	  self.boostPower = 0
	  self.boostFireTimer = 0
	  self.boostCharging = false
	  self.boostTimer = 0	
	  self.boostRecharging = false
	  
	  animator.playSound("mechBoostReadySound")
	end
	
	-- Primary weapon system (Rail cannon)
	if self.fireTimer <= 0 then
--      if args.actions["mechFire"] and status.resource("energy") > self.energyCostPerPrimaryShot + 10 then
      if self.holdingPrimaryFire and not self.energyLocked["seat"] then
   self.mechBeamEndProjectileConfig.power = projectilePowerAdjust(self.mechBeamEndProjectilePower)
	    if self.mechFlipped then		  
		  local endPoint = vec_add(mcontroller.position(), {animator.partPoint("backGun","backGunFirePoint")[1] + self.mechBeamRange * math.cos(gunAngle), animator.partPoint("backGun","backGunFirePoint")[2] + self.mechBeamRange * math.sin(gunAngle) })
		  local u = spawnPenetratingBeam(vec_add(mcontroller.position(), animator.partPoint("backGun","backGunFirePoint")), endPoint, self.mechBeamPen, self.mechBeamLongStep, self.mechBeamLongProjectile, { power = 15 }, self.mechBeamEndProjectile, { power = 0 })
		  
		  -- spawnBeam(animator.partPoint("backGunFirePoint"), gunAngle, self.mechBeamRange, self.mechBeamPen, self.mechBeamStep, self.mechBeamLongStep, self.mechBeamProjectile, self.mechBeamLongProjectile, { power = 0 }, self.mechBeamEndProjectile, { power = 0 }, true)
		  spawnDamageBeam(vec_add(mcontroller.position(), animator.partPoint("backGun","backGunFirePoint")), u, self.mechBeamWidth, self.mechBeamEndProjectile, self.mechBeamEndProjectileConfig)
		  animator.setAnimationState("backFiring", "fire")
		  animator.setAnimationState("arms", "gunBackFiring")
		  animator.setAnimationState("armsAlt", "gunBackFiring")
		else
		  local endPoint = vec_add(mcontroller.position(), {animator.partPoint("frontGun","frontGunFirePoint")[1] + self.mechBeamRange * math.cos(gunAngle), animator.partPoint("frontGun","frontGunFirePoint")[2] + self.mechBeamRange * math.sin(gunAngle) })
		  local u = spawnPenetratingBeam(vec_add(mcontroller.position(), animator.partPoint("frontGun","frontGunFirePoint")), endPoint, self.mechBeamPen, self.mechBeamLongStep, self.mechBeamLongProjectile, { power = 15 }, self.mechBeamEndProjectile, { power = 0 })
		  
		  -- spawnBeam(animator.partPoint("frontGunFirePoint"), gunAngle, self.mechBeamRange, self.mechBeamPen, self.mechBeamStep, self.mechBeamLongStep, self.mechBeamProjectile, self.mechBeamLongProjectile, { power = 0 }, self.mechBeamEndProjectile, { power = 0 }, true)
      spawnDamageBeam(vec_add(mcontroller.position(), animator.partPoint("frontGun","frontGunFirePoint")), u, self.mechBeamWidth, self.mechBeamEndProjectile, self.mechBeamEndProjectileConfig)
		  animator.setAnimationState("frontFiring", "fire")
		  animator.setAnimationState("arms", "gunFrontFiring")
		  animator.setAnimationState("armsAlt", "gunFrontFiring")
		end	

		-- Recoil Force
		local recoilForceDirection = math.sign(-math.cos(aimAngle))
		mcontroller.approachXVelocity(self.mechRecoilSpeed * recoilForceDirection, self.mechRecoilPower, true)
		
		animator.playSound("mechFireSound")	
		primaryShotsFired = primaryShotsFired + 1		
		self.fireTimer = self.mechFireCycle
      end
	else
	  self.fireTimer = self.fireTimer - script.updateDt()
	end
	
	-- Alternate fire system (Grenade box)
	if self.altFireTimer <= 0 and self.altFireCount <= 0 then
	  animator.setAnimationState("grenadeBox", "idle")
      if self.holdingAltFire and not self.energyLocked["seat"] then --and status.resource("energy") > self.energyCostPerAltShot then
	    -- Prime box for firing
	    self.altFireIntervalTimer = 0
	    self.altFireCount = 1
		self.altFireTimer = self.mechAltFireCycle
		animator.setAnimationState("grenadeBox", "open")
	  end
	elseif self.altFireTimer <= 1.0 and self.altFireCount >= 5 then
	  -- Reloading animation, reset weapon system
	  animator.setAnimationState("grenadeBox", "close")
	  self.altFireCount = 0
	end
	-- Advance Timers
	if self.altFireTimer > 0 then
	  self.altFireTimer = self.altFireTimer - script.updateDt()
	end	
	if self.altFireIntervalTimer > 0 then
	  self.altFireIntervalTimer = self.altFireIntervalTimer - script.updateDt()	
	end
    -- Fire grenades	
	if self.altFireIntervalTimer <= 0 and self.altFireCount > 0 and self.altFireCount < 5 then
   self.mechAltProjectileConfig.power = projectilePowerAdjust(self.mechAltProjectileConfigPower)
	  self.altFireIntervalTimer = self.mechAltFireShotInterval
	  if self.altFireCount % 2 == 0 then
	    world.spawnProjectile(self.mechAltProjectile, vec_add(mcontroller.position(), animator.partPoint("backGrenadeBox","grenadeBoxFirePoint1")), entity.id(), {math.sign(math.cos(aimAngle)) * 0.754, -0.656}, false, self.mechAltProjectileConfig)
		animator.playSound("mechAltFireSound")	
	  else
	    world.spawnProjectile(self.mechAltProjectile, vec_add(mcontroller.position(), animator.partPoint("frontGrenadeBox","grenadeBoxFirePoint2")), entity.id(), {math.sign(math.cos(aimAngle)) * 0.731, -0.682}, false, self.mechAltProjectileConfig)
		animator.playSound("mechAltFireSound")		
	  end
	  
	  self.altFireCount = self.altFireCount + 1
	  altShotsFired = altShotsFired + 1
	end

  self.useSeatEnergy("seat",self.energyCostPerSecond * script.updateDt() + altShotsFired * self.energyCostPerAltShot + primaryShotsFired * self.energyCostPerPrimaryShot + self.energyCostPerBoost * boostShotsFired)

--  return 0 -- tech.consumeTechEnergy(self.energyCostPerSecond * script.updateDt() + altShotsFired * self.energyCostPerAltShot + primaryShotsFired * self.energyCostPerPrimaryShot + self.energyCostPerBoost * boostShotsFired)
  end
  updateMechDamageEffects(false)

  return 0
end
