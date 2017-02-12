require "/vehicles/mech/xsm_mechapi.lua"
require "/vehicles/mech/xsm_mechdamage.lua"

--lpk: wrapper func for reading config params formats: glad vs cheerful
-- keep local lua copy for less overhead 
function configParameter(name,default)
  if vehicle.configParameter then
    return vehicle.configParameter(name,default)--Glad
  else
    return config.getParameter(name,default)--Cheerful
  end
end

function projectilePowerAdjust(pPower)
  if vehicle.configParameter then return root.evalFunction("gunDamageLevelMultiplier", self.level) * pPower * self.damageMulti end
  local rv = root.evalFunction("weaponDamageLevelMultiplier", self.level) * pPower * self.damageMulti
--  sb.logInfo("Lv:%s pP:%s rv:%s",self.level,pPower,rv)
  return rv
end

function mechLevelAdjust(hp_or_armor)
  return root.evalFunction("shieldLevelMultiplier", self.level) * hp_or_armor
end

function init()
  self.active = false
--  tech.setVisible(false)
  animator.rotateGroup("frontArm", 0, true)
  animator.rotateGroup("backArm", 0, true)
  animator.rotateGroup("frontArmPauldron", 0, true)
  animator.rotateGroup("frontHover", 0, true)
  animator.rotateGroup("backHover", 0, true)
  animator.rotateGroup("cannon", 0, true)
  self.holdingJump = false
  self.holdingUp = false
  self.holdingDown = false
  self.holdingLeft = false
  self.holdingRight = false
  self.holdingFire = false
  self.firePressed = false
  self.fireReleased = false
  self.holdingAltFire = false
  self.altFirePressed = false
  self.altFireReleased = false
  self.mechFlipped = false
  self.forceWalk = false
  self.lightTimer = 0
  
  -- Activate/Deactivate
  self.mechState = "off" -- Possible values "off" "turningOn" "on" "turningOff"
  self.mechStateTimer = 0
  
  -- Init landing variables
  self.fastDrop = false
  self.veryFastDrop = false
  self.veryVeryFastDrop = false
  self.movementSuppressed = false
  self.immobileTimer = 0
  
  -- Init jumping variables (short jump, dash, hover)
  self.isJumping = false
  self.hasJumped = false
  self.jumpPressed = false
  self.jumpReleased = false
  self.jumpTimer = 0
  self.jumpCoolDown = 0
  self.isDashing = false
  self.dashTimer = 0
  self.dashDirection = 0
  self.dashLastInput = 0
  self.dashTapLast = 0
  self.dashTapTimer = 0
  self.isHovering = false
  self.hoverTimer = 0
  self.backHopTimer = 0
  self.isSprinting = false
  
  -- Init weapon variables
  self.rightArmOccupied = false
  self.leftArmOccupied = false
  self.frontArmOccupied = false
  self.backArmOccupied = false
  self.torsoOccupied = false
  self.gunRotationSuppressed = false
  self.gunRotationOld = 0
  self.attackQueued = false
  self.attacking = false
  self.beamTimer = 0
  self.hGunTimer = 0
  self.fireTimer = 0
  self.hGunState = "idle"
  self.forceWalkGun = false
  self.mGunRecoilKick = 0
  self.parentAim = "right"

-- moved from update

  -- Energy usage
  self.energyCostPerSecond = 0--configParameter("energyCostPerSecond")
  self.energyCostPerSecondRunning = configParameter("energyCostPerSecondRunning")
  self.energyCostPerBackHop = configParameter("energyCostPerBackHop")
  self.energyCostPerSecondHover = configParameter("energyCostPerSecondHover")
  self.energyCostPerHover = configParameter("energyCostPerHover")
  self.energyCostPerBeamFire = configParameter("energyCostPerBeamFire")
  self.energyCostPerAltShot = configParameter("energyCostPerAltShot")
  
  -- Movement / misc
--  local mechCustomMovementParameters = configParameter("mechCustomMovementParameters")
--  local mechCustomTurningOnOffMovementParameters = copy(configParameter("mechCustomMovementParameters"))
--  mechCustomTurningOnOffMovementParameters.runSpeed = 0.0
--  mechCustomTurningOnOffMovementParameters.walkSpeed = 0.0
  -- local mechTransformPositionChange = configParameter("mechTransformPositionChange")
  -- local parentOffset = configParameter("parentOffset")
  -- local mechCollisionTest = configParameter("mechCollisionTest")
  -- local mechBackwardSpeed = configParameter("mechBackwardSpeed")
  -- local mechWalkSlowSpeed = configParameter("mechWalkSlowSpeed")
  self.mechSkiddingFriction = configParameter("mechSkiddingFriction")
  self.mechBoostAirForce = configParameter("mechBoostAirForce")
  self.mechLandingProjectile = configParameter("mechLandingProjectile")
  self.mechLandingLocation = configParameter("mechLandingLocation")
  self.mechStartupTime = configParameter("mechStartupTime")
  self.mechShutdownTime = configParameter("mechShutdownTime")
  
  -- Jump, Dash, Boost
  self.jumpDuration = configParameter("jumpDuration")
  self.jumpSpeed = configParameter("jumpSpeed")
  self.jumpControlForce = configParameter("jumpControlForce")
  self.dashDuration = configParameter("dashDuration")
  self.dashSpeed = configParameter("dashSpeed")
  self.dashControlForce = configParameter("dashControlForce")
  self.dashAngle = configParameter("dashAngle") * math.pi / 180
  self.backHopDuration = configParameter("backHopDuration")
  self.backHopSpeed = configParameter("backHopSpeed")
  self.backHopControlForce = configParameter("backHopControlForce")
  self.backHopAngle = configParameter("backHopAngle") * math.pi / 180
  self.backHopCooldown = configParameter("backHopCooldown")
  self.hoverSpeed = configParameter("hoverSpeed")
  self.hoverControlForce = configParameter("hoverControlForce")
  
  -- Equipment
  self.mechLeftEquip = configParameter("mechLeftEquip")
  self.mechLeftAnimation = configParameter("mechLeftAnimation")
  self.mechRightEquip = configParameter("mechRightEquip")
  self.mechRightAnimation = configParameter("mechRightAnimation")
  self.mechEquip = {self.mechLeftEquip, self.mechRightEquip}
  
  -- Torso cannon
  self.mechCannonAimLimit = configParameter("mechCannonAimLimit") * math.pi / 180
  self.mechCannonFireCone = configParameter("mechCannonFireCone") * math.pi / 180
  self.mechCannonFireCycle = configParameter("mechCannonFireCycle")
  self.mechCannonProjectile = configParameter("mechCannonProjectile")
  self.mechCannonProjectileConfig = configParameter("mechCannonProjectileConfig")
  self.mechCannonProjectilePower = configParameter("mechCannonProjectileConfig.power")
  
  -- Heat beam
  self.mechGunReadyTime = configParameter("mechGunReadyTime")
  self.mechGunHolsterTime = configParameter("mechGunHolsterTime")
  self.mechGunIdleTime = configParameter("mechGunIdleTime")
  self.mechGunFireTime = configParameter("mechGunFireTime")
  self.mechGunCoolingTime = configParameter("mechGunCoolingTime")
  self.mechGunSuppAngularVel = configParameter("mechGunSuppAngularVel") * math.pi / 180
  self.mechGunLightProjectile = configParameter("mechGunLightProjectile")
  self.mechGunBeamMaxRange = configParameter("mechGunBeamMaxRange")
  self.mechGunBeamStep = configParameter("mechGunBeamStep")
  self.mechGunBeamUpdateTime = configParameter("mechGunBeamUpdateTime")
  self.mechGunBeamEndProjectile = configParameter("mechGunBeamEndProjectile")
  self.mechGunBeamHitProjectile = configParameter("mechGunBeamHitProjectile")
  self.mechGunBeamSmokeProkectile = configParameter("mechGunBeamSmokeProkectile")
  self.mechGunBeamWidth = configParameter("mechGunBeamWidth")
  self.mechGunAimLimit = configParameter("mechGunAimLimit") * math.pi / 180
  self.mechGunRotationRadius = configParameter("mechGunRotationRadius")
  self.mechGunBeamUpperDamage = configParameter("mechGunBeamUpperDamage")
  self.mechGunBeamLowerDamage = configParameter("mechGunBeamLowerDamage")

  self.mechGunRecoilSpeed = configParameter("mechGunRecoilSpeed")
  self.mechGunRecoilPower = configParameter("mechGunRecoilPower")
  self.mechGunRecoilKick = configParameter("mechGunRecoilKick") * math.pi / 180
  

  self.level = math.max(1,world.threatLevel()) or configParameter("mechLevel",6)
  self.maxHealth = mechLevelAdjust(configParameter("maxHealth",1000))
  self.protection = mechLevelAdjust(configParameter("protection",50))
  self.materialKind = configParameter("materialKind","robotic")
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
  	animator.setAnimationState("backArmAltMovement", "idle")
    animator.setAnimationState("frontArmAltMovement", "off")
    animator.setAnimationState("backArmMovement", "off")
    animator.setAnimationState("frontArmMovement", "idle")
    animator.setAnimationState("frontArmPauldronMovement", "idle")
    animator.setAnimationState("frontFiring", "off")
    animator.setAnimationState("backFiring", "off")
    animator.setAnimationState("frontLaser", "off")
    animator.setAnimationState("backLaser", "off")


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
      end)

  -- setup energy
  self.energyToUse = {} -- <seatname : val> use val energy from seatname
  self.energyLocked = {} -- <seatname : bool> true when seat out of energy til regenerated
  self.configseats = configParameter("loungePositions",{})
  
  for _,s in ipairs(self.configseats) do
    if not self.energyToUse[s] then self.energyToUse[s] = 0 end 
