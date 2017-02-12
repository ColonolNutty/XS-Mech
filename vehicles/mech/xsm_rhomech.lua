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
  return root.evalFunction("weaponDamageLevelMultiplier", self.level) * pPower * self.damageMulti
end

function mechLevelAdjust(hp_or_armor)
  return root.evalFunction("shieldLevelMultiplier", self.level) * hp_or_armor
end

function init()
  self.active = false
--  tech.setVisible(false)
  animator.rotateGroup("guns", 0, true)
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
  
  -- Activate/Deactivate
  self.mechState = "off" -- Possible values "off" "turningOn" "on" "turningOff"
  self.mechStateTimer = 0
  
  -- Init landing variables
  self.fastDrop = false
  self.veryFastDrop = false
  self.veryVeryFastDrop = false
  self.movementSuppressed = false
  self.immobileTimer = 0
  
  -- Init jumping variables (short jump, dash, boost)
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
  self.isBoosting = false
  self.boostTimer = 0
  self.backHopTimer = 0
  self.isCrouching = false
  
  -- Weapon set
  self.weaponEquipped = 0
  
  -- Init melee variables
  self.rightArmOccupied = false
  self.leftArmOccupied = false
  self.frontArmOccupied = false
  self.backArmOccupied = false
  self.meleeTimer = 0
  self.oldMeleeTimer = 0
  self.twohswing = false
  self.weaponState = "idle"
  self.attackQueued = false
  self.attacking = false
  self.projectilesSpawned = 0
  self.forceWalkMelee = false
  
  -- Init tractor beam
  self.entityQueryTable = {}
  self.itemExceptionTable = {}
  self.altWeaponState = "idle"
  self.altTimer = 0
  self.forceWalkBeam = false
  self.beamTimer = 0
  
  -- Init machine gun
  self.mGunTimer = 0
  self.mGunState = "idle"
  self.forceWalkGun = false
  self.mGunRecoilKick = 0
  
  -- Energy usage
   self.energyCostPerSecond = 0--configParameter("energyCostPerSecond")
   self.energyCostPerSecondRunning = configParameter("energyCostPerSecondRunning")
   self.energyCostPerDash = configParameter("energyCostPerDash")
   self.energyCostPerBackHop = configParameter("energyCostPerBackHop")
   self.energyCostPerSecondBoost = configParameter("energyCostPerSecondBoost")
   self.energyCostPerBoost = configParameter("energyCostPerBoost")
   self.energyCostPerSlash = configParameter("energyCostPerSlash")
   self.energyCostPerSecondPull = configParameter("energyCostPerSecondPull")
   self.energyCostPerBullet = configParameter("energyCostPerBullet")
  
  -- Movement / misc
  -- local mechCustomMovementParameters = configParameter("mechCustomMovementParameters")
  -- local mechCustomTurningOnOffMovementParameters = copy(configParameter("mechCustomMovementParameters"))
  -- mechCustomTurningOnOffMovementParameters.runSpeed = 0.0
  -- mechCustomTurningOnOffMovementParameters.walkSpeed = 0.0
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
   self.boostSpeed = configParameter("boostSpeed")
   self.boostControlForce = configParameter("boostControlForce")
  
  -- Equipment
   self.mechLeftEquip = configParameter("mechLeftEquip")
   self.mechLeftAnimation = configParameter("mechLeftAnimation")
   self.mechRightEquip = configParameter("mechRightEquip")
   self.mechRightAnimation = configParameter("mechRightAnimation")
   self.mechEquip = {self.mechLeftEquip, self.mechRightEquip}
  
  -- Weapon 1 Plasma Lathe
   self.mechWeapon1Projectile = configParameter("mechWeapon1Projectile")
   self.mechWeapon1ProjectileF = configParameter("mechWeapon1ProjectileF")
   self.mechWeapon1Projectile2 = configParameter("mechWeapon1Projectile2")
   self.mechWeapon1Projectile2F = configParameter("mechWeapon1Projectile2F")
   self.mechWeapon1Projectile3 = configParameter("mechWeapon1Projectile3")
   self.mechWeapon1Projectile4 = configParameter("mechWeapon1Projectile4")
   self.mechWeapon1MinPower = configParameter("mechWeapon1MinPower")
   self.mechWeapon1MaxPower = configParameter("mechWeapon1MaxPower")
   self.mechWeapon1MaxEnergy = configParameter("mechWeapon1MaxEnergy") 
   self.mechWeapon1Scalar = (self.mechWeapon1MaxPower - self.mechWeapon1MinPower)/self.mechWeapon1MaxEnergy
   self.mechWeapon1DownSlashPowerMultiplier = configParameter("mechWeapon1DownSlashPowerMultiplier")
   self.mechWeapon1WindupTime = configParameter("mechWeapon1WindupTime")
   self.mechWeapon1SwingTime = configParameter("mechWeapon1SwingTime")
   self.mechWeapon1ProjectileSpawnDelay = self.mechWeapon1SwingTime - configParameter("mechWeapon1ProjectileSpawnDelay")
   self.mechWeapon1Projectile2SpawnDelay = self.mechWeapon1SwingTime - configParameter("mechWeapon1Projectile2SpawnDelay")
   self.mechWeapon1WinddownTime = configParameter("mechWeapon1WinddownTime")  
   self.mechWeapon1WindupTime2 = configParameter("mechWeapon1WindupTime2")
   self.mechWeapon1SwingTime2 = configParameter("mechWeapon1SwingTime2")
   self.mechWeapon1WinddownTime2 = configParameter("mechWeapon1WinddownTime2")    
   self.mechWeapon1ResetTime = configParameter("mechWeapon1ResetTime")
   self.mechWeapon1GracePeriod = configParameter("mechWeapon1GracePeriod")
   self.mechWeapon1CooldownTime = configParameter("mechWeapon1CooldownTime")
  
  -- Weapon 2 Zappo Graviton Beam
   self.mechWeapon2Mode = configParameter("mechWeapon2Mode")
   self.mechWeapon2WarmupTime = configParameter("mechWeapon2WarmupTime")
   self.mechWeapon2PullCoefficient = configParameter("mechWeapon2PullCoefficient")
   self.mechWeapon2MaxRange = configParameter("mechWeapon2MaxRange")
   self.mechWeapon2BeamCrosshair = configParameter("mechWeapon2BeamCrosshair")
   self.mechWeapon2BeamProjectile= configParameter("mechWeapon2BeamProjectile")
   self.mechWeapon2BeamIndicatorProjectile = configParameter("mechWeapon2BeamIndicatorProjectile")
   self.mechWeapon2BeamStep= configParameter("mechWeapon2BeamStep")
   self.mechWeapon2BeamUpdateTime = configParameter("mechWeapon2BeamUpdateTime")
   self.mechWeapon2BeamEndProjectile = configParameter("mechWeapon2BeamEndProjectile")
   self.mechWeapon2BeamStartProjectile = configParameter("mechWeapon2BeamStartProjectile")
   self.mechWeapon2BeamStartRadius = configParameter("mechWeapon2BeamStartRadius")
   self.mechWeapon2BeamIndicatorStartProjectile = configParameter("mechWeapon2BeamIndicatorStartProjectile")
  
  -- Weapon 3 Gun
   self.mechAimLimit = configParameter("mechAimLimit") * math.pi / 180
   self.mechFireCycle = configParameter("mechFireCycle")
   self.mechProjectile = configParameter("mechProjectile")
   self.mechProjectileConfig = configParameter("mechProjectileConfig")
   self.mechProjectileBasePower = configParameter("mechProjectileConfig.power")
   self.mechGunFireCone = configParameter("mechGunFireCone") * math.pi / 180
   self.mechGunRotationRadius = configParameter("mechGunRotationRadius")
   self.mechCasingProjectile = configParameter("mechCasingProjectile")
   self.mechGunChargeUpTime = configParameter("mechGunChargeUpTime")
   self.mechGunCooldownTime = configParameter("mechGunCooldownTime")
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
   self.mechLeftAnimation = configParameter("mechLeftAnimation")
   self.mechRightAnimation = configParameter("mechRightAnimation")
  animator.setAnimationState("movement", "sit")     
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
	mechAnimatePauldron("frontArmPauldronMovement", "idle")

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

	-- Animation / Particles
	animator.setAnimationState("jetFlame", "off")
	animator.setAnimationState("movement", "idle")
	animator.setAnimationState("frontWeapon1", "off")
	animator.setAnimationState("backWeapon1", "off")
	animator.setAnimationState("frontWeapon2", "off")
	animator.setAnimationState("backWeapon2", "off")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontArmMovement", "off")
	animator.setAnimationState("backArmMovement", "off")
	animator.setAnimationState("frontArmSwordMovement", "off")
	animator.setAnimationState("backArmSwordMovement", "off")
	animator.setAnimationState("frontArmGunMovement", "off")
	animator.setAnimationState("backArmGunMovement", "off")
	animator.setAnimationState("movement", "idle")
	animator.setAnimationState("torso", "idle")
	animator.setParticleEmitterActive("boostParticles", false)
	animator.setParticleEmitterActive("dashParticles", false)
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
  if vehicle.controlHeld("seat", "jump") then
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
    if self.holdingLeft then self.movingDirection = -1 end
    if ani == "walkSlow" or ani == "backWalkSlow" then
      speed = configParameter("mechWalkSlowSpeed")
    elseif ani == "backWalk" then
      speed = configParameter("mechBackwardSpeed")
    elseif ani == "run" then
      speed = configParameter("mechRunSpeed")
    else -- default to walk
      speed = configParameter("mechWalkSpeed")
    end
    
    speed = speed * self.movingDirection
    mcontroller.setXVelocity(speed)
    self.moving = true
    if self.holdingUp and mcontroller.onGround() then self.running = true end    
  end

  if not self.moving then
   mcontroller.approachXVelocity(0,100,true)
  end
  
  -- Double tap input for boosting -- blatantly stolen from dash.lua. Thanks Chucklefish!
  if self.dashTimer <= 0 then
	  local maximumDoubleTapTime = configParameter("maximumDoubleTapTime")

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
  
  -- if args.moves["special"] == 1 then
    -- if self.active then
      -- return "mechDeactivate"
    -- else
      -- return "mechActivate"
    -- end
  -- elseif args.moves["primaryFire"] then
    -- return "mechFire"
  -- end

  return nil
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
  end
  if not mechCheckArmOccupied(otherSide(altSide)) then
    mechAnimateActiveArm(frontState, backState, anim, otherSide(altSide), flipState)
    mechAnimateActiveArm(frontAltState, backAltState, "off", otherSide(altSide), flipState)
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
    animator.rotateGroup("guns", 0, true)
  end
  if entityInSeat ~= self.driver then
    self.driver = entityInSeat
    self.mechPilotProtection(entityInSeat)
  end
    
  if not self.active and self.driver ~= nil and self.mechState == "off" then
    -- mechCollisionTest[1] = mechCollisionTest[1] + mcontroller.position()[1]
    -- mechCollisionTest[2] = mechCollisionTest[2] + mcontroller.position()[2]
    -- mechCollisionTest[3] = mechCollisionTest[3] + mcontroller.position()[1]
    -- mechCollisionTest[4] = mechCollisionTest[4] + mcontroller.position()[2]
    -- if (not world.rectCollision(mechCollisionTest)) then
      -- -- animator.burstParticleEmitter("mechActivateParticles")
      -- mcontroller.translate(mechTransformPositionChange)
      -- tech.setVisible(true)
	  -- animator.setAnimationState("movement", "idle")
      -- tech.setParentState("stand")
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
	self.isBoosting = false
	self.boostTimer = 0
	self.backHopTimer = 0
	self.isCrouching = false
	
	-- Melee
    self.meleeTimer = 0
	self.oldMeleeTimer = 0
	self.forceWalk = false
	self.twohswing = false
	self.weaponState = "idle"
	self.attackQueued = false
	self.attacking = false
	self.projectilesSpawned = 0
	self.forceWalkMelee = false
    self.rightArmOccupied = false
    self.leftArmOccupied = false
    self.frontArmOccupied = false
    self.backArmOccupied = false
	
	-- Tractor beam
	self.entityQueryTable = {}
	self.itemExceptionTable = {}
    self.altWeaponState = "idle"
    self.altTimer = 0
	self.forceWalkBeam = false
	self.beamTimer = 0
	
	-- Machine Gun
	self.mGunTimer = 0
	self.mGunState = "idle"
	self.forceWalkGun = false
	self.mGunRecoilKick = 0
	
	-- Animation / Particles
	animator.setAnimationState("jetFlame", "off")
	animator.setAnimationState("frontWeapon1", "off")
	animator.setAnimationState("backWeapon1", "off")
	animator.setAnimationState("frontWeapon2", "off")
	animator.setAnimationState("backWeapon2", "off")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontArmMovement", "off")
	animator.setAnimationState("backArmMovement", "off")
	animator.setAnimationState("frontArmSwordMovement", "off")
	animator.setAnimationState("backArmSwordMovement", "off")
	animator.setAnimationState("frontArmGunMovement", "off")
	animator.setAnimationState("backArmGunMovement", "off")
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
	mechAnimatePauldron("frontArmPauldronMovement", "idle")
	animator.setAnimationState("movement", "sit")
	animator.setAnimationState("torso", "open")
	animator.setParticleEmitterActive("boostParticles", false)
	animator.setParticleEmitterActive("dashParticles", false)
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
  local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2  

  -- Basic animation
  if self.active then
  
