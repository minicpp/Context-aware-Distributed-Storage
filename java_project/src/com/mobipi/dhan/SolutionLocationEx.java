package com.mobipi.dhan;

import java.util.Arrays;
import java.util.Collections;

//In this extension, we calculate speed based on threshold of locations
public class SolutionLocationEx extends SolutionLocation{
	
	public void update(double[][] speedM) {
		for(AssignedStorage as: storageSet){
			as.speed = speedM[locationPattern.locationIndex][as.storageIndex];
		}
		
		Collections.sort(storageSet);
		double [] speedReadArray = new double[dataChunkStorageSet.size()];

		for(int i=0; i<dataChunkStorageSet.size(); ++i){
			AssignedStorage as = storageSet.get(i);
			storageForRead.add(as);
			speedReadArray[i] = as.speed;
		}
		this.readUnitTimeCost = getAverageSpeedForUnitSizeTransfer(speedReadArray, 1.0);
		
		double [] speedWriteArray = new double[checksumChunkStorageSet.size() + 1];
		for(int i=0; i<checksumChunkStorageSet.size(); ++i){
			AssignedStorage as = checksumChunkStorageSet.get(i);
			speedWriteArray[i+1] = as.speed;
		}
		this.writeUnitTimeCost = 0;
		for(int i=0; i< this.dataChunkStorageSet.size(); ++i){
			AssignedStorage as = dataChunkStorageSet.get(i);
			speedWriteArray[0] = as.speed;
			this.writeUnitTimeCost += 
					getAverageSpeedForUnitSizeTransfer(speedWriteArray, 1.0);
		}
		this.writeUnitTimeCost /= (double)this.dataChunkStorageSet.size();
		
	}
	
	private double getAverageSpeedForUnitSizeTransfer(double []speedArray, double unitSize){
		if(speedArray.length == 0)
			return 0;
		
		Arrays.sort(speedArray);

		double maxSpeed = this.locationPattern.maxSpeed;
		double costTime = 0;
		double restSize = unitSize;
		int pos = speedArray.length - 1;
		double maxV = 0;
		double minV = 0;
		double deltaTime = 0;
		while(restSize > 0){
			double sum = 0;
			for(int i=0; i<=pos; ++i){
				sum += speedArray[i];
			}
			if(sum <= maxSpeed){
				costTime += restSize/speedArray[0];
				restSize = -1;
			}
			else{
				maxV = maxSpeed*speedArray[pos]/sum;
				minV = maxSpeed*speedArray[0]/sum;
				deltaTime = unitSize/maxV;
				costTime += deltaTime;
				restSize -= deltaTime*minV;
				-- pos;
			}
		}
		return costTime;
	}
}