--    if not self.energyLocked[s] then self.energyLocked[s] = false end 
  end

  message.setHandler("vehicle_setEnergyLocked",
    function(_,_,args) 
      local seats = {"seat"}
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
	
	-- Animation / Particles
	animator.setAnimationState("movement", "idle")
	animator.setAnimationState("jetFlame", "off")
	animator.setAnimationState("jetPack", "off")
	animator.setAnimationState("hoverFlame", "off")
	animator.setAnimationState("crotch", "turnOn")
	animator.setAnimationState("torso", "idle")
	animator.setAnimationState("backArmAltMovement", "off")
	animator.setAnimationState("frontArmAltMovement", "off")
	animator.setAnimationState("backArmMovement", "off")
	animator.setAnimationState("frontArmMovement", "off")
	animator.setAnimationState("frontArmPauldronMovement", "off")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontLaser", "off")
	animator.setAnimationState("backLaser", "off")
	animator.setParticleEmitterActive("hoverFParticles", false)
	animator.setParticleEmitterActive("hoverParticles", false)
	animator.setParticleEmitterActive("hoverBParticles", false)
	animator.setParticleEmitterActive("skidParticles", false)
	animator.setParticleEmitterActive("veryHardLandingParticles", false)
	animator.setParticleEmitterActive("hardLandingParticles", false)
	animator.setParticleEmitterActive("mechSteam2", false)
	animator.setParticleEmitterActive("mechSteam", false)
	
  end
end
]]
function input(args)
  self.moving = false
  self.running = false
  -- Check if player is holding jump first
  if vehicle.controlHeld("seat", "jump")  then
    self.holdingJump = true
  else--if not args.moves["jump"] then
    self.holdingJump = false
  end
  
  -- Checks if jump was released
  if not self.jumpReleased then
    if self.holdingJump and not self.jumpPressed and not self.jumpReleased then
	  self.jumpPressed = true
    elseif not self.holdingJump and self.jumpPressed and not self.jumpReleased then
	  self.jumpReleased = true
	  self.jumpPressed = false
    end
  end
  
  -- Check if player is holding fire
  if vehicle.controlHeld("seat", "primaryFire") then
    self.holdingFire = true
  else--if not args.moves["primaryFire"] then
    self.holdingFire = false
  end 
 
  -- Checks if fire was released
  if not self.fireReleased then
    if self.holdingFire and not self.firePressed and not self.fireReleased then
	  self.firePressed = true
    elseif not self.holdingFire and self.firePressed and not self.fireReleased then
	  self.fireReleased = true
	  self.firePressed = false
    end
  end
  
  -- Check if player is holding altFire
  if vehicle.controlHeld("seat", "altFire") then
    self.holdingAltFire = true
  else--if not args.moves["altFire"] then
    self.holdingAltFire = false
  end 
 
  -- Checks if altFire was released
  if not self.altFireReleased then
    if self.holdingAltFire and not self.altFirePressed and not self.altFireReleased then
	  self.altFirePressed = true
    elseif not self.holdingAltFire and self.altFirePressed and not self.altFireReleased then
	  self.altFireReleased = true
	  self.altFirePressed = false
    end
  end
  
  -- Checks if player is holding other buttons
  if vehicle.controlHeld("seat", "up") then
    self.holdingUp = true
  else--if not args.moves["up"] then
    self.holdingUp = false
  end
  
  if vehicle.controlHeld("seat", "down") then
    self.holdingDown = true
    if mcontroller.onGround() and self.holdingJump then
      mcontroller.applyParameters({ignorePlatformCollision=true})
    end
  else--if not args.moves["down"] then
    self.holdingDown = false
    if mcontroller.parameters().ignorePlatformCollision then
      mcontroller.applyParameters({ignorePlatformCollision=false})
    end
  end
  
  if vehicle.controlHeld("seat", "left") then
    self.holdingLeft = true
  else--if not args.moves["left"] then
    self.holdingLeft = false
  end
  
  if vehicle.controlHeld("seat", "right") then
    self.holdingRight = true
  else--if not args.moves["right"] then
    self.holdingRight = false
  end
  
  if not self.movementSuppressed and (self.holdingLeft or self.holdingRight) and not self.isDashing then
    local ani = animator.animationState("movement")-- walk/run/backWalk/walkSlow=backWalkSlow
    local speed = 0
    self.movingDirection = 1
    if ani == "walkSlow" or ani == "backWalkSlow" then
      speed = configParameter("mechWalkSlowSpeed")
    elseif ani == "backWalk" then
      speed = configParameter("mechBackwardSpeed")
    elseif ani == "run" then
      speed = configParameter("mechRunSpeed")
    else -- default to walk
      speed = configParameter("mechWalkSpeed")
    end
    if self.holdingLeft then self.movingDirection = -1 end
    
    speed = speed * self.movingDirection
    mcontroller.setXVelocity(speed)
    self.moving = true
    if mcontroller.onGround() and self.holdingUp then self.running = true end    
  end
  
  
  if not self.moving then
   mcontroller.approachXVelocity(0,100,true)
  end

  -- Double tap input for boosting -- blatantly stolen from dash.lua. Thanks Chucklefish!
  if self.dashTimer <= 0 then
	  local maximumDoubleTapTime = configParameter("maximumDoubleTapTime")
	  local dashDuration = configParameter("dashDuration")

	  if self.dashTapTimer > 0 then
		self.dashTapTimer = self.dashTapTimer - script.updateDt()
	  end

	  if self.holdingRight then
		if self.dashLastInput ~= 1 then
		  if self.dashTapLast == 1 and self.dashTapTimer > 0 then
      if mcontroller.onGround() then mcontroller.setVelocity({10*self.dashTapLast,20}) end
			self.dashTapLast = 0
			self.dashTapTimer = 0
			self.dashRight = true
		  else
			self.dashTapLast = 1
			self.dashTapTimer = maximumDoubleTapTime
		  end
		end
		self.dashLastInput = 1
	  elseif self.holdingLeft then
		if self.dashLastInput ~= -1 then
		  if self.dashTapLast == -1 and self.dashTapTimer > 0 then
      if mcontroller.onGround() then mcontroller.setVelocity({10*self.dashTapLast,20}) end
			self.dashTapLast = 0
			self.dashTapTimer = 0
			self.dashLeft = true
		  else
			self.dashTapLast = -1
			self.dashTapTimer = maximumDoubleTapTime
		  end
		end
		self.dashLastInput = -1
	  else
		self.dashLastInput = 0
	  end
  end  
 --[[ 
  if args.moves["special"] == 1 then
    if self.active then
      return "mechDeactivate"
    else
      return "mechActivate"
    end
  elseif args.moves["primaryFire"] then
    return "mechFire"
  end
]]
  return nil
end