--	mcontroller.controlParameters(mechCustomMovementParameters)
    
	-- Gun angle correction
	if table.exists("machineGun", self.mechEquip) and self.mechState == "on" then
	  local gunSide = nil
	  local gunRotationPosition = {}
	  if self.mechLeftEquip == "machineGun" then
		gunSide = "left"
	  elseif self.mechRightEquip == "machineGun" then
		gunSide = "right"
	  end
	  gunRotationPosition = vec_add(mcontroller.position(), mechChooseObject( animator.partPoint("frontArmGun","frontGunRotationPoint"), animator.partPoint("backArmGun","backGunRotationPoint"), gunSide, self.mechFlipped))  
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

	if (not self.isDashing) and (not self.attacking) and self.mechState == "on" then
		if flip then  
		  self.mechFlipped = true
		else
		  self.mechFlipped = false
		end
	end	
	if self.mechFlipped then
	  animator.setFlipped(true)  
	  if self.rightArmOccupied or self.twohswing then
		self.backArmOccupied = true
	  else
		self.backArmOccupied = false
	  end
	  if self.leftArmOccupied or self.twohswing then
		self.frontArmOccupied = true
	  else
		self.frontArmOccupied = false
	  end				  
	  -- local nudge = tech.appliedOffset()
	  -- tech.setParentOffset({-parentOffset[1] - nudge[1], parentOffset[2] + nudge[2]})
	  -- mcontroller.controlFace(-1)	
      if aimAngle > 0 then
        aimAngle = math.max(aimAngle, math.pi - self.mechAimLimit)
      else
        aimAngle = math.min(aimAngle, -math.pi + self.mechAimLimit)
      end
	  if self.mechState == "on" then
	    animator.rotateGroup("guns", math.pi - aimAngle)
	  else
	    animator.rotateGroup("guns", 0)
	  end
	else
	  animator.setFlipped(false)
	  if self.rightArmOccupied or self.twohswing then
		self.frontArmOccupied = true
	  else
		self.frontArmOccupied = false
	  end
	  if self.leftArmOccupied or self.twohswing then
		self.backArmOccupied = true
	  else
		self.backArmOccupied = false
	  end	
	  -- local nudge = tech.appliedOffset()
	  -- tech.setParentOffset({parentOffset[1] + nudge[1], parentOffset[2] + nudge[2]})
	  -- mcontroller.controlFace(1)		
      if aimAngle > 0 then
        aimAngle = math.min(aimAngle, self.mechAimLimit)
      else
        aimAngle = math.max(aimAngle, -self.mechAimLimit)
      end	  
	  if self.mechState == "on" then
	    animator.rotateGroup("guns", aimAngle)
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
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
	mechAnimatePauldron("frontArmPauldronMovement", "idle")
  elseif self.mechState == "turningOff" then
