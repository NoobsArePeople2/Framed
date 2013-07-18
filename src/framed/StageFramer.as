package framed
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipOutput;
	
	/**
	 * Class for drawing a selected portion of the Flash stage to PNGs.
	 */
	public class StageFramer
	{
		///////////////////////////////////////////////////////////////
		//
		// Vars
		//
		///////////////////////////////////////////////////////////////
		
		private var mc:MovieClip;
		private var root:DisplayObject;
		
		private var output:String;
		
		private var bitmaps:Array;
		private var bmd:BitmapData;
		private var matrix:Matrix;
		
		private var outputType:String;
		private var autoSave:Boolean;
		private var writeWatchFile:Boolean;
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
		public function StageFramer(root:DisplayObject, mc:MovieClip)
		{
			this.mc = mc;
			this.root = root;
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
		public function frame(output:String = 'data.zip', autoSave:String = 'autoSaveOff', writeWatchFile:String = 'writeWatchFileOff'):void
		{
			var rootClip:MovieClip = root as MovieClip;
			if (!rootClip)
			{
				trace("Nope.");
				return;
			}

			this.autoSave = autoSave == Framed.AUTO_SAVE_ON;
			this.writeWatchFile = writeWatchFile == Framed.WRITE_WATCH_FILE_ON;
			this.output = output;
			if (!Util.fileIsZip(output)) 
			{
				outputType = Util.OUTPUT_FILE;
			}
			else
			{
				outputType = Util.OUTPUT_ZIP;
			}
			
			mc.alpha = 0;
			
			bitmaps = [];
			var pos:Point = mc.localToGlobal(new Point(mc.x, mc.y));
			bmd = new BitmapData(mc.width, mc.height, true, 0xffff0000);
			
			matrix = root.transform.matrix;
			matrix.translate(-pos.x / 2, -pos.y / 2);
			
			rootClip.stop();
			rootClip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			draw(rootClip);
			rootClip.gotoAndPlay(1);
		}
				
		///////////////////////////////////////////////////////////////
		//
		// Private Methods
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Draws the current frame of the stage to a <code>BitmapData</code>.
		 * 
		 * @param rootClip The root MovieClip object.
		 */
		private function draw(rootClip:MovieClip):void
		{
			trace("Drawing frame ", rootClip.currentFrame);
			// Clear the bitmap data
			bmd.fillRect(bmd.rect, 0);
			// Draw the current frame
			bmd.draw(rootClip, matrix);
			bitmaps.push(bmd.clone());
		}
		
		/**
		 * Writes all PNGs into a zip object.
		 * 
		 * @return The zip object.
		 */
		private function writeZip():ZipOutput
		{
			var bytes:ByteArray;
			var len:int = bitmaps.length;
			var zip:ZipOutput = new ZipOutput();
			var ze:ZipEntry;
			for (var i:int = 0; i < len; ++i)
			{
				trace("Putting entry ", "frames/frame_" + Util.prependZeroes(i) + ".png");
				ze = new ZipEntry("frames/frame_" + Util.prependZeroes(i) + ".png");
				zip.putNextEntry(ze);
				zip.write(PNGEncoder.encode(bitmaps[i]));
				zip.closeEntry();	
			}
			
			zip.finish();
			return zip;
		}
		
		/**
		 * Writes individual PNGs to disk.
		 */
		private function writeFiles():void
		{
			var len:int = bitmaps.length;
			var filename:String;
			
			var files:Array = [];
			for (var i:int = 0; i < len; ++i)
			{
				filename =  "frame_" + Util.prependZeroes(i) + ".png";
				trace("Adding file ", filename);
				files.push({ fileName: filename, bytes: PNGEncoder.encode(bitmaps[i]) });
			}
			util.saveFiles(output, files, autoSave, writeWatchFile);
		}
		
		///////////////////////////////////////////////////////////////
		//
		// Event Handlers
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Handles the "enterFrame" event.
		 * In order to properly draw each from of the Stage we must advance the
		 * Flash timeline. This function allows us to track where we are.
		 * 
		 * @param e <code>Event.ENTER_FRAME</code>.
		 */
		private function onEnterFrame(e:Event):void
		{
			var rootClip:MovieClip = e.currentTarget as MovieClip;
			if (!rootClip)
			{
				trace("Uh oh!");
				e.currentTarget.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				return;
			}
			
			draw(rootClip);
			
			if (rootClip.currentFrame == rootClip.totalFrames)
			{
				// We're done
				rootClip.stop();
				e.currentTarget.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				if (outputType == Util.OUTPUT_ZIP) 
				{
					util.save(output, writeZip().byteArray, this.autoSave);
				}
				else
				{
					writeFiles();
				}
			}
		}
		
	}
}