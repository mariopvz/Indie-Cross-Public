package vlc;

import flixel.FlxG;
#if cpp
import cpp.NativeArray;
import cpp.UInt8;
import haxe.io.Bytes;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.errors.Error;
import openfl.events.Event;
import vlc.LibVLC;

/**
 * ...
 * @author Tommy S
 */
#if cpp
@:cppFileCode('#include "LibVLC.cpp"')
#end
class VlcBitmap extends Bitmap
{
	/////////////////////////////////////////////////////////////////////////////////////
	// ===================================================================================
	// Consts
	//-----------------------------------------------------------------------------------
	// ===================================================================================
	// Properties
	//-----------------------------------------------------------------------------------
	public var videoWidth:Int;
	public var videoHeight:Int;
	public var repeat:Int = 0;
	public var duration:Float;
	public var length:Float;
	public var inWindow:Bool;
	public var initComplete:Bool;
	public var fullscreen:Bool;
	public var volume(default, set):Float = 1;

	public var isDisposed:Bool;
	public var isPlaying:Bool;
	public var disposeOnStop:Bool = false;
	public var time:Int;

	public var onVideoReady:Void->Void;
	public var onPlay:Void->Void;
	public var onStop:Void->Void;
	public var onPause:Void->Void;
	public var onResume:Void->Void;
	public var onSeek:Void->Void;
	public var onBuffer:Void->Void;
	public var onProgress:Void->Void;
	public var onOpening:Void->Void;
	public var onComplete:Void->Void;
	public var onError:Void->Void;

	// ===================================================================================
	// Declarations
	//-----------------------------------------------------------------------------------
	var bufferMem:Array<UInt8>;
	#if cpp
	var libvlc:LibVLC;
	#end

	// ===================================================================================
	// Variables
	//-----------------------------------------------------------------------------------
	var frameSize:Int;
	var _width:Null<Float>;
	var _height:Null<Float>;
	var texture:RectangleTexture;
	var texture2:RectangleTexture;
	var bmdBuf:BitmapData;
	var bmdBuf2:BitmapData;
	var oldTime:Int;
	var flipBuffer:Bool;
	var screenWidth:Float;
	var screenHeight:Float;

	/////////////////////////////////////////////////////////////////////////////////////

	public function new()
	{
		super(null, null, true);

		#if cpp
		init();
		#end
	}