--	mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)
	animator.setAnimationState("movement", "sit")
	animator.setAnimationState("torso", "turnOff")	   
	mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
	mechAnimatePauldron("frontArmPauldronMovement", "idle")
  elseif self.active and self.mechState == "on" then
	
	-- Misc. Animation-related checks
	animator.setAnimationState("torso", "idle")
	  if self.mechLeftEquip == "machineGun" then
		mechSetArmOccupied ("left", true)
	  elseif self.mechRightEquip == "machineGun" then
		mechSetArmOccupied ("right", true)
	  end
	
	-- -- Equip guns (only gravGun arm can swap to a gun)
	-- local equipArm = nil
	-- if table.exists("gravGun", self.mechEquip) and self.altWeaponState == "idle" then	  
	  -- if world.entityHandItem(entity.id(), "primary") == "xsm_mechmachinegun" then
	    -- if self.mechLeftEquip == "gravGun" then
		  -- self.mechLeftEquip = "machineGun"
		  -- self.mechLeftAnimation = {"frontArmGunMovement", "backArmGunMovement"}
		  -- mechSetArmOccupied ("left", true)
		  -- equipArm = "left"
		-- elseif self.mechRightEquip == "gravGun" then
		  -- self.mechRightEquip = "machineGun"
		  -- self.mechRightAnimation = {"frontArmGunMovement", "backArmGunMovement"}
		  -- mechSetArmOccupied ("right", true)
		  -- equipArm = "right"
		-- end
		-- table.delete("gravGun", self.mechEquip)
		-- table.nrAdd("machineGun", self.mechEquip)
		-- -- Turn off grav gun animation
		-- animator.setAnimationState("frontArmMovement", "off")
		-- animator.setAnimationState("backArmMovement", "off")
		
		-- -- Other item checks
	  -- end
	-- elseif table.exists("machineGun", self.mechEquip) and world.entityHandItem(entity.id(), "primary") ~= "xsm_mechmachinegun" then		  
	  -- if self.mechLeftEquip == "machineGun" then
		  -- equipArm = "left"
	  -- elseif self.mechRightEquip == "machineGun" then
		  -- equipArm = "right"
	  -- end	
	  -- mechAnimateActiveArm("frontArmMovement", "backArmMovement", "idle", equipArm, self.mechFlipped)
	  -- table.delete("machineGun", self.mechEquip)

	  -- animator.setAnimationState("frontArmGunMovement", "off")
	  -- animator.setAnimationState("backArmGunMovement", "off")
	  -- mech.animateActiveArm
	-- end
	
	-- State checks, animation
	self.isCrouching = false
    if not mcontroller.onGround() then
      if mcontroller.velocity()[2] > 0 then
	    -- Jump animation only
        animator.setAnimationState("movement", "jump")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "jump")
		mechAnimatePauldron("frontArmPauldronMovement", "jump")
		self.fastDrop = false
	    self.veryFastDrop = false
      elseif not self.movementSuppressed then
	    -- Falling animation. Hard landings and very hard landings suppress movement temporarily.
		if not self.hasJumped then
	      self.jumpReleased = true
		end
        animator.setAnimationState("movement", "fall")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "fall")
		mechAnimatePauldron("frontArmPauldronMovement", "fall")
		if (mcontroller.velocity()[2] < -30 and mcontroller.velocity()[2] > -52) or math.abs(mcontroller.velocity()[1]) > 30 then
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
	  if self.holdingJump and not self.isBoosting and self.jumpReleased and not self.isDashing and not self.holdingDown and not self.energyLocked["seat"] then--and status.resource("energy") > (self.energyCostPerBoost + self.energyCostPerSecondBoost * 0.4) then
	    -- Initiate boosting
		self.jumpReleased = false	    
		self.isBoosting = true
		animator.playSound("boostInitiateSound")
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerBoost
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
--		elseif (mcontroller.walking() or mcontroller.running()) and not self.movementSuppressed then
		elseif (self.moving) and not self.movementSuppressed then
		  -- walk/run/backWalk/walkSlow/backWalkSlow animations
		  self.fastDrop = false
		  self.veryFastDrop = false
--		  local mechCustomHopMovementParameters = copy(configParameter("mechCustomMovementParameters"))
		  if self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1 then
		    if self.forceWalk then
			  animator.setAnimationState("movement", "backWalkSlow")
			  mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "backWalkSlow")
			  mechAnimatePauldron("frontArmPauldronMovement", "backWalkSlow")
--			  mechCustomHopMovementParameters.runSpeed = mechWalkSlowSpeed
--			  mechCustomHopMovementParameters.walkSpeed = mechWalkSlowSpeed
--			  mcontroller.controlParameters(mechCustomHopMovementParameters)	
			else  
			  animator.setAnimationState("movement", "backWalk")
		      mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "backWalk")
			  mechAnimatePauldron("frontArmPauldronMovement", "backWalk")
