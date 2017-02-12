if xsm_mechdamage == nil then
xsm_mechdamage = "loaded"

function applyDamage(damageRequest)
  local damage = 0
  if damageRequest.damageType == "Damage" or damageRequest.damageType == "IgnoresDef" then
    damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection)
  elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  else
    return {}
  end

  if damage > 0 then
    updateMechDamage(damage)
    storage.health = storage.health - damage
  end

  if vehicle.getParameter then
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
  else
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = damage,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
  end

end

function updateMechDamage(damage)
local oldhp = storage.health / self.maxHealth
local newhp = (storage.health - damage) / self.maxHealth

  if oldhp > 0.8 and newhp <= 0.8 or oldhp > 0.6 and newhp <= 0.6
  or oldhp > 0.4 and newhp <= 0.4 or oldhp > 0.2 and newhp <= 0.2 then 
    updateMechDamageEffects(true) -- damageShards every 20%
  end

  if newhp <= 0 then -- blow chunks and EXPLOSIONS!
    local projectileConfig = {
      damageTeam = { type = "indiscriminate" },
      power = 1,
      onlyHitTerrain = true,
      timeToLive = 0.1,
      actionOnReap = {
        {
          action = "config",
          file =  "/projectiles/explosions/regularexplosion2/regularexplosion2.config"
        }
      }
    }
    world.spawnProjectile("invisibleprojectile", mcontroller.position(), 0, {0, 0}, false, projectileConfig)

    updateMechDamageEffects(true)
    animator.burstParticleEmitter("wreckage")

    vehicle.destroy()  -- your head asplode!
  end

end

function updateMechDamageEffects(dropShards)
if dropShards then animator.burstParticleEmitter("damageShards") return end
updateMechHealthBar()
local curhealth = storage.health/self.maxHealth
  if curhealth > 0.6 or math.random() < curhealth then return end  -- undamaged, gtfo
  
  if curhealth <= 0.6 and math.random()*0.6 > curhealth then    -- 1 smoke
    animator.burstParticleEmitter("smoke1")    
  end
  if curhealth <= 0.45 and math.random()*0.45 > curhealth then    -- 1 smoke
    animator.burstParticleEmitter("smoke1")    
  end
  if curhealth <= 0.3 and math.random()*0.3 > curhealth then   -- 1 smoke 1 fire
    animator.burstParticleEmitter("smoke2")    
    -- animator.burstParticleEmitter("fire1")
  end
  if curhealth <= 0.2 and math.random()*0.2 > curhealth then    -- 2 fire
    animator.burstParticleEmitter("fire1")
    -- animator.burstParticleEmitter("fire2")
  end


end

function updateMechHealthBar()
world.debugPoint(mcontroller.position(),"green")
world.debugText("%s/%s\n%s",storage.health,self.maxHealth,self.protection,mcontroller.position(),"red")
  vehicle.setInteractive(self.driver == nil)
if not animator.hasTransformationGroup("healthBar") then return end
if not animator.hasTransformationGroup("healthBarBack") then return end

  if self.driver == nil then 
    animator.setAnimationState("healthBar", "none")
    animator.setAnimationState("healthBarBack", "off")
    return
  end

  local ratio = storage.health / self.maxHealth
  local animationState = "full"
  local healthBarOffset = {-1.625,mcontroller.localBoundBox()[4]+self.healthBarY}
  local fd = self.mechFlipped and -1 or 1

  if ratio <= 0.8 then animationState = "high" end
  if ratio <= 0.6 then animationState = "medium" end
  if ratio <= 0.3 then animationState = "low" end
  if ratio <= 0 then animationState = "none" end

  local scale = {(self.mechFlipped and -1 or 1)*ratio * 24, 2}

  animator.resetTransformationGroup("healthBarBack")
  animator.translateTransformationGroup("healthBarBack", healthBarOffset)
  animator.setAnimationState("healthBarBack", "on")

  healthBarOffset[2] = healthBarOffset[2]+0.125
  healthBarOffset[1] = healthBarOffset[1] * fd + (fd*0.125)
  animator.resetTransformationGroup("healthBar")
  animator.scaleTransformationGroup("healthBar", scale)
  animator.translateTransformationGroup("healthBar", healthBarOffset)

  animator.setAnimationState("healthBar", animationState)

end

end --xsm_mechdamage