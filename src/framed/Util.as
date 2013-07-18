package framed
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	public class Util
	{
		///////////////////////////////////////////////////////////////
		//
		// Constants
		//
		///////////////////////////////////////////////////////////////
		
		// Version
		public static const MAJOR_VERSION:String = '1';
		public static const MINOR_VERSION:String = '1';
		public static const BUILD_VERSION:String = '0';
		public static const VERSION:String = MAJOR_VERSION + '.' + MINOR_VERSION + '.' + BUILD_VERSION;
		
		// Constants for file types
		public static const OUTPUT_ZIP:String = 'zip';
		public static const OUTPUT_FILE:String = 'file';
		
		// Constants for file names
		private const WATCH_FILE:String = 'framed-watch-file.txt';
		private const DIR_URL_FILE:String = 'last-dir-save-url.txt';
		private const ZIP_URL_FILE:String = 'last-zip-save-url.txt';
		
		///////////////////////////////////////////////////////////////
		//
		// Vars
		//
		///////////////////////////////////////////////////////////////
		
		// Temp storage for things
		private var files:Array;
		private var writeWatchFile:Boolean;
		private var data:ByteArray;
		
		///////////////////////////////////////////////////////////////
		//
		// Constructor
		//
		///////////////////////////////////////////////////////////////
		
		public function Util()
		{
		}
	
		///////////////////////////////////////////////////////////////
		//
		// Public Methods
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Saves a file.
		 * 
		 * @param fileName Name of the file to write.
		 * @param data ByteArray to write to the file.
		 */
		public function save(fileName:String, data:ByteArray, autoSave:Boolean):void
		{
			this.data = data;
			
			if (autoSave && hasUrl(ZIP_URL_FILE) && fileName == getUrl(ZIP_URL_FILE))
			{
				var url:String = getUrl(ZIP_URL_FILE);
				deleteFilesAtUrl(url);
				saveZipToUrl(url);
			}
			else
			{
				var file:File;
				if (fileName.substr(0, 7) == 'file://')
				{
					file = new File(fileName);
				}
				else
				{
					file = File.desktopDirectory.resolvePath(fileName);
				}
				file.addEventListener(Event.SELECT, onZipSelect);
				file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				file.addEventListener(Event.CANCEL, onCancel);
				file.browseForSave("Save your file...");
			}
		}
		
		/**
		 * Saves a list of files.
		 * 
		 * @param dir Path to directory where files will be written.
		 * @param files List of files to write to <code>dir</code>.
		 * @param autoSave Whether or not to prompt before saving.
		 * @param writeWatchFile Whether or not to write a watch file for automation.
		 */
		public function saveFiles(dir:String, files:Array, autoSave:Boolean, writeWatchFile:Boolean):void
		{
			this.files = files;
			this.writeWatchFile = writeWatchFile;
						
			if (autoSave && hasUrl(DIR_URL_FILE) && dir == getUrl(DIR_URL_FILE))
			{
				var url:String = getUrl(DIR_URL_FILE);
				deleteFilesAtUrl(url);
				saveToUrl(url);
			}
			else
			{
				var file:File = File.desktopDirectory.resolvePath(dir);
				file.addEventListener(Event.SELECT, onSelect);
				file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				file.addEventListener(Event.CANCEL, onCancel);
				file.browseForDirectory('Choose Folder To Save To');	
			}
		}
		
		///////////////////////////////////////////////////////////////
		//
		// Private Methods
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Saves a file at the specified URL.
		 * 
		 * @param url URL to write file to.
		 */
		private function saveToUrl(url:String):void
		{
			var fs:FileStream = new FileStream();
			
			var len:int = files.length;
			var f:Object;
			for (var i:int = 0; i < len; ++i)
			{
				f = files[i];
				try
				{
					fs.open(new File(url + '/' + f.fileName), FileMode.WRITE);
					fs.writeBytes(f.bytes);
				}
				catch (err:Error)
				{
					trace("Error writing file. ", err.message);
				}
				
				fs.close();
			}
			
			if (writeWatchFile)
			{
				writeWatchFileToUrl(url);
			}
			
			files = null;
			writeWatchFile = false;
			trace("Done!");
		}
		
		/**
		 * Saves the URL last selected by the user.
		 * This allows the tool to auto-save in the future.
		 * 
		 * @param url URL to save.
		 * @param urlType The type of URL to save. E.g., <code>DIR_URL_FILE</code>.
		 */
		private function saveUrl(url:String, urlType:String):void
		{
			var f:File = File.applicationStorageDirectory.resolvePath(urlType);
			var fs:FileStream = new FileStream();
			try
			{
				fs.open(f, FileMode.WRITE);
				fs.writeUTFBytes(url);	
			}
			catch (err:Error)
			{
				trace("Error writing URL file. ", err.message);
			}
			
			fs.close();
		}
		
		/**
		 * Saves a zip file.
		 * 
		 * @param url URL of the file to save.
		 */
		private function saveZipToUrl(url:String):void
		{
			var file:File = new File(url);
			var fs:FileStream = new FileStream();
			try
			{
				fs.open(file, FileMode.WRITE);
				fs.writeBytes(this.data);	
			}
			catch (err:Error)
			{
				trace("Error writing zip file. ", err.message);
			}
			
			fs.close();
			
			this.data = null;
		}
		
		/**
		 * Deletes files at the specified URL.
		 * Files are moved to the Trash so they can (potentially) be recovered.
		 * 
		 * @param url URL to delete.
		 */
		private function deleteFilesAtUrl(url:String):void
		{
			var f:File = new File(url);
			if (f.exists)
			{
				f.moveToTrash();
			}
		}
		
		/**
		 * Writes the current timestamp to the watch file.
		 * Allows automation tools to easily pickup when files have changed.
		 * 
		 * @param url The URL to write to.
		 */
		private function writeWatchFileToUrl(url:String):void
		{
			var fs:FileStream = new FileStream();
			var s:String = url + "\n" + new Date().getTime().toString();
			try
			{
				fs.open(new File(url + '/' + WATCH_FILE), FileMode.WRITE);
				fs.writeUTFBytes(s);	
			}
			catch (err:Error)
			{
				trace("Error writing watch file. ", err.message);
			}
			
			fs.close();
		}
		
		/**
		 * Checks if we have a saved URL for auto-saving.
		 * 
		 * @param url The URL to test.
		 * @return <code>true</code> if we have a saved URL.
		 */
		private function hasUrl(url:String):Boolean
		{
			var f:File = File.applicationStorageDirectory.resolvePath(url);
			return f.exists;
		}
		
		/**
		 * Gets the auto-save URL.
		 * 
		 * @param url The URL to retrieve.
		 * @return The auto-save URL.
		 */
		private function getUrl(url:String):String
		{
			var f:File = File.applicationStorageDirectory.resolvePath(url);
			var fs:FileStream = new FileStream();
			var url:String = '';
			try
			{
				fs.open(f, FileMode.READ);
				url = fs.readUTFBytes(f.size);
				fs.close();	
			}
			catch (err:Error)
			{
				trace("Error reading URL: ", err.message);
			}
			
			return url;
		}
		
		///////////////////////////////////////////////////////////////
		//
		// Static Methods
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Prepends zeroes to values less than 10.
		 * Transforms "9" to "09".
		 * Leaves "11" as "11".
		 * 
		 * @param value Value to prepend to.
		 * @return The value with zeroes prepended if neeeded.
		 */
		public static function prependZeroes(value:int):String
		{
			if (value < 10 && value > -1)
			{
				return "0" + value;
			}
			
			return value.toString();
		}
		
		/**
		 * Checks if the file has a 'zip' extenstion.
		 * 
		 * @param file File name to test.
		 * @return <code>true</code> if the file has a 'zip' extension.
		 */
		public static function fileIsZip(file:String):Boolean
		{
			return file.substring(file.lastIndexOf('.') + 1) == 'zip';
		}
		
		/**
		 * Checks if the user-specified export type is valid.
		 * 
		 * @param type Export type.
		 * @return <code>true</code> if the <code>type</code> is valid.
		 */
		public static function isValidExportType(type:String):Boolean
		{
			var arr:Array = [ OUTPUT_ZIP, OUTPUT_FILE ];
			return arr.indexOf(type) != -1;
		}
		
		///////////////////////////////////////////////////////////////
		//
		// Event Handlers
		//
		///////////////////////////////////////////////////////////////
		
		/**
		 * Handler for "save cancel" event.
		 */
		private function onCancel(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.SELECT, onSelect);
			e.currentTarget.removeEventListener(Event.SELECT, onIOError);
			e.currentTarget.removeEventListener(Event.SELECT, onCancel);
			e.currentTarget.removeEventListener(Event.SELECT, onZipSelect);
			
			files = null;
			writeWatchFile = false;
		}
		
		/**
		 * Handler for "save select" event.
		 */
		private function onSelect(e:Event):void
		{
			var dir:File = e.target as File;
			dir.removeEventListener(Event.SELECT, onSelect);
			dir.removeEventListener(Event.SELECT, onIOError);
			dir.removeEventListener(Event.SELECT, onCancel);
			
			if (!files) return;

			var url:String = decodeURI(dir.url);
			trace("Saving to '" + url + "'");
			saveUrl(url, DIR_URL_FILE);
			saveToUrl(url);
		}
		
		/**
		 * Handles when user selects where to save zip file.
		 */
		private function onZipSelect(e:Event):void
		{
			var file:File = e.target as File;
			file.addEventListener(Event.SELECT, onZipSelect);
			file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			file.addEventListener(Event.CANCEL, onCancel);
			
			var url:String = decodeURI(file.url);
			trace("Saving to '" + url + "'");
			saveUrl(url, ZIP_URL_FILE);
			saveZipToUrl(url);
		}

		/**
		 * Handler for IO error (e.g., "error writing to disk.") events.
		 */
		private function onIOError(e:IOErrorEvent):void
		{
			trace("io error");
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			e.currentTarget.removeEventListener(Event.COMPLETE, onComplete);
			
			e.currentTarget.removeEventListener(Event.SELECT, onSelect);
			e.currentTarget.removeEventListener(Event.SELECT, onCancel);
			e.currentTarget.removeEventListener(Event.SELECT, onZipSelect);
		}
		
		/**
		 * Complete handler.
		 */
		private function onComplete(e:Event):void
		{
			trace("complete");
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			e.currentTarget.removeEventListener(Event.COMPLETE, onComplete);
		}
				
		
	}
}