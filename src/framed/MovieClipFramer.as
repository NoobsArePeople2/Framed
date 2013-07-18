package framed
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipOutput;
	
	/**
	 * Class for drawing a MovieClip symbol to PNGs.
	 */
	public class MovieClipFramer
	{
		///////////////////////////////////////////////////////////////
		//
		// Constants
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Just export each frame at its individual size. Frames may be different size.
		 */
		public static const TO_EACH_FRAME:String    = "toEachFrame";
		
		/**
		 * Keep track of frame size and be sure to export all frames at the largest size.
		 * This ensures all frames are the same size. 
		 */
		public static const TO_LARGEST_FRAME:String = "toLargestFrame";
		
		///////////////////////////////////////////////////////////////
		//
		// Vars
		//
		///////////////////////////////////////////////////////////////
		
		private var root:DisplayObject;
		private var mc:MovieClip;
		
		private var widest:int = 0;
		private var tallest:int = 0;
		
		private var autoSave:Boolean;
		private var writeWatchFile:Boolean
		private var util:Util;
		
		///////////////////////////////////////////////////////////////
		//
		// Constructor
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Constructor.
		 * 
		 * @param root <code>this</code> on the Flash timeline.
		 * @param mc <code>MovieClip</code> symbol used as the "camera" bounds. This defines the portion of the stage to be drawn.
		 */
		public function MovieClipFramer(root:DisplayObject, mc:MovieClip)
		{
			this.root = root;
			this.mc = mc;
			util = new Util();
		}
		
		///////////////////////////////////////////////////////////////
		//
		// Public Methods
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Kicks of the drawing process.
		 * 
		 * @param output Where to write the files. Use a 'zip' extension to write to zip. Use a file URL to write PNGs directly.
		 * @param autoSave Whether to auto-save when running. @see <code>Framed.AUTO_SAVE_ON</code> and <code>Framed.AUTO_SAVE_OFF</code>.
		 * @param writeWatchFile Whether to write a watch file after running. @see <code>Framed.WRITE_WATCH_FILE_ON</code> and <code>Framed.WRITE_WATCH_FILE_OFF</code>.
		 * 
		 * @see: http://help.adobe.com/en_US/AIR/1.5/devappshtml/WS5b3ccc516d4fbf351e63e3d118666ade46-7fe4.html#WS5b3ccc516d4fbf351e63e3d118666ade46-7d9e
		 */
		public function frame(output:String = 'data.zip', method:String = '', autoSave:String = 'autoSaveOff', writeWatchFile:String = 'writeWatchFileOff'):void
		{
			var rootClip:MovieClip = root as MovieClip;
			if (!rootClip)
			{
				trace("Nope.");
				return;
			}
			rootClip.stop();
			
			if (method == '')
			{
				method = TO_LARGEST_FRAME;
			}
			
			this.autoSave = autoSave == Framed.AUTO_SAVE_ON;
			this.writeWatchFile = writeWatchFile == Framed.WRITE_WATCH_FILE_ON;
			var outputType:String = Util.OUTPUT_ZIP;
			if (!Util.fileIsZip(output)) 
			{
				outputType = Util.OUTPUT_FILE;
			}
			
			var frameBytes:Array = [];
			var bmd:BitmapData;
			var bitmaps:Array = [];
			
			// Draw all the frames to BitmapDatas
			for (var i:int = 1; i <= mc.totalFrames; ++i)
			{
//				trace("frame: ", mc.currentFrame, "w: ", mc.width, "h: ", mc.height);
				mc.nextFrame();
				
				var w:int = Math.ceil(mc.width);
				var h:int = Math.ceil(mc.height);
				
				if (w > widest) widest = w;
				if (h > tallest) tallest = h;
				
				bmd = new BitmapData(w, h, true, 0xffff0000);
				bmd.fillRect(bmd.rect, 0);
				
				var matrix:Matrix = mc.transform.matrix;
				var rect:Rectangle = mc.getBounds(rootClip);
				/* Apply a translation to the Matrix object using the x and y property of the Rectangle (bounding box) object */
				matrix.translate(-rect.x, -rect.y);
				bmd.draw(mc, matrix);
				
				bitmaps.push(bmd.clone());
			}

			var canvas:BitmapData;
			var len:int = bitmaps.length;
			var bytes:ByteArray;
			if (method == TO_LARGEST_FRAME)
			{
				// Make all the frames the same size.
				// This size will the {widest frame} x {tallest frame}
				canvas = new BitmapData(widest, tallest);
				for (i = 0; i < len; ++i)
				{
					bmd = bitmaps[i];
					var ox:Number = (canvas.width - bmd.width) / 2;
					var oy:Number = (canvas.height - bmd.height) / 2;
					
					canvas.fillRect(canvas.rect, 0);
					canvas.copyPixels(bmd, bmd.rect, new Point(ox, oy));
					bytes = PNGEncoder.encode(canvas);
					frameBytes.push(bytes);
				}
			}
			else
			{
				for (i = 0; i < len; ++i) 
				{
					bmd = bitmaps[i];
					bytes = PNGEncoder.encode(bmd);
					frameBytes.push(bytes);
				}
			}
			
			if (outputType == Util.OUTPUT_ZIP)
			{
				var zip:ZipOutput = new ZipOutput();
				var ze:ZipEntry;
				for (i = 0; i < len; ++i)
				{
					trace("Putting entry ", "frames/frame_" + Util.prependZeroes(i) + ".png");
					ze = new ZipEntry("frames/frame_" + Util.prependZeroes(i) + ".png");
					zip.putNextEntry(ze);
					zip.write(frameBytes[i]);
					zip.closeEntry();	
				}
				
				zip.finish();
				
				util.save(output, zip.byteArray, this.autoSave);
			}
			else
			{
				var filename:String;
				var files:Array = [];
				for (i = 0; i < len; ++i)
				{
					filename =  "frame_" + Util.prependZeroes(i) + ".png";
					trace("Adding file ", filename);
					files.push({ fileName: filename, bytes: frameBytes[i] });
				}
				util.saveFiles(output, files, this.autoSave, this.writeWatchFile);
			}
		}
	}
}