--			  mechCustomHopMovementParameters.runSpeed = mechBackwardSpeed
--			  mechCustomHopMovementParameters.walkSpeed = mechBackwardSpeed
--			  mcontroller.controlParameters(mechCustomHopMovementParameters)
			end
		  else
		    if self.forceWalk then
			  animator.setAnimationState("movement", "walkSlow")
			  mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "walkSlow")
			  mechAnimatePauldron("frontArmPauldronMovement", "walkSlow")
--			  mechCustomHopMovementParameters.runSpeed = mechWalkSlowSpeed
--			  mechCustomHopMovementParameters.walkSpeed = mechWalkSlowSpeed
--			  mcontroller.controlParameters(mechCustomHopMovementParameters)		
			else
			  if not self.running or (self.running and self.energyLocked["seat"]) then
			    animator.setAnimationState("movement", "walk")
			    mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "walk")
				mechAnimatePauldron("frontArmPauldronMovement", "walk")
			  else--if mcontroller.walking() then
			    animator.setAnimationState("movement", "run")
				animator.burstParticleEmitter("mechSteam2", true)
			    mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "run")
				mechAnimatePauldron("frontArmPauldronMovement", "run")
				energyCostAccumulated = energyCostAccumulated + self.energyCostPerSecondRunning * script.updateDt()
			  end
			end
		  end
		elseif not self.movementSuppressed then
		  -- Idle
		  self.fastDrop = false
		  self.veryFastDrop = false
		  mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "idle")
		  mechAnimatePauldron("frontArmPauldronMovement", "idle")
			-- Crouching
		  if self.holdingDown then
			animator.setAnimationState("movement", "sit")
			self.isCrouching = true
		  else
		    animator.setAnimationState("movement", "idle")
		  end
		end
	end
	
	-- Temp fall protection
	if mcontroller.velocity()[2] < -70 then
		mcontroller.approachYVelocity(-70, 6000, false)
	end
	
	-- Temp Air friction
	if math.abs(mcontroller.velocity()[1]) > 30 then
	  mcontroller.approachXVelocity(0, 100, true)
	end
	
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
	  if (self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1) and mcontroller.onGround() and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBackHop then
	    if self.backHopTimer <= 0 then
		  self.dashTimer = self.backHopDuration
	      self.dashDirection = 1	  
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBackHop
		  animator.playSound("backHopSound")
		  self.backHopTimer = self.backHopCooldown
		end
	  elseif mcontroller.onGround() and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerDash then
	    self.dashTimer = self.dashDuration
	    self.dashDirection = 2
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerDash
		animator.playSound("jumpSound")
		animator.playSound("dashSound")
	  elseif not (self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1) and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerDash then
	    self.dashTimer = self.dashDuration
	    self.dashDirection = 3
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerDash
		animator.playSound("dashSound")
	  end
      self.dashRight = false
	  self.isDashing = true
	  self.jumpReleased = true
	elseif self.dashLeft and self.dashTimer <= 0 and not self.movementSuppressed then
	  if (self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1) and mcontroller.onGround() and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBackHop then
	    if self.backHopTimer <= 0 then
		  self.dashTimer = self.backHopDuration
	      self.dashDirection = -1	 
		  energyCostAccumulated = energyCostAccumulated + self.energyCostPerBackHop
		  animator.playSound("backHopSound")
		  self.backHopTimer = self.backHopCooldown
		end
	  elseif mcontroller.onGround() and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerDash then  
	    self.dashTimer = self.dashDuration
	    self.dashDirection = -2
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerDash
		animator.playSound("jumpSound")
		animator.playSound("dashSound")
	  elseif not (self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1) and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerDash then
	    self.dashTimer = self.dashDuration
	    self.dashDirection = -3
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerDash 
		animator.playSound("dashSound")
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

	  -- Full Power Dash
	  elseif self.dashDirection == 2 then
		local diagX = math.cos(self.dashAngle)
		local diagY = math.sin(self.dashAngle)
		mcontroller.approachVelocity({self.dashSpeed * diagX, self.dashSpeed * diagY}, self.dashControlForce, true, true)
		animator.setAnimationState("jetPack", "boost3")
		animator.setAnimationState("jetFlame", "dash")
		animator.setParticleEmitterActive("dashParticles", true)
	  elseif self.dashDirection == -2 then
		local diagX = -math.cos(self.dashAngle)
		local diagY = math.sin(self.dashAngle)
		mcontroller.approachVelocity({self.dashSpeed * diagX, self.dashSpeed * diagY}, self.dashControlForce, true, true)	
		animator.setAnimationState("jetPack", "boost3")
		animator.setAnimationState("jetFlame", "dash")
		animator.setParticleEmitterActive("dashParticles", true)
		
	  -- Full Power Dash (in Midair)
	  elseif self.dashDirection == 3 then
		mcontroller.approachXVelocity(self.dashSpeed, self.dashControlForce, true)
		animator.setAnimationState("jetPack", "boost3")
		animator.setAnimationState("jetFlame", "dash")
		animator.setParticleEmitterActive("dashParticles", true)
	  elseif self.dashDirection == -3 then
		mcontroller.approachXVelocity(-self.dashSpeed, self.dashControlForce, true)	
		animator.setAnimationState("jetPack", "boost3")
		animator.setAnimationState("jetFlame", "dash")
		animator.setParticleEmitterActive("dashParticles", true)  
	  end  
	  self.dashTimer = self.dashTimer - script.updateDt()	  
	elseif self.isDashing then
	  self.isDashing = false
	  self.dashTimer = 0
	  animator.setAnimationState("jetPack", "turnoff3")
	  animator.setAnimationState("jetFlame", "off")
	  animator.setParticleEmitterActive("dashParticles", false)
	  self.jumpReleased = true
	end
	
	-- Boosting physics (Jetpack) - Dash overrides this
	if self.isBoosting and self.holdingJump and not self.isDashing and not self.energyLocked["seat"] then--and status.resource("energy") > ( self.energyCostPerSecondBoost * 0.4 ) then
	  mcontroller.approachYVelocity(self.boostSpeed, self.boostControlForce, true)
--	  local mechCustomJetpackMovementParameters = copy(configParameter("mechCustomMovementParameters"))
--	  mechCustomJetpackMovementParameters.airForce = self.mechBoostAirForce
--	  mcontroller.controlParameters(mechCustomJetpackMovementParameters)
	  animator.setAnimationState("jetPack", "boost1")
	  animator.setAnimationState("jetFlame", "boost")
	  animator.setParticleEmitterActive("boostParticles", true)
	  energyCostAccumulated = energyCostAccumulated + self.energyCostPerSecondBoost * script.updateDt()
	  self.boostTimer = self.boostTimer + script.updateDt()
	elseif self.isBoosting then
	  self.isBoosting = false
	  self.boostTimer = 0	
	  animator.setAnimationState("jetPack", "turnoff1")
	  animator.setAnimationState("jetFlame", "off")
	  animator.setParticleEmitterActive("boostParticles", false)
	end

	-- Landing Movement Suppression
	if self.immobileTimer > 0 and mcontroller.onGround() then
	  self.immobileTimer = self.immobileTimer - script.updateDt()  
	  -- Skidding
