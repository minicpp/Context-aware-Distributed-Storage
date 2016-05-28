function [ SpeedMatrix, locMaxSpeedArray, RouteMatrix] = GenerateSpeedMatrix( FA,FC, storeBegin, storeEnd, ...
    locBegin,locEnd,  minTransferSpeed, maxTransferSpeed, showFigure)
%GenerateSpeedMatrix Summary of this function goes here
%   Detailed explanation goes here

DistWeightMatrix = zeros(size(FA));

StorageNodeSize = storeEnd-storeBegin+1;
LocationNodeSize = locEnd-locBegin+1;

SpeedMatrix = zeros(StorageNodeSize,LocationNodeSize);
EuclideanMatrix = zeros(StorageNodeSize,LocationNodeSize);
HopMatrix = zeros(StorageNodeSize,LocationNodeSize);
RouteMatrix = zeros(StorageNodeSize,LocationNodeSize);

%% Calculate distance weight
I = find(FA>0);
[I,J] = ind2sub(size(FA),I);
for ii=1:numel(I)
    row = I(ii);
    col = J(ii);
    x1 = FC(row,1);
    y1 = FC(row,2);
    x2 = FC(col,1);
    y2 = FC(col,2);
    distWeight = sqrt( ( x1-x2 )^2 + ( y1-y2 )^2   );
    DistWeightMatrix(row,col) = distWeight;
    DistWeightMatrix(col,row) = distWeight;
end

for ii=locBegin:locEnd
    hopDistance = graphshortestpath(sparse(FA),ii);
    lineDistance = graphshortestpath(sparse(DistWeightMatrix),ii);
    HopMatrix(:,ii-locBegin+1) = hopDistance(storeBegin:storeEnd);
    RouteMatrix(:,ii-locBegin+1) = lineDistance(storeBegin:storeEnd);
    
    %calculate euclidean distance from location to storage
    locX = FC(ii,1);
    locY = FC(ii,2);
    storageX = FC(storeBegin:storeEnd,1);
    storageY = FC(storeBegin:storeEnd,2);
    EuclideanMatrix(:, ii-locBegin+1) = sqrt( (locX-storageX).^2 + (locY - storageY).^2 );
end

% pre-defined parameters to calculate bandwidth
%maxTTL = 390;
maxTTL = 500;
minTTL = 10;
MSS = 1460;
LossRate = 1e-6;

maxDistance = max(RouteMatrix(:));
minDistance = min(RouteMatrix(:));


for ii=locBegin:locEnd
     SpeedMatrix(:,ii-locBegin+1)=calcSpeed(RouteMatrix(:,ii-locBegin+1), ...
         HopMatrix(:,ii-locBegin+1), ...
        maxDistance, minDistance, maxTTL, minTTL, MSS, LossRate);
end

locMaxSpeedArray = floor(minTransferSpeed + rand(1,LocationNodeSize)*maxTransferSpeed);

for ii=1:LocationNodeSize
    maxSpeed = locMaxSpeedArray(ii);
    locSpeedArray = SpeedMatrix(:, ii);
    index = locSpeedArray>maxSpeed;
    locSpeedArray(index) = maxSpeed;
    SpeedMatrix(:,ii) = locSpeedArray;
end

if showFigure == 1
    drawFigure(EuclideanMatrix, SpeedMatrix, HopMatrix, RouteMatrix);
end


function speed=calcSpeed(DistVec,HopVec, maxDis,minDis,maxTTL,minTTL, MSS, LossRate)
RTT = (DistVec - minDis)./(maxDis-minDis) .* (maxTTL-minTTL) +minTTL;
Loss = 1 - (LossRate).^(HopVec);
speed = MSS./RTT;
speed = bsxfun(@rdivide,speed,sqrt(Loss));
%speed = speed ./1e3;


function drawFigure(EuclideanMatrix, SpeedMatrix, HopMatrix, RouteMatrix)
%% draw figure
figure;
DrawPointN = 500;
networkSize = size(SpeedMatrix);
X = zeros(1,DrawPointN);
Y = zeros(1,DrawPointN);
HY = zeros(1,DrawPointN);
RY = zeros(1,DrawPointN);

for ii=1:DrawPointN
    dim1 = randi(networkSize(1));
    dim2 = randi(networkSize(2));
    X(ii) = EuclideanMatrix(dim1,dim2);
    Y(ii) = SpeedMatrix(dim1,dim2);
    HY(ii) = HopMatrix(dim1, dim2);
    RY(ii) = RouteMatrix(dim1, dim2);
      
end
scatter(X,Y);
% draw bar, x axis is line distance of two nodes in a region
% y axis is average speed
binSize = 7;
avgY = zeros(binSize, 1);
avgYSize = zeros(binSize,1);
minEuclidean = min(EuclideanMatrix(:));
maxEuclidean = max(EuclideanMatrix(:));
avgScale = (maxEuclidean - minEuclidean)/10;
sampleSize = 50;
while true
    dim1 = randi(networkSize(1));
    dim2 = randi(networkSize(2));
    euclideanDist = EuclideanMatrix(dim1,dim2);
    speed = SpeedMatrix(dim1,dim2);
    index = floor( (euclideanDist-minEuclidean)/avgScale ) + 1;
    if index > binSize
        index = binSize;
    end
    if avgYSize(index) < sampleSize
        avgY(index) = avgY(index) + speed;
        avgYSize(index) = avgYSize(index) + 1;
    end    
    I = find(avgYSize == sampleSize);
    if(numel(I) == binSize)
        break;
    end        
end

for ii=1:binSize
    avgY(ii) = avgY(ii)/avgYSize(ii);
end
figure;
bar(avgY);
avgY(:)
