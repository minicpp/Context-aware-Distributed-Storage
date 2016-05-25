function [ BoneA, BoneCoord, ApA, ApCoord, StorageA, StorageCoord, ...
    LocA, UI, userA, AvgUserDist, FullA, FullCoord] = ...
    CreateLayout(numBoneNodes, numBoneEdge, numAP, totalStorage, mapScaleForLocation, ...
    selectLocation, locationMinDist, selectLocTestCount, userLocationCount, ...
    userLocationMinDist, userLocationMaxDist, bTri, TriDistance)
%CreateLayout Create a random network with backbone network, AP network,
%storages, and locations
%INPUT:
%   numBoneNodes: routers in backbone network
%   numBoneEdge: edges of backbone network
%   numAP: number of APs connected to backbone nodes
%   totalStorage: number of total storage nodes
%   mapScaleForLocation: number of optional selection scale of locations.
%                   It is totalLocation*totalLocation
%   selectLocation: number of selected locations
%   locationMinDist: the minimum distance between locations
%   selectLocTestCount: number of tests to choose all needed locations
%   userLocationCount: the number of user locations
%   userLcationMinDist: the minimum distance between user locations
%   userLocationMaxDist: the maximum distance between user locations
%   bTri: 1 is generate 3 symmetrical locations, 0 o/w
%OUTPUT:
%   BoneA: the backbone adjacent matrix
%   BoneCoord: the backbone nodes axis
%   ApA: the AP adjacent matrix, between AP and backbone nodes
%   ApCoord: the Backbone and AP nodes axis
%   StorageA: the storage adjacent matrix between AP and storage nodes
%   StorageCoord: the Backbone and AP and storage nodes axis
%   LocA: selected locations adjacent matrix between location and AP nodes
%   UI: user index begin and end in node arrays
%   userA: User node adjacent matrix
%   AvgUserDist: average distance between user locations
%   FullA: full adjacent matrix
%   FullCoord: all axis
%

%% Generate back bone network
[BoneA, BoneCoord] = generateBoneNet(numBoneNodes, numBoneEdge);

%% Generate AP network
apMapRatio =  ceil(numAP/numBoneNodes);
BoneCoord = BoneCoord .* apMapRatio;
mapScale = numBoneNodes * apMapRatio+apMapRatio;
distanceThreshold = mapScale/numAP*3;
mutualDisThreshold = mapScale/numAP*3;
[ApA,ApCoord] = generateAPNet(BoneA, BoneCoord, numAP, mapScale, ...
    distanceThreshold, mutualDisThreshold);
ExtBoneCoord = padarray(BoneCoord,[numAP,0],'post');
ApCoord = ExtBoneCoord+ApCoord;

%% Generate storage nodes
[StorageA, StorageCoord] = ...
    generateStorage(ApA, ApCoord,numBoneNodes+1, numBoneNodes+numAP, ...,
    totalStorage, mapScale, ...
    mapScale/numAP, ...
    distanceThreshold*numAP/totalStorage, ...
    distanceThreshold*numAP/totalStorage);
ExtApCoord = padarray(ApCoord,[totalStorage,0],'post');
StorageCoord = ExtApCoord+StorageCoord;

%% generate user locations
prevScale = numBoneNodes * apMapRatio;
locMapRatio = ceil(mapScaleForLocation/prevScale);
StorageCoord = StorageCoord.*locMapRatio+1-locMapRatio;
ApCoord = ApCoord.*locMapRatio+1-locMapRatio;
BoneCoord = BoneCoord.*locMapRatio+1-locMapRatio;
mapScale = locMapRatio * prevScale + locMapRatio;

%update coordinate
adjMat = StorageA;
adjMat(1:numBoneNodes,1:numBoneNodes) = adjMat(1:numBoneNodes,1:numBoneNodes) + BoneA;
ApBegin = numBoneNodes+1;
ApEnd = numBoneNodes+numAP;
adjMat(1:ApEnd,1:ApEnd) = adjMat(1:ApEnd,1:ApEnd)+ ...
    ApA(1:ApEnd,1:ApEnd);
StorageEnd = ApEnd + totalStorage;


