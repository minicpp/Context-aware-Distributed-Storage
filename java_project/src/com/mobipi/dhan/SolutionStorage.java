package com.mobipi.dhan;

public class SolutionStorage implements Comparable<SolutionStorage> {
	public int index;
	public int usedCapacity;
	boolean fail;
	@Override
	public int compareTo(SolutionStorage o) {
		if(this.usedCapacity == o.usedCapacity) //ascending
			return 0;
		return (this.usedCapacity - o.usedCapacity)<0?-1:1;
	}
	
	public SolutionStorage(){
		fail = false;
	}
}