function randomProjectileLine(startPoint, endPoint, stepSize, projectile, chanceToSpawn)
  local dist = math.distance(startPoint, endPoint)
  local steps = math.floor(dist / stepSize)
  local normX = (endPoint[1] - startPoint[1]) / dist
  local normY = (endPoint[2] - startPoint[2]) / dist
  for i = 0, steps do
    local p1 = { normX * i * stepSize + startPoint[1], normY * i * stepSize + startPoint[2]}
	local p2 = { normX * (i + 1) * stepSize + startPoint[1], normY * (i + 1) * stepSize + startPoint[2]} 
	if math.random() <= chanceToSpawn then
--  world.debugText("%s,%s : %s",normX,normY,dist,vec_add(mcontroller.position(),{0,-2}),"white")
	  world.spawnProjectile(projectile, math.midPoint(p1, p2), entity.id(), {normX, normY}, false,{speed=0})
	end
  end
  return endPoint
end

function mechSetArmOccupied(side, state)
  if side == "right" then
    self.rightArmOccupied = state
  elseif side == "left" then
    self.leftArmOccupied = state
  end
end

function mechCheckArmOccupied(side)
  if side == "right" then
    return self.rightArmOccupied
  elseif side == "left" then
    return self.leftArmOccupied
  elseif side == "front" then
    return self.frontArmOccupied
  elseif side == "back" then
    return self.backArmOccupied
  end
end

function mechAnimateActiveArm(frontState, backState, anim, side, flipState)
-- Animates a given arm (side = "left" or "right"). flipState is a global that keeps track of mech direction.
  if anim == nil then
    return 0
  end

  if side == "right" then
    if flipState then
	  if backState ~= nil then animator.setAnimationState(backState, anim) end
	else
	  if frontState ~= nil then animator.setAnimationState(frontState, anim) end
	end
  elseif side == "left" then
    if flipState then
	  if frontState ~= nil then animator.setAnimationState(frontState, anim) end
	else
	  if backState ~= nil then animator.setAnimationState(backState, anim) end
	end
  else
    -- Error message
  end
end

function mechAnimateArms(frontState, backState, frontAltState, backAltState, altSide, flipState, anim)
-- Animates front and back arms, if they are not busy doing something else. Used for walking animations etc.
-- Tracks asymmetry. Alt indicates the asymmetrical side.

  if not mechCheckArmOccupied(altSide) then
    mechAnimateActiveArm(frontAltState, backAltState, anim, altSide, flipState)
    mechAnimateActiveArm(frontState, backState, "off", altSide, flipState)
	-- world.logInfo("Animating %s", altSide)
	-- world.logInfo("with animation %s", anim)
  -- else
    -- world.logInfo("Failed to animate %s", altSide)
	-- world.logInfo("with animation %s", anim)
  end
  if not mechCheckArmOccupied(otherSide(altSide)) then
    mechAnimateActiveArm(frontState, backState, anim, otherSide(altSide), flipState)
    mechAnimateActiveArm(frontAltState, backAltState, "off", otherSide(altSide), flipState)
	-- world.logInfo("Animating %s" , otherSide(altSide))
	-- world.logInfo("with animation %s", anim)
  --else
   -- world.logInfo("Failed to animate %s", otherSide(altSide))
   -- world.logInfo("with animation %s", anim)
  end
end

function mechAnimateTorso(animState, anim)
  if not self.torsoOccupied then
    animator.setAnimationState(animState, anim)
  end
end

function mechAnimatePauldron(animState, anim)
  if not mechCheckArmOccupied("front") then
    animator.setAnimationState(animState, anim)
  end
end

function mechChooseObject(frontObject, backObject, side, flipState)
  if side == "right" then
    if flipState then
	  return backObject
	else
	  return frontObject
	end
  elseif side == "left" then
    if flipState then
	  return frontObject
	else
	  return backObject
	end
  elseif side == nil then
    if flipState then
	  return backObject
	else
	  return frontObject
	end
  end
end

function releaseInput(side)
  if side == "right" then
    self.altFireReleased = false
  elseif side == "left" then
    self.fireReleased = false
  end
end