%% create locations
if bTri ~= 1
    [LocA, FullCoord]=generateLocations(adjMat, StorageCoord, ApBegin, ApEnd, StorageEnd, selectLocation, mapScale, locationMinDist, selectLocTestCount);
else
    [LocA1, FullCoord1]=generateTriLocations(adjMat, StorageCoord, ApBegin, ApEnd, StorageEnd, mapScale, TriDistance);
    tempCoord = padarray( StorageCoord , [3 0], 0, 'post');
    tempCoord2 = FullCoord1;
    FullCoord1 = FullCoord1 + tempCoord;
    [LocA2, FullCoord]=generateLocations(LocA1, FullCoord1, ApBegin, ApEnd, StorageEnd+3, selectLocation, mapScale, locationMinDist, selectLocTestCount);
    tempCoord = padarray( tempCoord2 , [selectLocation 0], 0, 'post');
    FullCoord = tempCoord + FullCoord;
    LocAt = padarray( LocA1 , [selectLocation selectLocation], 0, 'post');
    LocA = LocAt+LocA2;
    selectLocation = selectLocation + 3;
end


locBegin = StorageEnd + 1;

locEnd = StorageEnd + selectLocation;
if bTri ~= 1
[AvgUserDist, userLocIndex] = generateUserLocations(FullCoord,  ...
    locBegin, locEnd, ...
    userLocationCount, userLocationMinDist, userLocationMaxDist);
else
    AvgUserDist = TriDistance;
    userLocIndex = [locBegin:locBegin+2];
end
userLocIndex = sort(userLocIndex);

nextIndex = locBegin;
userA = zeros(size(LocA));
for ii=userLocIndex
    LocA([nextIndex, ii],:) = LocA([ii, nextIndex],:);
    LocA(:,[nextIndex, ii]) = LocA(:,[ii, nextIndex]);
    FullCoord([nextIndex, ii],:)=FullCoord([ii, nextIndex],:);
    userA(nextIndex, :) = LocA(nextIndex,:);
    userA(:,nextIndex) = LocA(:,nextIndex);
    nextIndex = nextIndex + 1;
end

UI = locBegin:(nextIndex-1);
FullA = LocA;

FullA(1:StorageEnd,1:StorageEnd) = FullA(1:StorageEnd,1:StorageEnd)+adjMat;
ExtStorageCoord = padarray(StorageCoord,[selectLocation,0],'post');
FullCoord = ExtStorageCoord + FullCoord;


%% create tri locations
function [A, C]=generateTriLocations(bN,bC, ApBegin, ApEnd, StorageEnd, mapScale, mutualDisThres)
nLoc = 3;
A = zeros(size(bN)+nLoc);
C = zeros(size(bC,1)+nLoc, 2);

org_x = floor(mapScale / 2);
d = mutualDisThres;
org_y = org_x;
Loc_x = [0,        d/2            , -d/2];
Loc_y = [d/sqrt(3),- d/(2*sqrt(3)), -d/(2*sqrt(3)) ];
res = -1;
while res == -1
    deg = randi(360);
    xLoc = Loc_x.*cosd(deg) - Loc_y.*sind(deg);
    yLoc = Loc_x.*sind(deg) + Loc_y.*cosd(deg);
    xLoc = floor(org_x+xLoc);
    yLoc = floor(org_y+yLoc);
    
    %     % transform for x axis and y axis
    %     xMin = min(xLoc(:));
    %     yMin = min(yLoc(:));
    %     %new position
    %     xMinNew = randperm(xMin,1);
    %     yMinNew = randperm(yMin,1);
    %     deltaX1 = xMinNew - xMin;
    %     deltaY1 = yMinNew - yMin;
    %     xMax = max(xLoc(:));
    %     yMax = max(yLoc(:));
    %     xMaxNew = xMax + randperm(mapScale-xMax,1);
    %     yMaxNew = yMax + randperm(mapScale-yMax,1);
    %     deltaX2 = xMaxNew - xMax;
    %     deltaY2 = yMaxNew - yMax;
    %     randomDeltaX = [deltaX1, deltaX2];
    %     randomDeltaX = randomDeltaX(randperm(2,1));
    %     randomDeltaY = [deltaY1, deltaY2];
    %     randomDeltaY = randomDeltaY(randperm(2,1));
    %     xLoc = xLoc + randomDeltaX;
    %     yLoc = yLoc + randomDeltaY;
    
    sCount = 0;
    for ii=1:nLoc
        x = xLoc(ii);
        y = yLoc(ii);
        %check if this position is used by other nodes
        xI = find(bC(:,1) == x);
        yI = find(bC(:,2) == y);
        s = intersect(xI,yI);
        if isempty(s)
            sCount = sCount + 1;
        else
            break;
        end
    end
    if sCount == nLoc
        res = 1;
        break;
    else
        res = -1;
    end
