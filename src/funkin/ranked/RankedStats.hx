package funkin.ranked;

import flixel.FlxG;


class RankedStats {
	public static var totalMisses:Int = 0;

	public static function load() {
		if (FlxG.save.data.totalMisses != null)
			totalMisses = FlxG.save.data.totalMisses;
		else
			totalMisses = 0;
	}

	public static function save() {
		FlxG.save.data.totalMisses = totalMisses;
		FlxG.save.flush();
	}
}