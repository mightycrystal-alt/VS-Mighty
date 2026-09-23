package funkin.scripting;

import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import haxe.io.Path;
import Lambda;
#if sys
import sys.FileSystem;
import sys.io.File;
import Sys;
#end
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import openfl.utils.Assets;
import lime.app.Application;
import Main;
import funkin.Conductor;
import funkin.CoolUtil;
import Paths;
import funkin.Preferences;
import funkin.play.components.Section;
import funkin.play.PlayState;
import funkin.ui.MusicBeatState;
import funkin.play.Song;
import funkin.play.character.Character;
import funkin.play.components.HealthIcon;
import funkin.play.components.Note;
import funkin.play.components.StrumNote;
import funkin.graphics.Alphabet;
import funkin.ui.mainmenu.MainMenuState;

using StringTools;

class HScript
{
	private static var activeState:Dynamic;
	private static var scripts:Array<Interp> = [];
	private static var customNoteScripts:Map<String, Array<Interp>> = [];
	private static var scriptNames:Map<Interp, String> = [];
	private static var staticVariables:Map<String, Dynamic> = [];
	private static var loaded:Bool = false;

	public static function init(state:Dynamic):Void
	{
		if (activeState != state)
			load(state);
	}

	public static function update(state:Dynamic, elapsed:Float):Void
	{
		if (activeState != state)
		{
			load(state);
		}
		call('update', [elapsed]);
	}

	public static function stepHit():Void
	{
		call('stepHit');
	}

	public static function beatHit():Void
	{
		call('beatHit');
	}

	public static function sectionHit():Void
	{
		call('sectionHit');
	}

	public static function songStart():Void
	{
		call('songStart');
	}

	public static function event(name:String, value1:String, value2:String):Void
	{
		call('event', [name, value1, value2]);
	}

	public static function timerCompleted(tag:String, loops:Int, loopsLeft:Int):Void
	{
		call('timerCompleted', [tag, loops, loopsLeft]);
	}

	public static function clear(state:Dynamic):Void
	{
		if (activeState == state)
		{
			activeState = null;
			scripts = [];
			customNoteScripts = [];
			scriptNames = [];
			loaded = false;
		}
	}

	private static function load(state:Dynamic):Void
	{
		activeState = state;
		scripts = [];
		customNoteScripts = [];
		scriptNames = [];
		loaded = true;

		#if sys
		var scriptFolder:String = null;
		if (Std.isOfType(state, PlayState))
			scriptFolder = 'song';
		else if (Std.isOfType(state, MainMenuState))
			scriptFolder = 'mainmenu';

		if (scriptFolder != null)
		{
			var directories:Array<String> = [Paths.modFolders('scripts/$scriptFolder')];
			for (mod in Paths.getModDirectories())
			{
				var directory:String = Paths.mods(mod + '/scripts/' + scriptFolder);
				if (!directories.contains(directory)) directories.push(directory);
			}

			var songName:String = null;
			if (Std.isOfType(state, PlayState) && PlayState.SONG != null)
				songName = Paths.formatToSongPath(PlayState.SONG.song);
			if (songName != null)
			{
				var songDirectories:Array<String> = [Paths.modFolders('data/$songName')];
				for (mod in Paths.getModDirectories())
				{
					var directory:String = Paths.mods(mod + '/data/' + songName);
					if (!songDirectories.contains(directory)) songDirectories.push(directory);
				}
				directories = directories.concat(songDirectories);
			}

			if (Std.isOfType(state, PlayState) && PlayState.curStage != null && PlayState.curStage.length > 0)
			{
				var stageDirectories:Array<String> = [Paths.modFolders('stages')];
				for (mod in Paths.getModDirectories())
				{
					var directory:String = Paths.mods(mod + '/stages');
					if (!stageDirectories.contains(directory)) stageDirectories.push(directory);
				}
				for (directory in stageDirectories)
				{
					loadStageDirectory(directory, PlayState.curStage, state);
				}
			}

			for (directory in directories)
			{
				loadDirectory(directory, state);
			}
		}

		var customDirectories:Array<String> = [Paths.modFolders('custom_notes')];
		for (mod in Paths.getModDirectories())
		{
			var customDirectory:String = Paths.mods(mod + '/custom_notes');
			if (!customDirectories.contains(customDirectory)) customDirectories.push(customDirectory);
		}
		for (directory in customDirectories)
		{
			loadCustomNoteDirectory(directory, state);
		}
		#end

		for (interp in scripts)
		{
			try
			{
				var onCreate:Dynamic = interp.variables.get('onCreate');
				if (onCreate != null)
					Reflect.callMethod(null, onCreate, [state]);
				else
				{
					var create:Dynamic = interp.variables.get('create');
					if (create != null) Reflect.callMethod(null, create, []);
				}
			}
			catch (error:Dynamic)
			{
				FlxG.log.error('HScript create callback failed: $error');
			}
		}
	}