end


for ii=1:nLoc
    [index, minDistance] = getNeighborNode(bC, xLoc(ii),yLoc(ii), ApBegin, ApEnd);
    newIndex = StorageEnd + ii;
    A(index, newIndex) = 1;
    A(newIndex, index) = 1;
    C(newIndex,:)=[xLoc(ii), yLoc(ii)];
end

%%%%%%%
function [avgUserDistance, userI] = generateUserLocations(bC, locBegin, locEnd, userLocSize, minDist,maxDist)
locSize = locEnd - locBegin + 1;
res = -1;
while res == -1
    locArray = locBegin - 1 + randperm(locSize, userLocSize);
    xLoc = bC(locArray(:), 1);
    yLoc = bC(locArray(:), 2);
    res = chooseDistanceBetween(xLoc,yLoc,userLocSize,minDist,maxDist);
end
userI = locArray;
avgUserDistance = res;

function [A,C]=generateLocations(bN,bC, ApBegin, ApEnd, StorageEnd, nLoc, mapScale, mutualDisThres, tests)
A = zeros(size(bN)+nLoc);
C = zeros(size(bC,1)+nLoc, 2);
xLoc = zeros(1, nLoc);
yLoc = zeros(1, nLoc);
distance = -1;
xNewLoc = zeros(1, nLoc);
yNewLoc = zeros(1, nLoc);
while tests > 0
    xLoc = randperm(mapScale,nLoc);
    yLoc = randperm(mapScale,nLoc);
    sCount = 0;
    for ii=1:nLoc
        x = xLoc(ii);
        y = yLoc(ii);
        %check if this position is used by other nodes
        xI = find(bC(:,1) == x);
        yI = find(bC(:,2) == y);
        s = intersect(xI,yI);
        if isempty(s)
            sCount = sCount + 1;
        else
            break;
        end
    end
    if sCount == nLoc %we get nLoc different locations
        res = averageMutualDistance(xLoc,yLoc,nLoc,mutualDisThres);
        if res < 0
            continue;
        else
            if distance <0 || res>distance
                distance = res;
                xNewLoc = xLoc;
                yNewLoc = yLoc;
            end
            tests = tests - 1;
            %fprintf('test rest:%d\n',tests);
        end
    end
end

for ii=1:nLoc
    [index, minDistance] = getNeighborNode(bC, xNewLoc(ii),yNewLoc(ii), ApBegin, ApEnd);
    newIndex = StorageEnd + ii;
    A(index, newIndex) = 1;
    A(newIndex, index) = 1;
    C(newIndex,:)=[xNewLoc(ii), yNewLoc(ii)];
end


function [xResLoc,yResLoc]=descendingLocations(xLoc,yLoc)
eleSize = numel(xLoc);
xResLoc = zeros(eleSize,1),
yResLoc = xResLoc;
%find the longest two points

function [AvgRes]=chooseDistanceBetween(xLoc, yLoc, nLoc, minDist, maxDist)
C = nchoosek(1:nLoc, 2);
t = size(C,1);
sumdist = 0;
for ii=1:t
    sel = C(ii,:);
    x1 = xLoc(sel(1));
    y1 = yLoc(sel(1));
    x2 = xLoc(sel(2));
    y2 = yLoc(sel(2));
    dist = sqrt( (x1-x2)^2 + (y1-y2)^2 );
    if dist < minDist || dist > maxDist
        AvgRes = -1;
        return;
    end
    sumdist = sumdist + dist;
