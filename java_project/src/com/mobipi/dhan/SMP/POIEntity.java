package com.mobipi.dhan.SMP;

import java.util.Arrays;
import java.util.Comparator;

import com.mobipi.dhan.layout.UserPOIPattern;

public class POIEntity {
	public UserPOIPattern poiPattern;
	public StorageNode[] storageNodeArray;
	public StorageNode[] readStorageNodeArray;
	public VirtualNode[] virtualNodeArray;
	
	public double maxTimeReadUnit;	//the largest time cost for read a unit (1MB)
	public double maxTimeWriteDataChunkUnit; //the average largest time cost for write a unit to data chunk(1MB)
	public double maxTimeWriteChecksumChunkUnit;  //the largest time cost for write a unit to checksum chunk(1MB)
	public double maxTimeWriteUnit;
	public int k;
	
	public POIEntity(UserPOIPattern poiPattern, VirtualNode[] virtualNodeArray, int k, final double[][] speedM){
		this.poiPattern = poiPattern;
		this.k = k;
		final int locationIndex = poiPattern.locationIndex;
		this.storageNodeArray = new StorageNode[virtualNodeArray.length];
		this.virtualNodeArray = virtualNodeArray;
		for(int i=0; i<virtualNodeArray.length; ++i){
			storageNodeArray[i] = virtualNodeArray[i].engagedStorageNode;
		}
		Arrays.sort(storageNodeArray, new Comparator<StorageNode>(){

			@Override
			public int compare(StorageNode o1, StorageNode o2) {
				// TODO Auto-generated method stub
				double v1=speedM[locationIndex][o1.index];
				double v2=speedM[locationIndex][o2.index];
				if(v2 > v1)
					return 1;
				else if(v2 == v1)
					return 0;
				return -1;
			}});
		//choose the top k
		readStorageNodeArray = new StorageNode[k];
		System.arraycopy(storageNodeArray, 0, readStorageNodeArray, 0, k);
		int slowestStorageNodeIndex = readStorageNodeArray[k-1].index;
		this.maxTimeReadUnit = 1.0/speedM[locationIndex][slowestStorageNodeIndex];
		this.maxTimeWriteDataChunkUnit = this.getWriteDataChunkSpeed(speedM);
		this.maxTimeWriteChecksumChunkUnit = this.getWriteChecksumChunkSpeed(speedM);
		this.maxTimeWriteUnit = maxTimeWriteDataChunkUnit>maxTimeWriteChecksumChunkUnit?
				maxTimeWriteDataChunkUnit:maxTimeWriteChecksumChunkUnit;
	}
	
	private double getWriteDataChunkSpeed(double[][] speedM){
		double res = 0.0;
		double v = 0.0;
		for(VirtualNode n:virtualNodeArray){
			if(n.nodeType == VirtualNode.DATA_NODE){
				v = speedM[poiPattern.locationIndex][n.engagedStorageNode.index];
				res += 1.0/v;
			}
		}
		res /= (double)k;
		return res;
	}
	
	private double getWriteChecksumChunkSpeed(double[][] speedM){
		double res = 0.0;
		double v = 0.0;
		for(VirtualNode n:virtualNodeArray){
			if(n.nodeType == VirtualNode.CHECKSUM_NODE){
				v = speedM[poiPattern.locationIndex][n.engagedStorageNode.index];
				v = 1.0/v;
				if(v > res)
					res = v;
			}
		}
		return res;
	}
}
