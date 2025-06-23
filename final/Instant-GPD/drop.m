clc; close all;
vrep = remApi('remoteApi');
vrep.simxFinish(-1);
id = vrep.simxStart('127.0.0.1', 19007, true, true, 5000, 5);

if id < 0
    disp('Failed to connect MATLAB to CoppeliaSim.')
    vrep.delete;
    return;
else
    fprintf('Connection %d to remote API server is open. \n', id);
end

function[] = dropS(vrep, clientID)    
    inputTable = vrep.simxPackInts([2]);
    vrep.simxSetStringSignal(clientID, 'threadedInput', inputTable, vrep.simx_opmode_oneshot);
    
    % Wait for the result
    pause(1);
    [res, result] = vrep.simxGetIntegerSignal(clientID, 'threadedResult', vrep.simx_opmode_blocking);
    
    if res == vrep.simx_return_ok
        fprintf('Received result: %d\n', result);
    end
end

dropS(vrep, id);