-- Chooses an animation from animList based on the given angle between angleMin and angleMax
function chooseAnimAngle(angle, angleMin, angleMax, animList, flip)
  if #animList == 0 then
    return nil
  end
  local angleStep = (angleMax - angleMin) / #animList
  if flip then
    if angle > 0 then
      angle = math.pi - angle
	else
	  angle = -math.pi - angle
	end
  end
  if angle > angleMax then
    return animList[#animList]
  elseif angle <= angleMin then
    return animList[1]
  end
  for i, v in ipairs(animList) do
	if angle > (i-1) * angleStep + angleMin and angle <= i * angleStep + angleMin then
	  return animList[i]
	end
  end
  return nil
end

function spawnVariableDamageBeam(startPoint, endPoint, beamWidth, damageProjectile, damageUpper, damageLower, range)
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
  local damageScalar = (damageUpper - damageLower)/range
  for _, v in ipairs(entityTable) do
	if world.entityType(v) == "player" or world.entityType(v) == "npc" or world.entityType(v) == "monster" then
	  local pos = world.entityPosition(v)
	  local distdX = startPoint[1] - endPoint[1]
	  local distdY = startPoint[2] - endPoint[2]
	  local d = math.abs( distdY * pos[1] - distdX * pos[2] + startPoint[1] * endPoint[2] - startPoint[2] * endPoint[1] ) / math.sqrt( (distdX)^2 + (distdY)^2 )
	  if d <= beamWidth / 2 then
	    local damage = math.min( (range - math.distance( world.entityPosition(v), startPoint)) * damageScalar, damageUpper)
		world.spawnProjectile(damageProjectile, pos, entity.id(), {0, 0}, false, {power = damage})
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

  local energyCostAccumulated = 0
  
  local entityInSeat = vehicle.entityLoungingIn("seat")
  if entityInSeat then
    vehicle.setDamageTeam(world.entityDamageTeam(entityInSeat))
    input()
  else
    vehicle.setDamageTeam({type = "passive"})
    animator.rotateGroup("cannon", 0, true)
  end
  if entityInSeat ~= self.driver then
    self.driver = entityInSeat
    self.mechPilotProtection(entityInSeat)
  end
    
--  if not self.active and args.actions["mechActivate"] and self.mechState == "off" and mcontroller.onGround() then
  if not self.active and self.mechState == "off" and self.driver ~= nil then
    -- mechCollisionTest[1] = mechCollisionTest[1] + mcontroller.position()[1]
    -- mechCollisionTest[2] = mechCollisionTest[2] + mcontroller.position()[2]
    -- mechCollisionTest[3] = mechCollisionTest[3] + mcontroller.position()[1]
    -- mechCollisionTest[4] = mechCollisionTest[4] + mcontroller.position()[2]
    -- if (not world.rectCollision(mechCollisionTest)) then
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
	-- world.spawnProjectile("xsm_rhomechwarpout", mcontroller.position(), entity.id(), {0, 0}, false)
	
	-- tech.setVisible(false)
    -- tech.setParentState()  
    -- mcontroller.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
    -- tech.setToolUsageSuppressed(false)
    -- tech.setParentOffset({0, 0})
	
    -- Activate/Deactivate
    self.mechState = "off"
    self.mechStateTimer = 0
	
    self.firePressed = false
    self.fireReleased = false
    self.altFirePressed = false
    self.altFireReleased = false

	-- Landing
	self.fastDrop = false
	self.veryFastDrop = false
	self.veryVeryFastDrop = false
	self.movementSuppressed = false
	self.immobileTimer = 0
	
	-- Jumping (short jump, dash, boost)
	self.isJumping = false
	self.hasJumped = false
	self.jumpPressed = false
	self.jumpReleased = false
	self.jumpTimer = 0
	self.jumpCoolDown = 0
	self.isDashing = false
	self.dashTimer = 0
    self.dashDirection = 0
    self.dashLastInput = 0
    self.dashTapLast = 0
    self.dashTapTimer = 0
	self.isHovering = false
	self.hoverTimer = 0
	self.backHopTimer = 0
	self.isSprinting = false
	
	-- Weapons
	self.forceWalk = false
	self.attackQueued = false
	self.attacking = false
    self.rightArmOccupied = false
    self.leftArmOccupied = false
    self.frontArmOccupied = false
    self.backArmOccupied = false
	self.torsoOccupied = false
	self.gunRotationSuppressed = false
	self.gunRotationOld = 0
	self.beamTimer = 0
	self.hGunTimer = 0
	self.fireTimer = 0
	self.hGunState = "idle"
	self.forceWalkGun = false
	self.mGunRecoilKick = 0
	
	-- Animation / Particles
	animator.setAnimationState("movement", "sit")
	animator.setAnimationState("jetFlame", "off")
	animator.setAnimationState("jetPack", "off")
	animator.setAnimationState("hoverFlame", "off")
	animator.setAnimationState("crotch", "turnOn")
	animator.setAnimationState("torso", "open")
	animator.setAnimationState("backArmAltMovement", "off")
	animator.setAnimationState("frontArmAltMovement", "off")
	animator.setAnimationState("backArmMovement", "off")
	animator.setAnimationState("frontArmMovement", "off")
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
	animator.setAnimationState("frontArmPauldronMovement", "idle")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontLaser", "off")
	animator.setAnimationState("backLaser", "off")
	animator.setParticleEmitterActive("hoverFParticles", false)
	animator.setParticleEmitterActive("hoverParticles", false)
	animator.setParticleEmitterActive("hoverBParticles", false)
	animator.setParticleEmitterActive("skidParticles", false)
	animator.setParticleEmitterActive("veryHardLandingParticles", false)
	animator.setParticleEmitterActive("hardLandingParticles", false)
	animator.setParticleEmitterActive("mechSteam2", false)
	animator.setParticleEmitterActive("mechSteam", false)
	
    self.active = false
  end

--  mcontroller.controlFace(nil)
  
  if self.mechStateTimer > 0 then
	self.mechStateTimer = self.mechStateTimer - script.updateDt()
  end

  local diff = world.distance(vehicle.aimPosition("seat"), mcontroller.position())
  local aimAngle = math.atan(diff[2], diff[1])
  local cannonAimAngle = aimAngle
  local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2 

  -- Basic animation
  if self.active then
  
--	mcontroller.controlParameters(mechCustomMovementParameters)
    
	-- Gun angle correction
	if table.exists("heatBeam", self.mechEquip) and self.mechState == "on" then
	  local gunSide = nil
	  local gunRotationPosition = {}
	  -- self.parentAim indicates which arm is the primary aiming arm. It is also used (somewhat unintuitively) as a proxy to determine whether rotation should be applied.
	  if self.mechLeftEquip == "heatBeam" and self.hGunState ~= "idle" and self.hGunState ~= "holstering" then
		gunSide = "left"
		self.parentAim = "left"
	  elseif self.mechRightEquip == "heatBeam" and self.hGunState ~= "idle" and self.hGunState ~= "holstering" then
		gunSide = "right"
		self.parentAim = "right"
	  else
	    gunSide = "right"
	    self.parentAim = nil
		animator.rotateGroup("frontArmPauldron", 0)
	  end
	  gunRotationPosition = vec_add(mcontroller.position(), mechChooseObject( animator.partPoint("frontArmAlt","frontGunRotationPoint"), animator.partPoint("backArmAlt","backGunRotationPoint"), gunSide, self.mechFlipped))
	  local radius = self.mechGunRotationRadius
	  local range = math.distance(vehicle.aimPosition("seat"), gunRotationPosition)
	  local correction = math.asin( radius / range )
	  local diff2 = world.distance(vehicle.aimPosition("seat"), gunRotationPosition)
	  local refAngle = math.atan(diff2[2], diff2[1])
	  
	  -- Protection against gun wildly swinging at close range
	  if range <= 2 * radius then
	    correction = 0
	  end
	  
	  -- Apply correction
	  if self.mechFlipped then
	    aimAngle = refAngle - correction - self.mGunRecoilKick
	  else
	    aimAngle = refAngle + correction + self.mGunRecoilKick
	  end
	end
	
	-- Reduce rotation speed if rotation is suppressed
	if self.gunRotationSuppressed then
	  -- world.logInfo("aimAngle is: %s", aimAngle)
	  -- world.logInfo("gunRotationOld is: %s", self.gunRotationOld)
	  if self.mechFlipped then
	    if (aimAngle < 0 and self.gunRotationOld < 0) or (aimAngle > 0 and self.gunRotationOld > 0) then
	  	  if aimAngle > self.gunRotationOld then
		    aimAngle = self.gunRotationOld + self.mechGunSuppAngularVel * script.updateDt()
	      elseif aimAngle < self.gunRotationOld then
	        aimAngle = self.gunRotationOld - self.mechGunSuppAngularVel * script.updateDt()
  	      end
		else
	  	  if aimAngle > self.gunRotationOld then
		    aimAngle = self.gunRotationOld - self.mechGunSuppAngularVel * script.updateDt()
	      elseif aimAngle < self.gunRotationOld then
	        aimAngle = self.gunRotationOld + self.mechGunSuppAngularVel * script.updateDt()
  	      end		  
	    end
	  else
	    if aimAngle > self.gunRotationOld then
		  aimAngle = self.gunRotationOld + self.mechGunSuppAngularVel * script.updateDt()
	    elseif aimAngle < self.gunRotationOld then
	      aimAngle = self.gunRotationOld - self.mechGunSuppAngularVel * script.updateDt()
  	    end
	  end
	end  

	-- Flip mech, gun angles, etc.
	if (not self.isDashing) and (not self.attacking) and (self.hGunState == "limbo" or self.hGunState == "idle") and self.mechState == "on" then
		if flip then  
		  self.mechFlipped = true
		else
		  self.mechFlipped = false
		end
	end	
	if self.mechFlipped then
	  animator.setFlipped(true)  
	  if self.rightArmOccupied then
		self.backArmOccupied = true
	  else
		self.backArmOccupied = false
	  end
	  if self.leftArmOccupied then
		self.frontArmOccupied = true
	  else
		self.frontArmOccupied = false
	  end				  
--	  local nudge = tech.appliedOffset()
--	  tech.setParentOffset({-parentOffset[1] - nudge[1], parentOffset[2] + nudge[2]})
--	  mcontroller.controlFace(-1)	
	  -- Limits of aimAngle
      if aimAngle > 0 then
        aimAngle = math.max(aimAngle, math.pi - self.mechGunAimLimit)
      else
        aimAngle = math.min(aimAngle, -math.pi + self.mechGunAimLimit)
      end
	  if cannonAimAngle > 0 then
	    cannonAimAngle = math.max(cannonAimAngle, math.pi - self.mechCannonAimLimit)
	  else
	    cannonAimAngle = math.min(cannonAimAngle, -math.pi + self.mechCannonAimLimit)
	  end
	  -- Rotate arms
	  if self.mechState == "on" and self.parentAim ~= nil then
	    if self.parentAim == "right" then
		  animator.rotateGroup("backArm", math.pi - aimAngle)
		else
	      animator.rotateGroup("frontArm", math.pi - aimAngle)	
		end
	  else
	    animator.rotateGroup("frontArm", 0)
		animator.rotateGroup("backArm", 0)
	  end
	  if self.mechState == "on" then
	    animator.rotateGroup("cannon", math.pi - cannonAimAngle)
	  else
	    animator.rotateGroup("cannon", 0)
	  end
	else
	  animator.setFlipped(false)
	  if self.rightArmOccupied then
		self.frontArmOccupied = true
	  else
		self.frontArmOccupied = false
	  end
	  if self.leftArmOccupied then
		self.backArmOccupied = true
	  else
		self.backArmOccupied = false
	  end	
--	  local nudge = tech.appliedOffset()
--	  tech.setParentOffset({parentOffset[1] + nudge[1], parentOffset[2] + nudge[2]})
--	  mcontroller.controlFace(1)	
	  -- Limits of aimAngle
      if aimAngle > 0 then
        aimAngle = math.min(aimAngle, self.mechGunAimLimit)
      else
        aimAngle = math.max(aimAngle, -self.mechGunAimLimit)
      end	
      if cannonAimAngle > 0 then
        cannonAimAngle = math.min(cannonAimAngle, self.mechCannonAimLimit)
      else
        cannonAimAngle = math.max(cannonAimAngle, -self.mechCannonAimLimit)
      end		  
	  -- Rotate arms
	  if self.mechState == "on" and self.parentAim ~= nil then
	    if self.parentAim == "right" then
	      animator.rotateGroup("frontArm", aimAngle)
		else
		  animator.rotateGroup("backArm", aimAngle)		
		end
	  else
	    animator.rotateGroup("frontArm", 0)
		animator.rotateGroup("backArm", 0)
	  end
	  if self.mechState == "on" then
	    animator.rotateGroup("cannon", cannonAimAngle)
	  else
	    animator.rotateGroup("cannon", 0)
	  end
	end 
	self.gunRotationOld = aimAngle
  end
  
  -- Startup, shutdown, and active
  if self.mechState == "turningOn" then
--	mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)
	animator.setAnimationState("movement", "stand")
	animator.setAnimationState("crotch", "turnOn")
	mechAnimateTorso("torso", "turnOn")
	mechAnimatePauldron("frontArmPauldronMovement", "idle")
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
  elseif self.mechState == "turningOff" then
