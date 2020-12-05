--------
-- Chase cam script for Assetto Corsa pretending to be a drone flying ahead of the car.
--
-- Based on "Drone by Bombadil" script from Custom Shader Patch.
--------

-- This thing will smooth car velocity to reduce wobbling with replays or in online:
local carVelocity = smoothing(vec3(), 50)
local lastCarPos = vec3()

-- Will be called each frame:
-- Note: `dt` is time passed since last frame, `cameraIndex` is 1 or 2, depending on which camera is
-- chosen.
function update(dt, cameraIndex)

  smoothing.setDT(dt)

  -- Get AC camera parameters with some corrections to be somewhat compatible:
  local carForces = ac.getCarGForces()
  local cameraParameters = ac.getCameraParameters(cameraIndex)
  local camConfigDistance = cameraParameters.distance + 2.50 - math.clamp(carForces.z / 2, -3, 3)
  local height = cameraParameters.height
  local pitchAngle = cameraParameters.pitch

  -- Get car position and vectors:
  local carPos = ac.getCarPosition()
  local carDir = ac.getCarDirection()
  local carUp = ac.getCarUp()
  local carRight = math.cross(carDir, carUp):normalize()

  if lastCarPos == carPos then
  	return
  end

  local delta = lastCarPos - carPos
  local deltaLength = #delta
  if deltaLength > 5 then delta = delta / deltaLength * 5 end
  carVelocity:update(-delta / dt)
  lastCarPos = carPos

  local carVelocityDir = math.normalize(carVelocity.val)
  local carVelocityLen = #carVelocity.val

  local distanceToCar = #(carPos - ac.Camera.position)
  local distanceOffset = 50 + math.clamp(distanceToCar - 7, 0, 7) + carVelocityLen / 10

  ---- Lerp cam position

  local raise = math.clamp((distanceToCar - 6) / 3, 0, 30)
  local speedup = math.clamp((distanceToCar - 80) / 3, 0, 60)

  local targetCamPos = carPos
    + carVelocityDir * camConfigDistance * 2
    - carVelocityDir * distanceOffset
    + vec3(0, height - 0.5 + raise, 0)

  local posChange = math.lerp(ac.Camera.position, targetCamPos, dt * (2 + carVelocityLen / 15)) - ac.Camera.position
  local posChangeLen = #posChange
  posChange = posChange:normalize() * math.clamp(posChangeLen, 0, (carVelocityLen + 20 + speedup) * dt)
  ac.Camera.position = ac.Camera.position + posChange

  ---- Look

  -- Find camera look
  local targetCameraLook = (carPos - carDir * 3 - ac.Camera.position):normalize()
  -- Use of `pitchAngle`:
  targetCameraLook:rotate(quat.fromAngleAxis(math.radians(pitchAngle), carRight))
  
  local angle = math.angle(ac.Camera.direction, targetCameraLook)
  ac.Camera.direction = math.lerp(ac.Camera.direction, targetCameraLook, dt * angle / math.pi * 5)
  ac.Camera.up = (carUp + carVelocityDir):normalize()
  ac.Camera.fov = 31 + (#carVelocity.val*0.2)

end