%experiment:
%Adjust freq POI for a user from 2 to 6
%This is for small scale experiment
%Number of users at each layout is 4
% k=4, r=4
%Quota is 3
%20 Servers
%To make it faster, we set 30 samples

clc;clear;
rng('shuffle');
sampleSize = 30; % the layout size
rngSeed = randperm(10000,sampleSize);
S = struct();
quota = 3;
StorageNodeSize = 20; %storage node size
LocationSize = 30;  % the number of locations, we want to generate
LocationScale = 600; % the size of layout
LocationDist = 15;      % min distance between any a pair of locations

numberOfUsers = 256; % the number of users in each layout
minVisitedLocations = 2;
maxVisitedLocations = 6;

%%%%%%%%%%%%%%%

majorToMinorRatio = 3;
%major pattern
minPrRead1 = 0.7;
maxPrRead1 = 0.9;
%minor pattern
minPrRead2 = 0.1;
maxPrRead2 = 0.3;

minReadMegabyte=1;
maxReadMegabyte=10;
minWriteMegabyte=0.01;
maxWriteMegabyte=2;
pMoreWrite=0.5;
bTri = 0; % the tri points is appended at the end of all users' info array
bTriDistance = 3;%the distance between any 2 out of 3 users

%%%%%%%%%%%%%%%

BoneNodeSize = 10;
BoneEdgeSize = 12;
ApNodeSize = 60;        % number of base stations


%LocationDist = 3;
UserLocationCounts = 3; % the number of locations we pick from total generated locations
UserLocationMinDist = 4%floor(LocationScale/(UserLocationCounts+1)); the picked locations should qualify the constraint, i.e., greater than 230
UserLocationMaxDist = 3000%1000;   the picked locations should qualify the constraint, i.e., no greater than 3000
Test = 1;



for ii=1:sampleSize
    rng(rngSeed(ii));
    
    
    [BoneA,BoneC, ApA, ApC, SA, SC, LA, UI, UA, UAvg, FA, FC] = CreateLayout(BoneNodeSize, ...
        BoneEdgeSize, ApNodeSize, StorageNodeSize, LocationScale,LocationSize, LocationDist, Test, ...
        UserLocationCounts, UserLocationMinDist, UserLocationMaxDist, bTri, bTriDistance);
    
    %PlotNetwork(BoneA,BoneC, ApA, ApC, SA, SC, LA, FC);
    %
    StorageBegin = BoneNodeSize+ApNodeSize+1;
    StorageEnd = BoneNodeSize + ApNodeSize + StorageNodeSize;
    LocationBegin = StorageEnd + 1;
    LocationEnd = StorageEnd + LocationSize;
    speed = GenerateSpeedMatrix(FA, FC, StorageBegin, StorageEnd, LocationBegin, LocationEnd, 0);
    speed =speed';
        
    S(ii).index=ii;
    S(ii).quota = quota;
    S(ii).seed = rngSeed(ii);
    S(ii).BoneA = BoneA;
    S(ii).BoneC = BoneC;
    S(ii).ApA = ApA;
    S(ii).ApC = ApC;
    S(ii).SA = SA;
    S(ii).SC = SC;
    S(ii).LA = LA;
    S(ii).FA = FA;
    S(ii).FC = FC;
    S(ii).speedM = speed;
    S(ii).BoneNodeSize = BoneNodeSize;
    S(ii).BoneEdgeSize = BoneEdgeSize;
    S(ii).ApNodeSize = ApNodeSize;
    S(ii).StorageNodeSize = StorageNodeSize;
    S(ii).LocationScale = LocationScale;    
    S(ii).LocationSize = LocationSize;
    S(ii).StorageBegin = StorageBegin;
    S(ii).StorageEnd = StorageEnd;
    S(ii).LocationBegin = LocationBegin;
    S(ii).LocationEnd = LocationEnd;
   
    S(ii).UserLocationCounts = UserLocationCounts;
    
    S(ii).UI = UI;
    S(ii).UA = UA;
    S(ii).UAvg = UAvg;
    
    % add user patter for differnt number of locations 2~6
    UserPattern = struct();
    
   
    % generate random users and random locations for each user
    % we assume each user has random visited locations between 2 to 6
    S(ii).NumberOfUsers = numberOfUsers;
    S(ii).MinVisitedLocationsSize = minVisitedLocations;
    S(ii).MaxVisitedLocationsSize = maxVisitedLocations;
    
    seqNum = maxVisitedLocations - minVisitedLocations + 1;
    
     
    
    
    
    for i=1:numberOfUsers
        if i <= seqNum
            NumberOfLocForOneUser = minVisitedLocations - 1 + i;
        else
            NumberOfLocForOneUser = minVisitedLocations - 1 + randi(maxVisitedLocations-minVisitedLocations+1);
        end
        
        patternM = RandomPattern(NumberOfLocForOneUser, minPrRead1, maxPrRead1, ...
        minPrRead2, maxPrRead2, majorToMinorRatio, minReadMegabyte, ...
        maxReadMegabyte, minWriteMegabyte, maxWriteMegabyte, pMoreWrite);
        UserPattern(i).UserLocationCounts = NumberOfLocForOneUser;
        UserPattern(i).UserLocationPr = patternM(1,:);
        UserPattern(i).UserReadPr = patternM(2,:);
        UserPattern(i).UserUpdatePr = patternM(3,:);
        UserPattern(i).UserLocationIndex = randperm(LocationSize, NumberOfLocForOneUser);
        UserPattern(i).UserReadMegabytesPerOp = patternM(4,:);
        UserPattern(i).UserWriteMegabytesPerOp = patternM(5,:);
    end    
    
    S(ii).bTri = bTri;   
   
    if bTri == 1
        i = numberOfUsers+1;
        patternM = RandomPattern(3, minPrRead1, maxPrRead1, ...
            minPrRead2, maxPrRead2, majorToMinorRatio, minReadMegabyte, ...
            maxReadMegabyte, minWriteMegabyte, maxWriteMegabyte, pMoreWrite);
        
        UserPattern(i).UserLocationCounts = 3;
        UserPattern(i).UserLocationPr = patternM(1,:);
        UserPattern(i).UserReadPr = patternM(2,:);
        UserPattern(i).UserUpdatePr = patternM(3,:);
        UserPattern(i).UserLocationIndex = UI-LocationBegin+1;
        UserPattern(i).UserReadMegabytesPerOp = patternM(4,:);
        UserPattern(i).UserWriteMegabytesPerOp = patternM(5,:);
    end
    
    S(ii).ULocPattern = UserPattern;
    fprintf('Progress: %d\n',ii);
end
filenamePrefix = sprintf('smallScale3_%d_S%d_L%d_U%d', sampleSize, StorageNodeSize, LocationSize, numberOfUsers);
matFileName = sprintf('%s.mat',filenamePrefix);
jsonFileName = sprintf('%s.txt',filenamePrefix);
save(matFileName,'S');
S=rmfield(S,{'BoneA','BoneC','ApA','ApC','SA','SC','LA','FA','UserLocationCounts','UI','UA','UAvg'});
savejson('',S,jsonFileName);
fprintf('Done.\n');
clear;