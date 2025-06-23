-------------------- Core Functions --------------------
function getConfig()
    local c = {}
    for i = 1, #params.joints do
        c[i] = sim.getJointPosition(params.joints[i])
    end
    return c
end

function setConfig(c)
    for i = 1, #params.joints do
        sim.setJointPosition(params.joints[i], c[i])
    end
end

function collides(configs)
    local retVal = false
    local bufferedConfig = getConfig()
    for i = 1, #configs do
        setConfig(configs[i])
        if sim.checkCollision(params.robotCollection, sim.handle_all) > 0 then
            retVal = true
            break
        end
    end
    setConfig(bufferedConfig)
    return retVal
end

function moveToPose(pose)
    local p = {
        ik = {
            tip = params.robotTip,
            target = params.robotTarget,
            base = params.robotBase,
            joints = params.joints
        },
        targetPose = pose,
        maxVel = {1.2, 1.2, 1.2, 3.0},
        maxAccel = {2.4, 2.4, 2.4, 1.8},
        maxJerk = {1.8, 1.8, 1.8, 2.4}
    }
    sim.moveToPose(p)
end

function moveInYZTriangle(sideLength, pointsPerSide)
    local currentPose = sim.getObjectPose(params.robotTip, -1)
    
    -- Move to a lower starting position first
    local startPose = {
        currentPose[1],  -- Keep X constant
        currentPose[2],  -- Keep Y
        currentPose[3] - 0.1,  -- Move down by 0.1m
        0, 0, 0, 1  -- Orientation
    }
    moveToPose(startPose)
    sim.wait(0.5)  -- Wait for initial movement
    
    -- Get new current position after moving down
    currentPose = sim.getObjectPose(params.robotTip, -1)
    
    -- Define triangle vertices (starting from bottom center)
    local height = sideLength * math.sin(math.pi/3)  -- height of equilateral triangle
    local vertices = {
        {y = currentPose[2], z = currentPose[3]},  -- Bottom center (start)
        {y = currentPose[2] - sideLength/2, z = currentPose[3]},  -- Bottom left
        {y = currentPose[2], z = currentPose[3] + height},  -- Top center
        {y = currentPose[2] + sideLength/2, z = currentPose[3]},  -- Bottom right
        {y = currentPose[2], z = currentPose[3]}   -- Back to start
    }
    
    -- Move along each edge of the triangle
    for i = 1, #vertices - 1 do
        local startPoint = vertices[i]
        local endPoint = vertices[i + 1]
        
        -- Interpolate points along each edge
        for j = 0, pointsPerSide - 1 do
            local t = j / (pointsPerSide - 1)
            local targetPose = {
                currentPose[1],  -- Fixed X
                startPoint.y + t * (endPoint.y - startPoint.y),  -- Interpolated Y
                startPoint.z + t * (endPoint.z - startPoint.z),  -- Interpolated Z
                0, 0, 0, 1  -- Orientation
            }
            
            if not collides({getConfig()}) then
                moveToPose(targetPose)
                sim.wait(0.05)
            else
                print("Collision detected! Stopping motion.")
                return
            end
        end
    end
end

-------------------- Main Execution --------------------
function sysCall_thread()
    sim = require 'sim'
    simIK = require 'simIK'
    sim.setStepping(true)
    -- Robot configuration
    params = {
        joints = {},
        robotTip = sim.getObject('../tip'),
        robotTarget = sim.getObject('../target'),
        robotBase = sim.getObject('..'),
        robotCollection = sim.createCollection()
    }
    
    -- Initialize joints and collection
    for i = 1, 6 do
        params.joints[i] = sim.getObject('../joint', {index = i - 1})
    end
    sim.addItemToCollection(params.robotCollection, sim.handle_tree, params.robotBase, 0)
    
    -- Start motion with triangle path (smaller size)
    moveInYZTriangle(0.1, 12)  -- sideLength=0.1m, 12 points per side
    
    while sim.getSimulationState() ~= sim.simulation_stopped do
        sim.wait(0.03)
    end
end