package com.mobipi.dhan;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;

import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;

import com.mobipi.dhan.MILP.MILPModel;
import com.mobipi.dhan.MILP.MILPModelCNT1;
import com.mobipi.dhan.MILP.MILPModelCNT2;
import com.mobipi.dhan.MILP.MILPModelS;
import com.mobipi.dhan.layout.Layout;

import com.mobipi.dhan.naive.GreedyCNTDataChunkPrior;



public class LayoutReader {
	public Layout[] layoutList;
	public int layoutSize;
	
	public void readLayoutListFile(String fileName){
		layoutList = null;
		try {
			InputStream in = new FileInputStream(new File(fileName));
			JsonReader rdr = Json.createReader(in);
			JsonArray jarray = rdr.readArray();
			
			layoutSize = jarray.size();
			layoutList = new Layout[layoutSize];
			int i=0;
			
			for(JsonObject obj: jarray.getValuesAs(JsonObject.class)){
				Layout layout = new Layout(obj);
				layoutList[i++] = layout;
				System.out.println("Read "+i+" layout.");
			}			
			
			rdr.close();
			in.close();
			
			System.out.println("Done.");
			
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		LayoutReader mf = new LayoutReader();
		//String filePath = "D:\\mydoc\\research\\storage\\mobihoc2016\\matlab\\layout\\multiNetworkT50_S40_L30_U10.txt";
		String filePath = "smallScale1_30_S25_L30_U4.txt";
		mf.readLayoutListFile(filePath);
		
		int _k = 3;
		int _r = 2;
		
		Layout layout = mf.layoutList[0];
		Solution sol;
		GreedyCNTDataChunkPrior greedy = new GreedyCNTDataChunkPrior(_k, _r);
		greedy.build(layout, 4);
		sol = greedy.run();
		System.out.println("Greedy random opt Top="+sol.tOP+" time cost:"+sol.runTimeCost);
		
		for(int i=0; i<=layout.storageNodeSize; ++i){
			FailResult res = sol.getErorrTolerance(i, 1000);
			System.out.println("Fault Storage Nodes:"+res.failedNodesSize+", Average user running rate:"+res.availableUsersRate);
		}
		
		
		/*MILPModel milp = new MILPModel(_k, _r);
		milp.build(layout, 4);
		Solution sol1 = milp.run(60);
		MILPModelCNT2 milp2 = new MILPModelCNT2(_k, _r);
		milp2.build(layout, 4);
		Solution sol2 = milp2.run();
		MILPModelCNT1 milp3 = new MILPModelCNT1(_k, _r);
		milp3.build(layout, 4);
		Solution sol3 = milp3.run();
		MILPModelS milp4 = new MILPModelS(_k, _r);
		milp4.build(layout, 4);
		Solution sol4 = milp4.run();
		System.out.println("MILP opt Top="+sol1.tOP+" time cost:"+sol1.runTimeCost);
		System.out.println("MILP cnt2 Top="+sol2.tOP+" time cost:"+sol2.runTimeCost);
		System.out.println("MILP cnt2 Top="+sol3.tOP+" time cost:"+sol3.runTimeCost);
		System.out.println("MILP Top="+sol4.tOP+" time cost:"+sol4.runTimeCost);*/
	}

}
