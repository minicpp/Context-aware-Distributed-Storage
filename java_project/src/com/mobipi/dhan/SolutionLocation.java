package com.mobipi.dhan;

import java.util.ArrayList;

import java.util.Collections;

import com.mobipi.dhan.layout.UserPOIPattern;

public class SolutionLocation {
	public UserPOIPattern locationPattern;
	public ArrayList<AssignedStorage> storageSet = new ArrayList<AssignedStorage>();
	public ArrayList<AssignedStorage> dataChunkStorageSet = new ArrayList<AssignedStorage>();
	public ArrayList<AssignedStorage> checksumChunkStorageSet = new ArrayList<AssignedStorage>();
	public ArrayList<AssignedStorage> storageForRead = new ArrayList<AssignedStorage>();
	public double readUnitTimeCost;
	public double writeUnitTimeCost;

	public void update(double[][] speedM) {
		for(AssignedStorage as: storageSet){
			as.speed = speedM[locationPattern.locationIndex][as.storageIndex];
		}
		
		Collections.sort(storageSet);
		for(int i=0; i<dataChunkStorageSet.size(); ++i){
			storageForRead.add(storageSet.get(i));
		}
		int lastIndex = storageForRead.size() - 1;
		this.readUnitTimeCost = 1.0 / storageForRead.get(lastIndex).speed;

		double maxTimeWriteDataChunkUnit = this.getWriteDataChunkSpeed();
		double maxTimeWriteChecksumChunkUnit = this.getWriteChecksumChunkSpeed();
		this.writeUnitTimeCost = maxTimeWriteDataChunkUnit > maxTimeWriteChecksumChunkUnit ? maxTimeWriteDataChunkUnit
				: maxTimeWriteChecksumChunkUnit;
	}

	private double getWriteDataChunkSpeed() {
		// TODO Auto-generated method stub
		double res = 0.0;
		double v = 0.0;
		double k = dataChunkStorageSet.size();
		for (AssignedStorage n : dataChunkStorageSet) {
			v = n.speed;
			res += 1.0 / v;
		}
		res /= k;
		return res;
	}

	private double getWriteChecksumChunkSpeed() {
		double res = 0.0;
		double v = 0.0;
		for (AssignedStorage n : checksumChunkStorageSet) {
			v = n.speed;
			v = 1.0 / v;
			if (v > res)
				res = v;

		}
		return res;
	}

}