--	mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)
	animator.setAnimationState("movement", "sit")
	mechAnimateTorso("torso", "turnOff")
	animator.setAnimationState("crotch", "turnOff")
	mechAnimatePauldron("frontArmPauldronMovement", "idle")
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontLaser", "off")
	animator.setAnimationState("backLaser", "off")
  elseif self.active and self.mechState == "on" then
	
	-- Misc. Animation-related checks
	--mechSetArmOccupied ("left", true) TEMP
	--mechSetArmOccupied ("right", true) TEMP
	
	-- State checks, animation
    if not mcontroller.onGround() then
      if mcontroller.velocity()[2] > 0 and (not self.isHovering) then
	    -- Jump animation only
        animator.setAnimationState("movement", "jump")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "jump")
		mechAnimatePauldron("frontArmPauldronMovement", "jump")
		mechAnimateTorso("torso", "idle")
		animator.setAnimationState("crotch", "idle")
		self.fastDrop = false
	    self.veryFastDrop = false
      elseif not self.movementSuppressed and (not self.isHovering) then
	    -- Falling animation. Hard landings and very hard landings suppress movement temporarily.
		if (not self.hasJumped) and (not self.isHovering) then
	      self.jumpReleased = true
		  self.hasJumped = true
		end
        animator.setAnimationState("movement", "fall")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "fall")
		mechAnimatePauldron("frontArmPauldronMovement", "fall")
		mechAnimateTorso("torso", "idle")
		animator.setAnimationState("crotch", "idle")
		if (mcontroller.velocity()[2] < -30 and mcontroller.velocity()[2] > -52) and math.abs(mcontroller.velocity()[1]) < 30 then
		  self.fastDrop = true
		elseif mcontroller.velocity()[2] <= -52 and mcontroller.velocity()[2] > -68 then
		  self.fastDrop = false
		  self.veryFastDrop = true
		elseif mcontroller.velocity()[2] <= -68 then
		  self.fastDrop = false
		  self.veryFastDrop = false
		  self.veryVeryFastDrop = true
		end	
      end
	  if self.holdingJump and (not self.isHovering) and self.jumpReleased and (not self.isDashing) and (not self.holdingDown) and not self.energyLocked["seat"] then--and status.resource("energy") > (self.energyCostPerHover + self.energyCostPerSecondHover * 0.4) then
	    -- Initiate boosting
		self.jumpReleased = false	    
		self.isHovering = true
		animator.playSound("hoverInitiateSound")
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerHover
	  end
	else
	  self.jumpReleased = false
	  self.hasJumped = false
		if self.fastDrop and not self.movementSuppressed then
		  -- Hard landing
		  self.immobileTimer = 0.15 -- TEMP
		  self.movementSuppressed = true	  
		  animator.burstParticleEmitter("hardLandingParticles")
		elseif self.veryFastDrop and not self.movementSuppressed then
		  -- Very hard landing	  
		  self.immobileTimer = 0.66 -- TEMP
		  self.movementSuppressed = true
		  animator.burstParticleEmitter("veryHardLandingParticles")
		elseif self.veryVeryFastDrop and not self.movementSuppressed then
		  -- Very, Very hard landing
		  self.immobileTimer = 0.78 -- TEMP
		  self.movementSuppressed = true
		  animator.burstParticleEmitter("veryHardLandingParticles")	
		  local particlePosition = {mcontroller.position()[1] + self.mechLandingLocation[1], mcontroller.position()[2] + self.mechLandingLocation[2]}
		  world.spawnProjectile(self.mechLandingProjectile, particlePosition, entity.id(), {0, 0}, false)
		elseif self.holdingJump and not self.isJumping and not self.movementSuppressed and not self.holdingDown then
		  -- Activate hop (jumping)
		  self.isJumping = true
		  self.jumpTimer = self.jumpDuration
		  animator.playSound("jumpSound")
		  self.hasJumped = true
		elseif self.moving and not self.movementSuppressed then
		  -- walk/run/backWalk/walkSlow/backWalkSlow animations
		  self.fastDrop = false
		  self.veryFastDrop = false
