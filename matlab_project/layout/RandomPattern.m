function [ patternMatrix ] = RandomPattern( locSize, minPrRead1, maxPrRead1,...
    minPrRead2, maxPrRead2, ratio, minReadMegabyte, maxReadMegabyte, minWriteMegabyte, maxWriteMegabyte, pMoreWrite)

% locSize: generate users with frequently visited POIS from 2 to locSize
% minPrRead1, maxPrRead1: the first type of reader
% minPrRead2, maxPrRead2: the second type of reader
% ratio: major(first type reader) to minor(second type reader) ratio (at
% least one second type reader)
% minReadMegabyte
% maxReadMegabyte
% minWriteMegabyte
% maxWriteMegabyte
% pMoreWrite: the possible that write can be greater than read
% In a general case, writeMegabyte is less than the readMegabyte
% but there is a probability pMoreWrite, that writeMegabyte does not keep
% the constraint

% patternMatrix
% first row, the probability of staying at each location
% second row, the probability of writing at each location
% third row, the probability of reading at each location
% fourth row, the read megabytes of the user at each location
% fifth row, the write megabytes of the user at each location
randSeq = normrnd(10,3,[1,locSize*10]);
I = find(randSeq>0);
loc = randSeq(I(1:locSize));
loc = sort(loc,'descend');

loc2Size = ceil(locSize/(ratio+1)); % at least have one special
loc1Size = locSize - loc2Size;

patternMatrix  = zeros(5, locSize);
for ii=1:locSize
    patternMatrix(1, ii) = loc(ii)/sum(loc);
    
    if ii <= loc1Size
        patternMatrix(2, ii) = minPrRead1+rand(1)*(maxPrRead1 - minPrRead1);
    else
        patternMatrix(2, ii) = minPrRead2+rand(1)*(maxPrRead2 - minPrRead2);
    end
    patternMatrix(3, ii) = 1 - patternMatrix(2, ii);
    patternMatrix(4, ii) = minReadMegabyte+rand(1)*(maxReadMegabyte - minReadMegabyte);
    if rand(1) < pMoreWrite
        patternMatrix(5, ii)= minWriteMegabyte+rand(1)*(maxWriteMegabyte - minWriteMegabyte);
    else
        minWrite = minWriteMegabyte;
        maxWrite = patternMatrix(4, ii);
        if minWriteMegabyte > patternMatrix(4, ii)
            minWrite = patternMatrix(4, ii)/10;
        end
        patternMatrix(5, ii)= minWrite+rand(1)*(maxWrite - minWrite);
    end
end





end

