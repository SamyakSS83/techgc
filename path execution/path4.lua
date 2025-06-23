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

-------------------- Plus Motion Functions --------------------
function moveInYZPlus(sideLength, verticalLength, pointsPerArm)
    local currentPose = sim.getObjectPose(params.robotTip, -1)
    local centerY = currentPose[2]
    local centerZ = currentPose[3]
    
    -- Define plus path vertices (Y and Z movements)
    local vertices = {
        -- Horizontal arm (Y-axis)
        {y = centerY + sideLength/2, z = centerZ},  -- Right
        {y = centerY - sideLength/2, z = centerZ},  -- Left
        
        -- Vertical arm (Z-axis) with safety limits
        {y = centerY, z = centerZ + verticalLength/3},  -- Reduced upward movement
        {y = centerY, z = centerZ - verticalLength}      -- Full downward movement
    }

    -- Generate path segments
    local path = {}
    
    -- Horizontal right-to-left
    for j = 0, pointsPerArm do
        local t = j/pointsPerArm
        table.insert(path, {
            currentPose[1],
            vertices[1].y + t*(vertices[2].y - vertices[1].y),
            vertices[1].z + t*(vertices[2].z - vertices[1].z),
            0, 0, 0, 1
        })
    end

    -- Vertical up-to-down
    for j = 0, pointsPerArm do
        local t = j/pointsPerArm
        table.insert(path, {
            currentPose[1],
            vertices[3].y + t*(vertices[4].y - vertices[3].y),
            vertices[3].z + t*(vertices[4].z - vertices[3].z),
            0, 0, 0, 1
        })
    end

    -- Execute motion
    for i, pose in ipairs(path) do
        if not collides({getConfig()}) then
            moveToPose(pose)
            sim.wait(0.03)  -- Reduced wait time for faster motion
        else
            print("Collision detected! Stopping plus motion.")
            return
        end
    end
end

-------------------- Modified Main Execution --------------------
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

    -- Initialize joints
    for i = 1, 6 do
        params.joints[i] = sim.getObject('../joint', {index = i - 1})
    end
    sim.addItemToCollection(params.robotCollection, sim.handle_tree, params.robotBase, 0)

    -- Motion constraints
    params.ikMaxVel = {1.0, 1.0, 0.8, 2.5}  -- Reduced Z velocity
    params.ikMaxAccel = {2.0, 2.0, 1.5, 2.0}
    params.ikMaxJerk = {2.0, 2.0, 1.8, 2.2}

    -- Start plus motion with safety limits
    moveInYZPlus(
        0.4,   -- Horizontal arm length (Y-axis)
        0.2,   -- Vertical movement (Z-axis) - 1/3 up, full down
        15     -- Points per arm
    )

    while sim.getSimulationState() ~= sim.simulation_stopped do
        sim.wait(0.03)
    end
end