package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.utils.Assets;
import flixel.system.FlxSound;
import flixel.FlxCamera;
import flixel.effects.FlxFlicker;
import flixel.addons.display.FlxBackdrop;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
import openfl.filters.ShaderFilter;
import openfl.display.GraphicsShader;
import CameffectShader.CamShader;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var stopbro:Bool = false;
	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var alrumpicture:FlxSprite;
	var rank:String = '';

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	public var chromaticAberration:CameffectShader;
	public var aberrateTimeValue:Float = 0.065;
	var filter:Array<BitmapFilter> = [];

	var accuracy:Float = 0;
	public static var ratingStuff:Array<Dynamic> = [
		['F', 0.50], //From 0.01% to 9% SHIT PART
		['E', 0.60], //From 50% to 59% BAD PART
		['D', 0.70], //From 60% to 68%
		['C', 0.80], //69% to 69.99% GOOD PART
		['B', 0.85], //From 70% to 75%
		['A-', 0.90], //From 76% to 80% SICK PART
		['A', 0.93], //From 80% to 85%
		['A+', 0.9650], //From 86% to 89%
        ['S-', 0.99], //From 90% to 92% SICK GOLD
        ['S', 0.9950], //From 93% to 94%
        ['S+', 0.9970], //From 95% to 96%
        ['SS-', 0.9980], //From 97% to 98%
        ['SS', 0.9990], //From 99%-99.49%
        ['SS+', 0.99950], //From 99.5%-99.89%
        ['X-', 0.99980], //From 99.9%-99.94% EPIC PART
		['X', 1],//From 99.95%-99.9935% //lol sorry apro
		['PERFECT', 1] //The value on this one isn't used actually, since Perfect is always "1" EPIC GOLD
	];

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxBackdrop;
	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		persistentDraw = true;
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		Conductor.changeBPM(102);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		chromaticAberration = new CameffectShader();
		chromaticAberration.shader.distort.value = [aberrateTimeValue];
		var susfilter = new ShaderFilter(chromaticAberration.shader);
		filter.push(susfilter);
		FlxG.camera.setFilters(filter);
		FlxG.camera.filtersEnabled = true;

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxBackdrop(Paths.image('menuDesat'), 0.2, 0, true, true);
		bg.velocity.set(-100, 0);
		bg.updateHitbox();
		bg.alpha = 1;
		bg.screenCenter(X);
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (20 * i) + 30, songs[i].songName, true, false, 0, 0.8);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			if (songText.width > 450)
			{
				var textScale:Float = 450 / songText.width;
				songText.scale.x = textScale * 0.8;
				songText.scale.y *= 0.75;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}
			for (item in grpSongs){
				item.x += 750;
				item.moving = 1;
				item.distanceletter = 100;
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!s
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		alrumpicture = new FlxSprite().loadGraphic(Paths.image('albumcool'));
		alrumpicture.x = (FlxG.width - (alrumpicture.width * 0.2)) / 7.5;
		alrumpicture.y = (FlxG.height - (alrumpicture.height * 0.2)) / 6;
		alrumpicture.scale.set(0.2, 0.2);
		alrumpicture.updateHitbox();
		alrumpicture.antialiasing = ClientPrefs.globalAntialiasing;
		add(alrumpicture);

		scoreText = new FlxText(0, 0, 0, "", 32);
		scoreText.x = alrumpicture.x;
		scoreText.y = alrumpicture.y + alrumpicture.height + 32;
		scoreText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 2;

		diffText = new FlxText(0, 0, 0, "", 36);
		diffText.y = alrumpicture.y + alrumpicture.height - 48;
		diffText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diffText.borderSize = 2;
		add(diffText);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		/*var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 140).makeGraphic(FlxG.width, 95, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);*/
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		stopbro = false;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	public var speed:Float = 0.055;
	var comingshader:Bool = false;
	override function update(elapsed:Float){
		//fakeElapsedath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		//iconP2.scale.set(mult, mult);
		var fakeElapsed:Float = CoolUtil.clamp(elapsed, 0, 1);

		for (i in 0...iconArray.length)
		{
			var mult:Float = FlxMath.lerp(1, iconArray[i].scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconArray[i].scale.set(mult, mult);
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.7 && !controls.ACCEPT)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		if(controls.ACCEPT && !stopbro) FlxG.sound.music.volume = 0;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		accuracy = Std.parseFloat(ratingSplit.join('.'));
		scoreText.text = 'PERSONAL BEST\nSCORE: ${lerpScore}\nACCURACY : ${accuracy}%\nRANK : ${rank}\n';
		positionHighscore();

		if(ClientPrefs.camZooms) FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1)); // fnf grafex

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		if(comingshader){
			if (chromaticAberration != null)
			{
				speed += 0.0003125 * (fakeElapsed / (1 / 160));
				aberrateTimeValue += (fakeElapsed / (1 / 15)) * speed;
				chromaticAberration.shader.distort.value = [aberrateTimeValue * 0.25];
			}
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT && !stopbro) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP && !stopbro)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP && !stopbro)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP && !stopbro)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0 && !stopbro)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}

			if(FlxG.mouse.wheel != 0 && !stopbro)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (controls.UI_LEFT_P && !stopbro)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P && !stopbro)
			changeDiff(1);
		else if (upP || downP && !stopbro) changeDiff();

		if (controls.BACK && !stopbro)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if(ctrl && !stopbro)
		{
			//persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
			stopbro = true;
		}
		else if(space && !stopbro)
		{
			if(instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				Conductor.changeBPM(PlayState.SONG.bpm);
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				#end
			}
		}
		else if (accepted && !stopbro)
		{
			comingshader = true;
			stopbro = true;
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.pause();
					
			destroyFreeplayVocals();

			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
			if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
			}*/
			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());

			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxTween.tween(alrumpicture, {alpha: 0}, 0.5);
			FlxTween.tween(scoreText, {alpha: 0}, 0.5);
			FlxTween.tween(diffText, {alpha: 0}, 0.5);

			for (item in grpSongs.members)
			{
				item.enter = true;
				if (item.targetY != 0)
				{
					FlxTween.tween(item, {alpha: 0}, 0.3);
				}
				if (item.targetY == 0)
				{
					item.alpha = 1;
					//item.color = 0x0055FF00;
					item.center = true;
					FlxTween.tween(item, {x : FlxG.width / 2 - (item.width + 150) / 2}, 1.25);
					FlxFlicker.flicker(item, 1.5, 0.05, false);
				}
			}

			for (i in 0...iconArray.length)
			{
				if(i != curSelected) FlxTween.tween(iconArray[i], {alpha: 0}, 0.3);
				if(i == curSelected) {
					FlxFlicker.flicker(iconArray[curSelected], 1.5, 0.05, false);
				}
			}

			FlxTween.tween(FlxG.camera, {zoom: 2}, 1.2, {ease: FlxEase.quadInOut, startDelay: 0.75});

			new FlxTimer().start(1.5, function(tmr:FlxTimer)
			{
				if (FlxG.keys.pressed.SHIFT){
					LoadingState.loadAndSwitchState(new ChartingState());
				}else{
					LoadingState.loadAndSwitchState(new PlayState());
				}
			});
			/*if (FlxG.keys.pressed.SHIFT){
				LoadingState.loadAndSwitchState(new ChartingState());
			}else{
				LoadingState.loadAndSwitchState(new PlayState());
			}*/

			//FlxG.sound.music.volume = 0;
					
			//destroyFreeplayVocals();
		}
		else if(controls.RESET && !stopbro)
		{
			//persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
			stopbro = true;
		}
		super.update(elapsed);
	}

	override function beatHit() {
		super.beatHit();

		if(curBeat % 1 == 0){
			for (i in 0...iconArray.length)
			{
				iconArray[i].scale.set(1.3, 1.3);
			}
		}

		if (FlxG.camera.zoom < 1.35 && curBeat % 2 == 0){
			FlxG.camera.zoom += 0.03;
			//bf.dance();
		}
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		diffText.x = (alrumpicture.width - diffText.width) / 2 + alrumpicture.x;
		positionHighscore();

		switch(CoolUtil.difficulties[PlayState.storyDifficulty].toUpperCase()){
			case 'EASY':
				diffText.color = 0xFF66FF00;
			case 'NORMAL':
				diffText.color = 0xFFFFFF00;
			case 'HARD':
				diffText.color = 0xFFCC0000;
			case 'FUCKED':
				diffText.color = 0xFFCC00FF;
			case 'ERECT':
				diffText.color = 0xFF66FFCC;
			default:
				diffText.color = 0xFFFFFFFF;
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			
			bullShit++;

			item.color = 0x00FFFFFF;

			/*if(Math.abs(item.targetY) == 1) FlxTween.tween(item, {alpha: 0.6}, 0.1);
			if(Math.abs(item.targetY) == 2) FlxTween.tween(item, {alpha: 0.45}, 0.1);*/
			if (item.targetY == 0)
			{
				item.alpha = 1;
				item.color = 0xFFCDCA44;
				//FlxTween.tween(item.scale, {x: 0.8, y: 0.8}, 0.1);
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		if(accuracy / 100 >= 1)
        {
            rank = ratingStuff[ratingStuff.length-1][0]; //Uses last string
        }
        else
        {
            for (i in 0...ratingStuff.length-1)
            {
                if(accuracy / 100 < ratingStuff[i][1])
                {
                    rank = ratingStuff[i][0];
                    break;
                }
            }
        }
		if(accuracy == 0) rank = 'N/A';
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}