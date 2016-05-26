package com.mobipi.dhan.SMP;

public class NodePreference implements Comparable<NodePreference>{
	public double weight;
	public Node node;
	@Override
	public int compareTo(NodePreference o) {
		// TODO Auto-generated method stub
		if(this.weight == o.weight)
			return 0;
		return (this.weight - o.weight)>0?1:-1;
	}
	public NodePreference(double weight, Node node){
		this.weight = weight;
		this.node = node;
	}
}
