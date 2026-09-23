package;

import funkin.animateatlas.AtlasFrameMaker;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
import funkin.CoolUtil;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static var ignoreModFolders:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 'songs',
		'music', 'sounds', 'shaders', 'videos', 'images', 'stages', 'weeks',
		'fonts', 'scripts', 'custom_notes', 'achievements'
	];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key)
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key)
			&& !dumpExclusions.contains(key) && key != null) {
				//trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	static public var currentModDirectory:String = '';
	static public var globalMods:Array<String> = [];
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	static public function video(key:String)
	{
		var modPath:String = modsVideo(key);
		if (FileSystem.exists(modPath)) return modPath;
		var embeddedPath:String = embeddedModPath('videos/$key.$VIDEO_EXT', BINARY);
		if (embeddedPath != null) return embeddedPath;
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function voicesExists(song:String):Bool
	{
		var songKey:String = '${formatToSongPath(song)}/Voices.$SOUND_EXT';
		return fileExists('songs/$songKey', SOUND);
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}

	inline static public function image(key:String, ?library:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key, library);
		return returnAsset;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		if (!ignoreMods) {
			var modPath:String = modFolders(key);
			if (FileSystem.exists(modPath)) return File.getContent(modPath);
		}
		var preloadPath:String = getPreloadPath(key);
		if (FileSystem.exists(preloadPath)) return File.getContent(preloadPath);
		#end
		if (!ignoreMods) {
			var embeddedPath:String = embeddedModPath(key, TEXT);
			if (embeddedPath != null) return OpenFlAssets.getText(embeddedPath);
		}
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		var modPath:String = modsFont(key);
		if (FileSystem.exists(modPath)) return modPath;
		var embeddedPath:String = embeddedModPath('fonts/$key', FONT);
		if (embeddedPath != null) return embeddedPath;
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?library:String)
	{
		if (FileSystem.exists(modFolders(key))) return true;
		if (embeddedModPath(key, type) != null) return true;
		if(OpenFlAssets.exists(getPath(key, type))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		var modXml:String = modsXml(key);
		if (FileSystem.exists(modXml))
			return FlxAtlasFrames.fromSparrow(image(key, library), File.getContent(modXml));
		var embeddedXml:String = embeddedModPath('images/$key.xml', TEXT);
		if (embeddedXml != null)
			return FlxAtlasFrames.fromSparrow(image(key, library), OpenFlAssets.getText(embeddedXml));
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}


	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		var modTxt:String = modsTxt(key);
		if (FileSystem.exists(modTxt))
			return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), File.getContent(modTxt));
		var embeddedTxt:String = embeddedModPath('images/$key.txt', TEXT);
		if (embeddedTxt != null)
			return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), OpenFlAssets.getText(embeddedTxt));
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String) {
		var modPath:String = modsImages(key);
		if (FileSystem.exists(modPath)) {
			if (!currentTrackedAssets.exists(modPath)) {
				var bitmap:BitmapData = BitmapData.fromFile(modPath);
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, modPath);
				graphic.persist = true;
				currentTrackedAssets.set(modPath, graphic);
			}
			localTrackedAssets.push(modPath);
			return currentTrackedAssets.get(modPath);
		}
		var embeddedPath:String = embeddedModPath('images/$key.png', IMAGE);
		if (embeddedPath != null) {
			if (!currentTrackedAssets.exists(embeddedPath)) {
				var embeddedGraphic:FlxGraphic = FlxG.bitmap.add(embeddedPath, false, embeddedPath);
				embeddedGraphic.persist = true;
				currentTrackedAssets.set(embeddedPath, embeddedGraphic);
			}
			localTrackedAssets.push(embeddedPath);
			return currentTrackedAssets.get(embeddedPath);
		}
		var path = getPath('images/$key.png', IMAGE, library);
		//trace(path);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('failed to load graphic at "${path}", which returned null, does the file exist and is the name correctly typed?');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		var modPath:String = modsSounds(path, key);
		if (FileSystem.exists(modPath)) {
			if (!currentTrackedSounds.exists(modPath))
				currentTrackedSounds.set(modPath, Sound.fromFile(modPath));
			localTrackedAssets.push(modPath);
			return currentTrackedSounds.get(modPath);
		}
		var embeddedPath:String = embeddedModPath('$path/$key.$SOUND_EXT', SOUND);
		if (embeddedPath != null) {
			if (!currentTrackedSounds.exists(embeddedPath))
				currentTrackedSounds.set(embeddedPath, OpenFlAssets.getSound(embeddedPath));
			localTrackedAssets.push(embeddedPath);
			return currentTrackedSounds.get(embeddedPath);
		}
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		if(!currentTrackedSounds.exists(gottenPath))
		{
			var folder:String = '';
			if(path == 'songs') folder = 'songs:';

			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	inline static public function mods(key:String = ''):String return 'modding/' + key;
	inline static public function modsFont(key:String):String return modFolders('fonts/' + key);
	inline static public function modsJson(key:String):String return modFolders('data/' + key + '.json');
	inline static public function modsVideo(key:String):String return modFolders('videos/' + key + '.' + VIDEO_EXT);
	inline static public function modsSounds(path:String, key:String):String return modFolders(path + '/' + key + '.' + SOUND_EXT);
	inline static public function modsImages(key:String):String return modFolders('images/' + key + '.png');
	inline static public function modsXml(key:String):String return modFolders('images/' + key + '.xml');
	inline static public function modsTxt(key:String):String return modFolders('images/' + key + '.txt');

	static function embeddedModPath(key:String, type:AssetType):Null<String> {
		var candidates:Array<String> = [];
		if (currentModDirectory != null && currentModDirectory.length > 0)
			candidates.push(currentModDirectory + '/' + key);
		for (mod in globalMods)
			candidates.push(mod + '/' + key);
		candidates.push(key);
		for (candidate in candidates) {
			var path:String = 'modding/$candidate';
			if (OpenFlAssets.exists(path, type) || OpenFlAssets.exists(path)) return path;
		}
		return null;
	}

	static public function modFolders(key:String):String {
		if (currentModDirectory != null && currentModDirectory.length > 0) {
			var currentPath:String = mods(currentModDirectory + '/' + key);
			if (FileSystem.exists(currentPath)) return currentPath;
		}
		for (mod in globalMods) {
			var globalPath:String = mods(mod + '/' + key);
			if (FileSystem.exists(globalPath)) return globalPath;
		}
		return mods(key);
	}

	static public function pushGlobalMods():Array<String> {
		globalMods = [];
		var listPath:String = 'modsList.txt';
		if (!FileSystem.exists(listPath)) return globalMods;
		for (line in CoolUtil.coolTextFile(listPath)) {
			var data:Array<String> = line.split('|');
			if (data.length < 2 || data[1] != '1') continue;
			var metadataPath:String = mods(data[0] + '/pack.json');
			if (!FileSystem.exists(metadataPath)) continue;
			try {
				var metadata:Dynamic = Json.parse(File.getContent(metadataPath));
				if (Reflect.getProperty(metadata, 'runsGlobally') == true) globalMods.push(data[0]);
			} catch (error:Dynamic) trace(error);
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var result:Array<String> = [];
		if (!FileSystem.exists(mods())) return result;
		var configured:Array<String> = [];
		var listPath:String = 'modsList.txt';
		if (FileSystem.exists(listPath)) {
			for (line in CoolUtil.coolTextFile(listPath)) {
				var data:Array<String> = line.trim().split('|');
				if (data.length > 1 && data[1] == '1') configured.push(data[0]);
			}
		}
		for (entry in configured) {
			var configuredPath:String = mods(entry);
			if (FileSystem.isDirectory(configuredPath) && !ignoreModFolders.contains(entry.toLowerCase())) result.push(entry);
		}
		var discovered:Array<String> = [];
		for (entry in FileSystem.readDirectory(mods())) {
			var path:String = mods(entry);
			if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(entry.toLowerCase()) && !result.contains(entry)) discovered.push(entry);
		}
		discovered.sort(function(first:String, second:String):Int return first < second ? -1 : first > second ? 1 : 0);
		result = result.concat(discovered);
		return result;
	}
}