--		  local mechCustomAnimationMovementParameters = copy(configParameter("mechCustomMovementParameters"))
		  if self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1 then
		    if self.forceWalk then
			  animator.setAnimationState("movement", "backWalkSlow")
			  mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "backWalkSlow")
			  mechAnimatePauldron("frontArmPauldronMovement", "backWalkSlow")
			  mechAnimateTorso("torso", "backWalkSlow")
			  animator.setAnimationState("crotch", "backWalkSlow")
			  -- mechCustomAnimationMovementParameters.runSpeed = mechWalkSlowSpeed
			  -- mechCustomAnimationMovementParameters.walkSpeed = mechWalkSlowSpeed
			  -- mcontroller.controlParameters(mechCustomAnimationMovementParameters)	
			else  
			  animator.setAnimationState("movement", "backWalk")
			  mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "backWalk")
			  mechAnimatePauldron("frontArmPauldronMovement", "backWalk")
			  mechAnimateTorso("torso", "backWalk")
			  animator.setAnimationState("crotch", "backWalk")
			  -- mechCustomAnimationMovementParameters.runSpeed = mechBackwardSpeed
			  -- mechCustomAnimationMovementParameters.walkSpeed = mechBackwardSpeed
			  -- mcontroller.controlParameters(mechCustomAnimationMovementParameters)
			end
		  else
		    if self.forceWalk then
			  animator.setAnimationState("movement", "walkSlow")
			  mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "walkSlow")
			  mechAnimatePauldron("frontArmPauldronMovement", "walkSlow")
			  mechAnimateTorso("torso", "walkSlow")
			  animator.setAnimationState("crotch", "walkSlow")
			  -- mechCustomAnimationMovementParameters.runSpeed = mechWalkSlowSpeed
			  -- mechCustomAnimationMovementParameters.walkSpeed = mechWalkSlowSpeed
			  -- mcontroller.controlParameters(mechCustomAnimationMovementParameters)		
			else
			  if not self.running or (self.running and self.energyLocked["seat"]) then
			    animator.setAnimationState("movement", "walk")
				mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "walk")
				mechAnimatePauldron("frontArmPauldronMovement", "walk")
				mechAnimateTorso("torso", "walk")
				animator.setAnimationState("crotch", "walk")
			  else--if mcontroller.walking() then
			    animator.setAnimationState("movement", "run")
				mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "run")
				mechAnimatePauldron("frontArmPauldronMovement", "run")
				mechAnimateTorso("torso", "run")
				animator.setAnimationState("crotch", "run")
				animator.burstParticleEmitter("mechSteam2", true)
				energyCostAccumulated = energyCostAccumulated + self.energyCostPerSecondRunning * script.updateDt()
			  end
			end
		  end
		elseif not self.movementSuppressed then
		  -- Idle
		  self.fastDrop = false
		  self.veryFastDrop = false
			-- Crouching
		  if self.holdingDown then
			animator.setAnimationState("movement", "sit")
			mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
			mechAnimatePauldron("frontArmPauldronMovement", "idle")
			mechAnimateTorso("torso", "idle")
			animator.setAnimationState("crotch", "idle")
		  else
		    animator.setAnimationState("movement", "idle")
			mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
			mechAnimatePauldron("frontArmPauldronMovement", "idle")
			mechAnimateTorso("torso", "idle")
			animator.setAnimationState("crotch", "idle")
		  end
		end
	end
	
	-- Temp fall protection
	if mcontroller.velocity()[2] < -70 then
		mcontroller.approachYVelocity(-70, 6000, false)
	end

	-- Side sprinting 
	-- if self.isSprinting and mcontroller.walking() and mcontroller.onGround() then
	  -- animator.setAnimationState("movement", "sit")
	  -- animator.setAnimationState("jetPack", "boost3")
	  -- animator.setAnimationState("jetFlame", "dash")
	  -- mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "jump")
	  -- mechAnimatePauldron("frontArmPauldronMovement", "jump")
	  -- mechAnimateTorso("torso", "idle")
	  -- animator.setAnimationState("crotch", "idle")
	  -- animator.burstParticleEmitter("mechSteam2", true)
	  -- energyCostAccumulated = energyCostAccumulated + self.energyCostPerSecondRunning * script.updateDt()
	  -- if self.mechFlipped then
	    -- mcontroller.controlApproachXVelocity(-self.dashSpeed, self.hoverControlForce, true)
	  -- else
	    -- mcontroller.controlApproachXVelocity(self.dashSpeed, self.hoverControlForce, true)
	  -- end
	-- elseif self.isSprinting and (not mcontroller.walking() or not mcontroller.onGround()) then
	  -- self.isSprinting = false
	  -- animator.setAnimationState("jetPack", "turnoff3")
	  -- animator.setAnimationState("jetFlame", "off")
	-- end	
	
	-- Jumping physics
	if self.isJumping and self.jumpTimer > 0 and self.holdingJump and not self.movementSuppressed then
	  mcontroller.approachYVelocity(self.jumpSpeed, self.jumpControlForce, true)
	  self.jumpTimer = self.jumpTimer - script.updateDt()
	elseif self.isJumping then
	  self.isJumping = false
	  self.jumpTimer = 0
	end
	
	-- Dashing physics
	if self.dashRight and self.dashTimer <= 0 and not self.movementSuppressed then
	  if (self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1) and mcontroller.onGround() and not self.energyLocked["seat"] then-- and status.resource("energy") > self.energyCostPerBackHop then
	    if self.backHopTimer <= 0 then
		  self.dashTimer = self.backHopDuration
	      self.dashDirection = 1	  
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBackHop
		  animator.playSound("backHopSound")
		  self.backHopTimer = self.backHopCooldown
		end
	  elseif mcontroller.onGround() and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBackHop then
	    if self.backHopTimer <= 0 then
		  self.dashTimer = self.backHopDuration
	      self.dashDirection = 2	  
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBackHop
		  animator.playSound("backHopSound")
		  self.backHopTimer = self.backHopCooldown
		end
	  -- elseif not (self.mechFlipped and mcontroller.movingDirection() == 1 or not self.mechFlipped and mcontroller.movingDirection() == -1) and status.resource("energy") > energyCostPerDash then
	    -- self.dashTimer = self.dashDuration
	    -- self.dashDirection = 3
		-- energyCostAccumulated = energyCostAccumulated + energyCostPerDash
		-- animator.playSound("dashSound")
	  end
      self.dashRight = false
	  self.isDashing = true
	  self.jumpReleased = true
	elseif self.dashLeft and self.dashTimer <= 0 and not self.movementSuppressed then
	  if (self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1) and mcontroller.onGround() and not self.energyLocked["seat"] then --and status.resource("energy") > self.energyCostPerBackHop then
	    if self.backHopTimer <= 0 then
		  self.dashTimer = self.backHopDuration
	      self.dashDirection = -1	 
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBackHop
		  animator.playSound("backHopSound")
		  self.backHopTimer = self.backHopCooldown
		end
	  elseif mcontroller.onGround() and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBackHop then  
	    if self.backHopTimer <= 0 then
		  self.dashTimer = self.backHopDuration
	      self.dashDirection = -2	 
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBackHop
		  animator.playSound("backHopSound")
		  self.backHopTimer = self.backHopCooldown
		end
	  -- elseif not (self.mechFlipped and mcontroller.movingDirection() == 1 or not self.mechFlipped and mcontroller.movingDirection() == -1) and status.resource("energy") > energyCostPerDash then
	    -- self.dashTimer = self.dashDuration
	    -- self.dashDirection = -3
		-- energyCostAccumulated = energyCostAccumulated + energyCostPerDash 
		-- animator.playSound("dashSound")
	  end
      self.dashLeft = false
	  self.isDashing = true
	  self.jumpReleased = true
	end
	if self.dashTimer > 0 then
	  -- Backhop
	  if self.dashDirection == 1 then
		local diagX = math.cos(self.backHopAngle)
		local diagY = math.sin(self.backHopAngle)
		mcontroller.approachVelocity({self.backHopSpeed * diagX, self.backHopSpeed * diagY}, self.backHopControlForce, true, true)	
		-- Backhop right animation + particles
	  elseif self.dashDirection == -1 then
		local diagX = -math.cos(self.backHopAngle)
		local diagY = math.sin(self.backHopAngle)
		mcontroller.approachVelocity({self.backHopSpeed * diagX, self.backHopSpeed * diagY}, self.backHopControlForce, true, true)	
		-- Backhop left animation + particles  

	  -- Fronthop
	  elseif self.dashDirection == 2 then
		local diagX = math.cos(self.backHopAngle*1.5)
		local diagY = math.sin(self.backHopAngle*1.5)
		mcontroller.approachVelocity({self.backHopSpeed * diagX, self.backHopSpeed * diagY}, self.backHopControlForce, true, true)	
	  elseif self.dashDirection == -2 then
		local diagX = -math.cos(self.backHopAngle*1.5)
		local diagY = math.sin(self.backHopAngle*1.5)
		mcontroller.approachVelocity({self.backHopSpeed * diagX, self.backHopSpeed * diagY}, self.backHopControlForce, true, true)	
		
	  -- Full Power Dash (in Midair)
	  elseif self.dashDirection == 3 then
		mcontroller.approachXVelocity(self.dashSpeed, self.dashControlForce, true)
		animator.setAnimationState("jetPack", "boost3")
		animator.setAnimationState("jetFlame", "dash")
	  elseif self.dashDirection == -3 then
		mcontroller.approachXVelocity(-self.dashSpeed, self.dashControlForce, true)	
		animator.setAnimationState("jetPack", "boost3")
		animator.setAnimationState("jetFlame", "dash") 
	  end  
	  self.dashTimer = self.dashTimer - script.updateDt()	  
	elseif self.isDashing then
	  self.isDashing = false
	  self.dashTimer = 0
	  animator.setAnimationState("jetPack", "turnoff3")
	  animator.setAnimationState("jetFlame", "off")
	  self.jumpReleased = true
	end
	
	-- Hovering physics
	if self.isHovering and (not mcontroller.onGround()) and not (self.jumpReleased and self.holdingJump) and not self.energyLocked["seat"] then
	  local actualhoverSpeed
	  if self.holdingDown and not self.holdingUp then
	    mcontroller.approachYVelocity(self.hoverSpeed-10, self.hoverControlForce, false)
	  elseif self.holdingUp and not self.holdingDown then
	    mcontroller.approachYVelocity(self.hoverSpeed+10, self.hoverControlForce, false)
	  else
	    mcontroller.approachYVelocity(self.hoverSpeed, self.hoverControlForce, true)
	  end
	  --[[
	  local u = (math.random() * 2) - 1
	  local v = (math.random() * 2) - 1
	  mcontroller.controlApproachYVelocity(u * 10, 500, true)
	  mcontroller.controlApproachXVelocity(v * 4, 100, true)
	  --]]
