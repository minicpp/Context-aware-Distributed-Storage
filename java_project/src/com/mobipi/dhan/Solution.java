package com.mobipi.dhan;

import java.util.Arrays;

import com.mobipi.dhan.layout.Layout;
import com.mobipi.dhan.layout.UserPOIPattern;
import com.mobipi.dhan.layout.UserPattern;

public class Solution {

	public static final int OK = 1;
	public static final int FAIL = 0;
	public static final int TIMEOUT = 2;
	public String solver;
	public int status;

	private int extendSol; // if it is 0, we consider unlimited bound accessing,
							// o/w we consider limited speed at each location

	public int _k; // data chunk size
	public int _r; // checksum chunk size

	public Layout layout;
	public int layoutIndex;
	public SolutionUser[] userSet;
	public SolutionStorage[] storageSet;

	public double runTimeCost;
	public int quota; // quota of servers
	public double tOP; // total estimated transmission time of the layout and
						// correstponding users
	public double tAVG; // average estimated transmission time

	private int[] randperm; // list of fault servers

	public Solution() {
		this.extendSol = 0;
		this.status = FAIL;
	}

	public Solution(int extendSol) {
		this.extendSol = extendSol;
		this.status = FAIL;
	}

	public void updateTimeCostAndReadOperation(double[][] speedM) {
		for (SolutionUser u : userSet) {
			for (SolutionLocation loc : u.locationSet) {
				loc.update(speedM);
			}
		}
	}

	// reference: http://www.dotnetperls.com/shuffle-java
	static void shuffle(int[] array) {
		int n = array.length;
		for (int i = 0; i < array.length; i++) {
			// Get a random index of the array past i.
			int random = i + (int) (Math.random() * (n - i));
			// Swap the random element with the present element.
			int randomElement = array[random];
			array[random] = array[i];
			array[i] = randomElement;
		}
	}

	public FailResult getErorrTolerance(int errorNodesSize, int testSize) {

		if (this.randperm == null) {
			this.randperm = new int[this.storageSet.length];
			for (int i = 0; i < this.storageSet.length; ++i) {
				this.randperm[i] = i;
			}
		}

		FailResult res = new FailResult();
		res.testCounts = testSize;
		errorNodesSize = errorNodesSize > this.storageSet.length ? this.storageSet.length : errorNodesSize;
		res.failedNodesSize = errorNodesSize;
		res.failedNodesRate = (double) res.failedNodesSize / (double) storageSet.length;
		res.totalNodesSize = storageSet.length;
		res.layoutIndex = this.layoutIndex;

		int available = 0;


		for (int k = 0; k < testSize; ++k) {

			Solution.shuffle(this.randperm);

			for (int i = 0; i < this.storageSet.length; ++i) {
				storageSet[i].fail = false;
			}

			int index = 0;
			for (int i = 0; i < errorNodesSize; ++i) {
				index = this.randperm[i];
				storageSet[index].fail = true;
			}

			available += _getAvailableUsers();
			// top += _getTopWithError(errorNodesSize);
		}

		res.totalUsersSize = this.userSet.length;
		res.averageAvailableUsersSize = (double) available / (double) (testSize);
		res.availableUsersRate = res.averageAvailableUsersSize / (double) (this.userSet.length);
		res.sol = this;

		// res.averageTop = top/(double)testSize;


		return res;
	}

	private int _getAvailableUsers() {
		int failedCount = 0;
		int availableUsers = 0;
		for (int i = 0; i < this.userSet.length; ++i) {
			SolutionUser u = this.userSet[i];
			
			SolutionLocation loc = u.locationSet[0];
			for (AssignedStorage s : loc.storageSet) {
				SolutionStorage st = this.storageSet[s.storageIndex];
				if(st.fail){
					//++failedCount;
					if(++failedCount>this._r){
						break;
					}
				}
			}
			if(failedCount<=this._r)
				++availableUsers;			
			failedCount = 0;
		}
		return availableUsers;
	}

	/*
	 * private double _getTopWithError(int errorNodesSize){ return 0; }
	 */

	public double update() {
		if (this.status != Solution.FAIL) {
			// calculate
			tOP = 0;
			for (int h = 0; h < getUserSize(); ++h) {
				SolutionUser u = userSet[h];
				for (int i = 0; i < u.getLocationSize(); ++i) {
					SolutionLocation loc = u.locationSet[i];
					UserPOIPattern pattern = loc.locationPattern;
					double res = pattern.locationPr
							* (pattern.readPr * pattern.readMB * loc.readUnitTimeCost / (double) _k
									+ pattern.writePr * pattern.writeMB * loc.writeUnitTimeCost);
					tOP += res;
				}
			}
			tAVG = tOP / (double) getUserSize();

			// sort quota
			Arrays.sort(storageSet);
		} else {
			tOP = 0;
			tAVG = 0;
		}
		return 0;
	}

	public int getUserSize() {
		return userSet.length;
	}

	public void setSolutionUser(UserPattern[] U) {
		userSet = new SolutionUser[U.length];
		for (int i = 0; i < U.length; ++i) {
			SolutionUser solUser = new SolutionUser();
			userSet[i] = solUser;
			solUser.user = U[i];
			solUser.locationSet = new SolutionLocation[solUser.user.locationSize];

			SolutionLocation solLoc = null;
			for (int k = 0; k < solUser.user.locationSize; ++k) {
				solLoc = this.extendSol == 0 ? new SolutionLocation() : new SolutionLocationEx();
				solUser.locationSet[k] = solLoc;
				solLoc.locationPattern = solUser.user.locationArray[k];

			}
		}
	}

	public String toString() {
		// layoutIndex, solverName status
		String res = layoutIndex + ", " + this.solver + ", " + status + ", " + this.tOP + ", " + this.tAVG + ", "
				+ this.getUserSize() + "," + _k + ", " + _r + ", " + this.runTimeCost + ", " + this.storageSet.length
				+ ", " + this.layout.locationSize + ", " + this.quota + ", ";
		String quotaStr = "";
		int size = this.storageSet.length;
		for (int i = 0; i < size; ++i) {
			if (i == 0) {
				quotaStr += this.storageSet[i].usedCapacity;
			} else
				quotaStr += "|" + this.storageSet[i].usedCapacity;
		}
		res += quotaStr;
		return res;
	}

	public static String getStringTitle() {
		return "LayoutIndex, AlgorithmName, Status(0=FAIL 1=OK 3=TIMEOUT), UserTotalTime, UserAverageTime, UserSize, "
				+ "DataChunkSize(k), ChecksumChunkSize(r), RunTimeCost, StorageSize, POISize, MaxQuota, SortedQuota";
	}

	public static String getDummyString() {
		return "-1, DUMMY, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0";
	}

}
