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
  self.fireTimer = 0
  self.altFireTimer = 0
  self.altFireIntervalTimer = 0
  self.altFireCount = 0
--  tech.setVisible(false)
  animator.rotateGroup("guns", 0, true)
  self.holdingJump = false
  self.jumpPressed = false
  self.jumpReleased = false
  self.holdingUp = false
  self.holdingDown = false
  self.holdingPrimaryFire = false
  self.holdingAltFire = false
  self.hoverTimer = 0
  self.bHasHovered = false
  self.bIsHovering = false
  self.fTracerCount = 0
  self.bTracerCount = 0
  self.mechFlipped = false
  
  
  self.mechStartupTime = configParameter("mechStartupTime")
  self.mechShutdownTime = configParameter("mechShutdownTime")
  
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
  self.mechFireCycle = configParameter("mechFireCycle")
  self.mechProjectile = configParameter("mechProjectile")
  self.mechTracerProjectile = configParameter("mechTracerProjectile")
  self.mechProjectileConfig = configParameter("mechProjectileConfig")
  self.mechProjectilePower = configParameter("mechProjectileConfig.power")
  
  self.mechGunFireCone = configParameter("mechGunFireCone") * math.pi / 180
  
  self.mechAltFireCycle = configParameter("mechAltFireCycle") 
  self.mechAltProjectile = configParameter("mechAltProjectile")
  self.mechAltProjectileConfig = configParameter("mechAltProjectileConfig")
  self.mechAltProjectilePower = configParameter("mechAltProjectileConfig.power")
  self.mechAltFireShotInterval = configParameter("mechAltFireShotInterval")
  
  self.mechHoverSpeed = configParameter("mechHoverSpeed")
  self.mechHoverTime = configParameter("mechHoverTime")
  self.energyCostPerSecond = 0--configParameter("energyCostPerSecond")
  self.energyCostPerPrimaryShot = configParameter("energyCostPerPrimaryShot")
  self.energyCostPerAltShot = configParameter("energyCostPerAltShot")
  self.energyCostPerSecondRunning = configParameter("energyCostPerSecondRunning")