--	  local mechCustomHoveringMovementParameters = copy(configParameter("mechCustomMovementParameters"))
--	  mechCustomHoveringMovementParameters.airForce = self.mechBoostAirForce
--	  mcontroller.controlParameters(mechCustomHoveringMovementParameters)
	  energyCostAccumulated = energyCostAccumulated + self.energyCostPerSecondHover * script.updateDt()
	  self.hoverTimer = self.hoverTimer + script.updateDt()
	  animator.setAnimationState("hoverFlame", "on")
	  if (self.mechFlipped and self.holdingRight) or (not self.mechFlipped and self.holdingLeft) then
	    animator.setAnimationState("movement", "hoverB")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "hoverB")
		mechAnimatePauldron("frontArmPauldronMovement", "hoverB")
		animator.setParticleEmitterActive("hoverFParticles", false)
		animator.setParticleEmitterActive("hoverParticles", false)
		animator.setParticleEmitterActive("hoverBParticles", true)
		animator.rotateGroup("frontHover", 0.17, true)
		animator.rotateGroup("backHover", 0.17, true)
	  elseif (self.mechFlipped and self.holdingLeft) or (not self.mechFlipped and self.holdingRight) then
	    animator.setAnimationState("movement", "hoverF")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "hoverF")
		mechAnimatePauldron("frontArmPauldronMovement", "hoverF")
		animator.setParticleEmitterActive("hoverFParticles", true)
		animator.setParticleEmitterActive("hoverParticles", false)
		animator.setParticleEmitterActive("hoverBParticles", false)
		animator.rotateGroup("frontHover", -0.17, true)
		animator.rotateGroup("backHover", -0.17, true)
	  else
	    animator.setAnimationState("movement", "hoverIdle")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "hoverIdle")
		mechAnimatePauldron("frontArmPauldronMovement", "hoverIdle")
		animator.setParticleEmitterActive("hoverFParticles", false)
		animator.setParticleEmitterActive("hoverParticles", true)
		animator.setParticleEmitterActive("hoverBParticles", false)
		animator.rotateGroup("frontHover", 0, true)
		animator.rotateGroup("backHover", 0, true)
	  end
	  -- Other anims
	  mechAnimateTorso("torso", "idle")
	  animator.setAnimationState("crotch", "idle")
	  self.fastDrop = false
	  self.veryFastDrop = false
	elseif self.isHovering then
	  self.jumpReleased = false
	  self.isHovering = false
	  self.hoverTimer = 0	
	  animator.setAnimationState("jetPack", "turnoff1")
	  animator.setAnimationState("jetFlame", "off")
	  animator.setAnimationState("hoverFlame", "off")
	  animator.setParticleEmitterActive("hoverFParticles", false)
	  animator.setParticleEmitterActive("hoverParticles", false)
	  animator.setParticleEmitterActive("hoverBParticles", false)
	end
	
	-- Skidding
    if math.abs(mcontroller.velocity()[1]) >= 30 and mcontroller.onGround() then
--	  local mechCustomSkiddingMovementParameters = copy(configParameter("mechCustomMovementParameters"))
--	  mechCustomSkiddingMovementParameters.normalGroundFriction = self.mechSkiddingFriction
--	  mcontroller.controlParameters(mechCustomSkiddingMovementParameters) -- dynamic coefficient of friction, y'see....
	  animator.setParticleEmitterActive("skidParticles", true)
	  -- Spawn dust
	else 
	  animator.setParticleEmitterActive("skidParticles", false)
    end	  

	-- Landing Movement Suppression
	if self.immobileTimer > 0 and mcontroller.onGround() then
	  self.immobileTimer = self.immobileTimer - script.updateDt()  
	  -- Anti-Skidding
	  if math.abs(mcontroller.velocity()[1]) < 15 then
		mcontroller.approachXVelocity(0, 3000, true)
		animator.setParticleEmitterActive("skidParticles", false)
	  end 
	  -- Animation
	  if self.veryFastDrop or self.veryVeryFastDrop then
		animator.setAnimationState("movement", "landHard")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
		mechAnimatePauldron("frontArmPauldronMovement", "idle")
		mechAnimateTorso("torso", "idle")
		animator.setAnimationState("crotch", "idle")
	  elseif self.fastDrop then
		animator.setAnimationState("movement", "land")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
		mechAnimatePauldron("frontArmPauldronMovement", "idle")
		mechAnimateTorso("torso", "idle")
		animator.setAnimationState("crotch", "idle")
	  end
--	  mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)	  
	elseif (self.movementSuppressed and self.immobileTimer <= 0) or (self.immobileTimer > 0 and not mcontroller.onGround()) then
	  -- animator.setParticleEmitterActive("skidParticles", false)
	  self.movementSuppressed = false
	  self.immobileTimer = 0
	  self.fastDrop = false
	  self.veryFastDrop = false
	  self.veryVeryFastDrop = false
	end
	
	-- Force walking (when attacking)
	if self.forceWalkGun then
	  self.forceWalk = true
	else
	  self.forceWalk = false
	end
	
	-- Timers
	if self.backHopTimer > 0 then
	  self.backHopTimer = self.backHopTimer - script.updateDt()
	end
	if self.beamTimer > 0 then
	  self.beamTimer = self.beamTimer - script.updateDt()
	end
	if self.hGunTimer > 0 then
	  self.hGunTimer = self.hGunTimer - script.updateDt()
	end	  	  
	
	-- WEAPON: Torso Cannons
    if self.holdingAltFire and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerAltShot + 1 then
      if self.fireTimer <= 0 then
  self.mechCannonProjectileConfig.power = projectilePowerAdjust(self.mechCannonProjectilePower)
	    local fireAngle = cannonAimAngle - self.mechCannonFireCone * math.random() + self.mechCannonFireCone * math.random()      		
		world.spawnProjectile(self.mechCannonProjectile, vec_add(mcontroller.position(), animator.partPoint("frontCannon","frontCannonFirePoint")), entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechCannonProjectileConfig)
		self.fireTimer = self.fireTimer + self.mechCannonFireCycle
        animator.setAnimationState("frontCannonFiring", "fire")
		animator.setAnimationState("frontRecoil", "fire")
		animator.playSound("mechCannonFireSound")
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerAltShot
      else
        local oldFireTimer = self.fireTimer
		self.fireTimer = self.fireTimer - script.updateDt()
        if oldFireTimer > self.mechCannonFireCycle / 2 and self.fireTimer <= self.mechCannonFireCycle / 2 then
  self.mechCannonProjectileConfig.power = projectilePowerAdjust(self.mechCannonProjectilePower)
          local fireAngle = cannonAimAngle - self.mechCannonFireCone * math.random() + self.mechCannonFireCone * math.random()
		  world.spawnProjectile(self.mechCannonProjectile, vec_add(mcontroller.position(), animator.partPoint("backCannon","backCannonFirePoint")), entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechCannonProjectileConfig)	  
		  animator.setAnimationState("backCannonFiring", "fire")
		  animator.setAnimationState("backRecoil", "fire")
		  animator.playSound("mechCannonFireSound")
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerAltShot
        end
      end
    end

	-- WEAPON: Heat Beam
	if table.exists("heatBeam", self.mechEquip) then
	  -- Setup local variables left/right
	  local mechActiveSide = nil
	  local mechOtherSide = nil
	  local mechActiveAnim = {}
	  local mechOtherAnim = {}
	  local mechActiveSideButton = nil
	  if self.mechLeftEquip == "heatBeam" then
	    mechActiveSide = "left"
		mechOtherSide = "right"
		mechActiveAnim = self.mechLeftAnimation
		mechOtherAnim = self.mechRightAnimation
		mechActiveSideButton = self.holdingFire
	  elseif self.mechRightEquip == "heatBeam" then
	    mechActiveSide = "right"
		mechOtherSide = "left"
		mechActiveAnim = self.mechRightAnimation
		mechOtherAnim = self.mechLeftAnimation
		mechActiveSideButton = self.holdingAltFire
	  end  
	  
	  -- Keeps track of arm rotation
	  local firePoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontArmAlt","frontGunFirePoint"), animator.partPoint("backArmAlt","backGunFirePoint"), mechActiveSide, self.mechFlipped))
	  local rotPoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontArmAlt","frontGunRotationPoint"), animator.partPoint("backArmAlt","backGunRotationPoint"), mechActiveSide, self.mechFlipped))
	  local gunAngleDiff = world.distance(firePoint, rotPoint)
	  local gunAngle = math.atan(gunAngleDiff[2], gunAngleDiff[1])
	  local gunAngleOffset = math.atan(0.25, 5.125)
	  if self.mechFlipped then
		gunAngle = gunAngle - gunAngleOffset
	  else
		gunAngle = gunAngle + gunAngleOffset
	  end		  
	  
	  if mechActiveSideButton and (not self.attackQueued) and (self.hGunState == "limbo" or self.hGunState == "limbo2") then
	    self.attackQueued = true
	  end
	  
	  -- Weapon operation
	  if mechActiveSideButton and self.hGunState == "idle" then
	    self.hGunState = "readying"
		self.hGunTimer = self.mechGunReadyTime
		animator.playSound("mechGunReadySound")
		mechSetArmOccupied(mechActiveSide, true)
		self.forceWalkGun = true
		self.torsoOccupied = true
	  elseif self.hGunState == "readying" and self.hGunTimer <= 0 then
		self.hGunState = "limbo"
		self.hGunTimer = self.mechGunIdleTime
		animator.playSound("mechGunIdleSound")
	  elseif self.hGunState == "limbo" then
		if self.attackQueued and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBeamFire + 1 then
		  self.hGunState = "firing"
		  self.hGunTimer = self.mechGunFireTime
		  animator.playSound("mechGunFireSound")
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBeamFire
	--	  mechAnimateActiveArm("frontFiring", "backFiring", "fire", mechActiveSide, self.mechFlipped)	
		elseif self.hGunTimer <= 0 then
		  self.hGunState = "holstering"
		  self.hGunTimer = self.mechGunHolsterTime
		  animator.playSound("mechGunHolsterSound")
	    end	  
	  elseif self.hGunState == "firing" then
	    self.gunRotationSuppressed = true
		self.attackQueued = false
	    -- Fire shot
		if self.beamTimer <= 0 then	  
		  -- Spawn beam
		  local endPoint = {math.cos(gunAngle) * self.mechGunBeamMaxRange + firePoint[1], math.sin(gunAngle) * self.mechGunBeamMaxRange + firePoint[2]}
		  local beamCollision = progressiveLineCollision(firePoint, endPoint, self.mechGunBeamStep)
		  randomProjectileLine(firePoint, beamCollision, self.mechGunBeamStep, self.mechGunBeamSmokeProkectile, 0.08)
		  randomProjectileLine(firePoint, beamCollision, self.mechGunBeamStep*1.685, self.mechGunLightProjectile, 1)
