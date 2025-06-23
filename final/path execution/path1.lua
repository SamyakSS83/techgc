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

function moveInYZCircle(radius, numPoints)
    local currentPose = sim.getObjectPose(params.robotTip, -1)
    local angleStep = 2 * math.pi / numPoints
    
    for i = 1, numPoints do
        local angle = i * angleStep
        local targetPose = {
            currentPose[1],  -- Fixed X
            currentPose[2] + radius * math.cos(angle),  -- Y
            currentPose[3] + radius * math.sin(angle),  -- Z
            0, 0, 0, 1  -- Orientation
        }
        
        if not collides({getConfig()}) then
            moveToPose(targetPose)
            sim.wait(0.05)
        else
            print("Collision detected! Stopping motion.")
            break
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

    -- Start motion
    moveInYZCircle(0.2, 36)  -- radius=0.2m, 36 points

    while sim.getSimulationState() ~= sim.simulation_stopped do
        sim.wait(0.03)
    end
end