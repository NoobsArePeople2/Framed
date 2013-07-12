package framed
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipOutput;
	
	public class MovieClipFramer
	{
		// Just export each frame at its individual size. Frames may be different size.
		public static const TO_EACH_FRAME:String    = "toEachFrame";
		// Keep track of frame size and be sure to export all frames at the largest size.
		// This ensures all frames are the same size.
		public static const TO_LARGEST_FRAME:String = "toLargestFrame";
		
		private var root:DisplayObject;
		private var mc:MovieClip;
		
		private var widest:int = 0;
		private var tallest:int = 0;
		
		public function MovieClipFramer(root:DisplayObject, mc:MovieClip)
		{
			this.root = root;
			this.mc = mc;
		}
		
		public function frame(fileName:String = 'data.zip', method:String = ''):void
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
			
			var frameBytes:Array = [];
			var bmd:BitmapData;
			var bitmaps:Array = [];
			
			// Draw all the frames to BitmapDatas
			for (var i:int = 1; i <= mc.totalFrames; ++i)
			{
				trace("frame: ", mc.currentFrame, "w: ", mc.width, "h: ", mc.height);
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
			
			var zip:ZipOutput = new ZipOutput();
			var ze:ZipEntry;
			for (i = 0; i < len; ++i)
			{
				trace("Putting entry ", "frames/frame_" + prependZeroes(i) + ".png");
				ze = new ZipEntry("frames/frame_" + prependZeroes(i) + ".png");
				zip.putNextEntry(ze);
				zip.write(frameBytes[i]);
				zip.closeEntry();	
			}
			
			zip.finish();
			
			save(fileName, zip.byteArray);
		}
		
		private function save(fileName:String, data:ByteArray):void
		{
			var file:FileReference = new FileReference();
			file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			file.addEventListener(Event.COMPLETE, onComplete);
			file.save(data, fileName);
		}
		
		private function prependZeroes(value:int):String
		{
			if (value < 10 && value > -1)
			{
				return "0" + value;
			}
			
			return value.toString();
		}
		
		
		private function onIOError(e:IOErrorEvent):void
		{
			trace("io error");
		}
		
		private function onComplete(e:Event):void
		{
			trace("complete");
		}
		
	}
}