--		  local beamDamage = status.resource("energy")
		  spawnVariableDamageBeam(firePoint, beamCollision, self.mechGunBeamWidth, self.mechGunBeamHitProjectile, self.mechGunBeamUpperDamage, self.mechGunBeamLowerDamage, self.mechGunBeamMaxRange)
		  world.spawnProjectile(self.mechGunBeamEndProjectile, beamCollision, entity.id(), {0, 0}, false)
		
		  -- Beam animation graphic
		  local scaleGroup = mechChooseObject("frontLaser", "backLaser", mechActiveSide, self.mechFlipped)
		  local scale = math.distance(firePoint, beamCollision)
--		  tech.scaleGroup(scaleGroup, {scale, 1})
--      animator.resetTransformationGroup(scaleGroup)
--		  animator.scaleTransformationGroup(scaleGroup, {scale,1})
--      animator.translateTransformationGroup(scaleGroup,firePoint)
--      animator.setAnimationState(scaleGroup,"fire")
--      world.debugText("%s || %s",scale,beamCollision,mcontroller.position(),"white")
		  
		  self.beamTimer = self.mechGunBeamUpdateTime
		  self.mGunRecoilKick = self.mGunRecoilKick + self.mechGunRecoilKick
		  local diagX = -math.cos(gunAngle)
		  mcontroller.approachXVelocity(self.mechGunRecoilSpeed * diagX, self.mechGunRecoilPower * math.abs(diagX), true)	
		end		
		if self.hGunTimer <= 0 then
		  mechAnimateActiveArm("frontLaser", "backLaser", "fade", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontLaser", "backLaser", "off", mechOtherSide, self.mechFlipped)	
		  self.hGunState = "cooling"
		  self.hGunTimer = self.mechGunCoolingTime
		  animator.playSound("mechGunCoolingSound")
		  self.mGunRecoilKick = 0
		end
	  elseif self.hGunState == "cooling" and self.hGunTimer <= 0 then
		self.hGunState = "limbo2"
		self.hGunTimer = 0.25
		self.gunRotationSuppressed = false
	  elseif self.hGunState == "limbo2" and self.hGunTimer <= 0 then
		self.hGunState = "limbo"
		self.hGunTimer = self.mechGunIdleTime/3
		animator.playSound("mechGunIdleSound")    
	  elseif self.hGunState == "holstering" and self.hGunTimer <= 0 then
		self.hGunState = "idle"
		self.forceWalkGun = false
		mechSetArmOccupied(mechActiveSide, false)
		self.torsoOccupied = false
		self.hGunTimer = 0	
		self.mGunRecoilKick = 0
	  end	
	  -- Pauldron Animation
	  if self.hGunState == "readying" then
	    if (mechActiveSide == "left" and self.mechFlipped) or (mechActiveSide == "right" and not self.mechFlipped) then
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "gunTurnOn", mechActiveSide, self.mechFlipped)
		  if self.mechFlipped then
		    animator.rotateGroup("frontArmPauldron", math.pi - gunAngle)	
		  else
		    animator.rotateGroup("frontArmPauldron", gunAngle)	
		  end
	    end
	  elseif self.hGunState == "limbo" or self.hGunState == "limbo2" or self.hGunState == "firing" or self.hGunState == "cooling" then
	    if (mechActiveSide == "left" and self.mechFlipped) or (mechActiveSide == "right" and not self.mechFlipped) then
		  local animAnglePauldron = {"rot.2", "rot.3", "rot.4", "rot.5", "rot.6", "rot.7", "rot.8", "rot.9"}
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, chooseAnimAngle(gunAngle, -self.mechGunAimLimit, self.mechGunAimLimit, animAnglePauldron, self.mechFlipped), mechActiveSide, self.mechFlipped)
		  animator.rotateGroup("frontArmPauldron", 0)	
	    end
	  elseif self.hGunState == "holstering" then
	    if (mechActiveSide == "left" and self.mechFlipped) or (mechActiveSide == "right" and not self.mechFlipped) then
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "gunTurnOff", mechActiveSide, self.mechFlipped)
		  if self.mechFlipped then
		    animator.rotateGroup("frontArmPauldron", math.pi - gunAngle)	
		  else
		    animator.rotateGroup("frontArmPauldron", gunAngle)	
		  end
	    end	
	  end
	  
	  -- Arm Animation
	  if self.hGunState == "readying" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gunTurnOn", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
	  elseif self.hGunState == "limbo" or self.hGunState == "limbo2" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "rotation", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontLaser", "backLaser", "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontLaser", "backLaser", "off", mechOtherSide, self.mechFlipped)	
	  elseif self.hGunState == "firing" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gunFire", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)	
		mechAnimateActiveArm("frontFiring", "backFiring", "fire", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontFiring", "backFiring", "off", mechOtherSide, self.mechFlipped)		
		mechAnimateActiveArm("frontLaser", "backLaser", "fire", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontLaser", "backLaser", "off", mechOtherSide, self.mechFlipped)
	  elseif self.hGunState == "cooling" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gunCool", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontFiring", "backFiring", "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontFiring", "backFiring", "off", mechOtherSide, self.mechFlipped)
	  elseif self.hGunState == "holstering" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gunTurnOff", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)		
	  end
	  -- Torso Animation
	  if self.hGunState == "firing" then
	    if self.mechFlipped then
		  if mechActiveSide == "left" then
		    animator.setAnimationState("torso", "turnAway")
		  else
		    animator.setAnimationState("torso", "turnToward")
		  end
		else
		  if mechActiveSide == "left" then
		    animator.setAnimationState("torso", "turnToward")
		  else
		    animator.setAnimationState("torso", "turnAway")
		  end
		end
	  else
	    if self.torsoOccupied and self.mechFlipped then
	      if mechActiveSide == "left" then
		    animator.setAnimationState("torso", "idleAway")
		  else
		    animator.setAnimationState("torso", "idleToward")
		  end
	    elseif self.torsoOccupied and not self.mechFlipped then
	      if mechActiveSide == "left" then
		    animator.setAnimationState("torso", "idleToward")
	      else
		    animator.setAnimationState("torso", "idleAway")
		  end	  
	    end 
	  end
	end
	
  self.useSeatEnergy("seat",self.energyCostPerSecond * script.updateDt() + energyCostAccumulated)
--  return 0 -- tech.consumeTechEnergy(self.energyCostPerSecond * script.updateDt() + energyCostAccumulated)
  end  
  updateMechDamageEffects(false)
  
  return 0
end
