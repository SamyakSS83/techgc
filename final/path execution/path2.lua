-------------------- Core Functions --------------------
function getConfig()
    print("Getting current joint configuration")
    local c = {}
    for i = 1, #params.joints do
        c[i] = sim.getJointPosition(params.joints[i])
    end
    return c
end

function setConfig(c)
    print("Setting joint configuration")
    for i = 1, #params.joints do
        sim.setJointPosition(params.joints[i], c[i])
    end
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
        maxVel = {0.1, 0.1, 0.1, 0.1},         -- Changed to table format
        maxAccel = {0.3, 0.3, 0.3, 0.3},       -- Changed to table format
        maxJerk = {0.5, 0.5, 0.5, 0.5}         -- Changed to table format
    }
    return sim.moveToPose(p)
end

function collides(configs)
    print("Checking for collisions")
    local retVal = false
    local bufferedConfig = getConfig()
    for i = 1, #configs do
        setConfig(configs[i])
        if sim.checkCollision(params.robotCollection, sim.handle_all) > 0 then
            print("Collision detected!")
            retVal = true
            break
        end
    end
    setConfig(bufferedConfig)
    return retVal
end

-------------------- Motion Profile Functions --------------------
function generateSquarePath(center, sideLength, numPointsPerSide)
    print("Generating square path")
    local halfSide = sideLength / 2
    local path = {}
    
    -- Define square corners in the YZ plane (keeping X constant)
    local corners = {
        {y = center[2] - halfSide, z = center[3] - halfSide},  -- Start from bottom-left
        {y = center[2] - halfSide, z = center[3] + halfSide},  -- Top-left
        {y = center[2] + halfSide, z = center[3] + halfSide},  -- Top-right
        {y = center[2] + halfSide, z = center[3] - halfSide},  -- Bottom-right
        {y = center[2] - halfSide, z = center[3] - halfSide}   -- Back to start
    }
    
    -- Generate interpolated points between each corner
    for i = 1, #corners - 1 do
        local startCorner = corners[i]
        local endCorner = corners[i + 1]
        for j = 0, numPointsPerSide - 1 do
            local t = j / (numPointsPerSide - 1)
            local y = startCorner.y + t * (endCorner.y - startCorner.y)
            local z = startCorner.z + t * (endCorner.z - startCorner.z)
            -- Keep orientation constant throughout the movement
            table.insert(path, {center[1], y, z, center[4], center[5], center[6], center[7]})
        end
    end
    return path
end

-------------------- Motion Execution --------------------
function executeMotion(path)
    print("Executing motion along path")
    for i, pose in ipairs(path) do
        if not collides({getConfig()}) then
            print("Moving to pose " .. i)
            if not moveToPose(pose) then
                print("Failed to reach pose")
                return false
            end
            sim.wait(0.1)  -- Added small delay between moves
        else
            print("Collision detected! Aborting motion.")
            return false
        end
    end
    return true
end

-------------------- Main Thread --------------------
function sysCall_thread()
    print("Starting main thread")
    sim = require 'sim'
    simIK = require 'simIK'
    simOMPL = require 'simOMPL'
    sim.setStepping(true)
    
    -- Initialize parameters and object handles:
    params = {}
    params.joints = {}
    for i = 1, 6 do
        params.joints[i] = sim.getObject('../joint', {index = i - 1})
    end
    params.robotTip = sim.getObject('../tip')
    params.robotTarget = sim.getObject('../target')
    params.robotBase = sim.getObject('..')
    params.robotCollection = sim.createCollection()
    sim.addItemToCollection(params.robotCollection, sim.handle_tree, params.robotBase, 0)
    
    local motionParams = {
        sideLength = 0.15,    -- Using smaller square size
        numPoints = 32       -- Adjusted number of points
    }
    local numPointsPerSide = math.floor(motionParams.numPoints / 4)
    
    -- Wait for simulation to stabilize
    sim.wait(1.0)
    
    -- Main control loop
    while sim.getSimulationState() ~= sim.simulation_stopped do
        local currentPose = sim.getObjectPose(params.robotTip, -1)
        local path = generateSquarePath(currentPose, motionParams.sideLength, numPointsPerSide)
        
        if #path > 0 then
            if executeMotion(path) then
                sim.wait(0.5)  -- Wait before starting next iteration
            else
                sim.wait(1.0)  -- Longer wait after failure
            end
        else
            print("Invalid path generated!")
            sim.wait(1.0)
        end
    end
    print("Simulation stopped")
end