package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.getTimer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.text.TextFormat;
	import flash.display.SimpleButton;
	
	public class leiniao extends Sprite
	{
		private var bg:BG = new BG();
		private var startBtn:StartBtn;
		private var player:Player;
		private var _isGoLeft:Boolean;
		private var _isGoRight:Boolean;
		
		private var _marks:int = 0;
		private var	markBoard:MarksDis;


		private var t1:Number = 0;
		private var t2:Number = 0;
		private var t3:Number = 0;
		private var eff_duration:Number = 0;

		private var genDropsDuration:Number = 1000;
		// level
		private var levelPoints:Array = [500, 900, 1800]
		private var speedRang:Array = [2.8, 2.4, 2, 1];
		private var born_duration:Array = [600, 400, 300, 200]
		private var born_speed:Array = [6, 6.5, 7.5, 10]
		private var move_speed:Array = [10, 12, 14, 16]
		private var startDropDuration:Number = 0 	// 3s
		private var curLevel:int = -1;
		private var dx:Number = 10;


		private var _dropLists:Vector.<Drops>;
		private var _dropsHolder:Sprite;

		private var v0:Number = 7.5;	// 初始平均速度
		private var v_range:Number = 2.5 // 道具下落的差异速度

		private var playerLayer:Sprite = new Sprite();
		private var playerEffectLayer:Sprite = new Sprite();
		private var effectBitmap:Bitmap;
		private var state:String = "MENU";

		private var txt:TextField = new TextField();
		var ttt:TextFormat = new TextFormat();
		public function leiniao()
		{
			init();
			
		}
		private function init():void {
			initUI();
			initPlayer();
			ttt.size = 25;
			ttt.color = 0xffffff;
			txt.defaultTextFormat = ttt;
			addChild(txt)
		}
		
		private function initPlayer():void
		{
			// TODO Auto Generated method stub
			player = new Player();
			player.visible = false;
			playerLayer.addChild(player);
		}
		
		private function initUI():void {
			addChild(bg);
			playerLayer = new Sprite();
			playerEffectLayer = new Sprite();
			addChild(playerEffectLayer)
			addChild(playerLayer)

			startBtn = new StartBtn();
			markBoard = new MarksDis();
			startBtn.x = (stage.stageWidth - startBtn.width) * .5;
			startBtn.y = (stage.stageHeight - startBtn.height) * .5;
			startBtn.addEventListener(MouseEvent.CLICK, onStartBtnHandler);
			addChild(startBtn);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,handleKeyUp);
						
			marks = 0;;
			markBoard.x = 382.4;
			addChild(markBoard);
		}
		
		public function set marks(value:int):void {			
			_marks = value;
			trace(_marks)
			txt.text = _marks+'';
			markBoard.total.text = _marks + '';
		}
		
		public function get marks():int {			
			return _marks;
		}
		
		private function onStartBtnHandler(event:MouseEvent = null):void
		{
			// TODO Auto-generated method stub
			curLevel = -1;
			startBtn.visible = false;
			player.visible = true;
			_eff_elapse = 0;
			player.x = (stage.stageWidth - player.width) * .5;
			player.y = (stage.stageHeight - player.height) * .96;
			
			marks = 0;
			startDropDuration = 1000;
			state = "GAME";
			startBtn.removeEventListener(MouseEvent.CLICK, onStartBtnHandler);
			stage.addEventListener(Event.ENTER_FRAME, loop);
			markBoard.purseBtn.buttonMode = true;
			markBoard.purseBtn.addEventListener(MouseEvent.CLICK, onPurse);
			_dropLists = new Vector.<Drops>();
			_dropsHolder = new Sprite();
			addChild(_dropsHolder);			
			effectBitmap = new Bitmap(new BitmapData(stage.width,200,true,0));
			effectBitmap.y = 200
			playerEffectLayer.addChild(effectBitmap)
			bg.gotoAndPlay(2);
			player.gotoAndPlay(2)
			this.emptyBitmap = new BitmapData(stage.width,200,true,0);

		}

		private function onPurse(me:MouseEvent):void {
			markBoard['purseBtn'].visible = false;
			if(state == 'PAURSE'){
				state = 'GAME';
				markBoard['purseBtn'].gotoAndStop(1)
			}
			else if(state == 'GAME'){
				state = 'PAURSE';
				markBoard['purseBtn'].gotoAndStop(2)
			}
			markBoard['purseBtn'].visible = true;

		}
		
		protected function handleKeyUp(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub
			switch(event.keyCode){
				// <-
				case 37:
					_isGoLeft = false;
					break;
				case 39:
					_isGoRight = false;
					break;
				default:break;
			}
			event.updateAfterEvent();
		}

		private var _eff_elapse:int = 0;

		protected function handleKeyDown(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub
			// _isGoRight = _isGoLeft = false;
			switch(event.keyCode){
				case 37:	// <-
					_isGoLeft = true;
					_eff_elapse = 30;
					break;
				case 39:	// ->
					_eff_elapse = 30;
					_isGoRight = true;
					break;
				case 32:
					if(state == "MENU"){
						onStartBtnHandler();
					}
					break;
				default:break;
			}
			event.updateAfterEvent();
		}
		
		private function loop(event:Event):void {
			switch(state){
				case "GAME":
					onGameLoop();
					break;
				case "GAMEOVER":
					onGameOver();
					break
				default:break;
			}
		}
		
		private function onGameOver ():void {
			stage.removeEventListener(Event.ENTER_FRAME, loop);
			removeChild(_dropsHolder)
			_dropLists = null;
			_dropsHolder = null;
			player.visible = false;
			startBtn.visible = true;
			startBtn.addEventListener(MouseEvent.CLICK, onStartBtnHandler);
			playerEffectLayer.removeChild(effectBitmap)
			state = 'MENU';
		}

		protected function onGameLoop():void
		{
			// TODO Auto-generated method stub
			var r:Number = Math.random();
			t2 = getTimer() - t1;
			t1 = getTimer();
			t3 += t2
			eff_duration += t2;
			if(startDropDuration > 0){
				if(t3 < startDropDuration) {
					return;
				}
				else {
					startDropDuration = 0;
					t3 = 0;
				}
			}

			if(t3 > genDropsDuration){
				genDrops();
				t3 = 0;
			}
			
			//up grade
			updateDatas();

			updateDrops();
			updateplayer();

			if( _eff_elapse > 0 && eff_duration > 50){
				updateEffect();
				eff_duration = 0;
				eff_elapse --;
			}
		}

		private function set eff_elapse (value:int):void {
			_eff_elapse = value
			if(_eff_elapse == 0)
			effectBitmap.bitmapData = emptyBitmap.clone();
		}
		
		private function get eff_elapse():int{
			return _eff_elapse;
		}
		
		private function getDataFromMark(t_mark:int):Object {
			var obj = {};
			var level:int = 0;
			if(t_mark > 1800){
				level = 3;
			}
			else if(t_mark <= 500){
				level = 0
			}
			else if(t_mark <= 900){
				level = 1
			}
			else{
				level = 2
			}
			if(curLevel == level) return {};
			obj.update = true;
			obj.level = level;
			obj.du = born_duration[level];
			obj.range = speedRang[level]
			obj.dv = born_speed[level];
			obj.ms = move_speed[level]
			trace('leve up :'+ level)
			return obj;
		}

		private function updateDatas():void {
			var newData:Object = getDataFromMark(marks)
			if(!newData.update)return;
			curLevel = newData.level;
			genDropsDuration = newData.du;
			v_range = newData.range;
			v0 = newData.dv;
			dx = newData.ms
		}
		
		private var addMark:AddMark
		private function updateDrops():void
		{
			// TODO Auto Generated method stub
			var drop:Drops
			var i:int
			for(i = _dropLists.length-1; i >= 0; i--){
				drop = _dropLists[i];
				drop.update();
				if(drop.state == Drops.ACTIVATE) {
				  if(player['hit'] && drop.hitTestObject(player['hit'])) {
							drop.state = Drops.DIE;
							if(drop.type == 3){
								drop.state = Drops.BOWN;
								gameOver();
							}else {
								this.marks += drop.mark;
								if(player['lxMc']){
									player['lxMc'].pic.play();
									if(!addMark){
										addMark = new AddMark();
										addChild(addMark)
									}
									addMark.gotoAndPlay(2)
									addMark.x = player.x
									addMark.y = player.y
								}
							}
					}
				}
			}
			for(i = _dropLists.length-1; i >= 0; i--){
				drop = _dropLists[i];
				if(drop.state >= Drops.DIE){
					_dropsHolder.removeChild(drop);
					_dropLists.splice(i,1);
					drop = null;
				}
			}
			
		}
		
		private function gameOver():void
		{
			// TODO Auto Generated method stub
			state = 'GAMEOVER';
		}
		
		private function genDrops():void
		{
			// TODO Auto Generated method stub
			var type:uint = 1 + Math.random()*3;
			var min_v:Number = v0 - v_range;
			var max_v:Number = v0 + v_range;
			var t_v = min_v + Math.random() * max_v
			var drop:Drops = new Drops(type, t_v, player.y + player.height, player.y, player.y + player.height*.8, stage.stageWidth, stage.stageWidth, stage.stageHeight);
			_dropsHolder.addChild(drop);
			_dropLists.push(drop);
		}
		
		private function updateplayer():void
		{
			// TODO Auto Generated method stub
			if(_isGoLeft){
				player.x -= dx;
				if(player['lxMc'])player['lxMc'].scaleX = 1;
			}
			if(_isGoRight){
				player.x += dx;
				if(player['lxMc'])player['lxMc'].scaleX = -1;
			}
			//	80 为人物宽度
			player.x = Math.max(0, Math.min(player.x, 488 - 80));
		}

		//private var myColorTransform:ColorTransform = new ColorTransform(250, 255, 255, 0.5, 25, 187 , 250, 0);
		private var myColorTransform:ColorTransform = new ColorTransform(250, 255, 255, .4, 0, 0, 187, 1);
		private var canvas:BitmapData;
		private var emptyBitmap:BitmapData;
		private var rect:Rectangle = new Rectangle(0,0, 488, 200);
		private var matrix:Matrix = new Matrix(1, 0, 0, 1, 0, -200);
		private var p:Point = new Point(0,0)
		private function updateEffect():void {
			this.canvas = emptyBitmap.clone();
			this.canvas.draw(effectBitmap.bitmapData, null, myColorTransform);
			this.canvas.draw(playerLayer, matrix, myColorTransform);
			effectBitmap.bitmapData.dispose();
			effectBitmap.bitmapData = emptyBitmap.clone();
			effectBitmap.bitmapData.copyPixels(canvas, rect, p)
		}
	}
}