package com.mobipi.dhan;

public class Result {
	public int layoutIndex;	//id of layout
	public int k;	//size of data chunks
	public int r;	//size of checksum chunks
	public int c;	//number of users
	public int q;	//quota of servers
	public double tOP;	//total estimated transmission time of the layout and correstponding users
	public double tAVG;	//average estimated transmission time
	public String toString(){
		String res = ""+layoutIndex+", "+k+", "+r+", "+ c+", "+q+", "+tOP+", "+tAVG;
		return res;
	}
	public void print(){
		System.out.println("layout ID:"+layoutIndex+", data chunks k="+k+", checksum chunks r="+r+", size of users:"+c+", quota of servers"+q+", total user time cost:"+tOP+", average time cost:"+tAVG);
	}
}