	function mThread()
	{
		init();
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function init()
	{
		#if cpp
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		#end
	}

	function onAddedToStage(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		libvlc = LibVLC.create();
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(Event.ENTER_FRAME, vLoop);
	}

	/////////////////////////////////////////////////////////////////////////////////////

	public function play(?source:String)
	{
		#if cpp
		libvlc.setRepeat(repeat);

		if (!inWindow)
		{
			if (source != null)
				libvlc.play(source);
			else
				libvlc.play();
		}
		else
		{
			if (source != null)
				libvlc.playInWindow(source);
			else
				libvlc.playInWindow();

			libvlc.setWindowFullscreen(fullscreen);
		}

		if (onPlay != null)
			onPlay();
		#end
	}

	public function stop()
	{
		#if cpp
		isPlaying = false;
		libvlc.stop();
		// if (disposeOnStop)
		// dispose();

		if (onStop != null)
			onStop();
		#end
	}

	public function pause()
	{
		#if cpp
		isPlaying = false;
		libvlc.pause();
		if (onPause != null)
			onPause();
		#end
	}

	public function resume()
	{
		#if cpp
		isPlaying = true;
		libvlc.resume();
		if (onResume != null)
			onResume();
		#end
	}

	public function seek(seekTotime:Float)
	{
		#if cpp
		libvlc.setPosition(seekTotime);
		if (onSeek != null)
			onSeek();
		#end
	}

	public function getFPS():Float
	{
		#if cpp
		if (libvlc != null && initComplete)
			return libvlc.getFPS();
		else
			return 0;
		#else
		return 0;
		#end
	}

	public function getTime():Int
	{
		#if cpp
		if (libvlc != null && initComplete)
			return libvlc.getTime();
		else
			return 0;
		#else
		return 0;
		#end
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function checkFlags()
	{
		#if cpp
		if (!isDisposed)
		{
			if (untyped __cpp__('libvlc->flags[1]') == 1)
			{
				untyped __cpp__('libvlc->flags[1]=-1');
				statusOnPlaying();
			}
			if (untyped __cpp__('libvlc->flags[2]') == 1)
			{
				untyped __cpp__('libvlc->flags[2]=-1');
				statusOnPaused();
			}
			if (untyped __cpp__('libvlc->flags[3]') == 1)
			{
				untyped __cpp__('libvlc->flags[3]=-1');
				statusOnStopped();
			}
			if (untyped __cpp__('libvlc->flags[4]') == 1)
			{
				untyped __cpp__('libvlc->flags[4]=-1');
				statusOnEndReached();
			}
			if (untyped __cpp__('libvlc->flags[5]') != -1)
			{
				statusOnTimeChanged(untyped __cpp__('libvlc->flags[5]'));
			}
			if (untyped __cpp__('libvlc->flags[6]') != -1)
			{
				statusOnPositionChanged(untyped __cpp__('libvlc->flags[9]'));
			}
			if (untyped __cpp__('libvlc->flags[9]') == 1)
			{
				untyped __cpp__('libvlc->flags[9]=-1');
				statusOnError();
			}
			if (untyped __cpp__('libvlc->flags[10]') == 1)
			{
				untyped __cpp__('libvlc->flags[10]=-1');
				statusOnSeekableChanged(0);
			}
			if (untyped __cpp__('libvlc->flags[11]') == 1)
			{
				untyped __cpp__('libvlc->flags[11]=-1');
				statusOnOpening();
			}
			if (untyped __cpp__('libvlc->flags[12]') == 1)
			{
				untyped __cpp__('libvlc->flags[12]=-1');
				statusOnBuffering();
			}
			if (untyped __cpp__('libvlc->flags[13]') == 1)
			{
				untyped __cpp__('libvlc->flags[13]=-1');
				statusOnForward();
			}
			if (untyped __cpp__('libvlc->flags[14]') == 1)
			{
				untyped __cpp__('libvlc->flags[14]=-1');
				statusOnBackward();
			}
		}
		#end
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function onResize(e:Event):Void
	{
		set_width(calc(0));
		set_height(calc(1));
	}

	public function calc(Ind:Int):Float
	{
		var appliedWidth:Float = FlxG.stage.stageHeight * (FlxG.width / FlxG.height);
		var appliedHeight:Float = FlxG.stage.stageWidth * (FlxG.height / FlxG.width);

		if (appliedHeight > FlxG.stage.stageHeight)
			appliedHeight = FlxG.stage.stageHeight;

		if (appliedWidth > FlxG.stage.stageWidth)
			appliedWidth = FlxG.stage.stageWidth;

		switch (Ind)
		{
			case 0:
				return appliedWidth;
			case 1:
				return appliedHeight;
		}

		return 0;
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function videoInitComplete()
	{
		#if cpp
		videoWidth = libvlc.getWidth();
		videoHeight = libvlc.getHeight();

		duration = libvlc.getDuration();
		length = libvlc.getLength();

		if (bitmapData != null)
			bitmapData.dispose();

		if (texture != null)
			texture.dispose();
		if (texture2 != null)
			texture2.dispose();

		texture = Lib.current.stage.context3D.createRectangleTexture(videoWidth, videoHeight, BGRA, true);
		bitmapData = BitmapData.fromTexture(texture);

		smoothing = true;

		if (_width != null)
			width = _width;
		else
			width = videoWidth;

		if (_height != null)
			height = _height;
		else
			height = videoHeight;

		bufferMem = [];
		frameSize = videoWidth * videoHeight * 4;

		setVolume(volume);

		initComplete = true;

		if (onVideoReady != null)
			onVideoReady();
		#end
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function vLoop(e)
	{
		#if cpp
		checkFlags();
		render();
		#end
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function render()
	{
		var cTime = Lib.getTimer();

		// with fast gpu rendering now i think we can make the fps higher (35 to 60)
		if ((cTime - oldTime) > 16) // min 16 ms between renders, but this is not a good way to do it...
		{
			oldTime = cTime;

			#if cpp
			//if (isPlaying && texture != null) // (Stage3D)
			if (isPlaying)
			{
				try
				{
					NativeArray.setUnmanagedData(bufferMem, libvlc.getPixelData(), frameSize);
					if (bufferMem != null)
					{
						texture.uploadFromByteArray(Bytes.ofData(cast(bufferMem)), 0);
						width++; //This is a horrible hack to force the texture to update... Surely there is a better way...
						width--;
					}
				}
				catch (e:Error)
				{
					trace("error: " + e);
					throw new Error("render broke xd");
				}
			}
			#end
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function setVolume(vol:Float)
	{
		#if cpp
		if (libvlc != null && initComplete)
			libvlc.setVolume(vol * 100);
		#end
	}

	public function getVolume():Float
	{
		#if cpp
		if (libvlc != null && initComplete)
			return libvlc.getVolume();
		else
			return 0;
		#else
		return 0;
		#end
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function statusOnOpening()
	{
		if (onOpening != null)
			onOpening();
	}

	function statusOnBuffering()
	{
		trace("buffering");

		if (onBuffer != null)
			onBuffer();
	}

	function statusOnPlaying()
	{
		if (!initComplete)
		{
			isPlaying = true;
			initComplete = true;
			videoInitComplete();
		}
	}

	function statusOnPaused()
	{
		if (isPlaying)
			isPlaying = false;

		if (onPause != null)
			onPause();
	}

	function statusOnStopped()
	{
		if (isPlaying)
			isPlaying = false;

		if (onStop != null)
			onStop();
	}

	function statusOnEndReached()
	{
		if (isPlaying)
			isPlaying = false;

		// trace("end reached!");
		if (onComplete != null)
			onComplete();
	}

	function statusOnTimeChanged(newTime:Int)
	{
		time = newTime;
		if (onProgress != null)
			onProgress();
	}

	function statusOnPositionChanged(newPos:Int) {}

	function statusOnSeekableChanged(newPos:Int)
	{
		if (onSeek != null)
			onSeek();
	}

	function statusOnForward() {}

	function statusOnBackward() {}

	function onDisplay()
	{
		// render();
	}

	function statusOnError()
	{
		trace("VLC ERROR - File not found?");

		if (onError != null)
			onError();
	}

	/////////////////////////////////////////////////////////////////////////////////////

	private override function get_width():Float
	{
		return _width;
	}

	public override function set_width(value:Float):Float
	{
		_width = value;
		return super.set_width(value);
	}

	private override function get_height():Float
	{
		return _height;
	}

	public override function set_height(value:Float):Float
	{
		_height = value;
		return super.set_height(value);
	}

	function get_volume():Float
	{
		return volume;
	}

	function set_volume(value:Float):Float
	{
		setVolume(value);
		return volume = value;
	}

	// ===================================================================================
	// Dispose
	//-----------------------------------------------------------------------------------

	public function dispose()
	{
		#if cpp
		libvlc.stop();
		#end

		stage.removeEventListener(Event.ENTER_FRAME, vLoop);

		if (texture != null)
		{
			texture.dispose();
			texture = null;
		}
		onVideoReady = null;
		onComplete = null;
		onPause = null;
		onPlay = null;
		onResume = null;
		onSeek = null;
		onStop = null;
		onBuffer = null;
		onProgress = null;
		onError = null;
		bufferMem = null;
		isDisposed = true;

		#if cpp
		while (!isPlaying && !isDisposed)
		{
			libvlc.dispose();
			libvlc = null;
		}
		#end
	}

	/////////////////////////////////////////////////////////////////////////////////////
}
#end
