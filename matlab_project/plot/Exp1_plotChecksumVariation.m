%ep1
clear;
[LayoutIndex,AlgorithmName,Status0FAIL1OK3TIMEOUT,UserTotalTime, ...
    UserAverageTime,UserSize,DataChunkSizek,ChecksumChunkSizer, ...
    RunTimeCost,StorageSize,POISize] ...
    = loadCSVDataFileV1('D:\\mydoc\\research\\storage\\mobihoc2016\\java_mars\\storage_optimization\\smallScale1_1.csv');


alg=unique(AlgorithmName);
algSize = size(alg,1);

chunkSizeArray = min(ChecksumChunkSizer):max(ChecksumChunkSizer);
chunkSizeArray = chunkSizeArray';

data = zeros(algSize,length(chunkSizeArray));

totalLayoutSize = size(unique(LayoutIndex),1);
LayoutIndex = LayoutIndex+1;

for i=1:size(LayoutIndex,1)
    algName = AlgorithmName{i};
    algIndex = find(ismember(alg,algName));
    chunkSize = ChecksumChunkSizer(i);
    chunkSizeIndex = find(chunkSizeArray == chunkSize);
    data(algIndex,chunkSizeIndex) = data(algIndex,chunkSizeIndex)+UserAverageTime(i);
end

data = data/totalLayoutSize;

fprintf('Average\n')
for i=1:size(data,1)
    fprintf('%s:',alg{i})
    data(i,:)
    fprintf('\n')
end
fig = figure;
plotPattern={'-o','-x','--d','-*','-s','--o','--x','-d','--*','--s'};
%selectedAlg = {'MILP-OPT','SMP-USER','SMP-SERVER','Greedy-DT','BALANCE'};
selectedAlg = {'SMP-USER','SMP-SERVER','Greedy-DT','BALANCE','Greedy-CNT-D','Greedy-CNT-C'};
sizeSelectedAlg = size(selectedAlg,2);
for i=1:sizeSelectedAlg
    algName = selectedAlg{i};
    algIndex = find(strcmp(alg,algName));
   
        plot(chunkSizeArray(:), data(algIndex,:),plotPattern{i}, 'MarkerSize',12)
    hold on;
end
%selectedAlgFormName = {'MILP-OPT','SMP-U','SMP-S','Greedy','Balance'};
selectedAlgFormName = {'SMP-U','SMP-S','Greedy','Balance','Greedy-CNT-D','Greedy-CNT-C'};
%legend(selectedAlgFormName);
hold off;
xlabel('The number of checksum chunks {\itr} in each layout');
ylabel('Expected transmission time T^{op} (s)');
set(fig, 'Position', [100, 100, 500, 400]);
columnlegend(3,selectedAlgFormName,'boxon');