	#if sys
	private static function loadDirectory(directory:String, state:Dynamic):Void
	{
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;
		for (file in FileSystem.readDirectory(directory))
		{
			var lowerName:String = file.toLowerCase();
			if (lowerName.endsWith('.hx') || lowerName.endsWith('.hxc'))
			{
				execute(File.getContent('$directory/$file'), '$directory/$file', state);
			}
		}
	}

	private static function loadStageDirectory(directory:String, stage:String, state:Dynamic):Void
	{
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;
		for (file in FileSystem.readDirectory(directory))
		{
			var extension:String = Path.extension(file).toLowerCase();
			var stageName:String = Path.withoutExtension(file);
			if ((extension == 'hx' || extension == 'hxc') && stageName.toLowerCase() == stage.toLowerCase())
			{
				execute(File.getContent('$directory/$file'), '$directory/$file', state);
			}
		}
	}

	private static function loadCustomNoteDirectory(directory:String, state:Dynamic):Void
	{
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;
		for (file in FileSystem.readDirectory(directory))
		{
			var lowerName:String = file.toLowerCase();
			if (lowerName.endsWith('.hx') || lowerName.endsWith('.hxc'))
			{
				var noteName:String = Path.withoutExtension(file);
				var interp:Interp = executeScript(File.getContent('$directory/$file'), '$directory/$file', state);
				if (interp != null)
				{
					if (!customNoteScripts.exists(noteName)) customNoteScripts.set(noteName, []);
					customNoteScripts.get(noteName).push(interp);
				}
			}
		}
	}
	#end

	private static function execute(source:String, fileName:String, state:Dynamic):Void
	{
		var interp:Interp = executeScript(source, fileName, state);
		if (interp != null)
		{
			scripts.push(interp);
			scriptNames.set(interp, fileName);
		}
	}

	private static function executeScript(source:String, fileName:String, state:Dynamic):Interp
	{
		try
		{
			var parser:Parser = new Parser();
			parser.allowJSON = true;
			parser.allowMetadata = true;
			parser.allowTypes = true;
			var program:Expr = parser.parseString(source, fileName);
			var interp:Interp = new Interp();
			for (name => value in getDefaultVariables(state))
				interp.variables.set(name, value);
			interp.variables.set('__script__', interp);
			interp.execute(program);
			return interp;
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('HScript error in $fileName: $error');
			return null;
		}
	}

	public static function noteCreate(note:Dynamic):Void
	{
		callCustom(note, 'onCreate', [note]);
	}

	public static function noteUpdate(note:Dynamic, elapsed:Float):Void
	{
		callCustom(note, 'onUpdate', [note, elapsed]);
	}

	public static function noteGoodHit(note:Dynamic):Void
	{
		callCustom(note, 'goodNoteHit', [note], 'onGoodNoteHit');
	}

	public static function noteOpponentHit(note:Dynamic):Void
	{
		callCustom(note, 'opponentNoteHit', [note], 'onOpponentNoteHit');
	}

	public static function noteMiss(note:Dynamic):Void
	{
		callCustom(note, 'noteMiss', [note], 'onNoteMiss');
	}

