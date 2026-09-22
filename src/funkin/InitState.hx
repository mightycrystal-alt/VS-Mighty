package funkin;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;

import funkin.achievements.Achievements;
import funkin.input.Controls;
import funkin.ui.title.TitleState;
import funkin.data.WeekData;
/**
 * Handles initialization of variables when first opening the game.
**/
class InitState extends flixel.FlxState {
    override function create():Void {
        super.create();

        // -- FLIXEL STUFF -- //

        FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

        FlxTransitionableState.skipNextTransIn = true;

        // -- SETTINGS -- //

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

        Controls.instance = new Controls();

        ClientPrefs.loadDefaultKeys();
		ClientPrefs.loadPrefs();

        #if ACHIEVEMNTS_ALLOWED
        Achievements.init();
        #end

        // The project is intentionally kept on the base asset path for now so a custom polymod layer can be plugged in later.

        // -- -- -- //

        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

        FlxG.switchState(Type.createInstance(Main.initialState, []));
    }
}