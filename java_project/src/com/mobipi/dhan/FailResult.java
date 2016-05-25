package com.mobipi.dhan;

public class FailResult {
	public int testCounts;
	public int failedNodesSize;
	public double failedNodesRate;
	public int totalNodesSize;

	public double averageAvailableUsersSize;
	public int totalUsersSize;
	public double availableUsersRate;

	// public double averageTop;

	public int layoutIndex;
	public Solution sol;

	public static String getAvailableRateTitle() {
		return "LayoutIndex, AlgorithmName,"
				+ "DataChunkSize(k), ChecksumChunkSize(r), UserSize, TotalNodeSize, ErrorNodesSize, ErrorRate, AvailableRate";
	}

	public String getAvailableRate() {
		return layoutIndex + ", " + sol.solver + ", " + sol._k + ", " + sol._r + ", " + totalUsersSize + ", " + this.totalNodesSize+", "+
				+ failedNodesSize + ", " + this.failedNodesRate  +", "+ this.availableUsersRate;
	}
}