	private static function callCustom(note:Dynamic, name:String, args:Array<Dynamic>, ?alias:String):Void
	{
		if (note == null || note.noteType == null || !customNoteScripts.exists(note.noteType)) return;
		for (interp in customNoteScripts.get(note.noteType))
		{
			try
			{
				var callback:Dynamic = getCallback(interp, name);
				if (callback == null && alias != null) callback = interp.variables.get(alias);
				if (callback != null) Reflect.callMethod(null, callback, args);
			}
			catch (error:Dynamic)
			{
				FlxG.log.error('Custom note callback $name failed for ${note.noteType}: $error');
			}
		}
	}

	private static function call(name:String, ?args:Array<Dynamic>):Void
	{
		if (!loaded) return;
		if (args == null) args = [];

		for (interp in scripts)
		{
			try
			{
				var callback:Dynamic = getCallback(interp, name);
				if (callback != null) Reflect.callMethod(null, callback, args);
			}
			catch (error:Dynamic)
			{
				FlxG.log.error('HScript callback $name failed: $error');
			}
		}
	}

	private static function getCallback(interp:Interp, name:String):Dynamic
	{
		var callback:Dynamic = interp.variables.get(name);
		if (callback != null) return callback;

		switch (name)
		{
			case 'create': callback = interp.variables.get('onCreate');
			case 'update': callback = interp.variables.get('onUpdate');
			case 'stepHit': callback = interp.variables.get('onStepHit');
			case 'beatHit': callback = interp.variables.get('onBeatHit');
			case 'sectionHit': callback = interp.variables.get('onSectionHit');
			case 'event': callback = interp.variables.get('onEvent');
		}
		return callback;
	}

	public static function get(variable:String):Dynamic
	{
		if (scripts.length == 0) return null;
		return scripts[0].variables.get(variable);
	}

	public static function set(variable:String, value:Dynamic):Void
	{
		for (interp in scripts) interp.variables.set(variable, value);
	}

	public static function callFunction(name:String, ?args:Array<Dynamic>):Void
	{
		call(name, args);
	}

	private static function getDefaultVariables(state:Dynamic):Map<String, Dynamic>
	{
		var variables:Map<String, Dynamic> = [
			'Std' => Std,
			'Math' => Math,
			'Reflect' => Reflect,
			'StringTools' => StringTools,
			'Json' => haxe.Json,
			'Xml' => Xml,
			'Type' => Type,
			'Date' => Date,
			'Lambda' => Lambda,
			#if sys
			'Sys' => Sys,
			#end
			'Assets' => Assets,
			'Main' => Main,
			'FlxG' => FlxG,
			'FlxBasic' => FlxBasic,
			'FlxSprite' => FlxSprite,
			'FlxCamera' => FlxCamera,
			'FlxMath' => FlxMath,
			'FlxSound' => FlxSound,
			'FlxAssets' => FlxAssets,
			'FlxText' => FlxText,
			'FlxTypeText' => FlxTypeText,
			'FlxGroup' => FlxGroup,
			'FlxTypedGroup' => FlxTypedGroup,
			'FlxSpriteGroup' => FlxSpriteGroup,
			'FlxTween' => FlxTween,
			'FlxEase' => FlxEase,
			'FlxTimer' => FlxTimer,
			'ADD' => BlendMode.ADD,
			'MULTIPLY' => BlendMode.MULTIPLY,
			'BlendMode' => {
				ADD: BlendMode.ADD,
				MULTIPLY: BlendMode.MULTIPLY
			},
			'Application' => Application,
			'Paths' => Paths,
			'CoolUtil' => CoolUtil,
			'Preferences' => Preferences,
			'MusicBeatState' => MusicBeatState,
			'PlayState' => PlayState,
			'MainMenuState' => MainMenuState,
			'TitleState' => funkin.ui.title.TitleState,
			'Song' => Song,
			'Character' => Character,
			'HealthIcon' => HealthIcon,
			'Note' => Note,
			'StrumNote' => StrumNote,
			'Section' => Section,
			'Alphabet' => Alphabet,
			'Conductor' => Conductor,
			'state' => state,
			'window' => Application.current.window,
			'trace' => function(value:Dynamic):Void trace(value)
		];

		for (name => value in staticVariables)
			variables.set(name, value);
		return variables;
	}

}
