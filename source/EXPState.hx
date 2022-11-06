package;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxGradient;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

class EXPState extends MusicBeatState
{
    public static var exptotal:Int = 0;
    public static var levelshit:Int = 1;
    public static var expwant:Int = 0;
    public static var coin:Int = 0;

    var bg1:FlxSprite;
    var bg2:FlxSprite;
    var transGradient:FlxSprite;
    var anothertransGradient:FlxSprite;
    var transBlack:FlxSprite;
    var anothertransBlack:FlxSprite;

    override function create(){
        for (i in 0...levelshit+2){
            expwant += (i * 100);//if levelshit = 1 expwant = 300 i think lol
        }
        bg1 = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg1.color = ResultState.bg1.color;
        bg1.x = ResultState.bg1.x;
        bg1.updateHitbox();
        add(bg1);

        bg2 = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg2.color = ResultState.bg2.color;
        bg2.x = ResultState.bg2.x;
        bg2.updateHitbox();
        add(bg2);

        transGradient = FlxGradient.createGradientFlxSprite(FlxG.width, Math.floor(FlxG.height / 2), [FlxColor.BLACK, 0x0]);
        transGradient.y += 100;
		transGradient.scrollFactor.set();
		add(transGradient);

        anothertransGradient = FlxGradient.createGradientFlxSprite(FlxG.width, Math.floor(FlxG.height / 2), [0x0, FlxColor.BLACK]);
        anothertransGradient.y += FlxG.height / 2 - 100;
		anothertransGradient.scrollFactor.set();
		add(anothertransGradient);

        transBlack = new FlxSprite().makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		transBlack.scrollFactor.set();
        transBlack.y = Math.floor(transGradient.y - 100);
		add(transBlack);

        anothertransBlack = new FlxSprite().makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		anothertransBlack.scrollFactor.set();
        anothertransBlack.y = FlxG.height - 100;
		add(anothertransBlack);
        FlxTween.tween(bg1, {x: -1280}, 16);
        FlxTween.tween(bg2, {x: 0}, 16);
    }

    override function update(elapsed:Float)
    {
        if(bg1.x == 0){
            bg2.x = 1280;
            FlxTween.tween(bg1, {x: -1280}, 16);
            FlxTween.tween(bg2, {x: 0}, 16);
        }
        if(bg2.x == 0){
            bg1.x = 1280;
            FlxTween.tween(bg2, {x: -1280}, 16);
            FlxTween.tween(bg1, {x: 0}, 16);
        }
        if(controls.ACCEPT)
        {
            FlxTransitionableState.skipNextTransIn = false;
			FlxTransitionableState.skipNextTransOut = false;
            if(PlayState.isStoryMode){
                if(PlayState.storyPlaylist.length <= 0){
                    FlxG.sound.play(Paths.sound('confirmMenu'));
                    FlxG.sound.playMusic(Paths.music('freakyMenu'));
                    MusicBeatState.switchState(new StoryMenuState());
                }
                else {
                    var difficulty:String = CoolUtil.getDifficultyFilePath();

                    FlxG.sound.play(Paths.sound('confirmMenu'));
                    PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);

				    PlayState.cancelMusicFadeTween();
				    LoadingState.loadAndSwitchState(new PlayState());
                }
            }
            else {
                FlxG.sound.play(Paths.sound('confirmMenu'));
                MusicBeatState.switchState(new FreeplayState());
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
            }
        }
    }
    public static function saveSettings() {
        FlxG.save.data.exptotal = exptotal;
        FlxG.save.data.levelshit = levelshit;
        FlxG.save.data.expwant = expwant;
        FlxG.save.data.coin = coin;

        FlxG.save.flush();
    }
    public static function loadPrefs() {
        if(FlxG.save.data.exptotal != null) {
			exptotal = FlxG.save.data.exptotal;
		}
        if(FlxG.save.data.levelshit != null) {
			levelshit = FlxG.save.data.levelshit;
		}
        if(FlxG.save.data.expwant != null) {
			expwant = FlxG.save.data.expwant;
		}
        if(FlxG.save.data.coin != null) {
			coin = FlxG.save.data.coin;
		}
    }
}