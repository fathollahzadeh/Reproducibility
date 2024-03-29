package at.tugraz.benchmark;

import org.apache.sysds.common.Types;
import org.apache.sysds.runtime.io.FrameReader;
import org.apache.sysds.runtime.iogen.GenerateReader;
import org.apache.sysds.runtime.frame.data.FrameBlock;
import org.apache.sysds.runtime.iogen.SampleProperties;
import org.apache.wink.json4j.JSONObject;

public class GIOFrame {

	public static void main(String[] args) throws Exception {
		String sampleRawFileName;
		String sampleFrameFileName;
		String sampleRawDelimiter;
		String schemaFileName;
		String dataFileName;
		boolean parallel;
		long rows = -1;

		sampleRawFileName = System.getProperty("sampleRawFileName");
		sampleFrameFileName = System.getProperty("sampleFrameFileName");
		sampleRawDelimiter = "\t";
		schemaFileName = System.getProperty("schemaFileName");
		dataFileName = System.getProperty("dataFileName");
		parallel = Boolean.parseBoolean(System.getProperty("parallel"));
		Util util = new Util();

		// read and parse mtd file
		String mtdFileName = dataFileName + ".mtd";
		try {
			String mtd = util.readEntireTextFile(mtdFileName);
			mtd = mtd.replace("\n", "").replace("\r", "");
			mtd = mtd.toLowerCase().trim();
			JSONObject jsonObject = new JSONObject(mtd);
			if(jsonObject.containsKey("rows"))
				rows = jsonObject.getLong("rows");
		}
		catch(Exception exception) {
		}

		Types.ValueType[] sampleSchema = util.getSchema(schemaFileName);
		int ncols = sampleSchema.length;
		String[][] sampleFrameStrings = util.loadFrameData(sampleFrameFileName, sampleRawDelimiter, ncols);
		FrameBlock sampleFrame = new FrameBlock(sampleSchema, sampleFrameStrings);
		String sampleRaw = util.readEntireTextFile(sampleRawFileName);
		GenerateReader.GenerateReaderFrame gr = new GenerateReader.GenerateReaderFrame(sampleRaw, sampleFrame, parallel);
		FrameReader fr = gr.getReader();
		FrameBlock frameBlock = fr.readFrameFromHDFS(dataFileName, sampleSchema, rows, sampleSchema.length);
	}
}
