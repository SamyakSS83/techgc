function[] = move(index_k)
disp(index_k)
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

function[] = moveS(vrep, clientID)    
    inputTable = vrep.simxPackInts([1]);
    vrep.simxSetStringSignal(clientID, 'threadedInput', inputTable, vrep.simx_opmode_oneshot);
    
    % Wait for the result
    pause(1);
    [res, result] = vrep.simxGetIntegerSignal(clientID, 'threadedResult', vrep.simx_opmode_blocking);
    
    if res == vrep.simx_return_ok
        fprintf('Received result: %d\n', result);
    end
end
function[] = drop(vrep, clientID)    
    inputTable = vrep.simxPackInts([2]);
    vrep.simxSetStringSignal(clientID, 'threadedInput', inputTable, vrep.simx_opmode_oneshot);
    
    % Wait for the result
    pause(1);
    [res, result] = vrep.simxGetIntegerSignal(clientID, 'threadedResult', vrep.simx_opmode_blocking);
    
    if res == vrep.simx_return_ok
        fprintf('Received result: %d\n', result);
    end
end
function [ax, by, theta] = stat(img)
    image = img;

    % Convert to grayscale and detect edges
    grayImage = rgb2gray(image);
    edges1 = edge(grayImage, 'sobel');
    edges2 = edge(grayImage, 'Canny', [0.1, 0.3]);
    edges3 = edge(grayImage, "prewitt");
    edges4 = edge(grayImage, "log");


    edges = edges2;

    %imshow(edges);


    % Extract boundary points
    boundaries = bwboundaries(edges, 'noholes'); 
    if isempty(boundaries)
        error('No boundaries found.');
    end
    boundary = boundaries{index_k}; % Select the first boundary
    disp(length(boundaries))
    disp(length(boundary))
    % Display edge-detected image
    %imshow(edges);
    hold on;
    
    % Plot the traced boundary
    plot(boundary(:,2), boundary(:,1), 'r-', 'LineWidth', 2);
    
    % Step 1: Extract only edges **inside** the convex hull
    numPoints = size(boundary, 1);
    segmentPoints = zeros(numPoints-1, 4); % Store segment endpoints

    for i = 1:numPoints-1
        segmentPoints(i, :) = [boundary(i, :), boundary(i+1, :)];
    end

    % Step 2: Find One Pair of Antiparallel Vectors with Overlapping Projections
    threshold = 0.01; % Angle similarity threshold
    foundPair = false;
    minDist = 1000000000000000;
    
    
    centroid_y = mean(segmentPoints(:, [1, 3]), 'all');
    centroid_x = mean(segmentPoints(:, [2, 4]), 'all');
    [xs, ys] = size(img);
    mask = poly2mask(boundary(:,2), boundary(:,1), xs, ys);

    % Compute the distance transform (distance to the nearest edge)
    distMap = bwdist(~mask);

    % Find the maximum distance (deepest inside the polygon)
    [max_radius, maxIdx] = max(distMap(:));
    [centroid_y, centroid_x] = ind2sub(size(distMap), maxIdx);

    disp(centroid_x);
    disp(centroid_y);

    centroid_y2 = mean(segmentPoints(:, [1, 3]), 'all');
    centroid_x2 = mean(segmentPoints(:, [2, 4]), 'all');

    if (inpolygon(centroid_x2, centroid_y2, boundary(:, 2), boundary(:, 1)))
        centroid_x = centroid_x2;
        centroid_y = centroid_y2;
    end

    
    for i = 1:size(segmentPoints, 1)
        p1 = segmentPoints(i, 1:2);
        p2 = segmentPoints (i, 3:4);
        v1 = p2 - p1; % First edge vector

        for j = i+1:size(segmentPoints, 1)
            q1 = segmentPoints(j, 1:2);
            q2 = segmentPoints(j, 3:4);
            v2 = q2 - q1; % Second edge vector

            % Check if vectors are antiparallel
            cosTheta = dot(v1, v2) / (norm(v1) * norm(v2));
            if cosTheta < -1 + threshold
                % Project endpoints onto the longest axis
                axisDir = v1 / norm(v1); % Normalize direction
                proj_p1 = dot(p1, axisDir);
                proj_p2 = dot(p2, axisDir);
                proj_q1 = dot(q1, axisDir);
                proj_q2 = dot(q2, axisDir);

                % Check for overlapping projections
                if max(min(proj_p1, proj_p2), min(proj_q1, proj_q2)) <= ...
                   min(max(proj_p1, proj_p2), max(proj_q1, proj_q2))

                    % Highlight found pair in blue
                    %plot([p1(2), p2(2)], [p1(1), p2(1)], 'b-', 'LineWidth', 3);
                    %plot([q1(2), q2(2)], [q1(1), q2(1)], 'b-', 'LineWidth', 3);

                    % Compute the midpoint of the two line segments
                    by = (p1(1) + p2(1) + q1(1) + q2(1)) / 4;
                    ax = (p1(2) + p2(2) + q1(2) + q2(2)) / 4;

                    dist  = sqrt((ax-centroid_x)^2 + (by-centroid_y)^2);


                    % Compute the orientation angle
                    theta = atan2(p2(2) - p1(2), p2(1) - p1(1));


                    if (dist < minDist && inpolygon(ax, by, boundary(:, 2), boundary(:, 1)))
                        minPair = [ax, by, theta];
                        pq = [p1, p2, q1, q2];
                        minDist=dist;
                    end




                    break;
                end
            end
        end
        if foundPair, break; end
    end


    % Mark centroid and reference point
    %plot(centroid_x, centroid_y, 'y.', 'MarkerSize', 10);
    %plot(minPair(1), minPair(2), 'g.', 'MarkerSize', 10);
    ax = minPair(1);
    by  = minPair(2);
    theta = minPair(3);
    disp(pq);
    p1 = [pq(1), pq(2)];
    p2 = [pq(3), pq(4)];
    q1 = [pq(5), pq(6)];
    q2 = [pq(7), pq(8)];
    %plot([p1(2), p2(2)], [p1(1), p2(1)], 'b-', 'LineWidth', 3);
    %plot([q1(2), q2(2)], [q1(1), q2(1)], 'b-', 'LineWidth', 3);

    hold off;
