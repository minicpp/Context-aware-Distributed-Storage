package com.mobipi.dhan;

import com.mobipi.dhan.layout.UserPattern;

public class SolutionUser {
	public UserPattern user;
	public SolutionLocation[] locationSet;
	public int getLocationSize(){
		return locationSet.length;
	}
}
