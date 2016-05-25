package com.mobipi.dhan;


public class AssignedStorage implements Comparable<AssignedStorage>{
	public static final int DATA_NODE = 0;
	public static final int CHECKSUM_NODE = 1;
	public double speed;
	public int storageIndex;
	public int storageType;
	@Override
	public int compareTo(AssignedStorage o) {
		if(this.speed == o.speed) //descending
			return 0;
		return (this.speed - o.speed)<0?1:-1;
	}
}