end






%% Get Handles
[~, camhandle] = vrep.simxGetObjectHandle(id, 'visionSensor', vrep.simx_opmode_blocking);
[~, targetHandle] = vrep.simxGetObjectHandle(id, 'target', vrep.simx_opmode_blocking);

%% Get Image
[~, resolution, img] = vrep.simxGetVisionSensorImage2(id, camhandle, 0, vrep.simx_opmode_blocking);

pause(1);

[~, rgbCamera] = vrep.simxGetObjectHandle(id, 'kinect_rgb', vrep.simx_opmode_blocking);
[~, depthCamera] = vrep.simxGetObjectHandle(id, 'kinect_depth', vrep.simx_opmode_blocking);
%sim.simxGetVisionSensorImage2(clientID, rgbCamera, 0, sim.simx_opmode_streaming);
%sim.simxGetVisionSensorDepthBuffer(clientID, depthCamera, sim.simx_opmode_streaming)

[~, res, rgbImage] = vrep.simxGetVisionSensorImage2(id, rgbCamera, 0, vrep.simx_opmode_blocking);
[~, resolution, depthBuffer] = vrep.simxGetVisionSensorDepthBuffer2(id, depthCamera, vrep.simx_opmode_blocking);
depthBuffer = reshape(depthBuffer, resolution(2), resolution(1));
%imshow(depthBuffer);
pause(2);
img = rgbImage;


[~, camFoV] = vrep.simxGetObjectFloatParameter(id, rgbCamera, 1004, vrep.simx_opmode_blocking);
camFoV = camFoV * (pi / 180); % Convert to radians
fov = camFoV;
img_width = resolution(1);
img_height = resolution(2);

fx = double(img_width / 2) / tan(fov / 2); % Approximate focal length
fy = double(fx);  % Assuming square pixels

%% Get camera pose
[~, camPos] = vrep.simxGetObjectPosition(id, rgbCamera, -1, vrep.simx_opmode_blocking);
[~, camOri] = vrep.simxGetObjectOrientation(id, rgbCamera, -1, vrep.simx_opmode_blocking);

%% Convert Bounding Box to World Coordinates
[ax, by, theta] = stat(img)
cx = ax;  % Center X in image
cy = by;  % Center Y in image

% Normalize image coordinates (convert to camera space)
nx = (double(cx) - double(img_width / 2)) / double(fx);
ny = (double(cy) - double(img_height / 2)) / double(fy);

