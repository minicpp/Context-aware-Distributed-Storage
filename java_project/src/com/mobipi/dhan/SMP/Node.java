package com.mobipi.dhan.SMP;

public class Node {
	
	public int index;
	public NodePreference[] preferArray;
	public NodePreference[] preferSortedArray;
	private int nextProposal;
	
	public Node(){
		nextProposal = 0;
	}
	
	public String getNodeTypeAsString(){
		return "Abstract node";
	};
	
	public NodePreference getNextProposal(){
		if (nextProposal<preferSortedArray.length){			
			return preferSortedArray[nextProposal++];
		}
		return null;
	}
	
	public void resetNextProposal(){
		this.nextProposal = 0;
	}
	
}