--	  local mechCustomSkiddingMovementParameters = copy(configParameter("mechCustomMovementParameters"))
	  if math.abs(mcontroller.velocity()[1]) < 15 then
		mcontroller.approachXVelocity(0, 3000, true)
		animator.setParticleEmitterActive("skidParticles", false)
	  elseif math.abs(mcontroller.velocity()[1]) < 30 then
	    -- do nothing
		animator.setParticleEmitterActive("skidParticles", false)
	  else
--	    mechCustomSkiddingMovementParameters.normalGroundFriction = self.mechSkiddingFriction
--	    mcontroller.controlParameters(mechCustomSkiddingMovementParameters) -- dynamic coefficient of friction, y'see....
		animator.setParticleEmitterActive("skidParticles", true)
		-- Spawn dust
	  end	  
	  -- Animation
	  if self.veryFastDrop or self.veryVeryFastDrop then
		animator.setAnimationState("movement", "landHard")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "landHard")	
		mechAnimatePauldron("frontArmPauldronMovement", "landHard")
	  elseif self.fastDrop then
		animator.setAnimationState("movement", "land")
		mechAnimateArms(self.mechLeftAnimation[1], self.mechLeftAnimation[2], self.mechRightAnimation[1], self.mechRightAnimation[2], "right", self.mechFlipped, "land")	
		mechAnimatePauldron("frontArmPauldronMovement", "land")
	  end
