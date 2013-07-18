# Framed: A Library for Exporting Frames From Flash

Framed exports frames from Flash animations as a sequence of PNGs. Framed supports exporting MovieClips and the Flash stage.

## Why Framed?

I'm using Flash to make traditional, hand-drawn animations. That is, I draw my each frame of my animations as if I were doing it with pencil and paper over a light box. I created Framed because I couldn't find another exporter that did exactly what I wanted. Before using Framed I'd highly recommend checking out [Grapefrukt Exporter](https://github.com/grapefrukt/grapefrukt-export) to see if it suits your needs -- it is almost certainly more polished than Framed. If you're still reading this you've probably checked out a bunch of other projects and landed here.

## How Does Framed Work?

Framed can export either a MovieClip symbol (MovieClip Framing) or a section of the Stage (Stage Framing) as a sequence of PNGs. Framed will draw each frame of an animation to a PNG, stuff all of the PNGs into a zip archive and write that file to disk.

### Set Up

All you need to do is add the Framed SWC to your Flash Library Path (see [this StackOverlow answer](http://stackoverflow.com/a/2892713/608884) for details) and update your project to be an Adobe AIR project. Then just add a few lines of Actionscript to the first frame of your timeline and blamo! Exported frames!

### Export the Frames of a MovieClip

This assumes you've already converted your animation into a MovieClip and added it to your project's library.

```
import framed.MovieClipFramer;

// Instantiate a MovieClip from your library
var mc:MovieClip = new MyMovieClip();

// Create a MovieClipFramer object passing it a reference to the
// timeline and the clip you created above.
var framer:MovieClipFramer = new MovieClipFramer(this, mc);

// Run the framer.
framer.frame();
```

### MovieClip Export Options

The MovieClip exporter takes two optional parameters:

1. The file name for the exported zip archive.
2. The framing method.

#### Set a Custom Export File Name

By default the exported zip archive is named `data.zip`.

```
import framed.MovieClipFramer;

var mc:MovieClip = new MyMovieClip();
var framer:MovieClipFramer = new MovieClipFramer(this, mc);
framer.frame('myCustomFileName.zip');
```

#### Set the Framing Method

MovieClip exporting supports two framing methods:

1. **TO\_LARGEST\_FRAME**: Calculates the widest and tallest frame size and exports all frames, centered, into a frame this size.
2. **TO\_EACH\_FRAME**: Exports each frame as its own size.

The default framing method is `TO_LARGEST_FRAME`.

Examples tend to make things clearer so here are a couple:

Assume you have an animation with three frames. The first frame is 20 x 20px, the second frame is 20 x 30px and the third frame is 40 x 20px.

Using `TO_LARGEST_FRAME` each frame will be 40 x 30px as the widest frame is 40px and the tallest frame is 30px (all frames are centered into this frame). Using `TO_EACH_FRAME` the first frame will be 20 x 20px, the second 20 x 30px and the third 40 x 20px.

To set the framing method pass in the constant as the second parameter to the `frame()` methood.

```
import framed.MovieClipFramer;

var mc:MovieClip = new SnoozingPotato();
var framer:MovieClipFramer = new MovieClipFramer(this.stage, mc);

// Use 'TO_LARGEST_FRAME'
framer.frame('data.zip', MovieClipFramer.TO_LARGEST_FRAME);

// or use 'TO_EACH_FRAME'
// framer.frame('data.zip', MovieClipFramer.TO_EACH_FRAME);
```

### Export the Frames of a the Stage

Sometimes making a MovieClip of your animation is just too much of a pain. You just want to dump what's on the stage into a bunch of PNGs and be done with it. This is where Stage framing comes in. With Stage framing you draw a shape to define the region of the Stage you want to capture and that's it. Here's a step-by-step:

1. Create your awesome animation.
2. Create a new layer in your timeline. I like to call it `frame` but you can call yours whatever you fancy.
3. Use the Rectangle tool to draw a box around the content on the timeline you want to capture. This box will what Framed captures.
4. With the box you just drew selected open the Properties Panel and give the box an instance name. Again, I like `frame`.
5. Add the following Actionscript and that's it!

```
import framed.StageFramer;

var framer:StageFramer = new StageFramer(this, frame);
framer.frame();
// or
// framer.frame('myCustomFileName.zip');
```

### Auto Saving

Choosing where you want to save and clicking a bunch of buttons each and every time you export your animations gets annoying rather quickly. You can keep your annoyance at locked away by using auto-save! Simply pass in the `Framed.AUTO_SAVE_ON` parameter to the `frame()` method and you'll be ... not automatically auto-saving. There is some initial setup.

Auto-saving requires you to first manually select where you want to save for two reasons. First, auto-saving will also auto-trash anything that lives at the auto-save destination. Manually selecting the auto-save location helps avoid accidentally obliterating a bunch of work (fear not! when trashing work Framed moves it to the trash/recycle bin so it should be retrievable). Second, manually selecting the auto-save destination allows Framed to spit out the path for you so you can just copy-paste it into your code.

Here's an auto-save example using Stage framing:

```
import framed.Framed;
import framed.StageFramer;

var framer:StageFramer = new StageFramer(this, frame);
framer.frame('data.zip', Framed.AUTO_SAVE_ON);
```

The first time you run this you'll notice nothing different from the non-auto-save version: You still have to select your save location and hit a few buttons to save your file. Switching to the Output tab in Flash there will be a line that looks similar to this:

```
Saving to 'file:///E:/path/to/data.zip'
```

Select and copy the part between the single quotes (in the above example this would be `file:///E:/path/to/data.zip`) and paste that into your Actionscript code for file name. Your call to the `frame()` method will now look like this:

```
framer.frame('file:///E:/path/to/data.zip', Framed.AUTO_SAVE_ON);
```

Now when you run your animation it will auto-save to the location you selected.

### File Export

Exporting a zip archive of all your frames isn't always convenient. It might be nicer to just export all of the files individually to a folder. With File Export you can do this. To use file export simply specify a directory for the file name rather than a zip archive:

```
framer.frame('file:///E:/path/to/folder');
```

File Export even works with auto-save:

```
framer.frame('file:///E:/path/to/folder', Framed.AUTO_SAVE_ON);
```

### Watch Files

The goal of Framed is to automate boring, repetitive work as much as possible so you can get your animations from Flash into your game quickly and easily. However, in most cases the output from Framed isn't ready to be plopped into a game. You might need to resize or rename the images, or drop them into a texture atlas. All of these things are outside the scope of Framed but Framed does provide a mechanism for hooking into an asset pipeline: watch files.

Watch files are specific files that a task runner tool (e.g., [Grunt](http://gruntjs.com/)) watches for changes. When a watch file is changed the task runner executes a specific action or series of actions. When using File Export you can also choose to export a watch file:

```
framer.frame('file:///E:/path/to/folder', Framed.AUTO_SAVE_ON, Framed.WRITE_WATCH_FILE_ON);
```

This writes a file called `framed-watch-file.txt` in the same folder as the exported PNG frames. The watch file is a UTF-8 encoded plain text file that contains two lines, in this order:

1. The [absolute URL](http://help.adobe.com/en_US/AIR/1.5/devappshtml/WS5b3ccc516d4fbf351e63e3d118666ade46-7fe4.html#WS5b3ccc516d4fbf351e63e3d118666ade46-7d9e) to the export folder
2. The [Unix timestamp](http://en.wikipedia.org/wiki/Unix_time) as milliseconds when the file was written. [See also](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/Date.html#getTime(\))


## Supported Flash Versions

The following are the supported versions (read: I've used Framed with these) of Flash. Framed will probably work with other versions of Flash (<a href="mailto:hello@seanmonahan.org?subject=Framed">let me know!</a>) but I have no way of knowing that.

  - Flash CS4 (Windows).

## Building Framed

Framed is built with Flash Builder 4.7. You should be able to use any version of Flash Builder so long as it can compile a SWC using the Flex 4.0A SDK. To build Framed first make sure you have all the dependencies:

  - [as3corelib](https://github.com/mikechambers/as3corelib/) `images` package. Source files included in repo.
  - [nochump zip](http://nochump.com/blog/archives/15). SWC included in repo.
  - [Flex 4.0A SDK](http://sourceforge.net/adobe/flexsdk/wiki/Download%20Flex%204/). Download this guy separately.
  - [Adobe AIR SDK](http://www.adobe.com/devnet/air/air-sdk-download.html). Download and install this into your Flex 4.0A folder.

1. Once you have all the dependencies [add the Flex 4.0A SDK to Flash Builder](http://help.adobe.com/en_US/Flex/4.0/UsingFlashBuilder/WSbde04e3d3e6474c4-fb4ed5124020245e3-7ff8.html).
2. Next select File > New > Flex Library Project.
3. In the dialog that appears enter:
  - "Framed" for the Project Name
  - Point Project Location to the root of this repo.
  - Select "Flex 4.0A" for the Flex SDK Version
  - Tick the box labeld "Include Adobe AIR libraries".
  - Click Next.
  - Under the Library Path tab click "Add SWC Folder". In the dialog that appears enter "libs". Click OK.
  - Click Finish.
4. Compile the Framed SWC by selecting Project > Build All. The SWC file will be compiled into the `bin` folder in the project root.



## License

Framed is licensed under the MIT license.