--  self.energyCostPerHover = configParameter("energyCostPerHover")
  self.energyCostPerSecondHovering = configParameter("energyCostPerSecondHovering")

  -- Activate/Deactivate
  self.mechState = "off" -- Possible values "off" "turningOn" "on" "turningOff"
  self.mechStateTimer = 0
  
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
    animator.setAnimationState("movement", "sit")     
    animator.setAnimationState("torso", "open")--o
  else
    local startHealthFactor = configParameter("startHealthFactor")

    if (startHealthFactor == nil) then
        storage.health = self.maxHealth or 1
    else
       storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
    end    
    animator.setAnimationState("movement", "sit")  -- change to warping
    animator.setAnimationState("torso", "turnOff")--tof
  end

  --setup the store functionality  
  message.setHandler("store",
      function(_, _, ownerKey)
        if (self.ownerKey and self.ownerKey == ownerKey and self.driver == nil and animator.animationState("movement") == "sit") then
          animator.setAnimationState("torso", "turnOn")
          animator.setAnimationState("movement", "stand")
          self.mechState = "despawn"
          self.mechStateTimer = configParameter("mechShutdownTime")
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
	
	-- Particles / Anims
	animator.setAnimationState("movement", "idle")
	animator.setAnimationState("hovering", "off")
	animator.setAnimationState("torso", "idle")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontRecoil", "off")
	animator.setAnimationState("backRecoil", "off")
	animator.setAnimationState("missilePodRecoil", "off")
	animator.setParticleEmitterActive("hoverParticles", false)
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
    if mcontroller.onGround() and not self.holdingDown then 
      mcontroller.setYVelocity(48) -- jump velocity
      -- should play jump sound here instead of in animation
    end 
    elseif not self.holdingJump and self.jumpPressed and not self.jumpReleased then
	  self.jumpReleased = true
	  self.jumpPressed = false
    end
  end
  
  if vehicle.controlHeld("seat", "up") then
    self.holdingUp = true
  else
    self.holdingUp = false
    self.running = false
  end
  
  if vehicle.controlHeld("seat", "down") then
    self.holdingDown = true
    if mcontroller.onGround() and self.holdingJump then
      mcontroller.applyParameters({ignorePlatformCollision=true})
    end
  else
    self.holdingDown = false
    if mcontroller.parameters().ignorePlatformCollision then
      mcontroller.applyParameters({ignorePlatformCollision=false})
    end
  end

  if vehicle.controlHeld("seat", "left") and self.mechState == "on" then
    local mechHorizontalMovement = configParameter("mechHorizontalMovement")
    if not self.mechFlipped then -- backwalking
      mechHorizontalMovement = configParameter("mechHorizontalBackMovement")
    elseif self.holdingUp and mcontroller.onGround() and not self.energyLocked["seat"] then
      self.running = true
      mechHorizontalMovement = configParameter("mechHorizontalRunMovement")
    end
    mcontroller.setXVelocity(-mechHorizontalMovement)
    self.moving = true
    self.movingDirection = -1
  elseif vehicle.controlHeld("seat", "right") and self.mechState == "on" then
    local mechHorizontalMovement = configParameter("mechHorizontalMovement")
    if self.mechFlipped then -- backwalking
      mechHorizontalMovement = configParameter("mechHorizontalBackMovement")
    elseif self.holdingUp and mcontroller.onGround() and not self.energyLocked["seat"] then
      self.running = true
      mechHorizontalMovement = configParameter("mechHorizontalRunMovement")
    end
    mcontroller.setXVelocity(mechHorizontalMovement)
    self.moving = true
    self.movingDirection = 1
  else
    self.moving = false
    self.running = false
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

function update(args)
  if self.mechState == "despawn" and self.mechStateTimer <= 0 then 
    vehicle.destroy() 
    return
  end
animator.setAnimationRate(1)
  local primaryShotsFired = 0
  local altShotsFired = 0
  
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
    -- if not world.rectCollision(mechCollisionTest) then
      -- animator.burstParticleEmitter("mechActivateParticles")
      -- mcontroller.translate(mechTransformPositionChange)
      -- tech.setVisible(true)
--	     animator.setAnimationState("movement", "sit")
      -- tech.setParentState("sit")
      -- tech.setToolUsageSuppressed(true)

	    self.mechState = "turningOn"
	    self.mechStateTimer = self.mechStartupTime
	    self.active = true
	    animator.playSound("mechStartupSound")
	  
	  local diff = world.distance(vehicle.aimPosition("seat"), mcontroller.position())
      local aimAngle = math.atan(diff[2], diff[1])
      self.mechFlipped = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2
    -- else
      -- -- Make some kind of error noise
    -- end
  elseif self.mechState == "turningOn" and self.mechStateTimer <= 0 then
    self.mechState = "on"
	self.mechStateTimer = 0
  elseif (self.active and self.driver == nil and self.mechState == "on" ) then
	self.mechState = "turningOff"
	self.mechStateTimer = self.mechShutdownTime
	animator.playSound("mechShutdownSound")
  elseif self.mechState == "turningOff" and self.mechStateTimer <= 0 then 
    animator.burstParticleEmitter("mechDeactivateParticles")
	
	-- Particles / Anims
	animator.setAnimationState("movement", "sit")
	animator.setAnimationState("torso", "open")
	animator.setAnimationState("hovering", "off")
	animator.setAnimationState("frontFiring", "off")
	animator.setAnimationState("backFiring", "off")
	animator.setAnimationState("frontRecoil", "off")
	animator.setAnimationState("backRecoil", "off")
	animator.setAnimationState("missilePodRecoil", "off")
	animator.setParticleEmitterActive("hoverParticles", false)
	
	self.jumpPressed = false
	self.jumpReleased = false
    self.hoverTimer = 0
    -- self.bHasHovered = false
    self.bIsHovering = false
	self.mechState = "off"
	self.mechStateTimer = 0
	
    self.active = false
  end

  --mcontroller.controlFace(nil)
  
  if self.mechStateTimer > 0 then
	self.mechStateTimer = self.mechStateTimer - script.updateDt()
  end

 local diff = world.distance(vehicle.aimPosition("seat"), mcontroller.position())
 local aimAngle = math.atan(diff[2], diff[1])
 local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2
  
  -- Basic animation
  if self.active then
	if self.mechState == "on" then
		if flip then  
		  self.mechFlipped = true
		else
		  self.mechFlipped = false
		end
	end	
	if self.mechFlipped then
	  animator.setFlipped(true)  			  
	  -- local nudge = tech.appliedOffset()
	  -- tech.setParentOffset({-parentOffset[1] - nudge[1], parentOffset[2] + nudge[2]})
	  -- mcontroller.controlFace(-1)	
      if aimAngle > 0 then
        aimAngle = math.max(aimAngle, math.pi - self.mechAimLimit)
      else
        aimAngle = math.min(aimAngle, -math.pi + self.mechAimLimit)
      end
	  animator.rotateGroup("guns", math.pi - aimAngle)	  
	else
	  animator.setFlipped(false)
	  -- local nudge = tech.appliedOffset()
	  -- tech.setParentOffset({parentOffset[1] + nudge[1], parentOffset[2] + nudge[2]})
	  -- mcontroller.controlFace(1)	
      if aimAngle > 0 then
        aimAngle = math.min(aimAngle, self.mechAimLimit)
      else
        aimAngle = math.max(aimAngle, -self.mechAimLimit)
      end	  
	  animator.rotateGroup("guns", aimAngle)
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
--  mcontroller.controlParameters(mechCustomMovementParameters)
	animator.setAnimationState("torso", "idle")	   
    if not mcontroller.onGround() then
	  if self.holdingJump and not self.holdingDown and self.jumpReleased and not self.bHasHovered then
	    -- Activate hovering
	    self.bIsHovering = true
		self.hoverTimer = self.mechHoverTime
		self.bHasHovered = true
		self.jumpReleased = false
	  elseif mcontroller.velocity()[2] > 0 and not self.bIsHovering then
        animator.setAnimationState("movement", "jump")
	  elseif self.bIsHovering and not self.energyLocked["seat"] then --and self.hoverTimer > 0
	    -- Maintain hovering
		animator.setAnimationState("movement", "jump")
		if self.holdingUp and not self.holdingDown then
		  mcontroller.approachYVelocity(5, 5000, false)
		elseif self.holdingDown and not self.holdingUp then
	      mcontroller.approachYVelocity(-5, 5000, false)
		else
		  mcontroller.approachYVelocity(0, 1000, true)
		end			
		-- Hover Timer
		self.hoverTimer = self.hoverTimer - script.updateDt()			
		if self.jumpReleased and self.holdingJump then
			-- Deactivate hovering if jump is pressed again
			self.hoverTimer = 0
			self.bIsHovering = false
			self.jumpReleased = false
			animator.setAnimationState("movement", "fall")	
		end		
	  elseif self.bIsHovering and (self.energyLocked["seat"]) then --self.hoverTimer <= 0 or 
		-- Deactivate hovering if hover time runs out
		self.jumpReleased = false
		self.hoverTimer = 0
		self.bIsHovering = false
		animator.setAnimationState("movement", "fall")	
      else
        animator.setAnimationState("movement", "fall")
		self.jumpReleased = true
      end
	elseif mcontroller.onGround() and self.bHasHovered then
	  -- Deactivate hovering if on the ground, reset hover ability
	  self.bHasHovered = false
	  self.bIsHovering = false
	  self.jumpReleased = false
  elseif self.moving then --mcontroller.walking() or mcontroller.running() then
	  self.jumpReleased = false
      if self.bIsHovering then
	    -- Deactivate hovering if walking/running
		self.hoverTimer = 0
		self.bIsHovering = false
		self.bHasHovered = false
	  end 
	  if self.mechFlipped and self.movingDirection == 1 or not self.mechFlipped and self.movingDirection == -1 then
        animator.setAnimationState("movement", "backWalk")
      else
        animator.setAnimationState("movement", "walk")
        animator.setAnimationRate((math.abs(mcontroller.xVelocity()))*0.1)
      end
    else
	  self.jumpReleased = false
	  -- Crouching
	  if self.holdingDown then
		animator.setAnimationState("movement", "sit")
	  else
		animator.setAnimationState("movement", "idle")
	  end
    end
	
	-- If hovering, activate hover animations, sound, and particle effects. Otherwise deactivate.
	if self.bIsHovering then
      animator.setAnimationState("hovering", "on")
      animator.setParticleEmitterActive("hoverParticles", true)
    else
      animator.setAnimationState("hovering", "off")
      animator.setParticleEmitterActive("hoverParticles", false)
    end
	
	-- Temp fall protection
	if mcontroller.velocity()[2] < -70 then
		mcontroller.approachYVelocity(-70, 6000, false)
	end

	-- Primary weapon system (Miniguns)
 --   if args.actions["mechFire"] and status.resource("energy") > energyCostPerPrimaryShot then
  if self.holdingPrimaryFire and not self.energyLocked["seat"] then
   self.mechProjectileConfig.power = projectilePowerAdjust(self.mechProjectilePower)
 if self.fireTimer <= 0 then
	    local fireAngle = aimAngle - self.mechGunFireCone * math.random() + self.mechGunFireCone * math.random()      		
		-- Front Gun Tracer Counter
		if self.fTracerCount < 4 then
		  world.spawnProjectile(self.mechProjectile, vec_add(mcontroller.position(), animator.partPoint("frontGun","firePoint")), entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechProjectileConfig)
          self.fTracerCount = self.fTracerCount + 1
		else
		  world.spawnProjectile(self.mechTracerProjectile, vec_add(mcontroller.position(), animator.partPoint("frontGun","firePoint")), entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechProjectileConfig)
		  self.fTracerCount = 0
		end
		self.fireTimer = self.fireTimer + self.mechFireCycle
        animator.setAnimationState("frontFiring", "fire")
		animator.setAnimationState("frontRecoil", "fire")
		animator.playSound("mechFireSound")
		primaryShotsFired = primaryShotsFired + 1
      else
        local oldFireTimer = self.fireTimer
        self.fireTimer = self.fireTimer - script.updateDt()
        if oldFireTimer > self.mechFireCycle / 2 and self.fireTimer <= self.mechFireCycle / 2 then
          local fireAngle = aimAngle - self.mechGunFireCone + math.random() * 2 * self.mechGunFireCone
		  -- Back Gun Tracer Counter
		  if self.bTracerCount < 4 then
		    world.spawnProjectile(self.mechProjectile, vec_add(mcontroller.position(), animator.partPoint("backGun","firePoint")), entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechProjectileConfig)
            self.bTracerCount = self.bTracerCount + 1
		  else
		    world.spawnProjectile(self.mechTracerProjectile, vec_add(mcontroller.position(), animator.partPoint("backGun","firePoint")), entity.id(), {math.cos(fireAngle), math.sin(fireAngle)}, false, self.mechProjectileConfig)
            self.bTracerCount = 0
		  end		  
		  animator.setAnimationState("backFiring", "fire")
		  animator.setAnimationState("backRecoil", "fire")
		  animator.playSound("mechFireSound2")
		  primaryShotsFired = primaryShotsFired + 1
        end
      end
    end

	-- Secondary weapon system (Missile Pod)
	if self.altFireTimer <= 0 and self.altFireCount <= 0 then
	  animator.setAnimationState("missilePodRecoil", "off")
      if self.holdingAltFire and not self.energyLocked["seat"] then--and status.resource("energy") > energyCostPerAltShot then
	    -- Prime pod for firing
	    self.altFireIntervalTimer = 0 -- mechAltFireShotInterval
	    self.altFireCount = 1
		self.altFireTimer = self.mechAltFireCycle
	  end
	elseif self.altFireTimer <= 1.0 and self.altFireCount >= 5 then
	  -- Reloading animation, reset weapon system
	  animator.setAnimationState("missilePodRecoil", "reload")
	  self.altFireCount = 0
	end
	-- Advance Timers
	if self.altFireTimer > 0 then
	  self.altFireTimer = self.altFireTimer - script.updateDt()
	end	
	if self.altFireIntervalTimer > 0 then
	  self.altFireIntervalTimer = self.altFireIntervalTimer - script.updateDt()	
	end
    -- Missile barrage	
	if self.altFireIntervalTimer <= 0 and self.altFireCount > 0 and self.altFireCount < 5 then
   self.mechAltProjectileConfig.power = projectilePowerAdjust(self.mechAltProjectilePower)
	  self.altFireIntervalTimer = self.mechAltFireShotInterval
	  if self.altFireCount == 1 then
	    world.spawnProjectile(self.mechAltProjectile, vec_add(mcontroller.position(), animator.partPoint("missilepod","missilePodFirePoint1")), entity.id(), {math.sign(math.cos(aimAngle)) * 0.754, 0.656}, false, self.mechAltProjectileConfig)
        animator.setAnimationState("missilePodRecoil", "fire1")
		animator.playSound("mechAltFireSound")	
	  elseif self.altFireCount == 2 then
	    world.spawnProjectile(self.mechAltProjectile, vec_add(mcontroller.position(), animator.partPoint("missilepod","missilePodFirePoint2")), entity.id(), {math.sign(math.cos(aimAngle)) * 0.731, 0.682}, false, self.mechAltProjectileConfig)
        animator.setAnimationState("missilePodRecoil", "fire2")
		animator.playSound("mechAltFireSound")	
	  elseif self.altFireCount == 3 then
	    world.spawnProjectile(self.mechAltProjectile, vec_add(mcontroller.position(), animator.partPoint("missilepod","missilePodFirePoint3")), entity.id(), {math.sign(math.cos(aimAngle)) * 0.707, 0.707}, false, self.mechAltProjectileConfig)
        animator.setAnimationState("missilePodRecoil", "fire3")
		animator.playSound("mechAltFireSound")		
	  elseif self.altFireCount == 4 then
	    world.spawnProjectile(self.mechAltProjectile, vec_add(mcontroller.position(), animator.partPoint("missilepod","missilePodFirePoint4")), entity.id(), {math.sign(math.cos(aimAngle)) * 0.682, 0.731}, false, self.mechAltProjectileConfig)
        animator.setAnimationState("missilePodRecoil", "fire4")
		animator.playSound("mechAltFireSound")	
	  end
	  self.altFireCount = self.altFireCount + 1
	  altShotsFired = altShotsFired + 1
	end

  self.useSeatEnergy("seat",self.energyCostPerSecond * script.updateDt() + altShotsFired * self.energyCostPerAltShot + primaryShotsFired * self.energyCostPerPrimaryShot 
    + (self.running and self.energyCostPerSecondRunning * script.updateDt() or 0) + (self.bIsHovering and self.energyCostPerSecondHovering * script.updateDt() or 0))
--    return 0 -- tech.consumeTechEnergy(energyCostPerSecond * args.dt + altShotsFired * energyCostPerAltShot + primaryShotsFired * energyCostPerPrimaryShot)
  end
  updateMechDamageEffects(false)

  return 0
end
