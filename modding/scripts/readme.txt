ShardEngine HScript support

Put menu .hx or .hxc scripts in scripts/mainmenu/ and gameplay scripts in
scripts/song/. The same folders can be used inside a mod folder. Gameplay
scripts can also be placed in the active song folder at data/<song-name>/.

Main menu scripts run while MainMenuState is active. Song scripts run while
playing a song. The old root scripts/ folder is no longer loaded.

Available callbacks:
  onCreate(state)
  onUpdate(elapsed)
  onStepHit()
  onBeatHit()
  onSectionHit()

Custom note scripts go in custom_notes/ and use the note type filename:
  custom_notes/Glitch Note.hxc

Custom note callbacks:
  onCreate(note)
  onUpdate(note, elapsed)
  goodNoteHit(note)
  opponentNoteHit(note)
  noteMiss(note)

Available variables:
  state, FlxG, Paths, Preferences, PlayState, MainMenuState, Conductor

Scripts may use either the HScript callback names above or the Lua-style names:
  create/onCreate, update/onUpdate, stepHit/onStepHit,
  beatHit/onBeatHit, sectionHit/onSectionHit, event/onEvent

Example:
  function onBeatHit() {
    FlxG.log.add('Beat hit');
  }