--	  mcontroller.controlParameters(mechCustomTurningOnOffMovementParameters)	  
	elseif (self.movementSuppressed and self.immobileTimer <= 0) or (self.immobileTimer > 0 and not mcontroller.onGround()) then
	  animator.setParticleEmitterActive("skidParticles", false)
	  self.movementSuppressed = false
	  self.immobileTimer = 0
	  self.fastDrop = false
	  self.veryFastDrop = false
	  self.veryVeryFastDrop = false
	end
	
	-- Force walking (when attacking with melee or beam)
	if self.forceWalkMelee or self.forceWalkBeam or self.forceWalkGun then
	  self.forceWalk = true
	else
	  self.forceWalk = false
	end
	
	-- Timers
	if self.meleeTimer > 0 then
	  self.meleeTimer = self.meleeTimer - script.updateDt()
	end
	if self.altTimer > 0 then
	  self.altTimer = self.altTimer - script.updateDt()
	end
	if self.backHopTimer > 0 then
	  self.backHopTimer = self.backHopTimer - script.updateDt()
	end
	if self.beamTimer > 0 then
	  self.beamTimer = self.beamTimer - script.updateDt()
	end
	if self.mGunTimer > 0 then
	  self.mGunTimer = self.mGunTimer - script.updateDt()
	end
	
	-- STANDARD WEAPON: Plasma Lathe. A one-handed plasma lathe (a sword built into the mech's arm). Damage scales with energy remaining.
	if table.exists("sword", self.mechEquip) then
	
	  local mechActiveSide = nil
	  local mechOtherSide = nil
	  local mechActiveAnim = {}
	  local mechOtherAnim = {}
	  local mechActiveSideButton = nil
	  local mechActiveSideButtonRelease = nil
	  
	  if self.mechLeftEquip == "sword" then
	    mechActiveSide = "left"
		mechOtherSide = "right"
		mechActiveAnim = self.mechLeftAnimation
		mechOtherAnim = self.mechRightAnimation
		mechActiveSideButton = self.holdingFire
		mechActiveSideButtonRelease = self.fireReleased
	  elseif self.mechRightEquip == "sword" then
	    mechActiveSide = "right"
		mechOtherSide = "left"
		mechActiveAnim = self.mechRightAnimation
		mechOtherAnim = self.mechLeftAnimation
		mechActiveSideButton = self.holdingAltFire
		mechActiveSideButtonRelease = self.altFireReleased
	  end
	  
	  if mechActiveSideButtonRelease and mechActiveSideButton and not self.attackQueued then
	    self.attackQueued = true
		releaseInput(mechActiveSide)
	  end
	  
	  if (self.weaponState == "slashUp_windup" or self.weaponState == "slashUp" or self.weaponState == "slashUp_winddown" or self.weaponState == "slashUp_reset" or self.weaponState == "slashDown_windup" or self.weaponState == "slashDown" or self.weaponState == "slashDown_winddown" or self.weaponState == "slashDown_reset") then
	    self.attacking = true
	  else
	    self.attacking = false
	  end  
	  	  
	  -- Primary attack
	  if (mechActiveSideButton or self.attackQueued) and self.meleeTimer <= 0 and self.weaponState == "idle" and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerSlash then
		-- Slash Up Wind Up
	    mechSetArmOccupied (mechActiveSide, true)
		self.forceWalkMelee = true	
	    self.attackQueued = false
		releaseInput(mechActiveSide)			    
		animator.playSound("mechWeapon1IgniteSound")		
	    self.weaponState = "slashUp_windup"
		self.meleeTimer = self.mechWeapon1WindupTime
	  elseif self.weaponState == "slashUp_windup" and self.meleeTimer <= 0 then
	    -- Slash Up
	    self.weaponState = "slashUp"
		self.meleeTimer = self.mechWeapon1SwingTime
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerSlash
		animator.playSound("mechWeapon1SwingSound")
		local firePoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontWeapon1","frontWeaponFirePoint"), animator.partPoint("backWeapon1","backWeaponFirePoint"), mechActiveSide, self.mechFlipped))
		world.spawnProjectile(self.mechWeapon1Projectile4, firePoint, entity.id(), {0, 0}, false)		
	  elseif self.weaponState == "slashUp" and self.meleeTimer > 0 then
		if self.oldMeleeTimer > self.mechWeapon1ProjectileSpawnDelay and self.meleeTimer <= self.mechWeapon1ProjectileSpawnDelay then  
		  -- Slash Up projectiles
		  local firePoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontWeapon1","frontWeaponFirePoint"), animator.partPoint("backWeapon1","backWeaponFirePoint"), mechActiveSide, self.mechFlipped))
		   self.mechProjectile = mechChooseObject(self.mechWeapon1Projectile, self.mechWeapon1ProjectileF, nil, self.mechFlipped)
		  local slashPower =  projectilePowerAdjust(self.mechWeapon1MaxPower)--math.min(status.resource("energy") * self.mechWeapon1Scalar, self.mechWeapon1MaxPower)
		  world.spawnProjectile(self.mechProjectile, firePoint, entity.id(), {0, 0}, false, {power = slashPower})
		  world.spawnProjectile(self.mechWeapon1Projectile3, firePoint, entity.id(), {0, 0}, false)
		end
		self.oldMeleeTimer = self.meleeTimer		
		-- Spawn any projectiles particles etc
	  elseif self.weaponState == "slashUp" and self.meleeTimer <= 0 then
	    -- Slash Up Wind Down
	    self.weaponState = "slashUp_winddown"
		self.meleeTimer = self.mechWeapon1WinddownTime
	  elseif self.weaponState == "slashUp_winddown" and self.meleeTimer <= 0 then
	    -- Limbo, can turn around here
	    self.weaponState = "limbo"
		self.meleeTimer = self.mechWeapon1GracePeriod
	  elseif self.weaponState == "limbo" and self.meleeTimer <= 0 then -- and not self.attackQueued then
	    -- Slash Up Reset
	    self.weaponState = "slashUp_reset"
		self.meleeTimer = self.mechWeapon1ResetTime 
	  elseif (self.weaponState == "limbo" or self.weaponState == "slashUp_reset") and self.attackQueued and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerSlash then
	    -- Slash Down Wind Up
	    self.attackQueued = false
		releaseInput(mechActiveSide)
	    self.weaponState = "slashDown_windup"
		self.meleeTimer = self.mechWeapon1WindupTime2
	  elseif self.weaponState == "slashDown_windup" and self.meleeTimer <= 0 then
	    -- Slash Down
	    self.weaponState = "slashDown"
		self.meleeTimer = self.mechWeapon1SwingTime2
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerSlash	
		animator.playSound("mechWeapon1SwingSound2")
		local firePoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontWeapon1","frontWeaponFirePoint"), animator.partPoint("backWeapon1","backWeaponFirePoint"), mechActiveSide, self.mechFlipped))
		world.spawnProjectile(self.mechWeapon1Projectile4, firePoint, entity.id(), {0, 0}, false)
	  elseif self.weaponState == "slashDown" and self.meleeTimer > 0 then
		if self.oldMeleeTimer > self.mechWeapon1Projectile2SpawnDelay and self.meleeTimer <= self.mechWeapon1Projectile2SpawnDelay then  
		  -- Slash Down projectiles
		  local firePoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontWeapon1","frontWeaponFirePoint"), animator.partPoint("backWeapon1","backWeaponFirePoint"), mechActiveSide, self.mechFlipped))
		   self.mechProjectile = mechChooseObject(self.mechWeapon1Projectile2, self.mechWeapon1Projectile2F, nil, self.mechFlipped)
		  local slashPower = projectilePowerAdjust(self.mechWeapon1MaxPower)*self.mechWeapon1DownSlashPowerMultiplier--math.min(status.resource("energy") * self.mechWeapon1Scalar, self.mechWeapon1MaxPower)
		  world.spawnProjectile(self.mechProjectile, firePoint, entity.id(), {0, 0}, false, {power = slashPower})
		  world.spawnProjectile(self.mechWeapon1Projectile3, firePoint, entity.id(), {0, 0}, false)
		end
		self.oldMeleeTimer = self.meleeTimer		
	  elseif self.weaponState == "slashDown" and self.meleeTimer <= 0 then
	    -- Slash Down Wind Down
	    self.weaponState = "slashDown_winddown"
		self.meleeTimer = self.mechWeapon1WinddownTime2
	  elseif self.weaponState == "slashDown_winddown" and self.meleeTimer <= 0 then
	    -- Limbo 2, can turn around here
	    self.weaponState = "limbo2"
		self.meleeTimer = self.mechWeapon1GracePeriod
	  elseif self.weaponState == "limbo2" and self.meleeTimer <= 0 then
	    -- Slash Down Reset
	    self.weaponState = "slashDown_reset"
		self.meleeTimer = self.mechWeapon1ResetTime
	  elseif (self.weaponState == "slashDown_reset" or self.weaponState == "limbo2") and self.attackQueued and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerSlash then
	    -- Slash Up Wind Up (for combo)
	    self.attackQueued = false
		releaseInput(mechActiveSide)
	    self.weaponState = "slashUp_windup"
		self.meleeTimer = self.mechWeapon1WindupTime
	  elseif (self.weaponState == "slashDown_reset" or self.weaponState == "slashUp_reset") and self.meleeTimer <= 0 then
	    -- Cooldown
	    animator.playSound("mechWeapon1TurnOffSound")
	    self.weaponState = "cooldown"
		self.meleeTimer = self.mechWeapon1CooldownTime	
	    mechSetArmOccupied (mechActiveSide, false)
		self.forceWalkMelee = false
		self.attackQueued = false
		releaseInput(mechActiveSide)		
	  elseif self.weaponState == "cooldown" and self.meleeTimer <= 0 then
	    -- Set Idle
		self.weaponState = "idle"		
		self.meleeTimer = 0
	  elseif self.weaponState == "idle" then
	    -- Idle State
		-- Do nothing
	  end
	  
	  -- Animation
		if self.weaponState == "slashUp_windup" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashIdleDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)		
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashIdleDown", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashUp" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashUp", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "slashUp", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)	
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashUp", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashUp_winddown" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashIdleUp", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)	
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashIdleUp", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "limbo" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashIdleUp", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)	
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashIdleUp", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashUp_reset" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "resetSlash", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "resetSlash", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)	
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "resetSlash", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashDown_windup" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashIdleUp", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)		
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashIdleUp", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashDown" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "slashDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)	
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashDown", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashDown_winddown" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashIdleDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashIdleDown", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "limbo2" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "slashIdleDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)	
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "slashIdleDown", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "slashDown_reset" then
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "resetSlashDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		  mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "resetSlashDown", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)		
		  mechAnimateActiveArm("frontArmPauldronMovement", nil, "resetSlashDown", mechActiveSide, self.mechFlipped)
		elseif self.weaponState == "cooldown" then
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)
		elseif self.weaponState == "idle" then
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechActiveSide, self.mechFlipped)
		  mechAnimateActiveArm("frontWeapon1", "backWeapon1", "off", mechOtherSide, self.mechFlipped)				
		end  
	end
	
	
	
	-- WEAPON: "Zappo" Graviton Beam. Can pull enemies to a set point, or alternatively, to the mouse cursor.
	if table.exists("gravGun", self.mechEquip) then
	
	  local mechActiveSide = nil
	  local mechOtherSide = nil
	  local mechActiveAnim = {}
	  local mechOtherAnim = {}
	  local mechActiveSideButton = nil
	  
	  if self.mechLeftEquip == "gravGun" then
	    mechActiveSide = "left"
		mechOtherSide = "right"
		mechActiveAnim = self.mechLeftAnimation
		mechOtherAnim = self.mechRightAnimation
		mechActiveSideButton = self.holdingFire
	  elseif self.mechRightEquip == "gravGun" then
	    mechActiveSide = "right"
		mechOtherSide = "left"
		mechActiveAnim = self.mechRightAnimation
		mechOtherAnim = self.mechLeftAnimation
		mechActiveSideButton = self.holdingAltFire
	  end
	
	  local pullTo = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontArm","frontGravFirePoint"), animator.partPoint("backArm","backGravFirePoint"), mechActiveSide, self.mechFlipped))
	  if self.altWeaponState == "idle" and mechActiveSideButton then
	  -- Warm up
	    mechSetArmOccupied (mechActiveSide, true)
		self.forceWalkBeam = true				    
		animator.playSound("mechWeapon2WarmupSound")		
	    self.altWeaponState = "warmup"
		self.altTimer = self.mechWeapon2WarmupTime		
	  elseif self.altWeaponState == "warmup" and self.altTimer <= 0 and mechActiveSideButton then
		self.altWeaponState = "firing"
		animator.playSound("mechWeapon2FireSound")
	  elseif self.altWeaponState == "firing" and mechActiveSideButton then	  
		if self.beamTimer <= 0 then
		  local endPoint = {0, 0}
		  local endPointCollisionTest = progressiveLineCollision(pullTo, vehicle.aimPosition("seat"), self.mechWeapon2BeamStep)
		    if math.distance(pullTo, endPointCollisionTest) <= self.mechWeapon2MaxRange then
			  endPoint = endPointCollisionTest
			else
			  local vec = math.getDir(pullTo, vehicle.aimPosition("seat"))
			  endPoint = { vec[1] * self.mechWeapon2MaxRange + pullTo[1], vec[2] * self.mechWeapon2MaxRange + pullTo[2] }
			end
		  progressiveLineCollision(pullTo, endPoint, self.mechWeapon2BeamStep, self.mechWeapon2BeamIndicatorProjectile)
		  world.spawnProjectile(self.mechWeapon2BeamIndicatorStartProjectile, pullTo, entity.id(), math.getDir(pullTo,endPoint), false,{speed=0})
		  world.spawnProjectile(self.mechWeapon2BeamCrosshair, endPoint, entity.id(), {0, 0}, false)
		  self.beamTimer = self.mechWeapon2BeamUpdateTime
		end
	  
	  -- Find a target
	    local entityTable = world.entityQuery(vehicle.aimPosition("seat"), 4)
	    if #entityTable > 0 then
	      for _, v in ipairs(entityTable) do
			-- if world.entityType(v) == "itemdrop" and (not table.exists(v, self.itemExceptionTable)) and (not world.lineTileCollision(pullTo, world.entityPosition(v)), "Dynamic") then
			  -- self.itemExceptionTable[#self.itemExceptionTable + 1] = v
			  -- local q = entity.id() --= world.playerQuery(mcontroller.position(), 4)
			    -- world.logInfo("%s", q)
			  -- local u = world.takeItemDrop(v, q)
			  -- if u == nil then
			    -- world.logInfo("%s", "XSM nil")
			  -- else
			    -- world.logInfo("%s", u)
			  -- end
			-- end	
			
		    if not table.exists(v, self.entityQueryTable) then	
			  -- With world.entityType(v) == "player", the Mech has the rather odd ability to grab itself. Not that it does anything.		  
			  if (world.entityType(v) == "monster" or world.entityType(v) == "npc") and (not world.lineTileCollision(pullTo, world.entityPosition(v), {"Null","Block","Dynamic"}))
			    and math.distance(pullTo, world.entityPosition(v)) <= self.mechWeapon2MaxRange and not self.energyLocked["seat"] then--and status.resource("energy") > (self.energyCostPerSecondPull * 0.5) then
			    self.entityQueryTable[#self.entityQueryTable + 1] = v
				self.altWeaponState = "locked"
				animator.playSound("mechWeapon2LockedSound")
				break -- Because we can only grab one at a time :D or else it would be OP D:
			  end
		    end	  
	      end
	    end
	  elseif self.altWeaponState == "locked" and mechActiveSideButton then
	  -- Pull Target	  
	    for _, v in ipairs(self.entityQueryTable) do
	      if world.entityExists(v) and not world.lineTileCollision(pullTo, world.entityPosition(v), {"Null","Block","Dynamic"}) 
        and math.distance(pullTo, world.entityPosition(v)) <= self.mechWeapon2MaxRange and not self.energyLocked["seat"] then--and status.resource("energy") > (self.energyCostPerSecondPull * 0.2) then		
			local diffX = (pullTo[1] - world.entityPosition(v)[1]) 
			local diffY = (pullTo[2] - world.entityPosition(v)[2])
			if self.mechWeapon2Mode == "control" then
			  diffX = (vehicle.aimPosition("seat")[1] - world.entityPosition(v)[1])
			  diffY = (vehicle.aimPosition("seat")[2] - world.entityPosition(v)[2])
			end		
		    local velocity = {self.mechWeapon2PullCoefficient * diffX, self.mechWeapon2PullCoefficient * diffY}		  
		    world.callScriptedEntity(v, "mcontroller.setVelocity", velocity)
			if self.beamTimer <= 0 then
				local vec = math.getDir(pullTo, world.entityPosition(v))
				local pullToOffset = { vec[1] * self.mechWeapon2BeamStartRadius + pullTo[1], vec[2] * self.mechWeapon2BeamStartRadius + pullTo[2] }
				local endPoint = progressiveLineCollision(pullToOffset, world.entityPosition(v), self.mechWeapon2BeamStep, self.mechWeapon2BeamProjectile)
				world.spawnProjectile(self.mechWeapon2BeamStartProjectile, pullTo, entity.id(), math.getDir(pullTo,endPoint), false,{speed=0})
				world.spawnProjectile(self.mechWeapon2BeamEndProjectile, endPoint, entity.id(), {0, 0}, false)
				self.beamTimer = self.mechWeapon2BeamUpdateTime
			end
		  else
		    table.remove(self.entityQueryTable, _)
		  end
	    end
		-- Energy Cost
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerSecondPull * script.updateDt()
	    -- Cancel
		if #self.entityQueryTable <= 0 then
		  self.altWeaponState = "firing"
		end			
	  elseif (self.altWeaponState == "firing" or self.altWeaponState == "locked" or self.altWeaponState == "warmup") and not mechActiveSideButton then
	  -- Cooldown
	    self.entityQueryTable = {}
		self.itemExceptionTable = {}
	    self.altWeaponState = "cooldown"
		self.altTimer = self.mechWeapon2WarmupTime
		self.forceWalkBeam = false
	  elseif self.altWeaponState == "cooldown" and self.altTimer <= 0 then
	  -- Set Idle
	    self.altWeaponState = "idle"
		mechSetArmOccupied (mechActiveSide, false)
		animator.playSound("mechWeapon2EndSound")
	  elseif self.altWeaponState == "idle" then
	    -- Idle; do nada
	  end
	  
	  -- Animation/Particles
	  if self.altWeaponState == "warmup" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gravOn", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontArmPauldronMovement", nil, "gravOn", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "off", mechOtherSide, self.mechFlipped)	
	  elseif self.altWeaponState == "firing" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gravFire", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontArmPauldronMovement", nil, "gravFire", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "gravFire", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "off", mechOtherSide, self.mechFlipped)	
		animator.setParticleEmitterActive("mechSteam", false)
	  elseif self.altWeaponState == "locked" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gravLock", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontArmPauldronMovement", nil, "gravLock", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "gravLock", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "off", mechOtherSide, self.mechFlipped)	
		animator.setParticleEmitterActive("mechSteam", true)
	  elseif self.altWeaponState == "cooldown" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "gravOff", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)	
		mechAnimateActiveArm("frontArmPauldronMovement", nil, "gravOff", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "off", mechActiveSide, self.mechFlipped)
		mechAnimateActiveArm("frontWeapon2", "backWeapon2", "off", mechOtherSide, self.mechFlipped)	
		animator.setParticleEmitterActive("mechSteam", false)
	  end
	end

	-- WEAPON: Heavy machine gun
	if table.exists("machineGun", self.mechEquip) then
	
	  local mechActiveSide = nil
	  local mechOtherSide = nil
	  local mechActiveAnim = {}
	  local mechOtherAnim = {}
	  local mechActiveSideButton = nil
    
    local mechGunRecoilKick = self.mechGunRecoilKick
		local mechGunFireCone = self.mechGunFireCone
		local mechGunRecoilSpeed = self.mechGunRecoilSpeed
		local mechGunRecoilPower = self.mechGunRecoilPower

	  
	  if self.mechLeftEquip == "machineGun" then
	    mechActiveSide = "left"
		mechOtherSide = "right"
		mechActiveAnim = self.mechLeftAnimation
		mechOtherAnim = self.mechRightAnimation
		mechActiveSideButton = self.holdingFire
	  elseif self.mechRightEquip == "machineGun" then
	    mechActiveSide = "right"
		mechOtherSide = "left"
		mechActiveAnim = self.mechRightAnimation
		mechOtherAnim = self.mechLeftAnimation
		mechActiveSideButton = self.holdingAltFire
	  end  
	  
	  -- Firing
	  if mechActiveSideButton and self.mGunState == "idle" and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBullet + 1 then
	    self.mGunState = "chargeUp"
		self.forceWalkGun = true
		self.mGunTimer = self.mechGunChargeUpTime
		animator.playSound("mechGunChargeUpSound")
	  elseif self.mGunState == "chargeUp" and self.mGunTimer <= 0 then
		if mechActiveSideButton and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBullet + 1 then
		  self.mGunState = "firing"
		  self.mGunTimer = 0
		else
		  self.mGunState = "coolDown"
		  self.mGunTimer = self.mechGunCooldownTime
		  animator.playSound("mechGunCooldownSound")
		  self.forceWalkGun = false
		end		
	  elseif self.mGunState == "firing" and self.mGunTimer <= 0 then
	    -- If crouching, reduce fire cone, gun kick and recoil; if in the air, increase fire cone and kick (but reduce recoil due to weird physics)
		if self.isCrouching then
		  mechGunRecoilKick = self.mechGunRecoilKick * 0.5
		  -- mechGunFireCone = self.mechGunFireCone * 0.5
		  mechGunRecoilSpeed = self.mechGunRecoilSpeed * 0.85
		  mechGunRecoilPower = self.mechGunRecoilPower * 0.85
		elseif not mcontroller.onGround() then
		  mechGunRecoilKick = self.mechGunRecoilKick * 1.25
		  mechGunFireCone = self.mechGunFireCone * 1.5
		  mechGunRecoilSpeed = self.mechGunRecoilSpeed * 0.85
		  mechGunRecoilPower = self.mechGunRecoilPower * 0.5
		end
	    -- Fire shot
		local firePoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontArmGun","frontGunFirePoint"), animator.partPoint("backArmGun","backGunFirePoint"), mechActiveSide, self.mechFlipped))
		local fireAngle = aimAngle - mechGunFireCone + math.random() * 2 * mechGunFireCone
   self.mechProjectileConfig.power = projectilePowerAdjust(self.mechProjectileBasePower)
		world.spawnProjectile(self.mechProjectile, firePoint, entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechProjectileConfig)
		energyCostAccumulated = energyCostAccumulated + self.energyCostPerBullet
	    self.mGunState = "fireCycle"
		self.mGunTimer = self.mechFireCycle
		animator.playSound("mechFireSound")
		mechAnimateActiveArm("frontFiring", "backFiring", "fire", mechActiveSide, self.mechFlipped)	
		-- Casing ejection
		local casingPoint = vec_add(mcontroller.position(), mechChooseObject(animator.partPoint("frontArmGun","frontGunCasingPoint"), animator.partPoint("backArmGun","backGunCasingPoint"), mechActiveSide, self.mechFlipped))
		world.spawnProjectile(self.mechCasingProjectile, casingPoint, entity.id(), {math.random() - 0.5, 1}, false)
		-- Recoil
		self.mGunRecoilKick = self.mGunRecoilKick + mechGunRecoilKick
		local diagX = -math.cos(fireAngle)
		mcontroller.approachXVelocity(mechGunRecoilSpeed * diagX, mechGunRecoilPower * math.abs(diagX), true)	
	  elseif self.mGunState == "fireCycle" and self.mGunTimer <= 0 then
	    if mechActiveSideButton and not self.energyLocked["seat"] then--and status.resource("energy") > self.energyCostPerBullet + 1 then
		  self.mGunState = "firing"
		  self.mGunTimer = 0
		else
		  self.mGunState = "coolDown"
		  self.mGunTimer = 0
		  animator.playSound("mechEndFireSound")
		  animator.playSound("mechGunCooldownSound")
		  self.forceWalkGun = false
		  self.mGunRecoilKick = 0
		end
	  elseif self.mGunState == "coolDown" and self.mGunTimer <= 0 then
		self.mGunState = "idle"
		self.mGunTimer = 0	
		self.mGunRecoilKick = 0
	  end
	  
	  -- Animation
	  local animAnglePauldron = {"gun-60Idle", "gun-30Idle", "gun+30Idle", "gun+60Idle", "gun+90Idle"}
	  mechAnimateActiveArm("frontArmPauldronMovement", nil, chooseAnimAngle(aimAngle, -self.mechAimLimit, self.mechAimLimit, animAnglePauldron, self.mechFlipped), mechActiveSide, self.mechFlipped)
	  if self.mGunState == "firing" then
		mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "idle", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)
	  elseif self.mGunState == "fireCycle" then
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "fire", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)	
	  elseif self.mGunState == "idle" or self.mGunState == "chargeUp" or self.mGunState == "coolDown" then
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "idle", mechActiveSide, self.mechFlipped)
	    mechAnimateActiveArm(mechActiveAnim[1], mechActiveAnim[2], "off", mechOtherSide, self.mechFlipped)
		mechAnimateActiveArm(mechOtherAnim[1], mechOtherAnim[2], "off", mechActiveSide, self.mechFlipped)		  	  
	  end
	end
	
  self.useSeatEnergy("seat",self.energyCostPerSecond * script.updateDt() + energyCostAccumulated)
--  return 0 -- tech.consumeTechEnergy(self.energyCostPerSecond * script.updateDt() + energyCostAccumulated)
  end  
  updateMechDamageEffects(false)
  
  return 0
end