end
AvgRes = sumdist/t;

function res=averageMutualDistance(xLoc, yLoc, nLoc, mutualDisThres)
C = nchoosek(1:nLoc,2);
t = size(C,1);
sumdist = 0;
for ii=1:t
    sel = C(ii,:);
    x1 = xLoc(sel(1));
    y1 = yLoc(sel(1));
    x2 = xLoc(sel(2));
    y2 = yLoc(sel(2));
    dist = sqrt( (x1-x2)^2 + (y1-y2)^2 );
    if dist < mutualDisThres
        res = -1;
        return;
    end
    sumdist = sumdist + dist;
end
res = sumdist/t;

function [A,C] = generateStorage(bN, bC, ApBegin, ApEnd, sNum, mapScale, ...
    minThreshold, maxThreshold,mutualDisThreshold)
A = zeros(size(bN)+sNum);
C = zeros(size(bC,1)+sNum, 2);
xLocPre = randperm(mapScale);
yLocPre = randperm(mapScale);
xLoc = [];
yLoc = [];
nodeNum = sNum;
ii=1;
while nodeNum > 0
    x = xLocPre(ii);
    y = yLocPre(ii);
    xI = find(bC(:,1) == x);
    yI = find(bC(:,2) == y);
    sameXY = intersect(xI,yI);
    if isempty(sameXY)
        xI = find(xLoc == x);
        yI = find(yLoc == y);
        sameXY = intersect(xI,yI);
        if isempty(sameXY)
            [index,distance] = getNeighborNode(bC, x, y, ApBegin, ApEnd);
            if distance < maxThreshold && distance >minThreshold
                mutualTest = 1;
                if numel(xLoc > 0)
                    mutualTest = testMutualDistance(xLoc,yLoc, x,y,mutualDisThreshold);
                end
                if mutualTest == 1
                    xLoc(end+1) = x;
                    yLoc(end+1) = y;
                    nodeNum = nodeNum - 1;
                    newIndex = numel(xLoc)+ApEnd;
                    A(index,newIndex) = 1;
                    A(newIndex,index) = 1;
                    C(newIndex,:)=[x, y];
                end
            else
                %fprintf('exclude a node in storage\n');
                ;
            end
        end
    end
    ii = ii + 1;
    if ii > numel(xLocPre)
        xLocPre = randperm(mapScale);;
        yLocPre = randperm(mapScale);;
        ii = 1;
    end
end

function res = testMutualDistance(xList,yList,x,y, disThreshold)
for i=1:numel(xList)
    x1 = xList(i);
    y1 = yList(i);
    dis = sqrt( (x1-x)^2 + (y1-y)^2 );
    if dis < disThreshold
        res = 0;
        return;
    end
end
res = 1;

function [A,C] = generateAPNet(baseNodes, baseCoord, attachNodesNum, mapScale, ...
    distanceThreshold, mutualDisThreshold)
