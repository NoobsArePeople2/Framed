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
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipOutput;
	
	public class StageFramer
	{
		private var mc:MovieClip;
		private var root:DisplayObject;
		
		private var fileName:String;
		
		private var bitmaps:Array;
		private var bmd:BitmapData;
		private var matrix:Matrix;
		
		
		public function StageFramer(root:DisplayObject, mc:MovieClip)
		{
			this.mc = mc;
			this.root = root;
		}
		
		public function frame(fileName:String = 'data.zip'):void
		{
			var rootClip:MovieClip = root as MovieClip;
			if (!rootClip)
			{
				trace("Nope.");
				return;
			}
			
			this.fileName = fileName;
			
			mc.alpha = 0;
			
			bitmaps = [];
			var pos:Point = mc.localToGlobal(new Point(mc.x, mc.y));
			bmd = new BitmapData(mc.width, mc.height, true, 0xffff0000);
			
			matrix = root.transform.matrix;
			matrix.translate(-pos.x / 2, -pos.y / 2);
			
//			trace("Stopping.");
			rootClip.stop();
//			trace("Playing.");
			rootClip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			draw(rootClip);
			rootClip.gotoAndPlay(1);
		}
		
		private function draw(rootClip:MovieClip):void
		{
			trace("Drawing frame ", rootClip.currentFrame);
			// Clear the bitmap data
			bmd.fillRect(bmd.rect, 0);
			// Draw the current frame
			bmd.draw(rootClip, matrix);
			bitmaps.push(bmd.clone());
		}
		
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
				save(fileName, writeZip().byteArray);
			}
		}
		
		private function writeZip():ZipOutput
		{
			var bytes:ByteArray;
			var len:int = bitmaps.length;
			var zip:ZipOutput = new ZipOutput();
			var ze:ZipEntry;
			for (var i:int = 0; i < len; ++i)
			{
				trace("Putting entry ", "frames/frame_" + prependZeroes(i) + ".png");
				ze = new ZipEntry("frames/frame_" + prependZeroes(i) + ".png");
				zip.putNextEntry(ze);
				zip.write(PNGEncoder.encode(bitmaps[i]));
				zip.closeEntry();	
			}
			
			zip.finish();
			return zip;
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