% Approximate depth (Z-coordinate in world space)
depth = 0.695;  % Set depth to a fixed value (or estimate using stereo/depth map)1

% Compute world coordinates in camera frame
camX = nx * depth;
camY = ny * depth;
camZ = depth;

% Convert from camera frame to world frame
alpha = camOri(1) ;  % Yaw (Z-axis)
beta  = camOri(2);   % Pitch (Y-axis)
gamma = camOri(3);  % Roll (X-axis)

Rz = [cos(alpha), -sin(alpha), 0;
      sin(alpha), cos(alpha), 0;
      0, 0, 1.00];

Ry = [cos(beta), 0, sin(beta);
      0, 1.00, 0;
      -sin(beta), 0, cos(beta)];

Rx = [1.00, 0, 0;
      0, cos(gamma), -sin(gamma);
      0, sin(gamma), cos(gamma)];

R = Rz * Ry * Rx;  % Final Rotation Matrix
R = double(R);   % Ensure rotation matrix is double
camX = double(camX);
camY = double(camY);
camZ = double(camZ);
worldCoords = R * [camX*-58; camY*-58; camZ] + double(camPos)';  % Transform to world frame

ax = round(ax);
by = round(by);
disp(depthBuffer(by, ax));

disp(depthBuffer(1, 1));

worldCoords(3) = depth - depth*(depthBuffer(by, ax)/depthBuffer(1, 1));



vrep.simxSetObjectPosition(id, targetHandle, -1, [worldCoords(1), worldCoords(2), worldCoords(3)+0.05], vrep.simx_opmode_oneshot);
%%[~, objectHandle] = vrep.simxGetObjectHandle(id, 'dummy', vrep.simx_opmode_blocking);

rotation = [0,0,theta];  % theta is in radians
vrep.simxSetObjectOrientation(id, targetHandle, -1, rotation, vrep.simx_opmode_oneshot);



pause(2);  % Allow some time for the movement
moveS(vrep, id);

[~, targetHandle2] = vrep.simxGetObjectHandle(id, 'drop', vrep.simx_opmode_blocking);
[~, depthCamera2] = vrep.simxGetObjectHandle(id, 'depth', vrep.simx_opmode_blocking);
[~, resolution, depthBuffer2] = vrep.simxGetVisionSensorDepthBuffer2(id, depthCamera2, vrep.simx_opmode_blocking);
depthBuffer2 = reshape(depthBuffer2, resolution(2), resolution(1));
object_space = depthBuffer2(128, 128);
total_height = depthBuffer2(1, 1);
object_height = 1 - object_space/total_height;
val = object_height;
%%val is here only
%disp(worldCoords(3));
%disp(double(worldCoords(3))+double(val));
vrep.simxSetObjectPosition(id, targetHandle2, -1, [-0.25, -0.65, val+2*worldCoords(3)], vrep.simx_opmode_oneshot);
%% Close connection
vrep.simxFinish(id);
vrep.delete();
%{
while true
[res, result] = vrep.simxGetIntegerSignal(id, 'moveResult', vrep.simx_opmode_blocking);
    
if res == vrep.simx_return_ok
    fprintf('Received result: %d\n', result)
    vrep.simxFinish(id);
    vrep.delete();
    break

end
%disp(res)
end
%}
function euler_angles = calculateRotation(theta)
    % theta is already in radians
    beta = deg2rad(-90);  % Convert -90 degrees to radians
    
    % Rotation matrix for -90 around Y
    R1 = [
        cos(beta)   0   sin(beta);
        0          1   0;
        -sin(beta)  0   cos(beta)
    ];
    
    % Rotation matrix for theta around X
    R2 = [
        1    0           0;
        0    cos(theta)  -sin(theta);
        0    sin(theta)  cos(theta)
    ];
    
    % Combined rotation
    R = -1* R1 * R2;
    
    % Extract euler angles from rotation matrix (ZYX order)
    beta = atan2(-R(3,1), sqrt(R(3,2)^2 + R(3,3)^2));
    alpha = atan2(R(2,1), R(1,1));
    gamma = atan2(R(3,2), R(3,3));
    
    % Return in radians since CoppeliaSim expects radians
    euler_angles = [alpha, beta, gamma];
end
end