A = zeros(size(baseNodes)+attachNodesNum);%padarray(baseNodes,[attachNodesNum, attachNodesNum], 'post');
C = zeros(size(baseCoord,1)+attachNodesNum, 2);%padarray(baseCoord,[attachNodesNum,0],'post');
randSize = mapScale*10;
xLocPre = randi(mapScale, 1, randSize);
yLocPre = randi(mapScale, 1, randSize);
xLoc = [];
yLoc = [];
nodeNum = attachNodesNum;
ii = 1;
baseNodeNum = size(baseNodes,1);
while nodeNum > 0
    x = xLocPre(ii);
    y = yLocPre(ii);
    xI = find(baseCoord(:,1) == x);
    yI = find(baseCoord(:,2) == y);
    sameXY = intersect(xI,yI);
    if isempty(sameXY)
        %if isempty(xI) || isempty(yI) || ~isequal(xI,yI)
        xI = find(xLoc(:)==x);
        yI = find(yLoc(:)==y);
        sameXY = intersect(xI,yI);
        try
            if isempty(sameXY)
                %if isempty(xI) || isempty(yI) || ~isequal(xI,yI)
                [index,distance] = getNeighborNode(baseCoord, x, y);
                if distance > distanceThreshold
                    mutualTest = 1;
                    if numel(xLoc > 0)
                        mutualTest = testMutualDistance(xLoc,yLoc, x,y,mutualDisThreshold);
                    end
                    if mutualTest == 1
                        xLoc(end+1) = x;
                        yLoc(end+1) = y;
                        nodeNum = nodeNum - 1;
                        newIndex = numel(xLoc)+baseNodeNum;
                        A(index,newIndex) = 1;
                        A(newIndex,index) = 1;
                        C(newIndex,:)=[x, y];
                    end
                else
                    %fprintf('exclude a node in AP\n');
                end
            end
        catch err
            fprintf('error happened, paused!!!\n');
            pause();
        end
    end
    ii = ii + 1;
    if ii > numel(xLocPre)
        %xLocPre = randperm(mapScale);;
        %yLocPre = randperm(mapScale);;
        xLocPre = randi(mapScale, 1, randSize);
        yLocPre = randi(mapScale, 1, randSize);
        ii = 1;
    end
end

function [index, minDistance] = getNeighborNode(baseCoord, nodeX,nodeY, beginPos, endPos)
numBase = size(baseCoord,1);
if nargin == 3
    beginPos = 1;
    endPos = numBase;
end
minDistance = -1;
index = -1;
for ii=beginPos:endPos
    d = sqrt((baseCoord(ii,1)-nodeX)^2 + (baseCoord(ii,2) - nodeY)^2);
    if minDistance == -1 || d<minDistance
        minDistance = d;
        index = ii;
    end
end


%% Create Bone Net
function [A,Coordinates] = generateBoneNet(numBoneNodes, numBoneEdge)
A = zeros(numBoneNodes,numBoneNodes);

if numBoneEdge < numBoneNodes - 1
    fprintf('The number of edge %d cannot span a connect graph with %d nodes\n', ...
        numBoneEdge, numBoneNodes);
    numBoneEdge = numBoneNodes-1;
    fprintf('Change the number of edge to %d\n', numBoneEdge);
end

xLoc = randperm(numBoneNodes);
yLoc = randperm(numBoneNodes);

Coordinates = [xLoc;yLoc]';

connectSet=[1];
unconnectSet=[2:numel(xLoc)];

%% make spanning tree
%  if we have gotten spanning tree, add more edge randomly
while numBoneEdge > 0
    if numel(unconnectSet) > 0
        randIndex1 = randi(numel(connectSet));
        nodeIndex1 = connectSet(randIndex1);
        randIndex2 = randi(numel(unconnectSet));
        nodeIndex2 = unconnectSet(randIndex2);
    else % add more edges
        indexArray = randperm(numel(connectSet),2);
        randIndex1 = indexArray(1);
        randIndex2 = indexArray(2);
        nodeIndex1 = connectSet(randIndex1);
        nodeIndex2 = connectSet(randIndex2);
        if A(nodeIndex1,nodeIndex2) == 1
            continue;
        end
    end
    
    res = addConnection(xLoc(nodeIndex1),yLoc(nodeIndex1), ...
        xLoc(nodeIndex2), yLoc(nodeIndex2), numBoneNodes);
    if res == 1
        if numel(unconnectSet) > 0
            connectSet(end+1) = nodeIndex2;
            unconnectSet(randIndex2)=[];
        end
        A(nodeIndex1,nodeIndex2) = 1;
        A(nodeIndex2,nodeIndex1) = 1;
        numBoneEdge = numBoneEdge - 1;
    end
end

function res = addConnection(xLoc1,yLoc1,xLoc2,yLoc2,mapLength)
d = sqrt((xLoc2-xLoc1)^2 + (yLoc2 - yLoc1)^2);
a = 0.5;      %a should be >0, larger a, higher probability of connection
b = 0.8;    %b should be <=1, larger b, shorter of edge
L = sqrt(2)*(mapLength-1);  %largest length
p = a*exp(-d/(b*L));
r = rand();
if r < p
    res = 1;
else
    res = 0;
end