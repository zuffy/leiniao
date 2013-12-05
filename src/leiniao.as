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
	import flash.system.Security;
	import flash.display.StageScaleMode;
	import flash.external.ExternalInterface;
	import flash.display.StageAlign;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import com.zuffy.model.PhotoModel;
	import com.zuffy.model.DataList;
	import com.greensock.TweenLite;

	
	public class leiniao extends Sprite	{
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
		private var playedTime:Number = 0;

		private var genDropsDuration:Number = 1000;
		// level
		private var levelPoints:Array = [500, 900, 1800, 2800, 4000, 5000]
		private var speedRang:Array = [2.8, 2.4, 2, 1, 0.5, 0.4, 0]
		private var born_duration:Array = [600, 400, 300, 200, 100, 90, 50]
		private var born_speed:Array = [6, 6.5, 7.5, 10, 12, 14, 18]
		private var move_speed:Array = [10, 12, 14, 16, 17, 18, 18]
		private var startDropDuration:Number = 0 	// 3s
		private var curLevel:int = -1;
		private var dx:Number = 10;


		private var _dropLists:Vector.<Drops>;
		private var _dropsHolder:Sprite;

		private var v0:Number = 7.5;	// 初始平均速度
		private var v_range:Number = 2.5 // 道具下落的差异速度

		private var playerLayer:Sprite = new Sprite();
		private var objsLayer:Sprite = new Sprite();
		private var playerEffectLayer:Sprite = new Sprite();
		private var effectBitmap:Bitmap;

		private const StageWidth:Number = 850;
		private const StageHeight:Number = 474;
		
		private var turnOtherSide:Boolean = false;


		private var state:String = "MENU";

		private var txt:TextField = new TextField();
		var ttt:TextFormat = new TextFormat();
		private var ctrlTip:Tip;

		private var rankBtn:RankBtn;
		private var rank:Sprite;

		public function leiniao() {
			Security.allowDomain("*");  
			Security.allowInsecureDomain("*");

			if(stage){
				stage_init();
			}
			else {
				addEventListener(Event.ADDED_TO_STAGE, stage_init)
			}
			
		}

		private function stage_init(e:Event = null):void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.tabChildren = false;
			removeEventListener(Event.ADDED_TO_STAGE, stage_init)

			if(stage.stageWidth == 0 || stage.stageHeight == 0) {
				stage.addEventListener(Event.RESIZE, on_stage_RESIZE);
			}
			else {
				init();
			}
		}

		private var logTxt:TextField = new TextField();
		private function on_stage_RESIZE(e:Event = null):void {
			if(stage.stageWidth > 0 && stage.stageHeight > 0) {
				stage.removeEventListener(Event.RESIZE, on_stage_RESIZE);
				init();
			}
		}
		private function init():void {
			initJS();
			initUI();
			/* test
			ttt.size = 25;
			ttt.color = 0xffffff;
			txt.defaultTextFormat = ttt;
			//addChild(txt)
			*/
		}
		
		private function initJS():void {
			if (ExternalInterface.available) {
				ExternalInterface.addCallback('setParam', setParam);
				ExternalInterface.addCallback('setList', setList);
				ExternalInterface.addCallback('showShanePanel', showShanePanel);
				ExternalInterface.addCallback('saveSnaptShoot', saveSnaptShoot);
				ExternalInterface.addCallback('saveRankSnaptShoot', saveRankSnaptShoot);
				ExternalInterface.addCallback('resetgame', resetgame);
			}

		}

		private function setList(lists:Array):void {
			DataList.instance.setData(lists);
		}

		private var uploadUrl:String = '';
		private var gameStartCall:String;
		private var gameOverCall:String;
		private var startShare:String;
		private var sharPanelCloseCall:String;		
		private var snapUploadComplete:String;
		private var showRankHandlerFunc:String;

		private var logFunc:String;

		private var snaptShootWdith:Number = 260;
		private var snaptShootHeight:Number = 315;
		private var showMoreFunc:String;

		private function setParam(obj:Object):void {
			snaptShootHeight = obj.height || snaptShootHeight
			showMoreFunc = obj.showMoreFunc	// 显示更多按钮点击的回调函数

			uploadUrl  = obj.uploadUrl  
			gameStartCall = obj.gameStartCall
			gameOverCall = obj.gameOverCall
			sharPanelCloseCall = obj.sharPanelCloseCall
			startShare = obj.startShare
      snapUploadComplete = obj.snapUploadComplete
      showRankHandlerFunc = obj.showRankHandlerCall
			logFunc = obj.logFunc

			var funcName = obj.snapUploadComplete // 截图上传完毕
			sharComplete = function __sharComplete(obj):void {
					isSharing = false;
					debug('snap Upload Complete')
					ExternalInterface.call('' + funcName, obj)
			}


			startBtn.addEventListener(MouseEvent.CLICK, onStartBtnHandler);

			var dh:Number = snaptShootHeight - listHolder.y;
			DataList.instance.setup(listHolder, showMoreFunc, snaptShootWdith, dh);
			debug('ok startBtn.visible:'+startBtn.visible)
			resetgame()
			debug('resetgame')
		}
		
		private var gameOverPanel:Panel;
		private var sharComplete:Function;
		private var rankSharComplete:Function;
		private var isSharing:Boolean = false;
		private function showShanePanel(score:String, times:String):void {
			debug('排名：'+score + '抽奖次数：'+times)
			if(!gameOverPanel){
				gameOverPanel = new Panel();
				gameOverPanel.close.addEventListener(MouseEvent.CLICK, closePanel)
				gameOverPanel.again.addEventListener(MouseEvent.CLICK, onStartBtnHandler)
				addChild(gameOverPanel)
				gameOverPanel.btndouban.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(false));
				gameOverPanel.btnsina.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(false));
				gameOverPanel.btnrenren.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(false));
				gameOverPanel.btntengxun.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(false));
				/*
				rankSharComplete = function __sharComplete(obj):void {
					isSharing = false;
					ExternalInterface.call('' + snapUploadComplete, obj)
				}*/

			}
			gameOverPanel.visible = true;
			gameOverPanel.snapShotArea.myScore.text = marks + '分';
			gameOverPanel.snapShotArea.myRank.text = score + '位';
			gameOverPanel.snapShotArea.timesDis.text = times;
			gameOverPanel.x = (StageWidth - gameOverPanel.width) * .5;
			gameOverPanel.y = (StageHeight - gameOverPanel.height) * .5;
		}
		private function shareRankBtnClickHandler(isFromRankList:Boolean):Function {
			var func:Function = function __shareRankBtnClickHandler(me:MouseEvent):void {
				debug('the btn:' + me.target.name.slice(3) + ' from rank list:'+isFromRankList + ' isSharing:'+isSharing)
				if(isSharing){
					return;
				}
				isSharing = true;
				ExternalInterface.call(startShare, '' + me.target.name.slice(3), isFromRankList)
			}
			return func;
		}

		private function closePanel(me:MouseEvent):void {
			gameOverPanel.visible = false;
			ExternalInterface.call(sharPanelCloseCall)
		}
		
		private function saveRankSnaptShoot():void{
			var photoModel:PhotoModel = PhotoModel.instance()
			photoModel.photo(rank, rank.width, rank.height)
			photoModel.uploadPic(uploadUrl, sharComplete)
		}
		private function saveSnaptShoot():void{
			onSaveGameOverTip();
		}

		private function onSaveGameOverTip(me:MouseEvent = null):void {
			var photoModel:PhotoModel = PhotoModel.instance()
			photoModel.photo(gameOverPanel.snapShotArea, 306, 67)
			photoModel.uploadPic(uploadUrl, sharComplete)
		}

		private function resetgame():void {
			state = "MENU"
			startBtn.addEventListener(MouseEvent.CLICK, onStartBtnHandler);
			if(gameOverPanel){
				gameOverPanel.visible = false;
			}
			isSharing = false;
			debug('resetgame in flash')
		}

		
		private function initUI():void {
			addChild(bg);
			playerLayer = new Sprite();
			objsLayer = new Sprite();
			playerEffectLayer = new Sprite();
			addChild(playerEffectLayer)
			addChild(playerLayer)
			addChild(objsLayer)

			startBtn = new StartBtn();
			markBoard = new MarksDis();
			startBtn.x = (stage.stageWidth - startBtn.width) * .5;
			startBtn.y = (stage.stageHeight - startBtn.height) * .5;
			addChild(startBtn);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,handleKeyUp);

			/*
			stage.addEventListener(MouseEvent.MOUSE_OUT, onDeactivate);
			stage.addEventListener(MouseEvent.MOUSE_OVER,onActivate);
			*/					
			marks = 0;
			markBoard.y = 10;
			markBoard.x = StageWidth - markBoard.width - 10;
			addChild(markBoard);

			isSharing = false;

			initPlayer();

			initRank();

			ctrlTip = new Tip();
			ctrlTip.x = 15
			ctrlTip.y = stage.stageHeight - ctrlTip.height - 15
			addChild(ctrlTip)
			/* **********log**********
			logTxt.width = 500;
			logTxt.height = 300;
			logTxt.textColor = 0xffffff;

			addChild(logTxt)
			debug('stage:'+stage + ' height:'+stage.stageHeight)
			*/
		}

		private var listHolder:Sprite;
		private var rankbg:RankBG = new RankBG();
		private function initRank():void {
			rankBtn = new RankBtn();
			rankBtn.x = stage.stageWidth - rankBtn.width;
			rankBtn.y = stage.stageHeight - rankBtn.height;
			rankBtn.buttonMode = true;
			rankBtn.addEventListener(MouseEvent.MOUSE_OVER, onShowRankHandler)
			addChild(rankBtn);

			rank = new Sprite();
			rank.addChild(rankbg)
			rankbg.btndouban.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(true));
			rankbg.btnsina.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(true));
			rankbg.btnrenren.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(true));
			rankbg.btntengxun.addEventListener(MouseEvent.CLICK, shareRankBtnClickHandler(true));

			listHolder = new Sprite();
			listHolder.x = 15;
			listHolder.y = 60;
			rank.x = stage.stageWidth;
			rank.addChild(listHolder)
			addChild(rank)
		}
		
		private function onShowRankHandler(me:MouseEvent):void {
			ExternalInterface.call(showRankHandlerFunc);
			var todx:Number = stage.stageWidth - 250;
			TweenLite.killTweensOf(rank);
			TweenLite.to(rank, 0.3, { x: todx, onComplete:rankOnShow} );
		}

		private function rankOnShow():void {
			//rank.addEventListener(MouseEvent.ROLL_OUT, rankOnHide)
			stage.addEventListener(Event.ENTER_FRAME, testHide)
		}
		/*
		private function rankOnHide(me:MouseEvent):void {
				TweenLite.to(rank, 0.3, { x:stage.stageWidth, onComplete:function __():void {
					rank.removeEventListener(MouseEvent.ROLL_OUT, rankOnHide)
				}} );
		}*/
		private function testHide(e:Event):void {
			if(mouseX < rank.x - 60){
				stage.removeEventListener(Event.ENTER_FRAME, testHide)
				TweenLite.to(rank, 0.3, { x:stage.stageWidth} );
			}
		}


		private function initPlayer():void {
			// TODO Auto Generated method stub
			player = new Player();
			player.visible = false;
			playerLayer.addChild(player);
		}
		
		private function onDeactivate(me:MouseEvent):void {
			state = 'DEACTIVATE';
		}
		
		private function onActivate(me:MouseEvent):void {
			state = 'GAME';
		}
		
		public function set marks(value:int):void {			
			_marks = value;
			trace(_marks)
			updateDatas();
			markBoard.total.text = _marks + '';
		}
		
		public function get marks():int {			
			return _marks;
		}
		
		private function hideCtrlTip():void {
			var  timeoutID:int = setTimeout(function(){
				ctrlTip.visible = false;
				clearTimeout(timeoutID)
			}, 2000)
		}

		private function onStartBtnHandler(event:MouseEvent = null):void {
			// TODO Auto-generated method stub
			if(!ExternalInterface.call(gameStartCall)){
				return;
			}
			hideCtrlTip();
			curLevel = -1;
			startBtn.visible = false;
			player.visible = true;
			_eff_elapse = 0;
			player.x = (stage.stageWidth - player.width) * .5;
			player.y = (stage.stageHeight - player.height) * .96;
			
			marks = 0;
			startDropDuration = 1000;
			playedTime = 0;
			state = "GAME";
			startBtn.removeEventListener(MouseEvent.CLICK, onStartBtnHandler);
			stage.addEventListener(Event.ENTER_FRAME, loop);
			markBoard.purseBtn.buttonMode = true;
			markBoard.purseBtn.addEventListener(MouseEvent.CLICK, onPurse);
			_dropLists = new Vector.<Drops>();
			_dropsHolder = new Sprite();
			objsLayer.addChild(_dropsHolder);			
			effectBitmap = new Bitmap(new BitmapData(stage.width,200,true,0));
			effectBitmap.y = 200
			playerEffectLayer.addChild(effectBitmap)
			bg.gotoAndPlay(2);
			player.gotoAndPlay(2)
			if(gameOverPanel) {
				gameOverPanel.visible = false;
			}
			this.emptyBitmap = new BitmapData(stage.width,200,true,0);
			
		}

		private function onPurse(me:MouseEvent):void {
			if(state == 'PAURSE'){
				state = 'GAME';
				markBoard['purseBtn'].gotoAndStop(1)
				_isGoLeft = _isGoRight = false;
			}
			else if(state == 'GAME'){
				state = 'PAURSE';
				markBoard['purseBtn'].gotoAndStop(2)
			}
		}
		
		protected function handleKeyUp(event:KeyboardEvent):void {
			// TODO Auto-generated method stub
			switch(event.keyCode){
				// <-
				case 37:
					turnOtherSide = false
					_isGoLeft = false;
					break;
				case 39:
					turnOtherSide = false
					_isGoRight = false;
					break;
				default:break;
			}
			event.updateAfterEvent();
		}

		private var _eff_elapse:int = 0;

		protected function handleKeyDown(event:KeyboardEvent):void {
			// TODO Auto-generated method stub
			// _isGoRight = _isGoLeft = false;
			switch(event.keyCode){
				case 37:	// <-
					_isGoLeft = true;
					_eff_elapse = 30;
					turnOtherSide = false
					break;
				case 39:	// ->
					_eff_elapse = 30;
					_isGoRight = true;
					turnOtherSide = false
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
			objsLayer.removeChild(_dropsHolder)
			_dropLists = null;
			_dropsHolder = null;
			player.visible = false;
			startBtn.visible = true;
			//startBtn.addEventListener(MouseEvent.CLICK, onStartBtnHandler);
			playerEffectLayer.removeChild(effectBitmap)
			state = '';
			ExternalInterface.call(gameOverCall, marks, playedTime);
		}

		protected function onGameLoop():void {
			// TODO Auto-generated method stub
			var r:Number = Math.random();
			t2 = getTimer() - t1;
			if(t2 < 30) return;
			if(t2 > 80){
				t1 = getTimer();
				return
			};

			t1 = getTimer();
			t3 += t2
			eff_duration += t2;
			playedTime += t2;
			if(startDropDuration > 0){
				if(t3 < startDropDuration) {
					return;
				}
				else {
					startDropDuration = 0;
					t3 = 0;
				}
			}

			if(t3 > genDropsDuration && _dropLists.length < 20){
				genDrops();
				t3 = 0;
			}
			updateDrops();
			updateplayer();
			/*
			if( _eff_elapse > 0 && eff_duration > 50){
				updateEffect();
				eff_duration = 0;
				eff_elapse --;
			}*/
		}

		private function set eff_elapse (value:int):void {
			_eff_elapse = value
			if(_eff_elapse == 0)
			effectBitmap.bitmapData = emptyBitmap.clone();
		}
		
		private function get eff_elapse():int {
			return _eff_elapse;
		}
		
		private function getDataFromMark(t_mark:int):Object {
			var obj = {};
			var level:int = 0;
			if(t_mark > 5000){
				level = 6;
			}
			else if(t_mark <= 500){
				level = 0
			}
			else if(t_mark <= 900){
				level = 1
			}
			else if(t_mark <= 1800){
				level = 2
			}
			else if(t_mark <= 2800){
				level = 3
			}
			else if(t_mark <= 4000){
				level = 4
			}
			else{
				level = 5
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
		private function updateDrops():void {
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
		
		private function gameOver():void {
			// TODO Auto Generated method stub
			state = 'GAMEOVER';
		}
		
		private function genDrops():void {
			// TODO Auto Generated method stub
			var type:uint = 1 + Math.random()*3;
			var min_v:Number = v0 - v_range;
			var max_v:Number = v0 + v_range;
			var t_v = min_v + Math.random() * max_v
			var drop:Drops = new Drops(type, t_v, player.y + player.height, player.y, player.y + player.height*.8, stage.stageWidth, stage.stageWidth, stage.stageHeight);
			_dropsHolder.addChild(drop);
			_dropLists.push(drop);
		}
		
		private function updateplayer():void {
			// TODO Auto Generated method stub
			if(_isGoLeft){
				player.x -= dx;
				if(!turnOtherSide){
					if(player['lxMc'])player['lxMc'].scaleX = 1;
					turnOtherSide = true;
				}
			}
			if(_isGoRight){
				player.x += dx;
				if(!turnOtherSide){
					if(player['lxMc'])player['lxMc'].scaleX = -1;
					turnOtherSide = true;
				}
			}

			//	80 为人物宽度
			player.x = Math.max(10, Math.min(player.x, StageWidth - 100));
		}

		//private var myColorTransform:ColorTransform = new ColorTransform(250, 255, 255, 0.5, 25, 187 , 250, 0);
		private var myColorTransform:ColorTransform = new ColorTransform(250, 255, 255, .4, 0, 0, 187, 1);
		private var canvas:BitmapData;
		private var emptyBitmap:BitmapData;
		private var rect:Rectangle = new Rectangle(0,0, StageWidth, 200);
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


		private function debug(str:String):void {
			//logTxt && (logTxt.text = str);
			ExternalInterface.call(logFunc, str)
			//ExternalInterface.call('window.console.log', str)
		}
	}
}