package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	public class leiniao extends Sprite
	{
		private var startBtn:Sprite;
		private var player:Sprite;
		private var _isGoLeft:Boolean;
		private var _isGoRight:Boolean;
		
		private var _marks:int = 0;
		private var markBoard:TextField = new TextField();
				
		public function leiniao()
		{
			init();
			
		}
		private function init():void {
			initUI();
			initPlayer();
		}
		
		private function initPlayer():void
		{
			// TODO Auto Generated method stub
			player = new Sprite();
			player.graphics.beginFill(0x0000ff, .8);
			player.graphics.drawCircle(0,0,25);
			player.graphics.endFill();
			player.x = (stage.stageWidth - startBtn.width) * .5;
			player.y = (stage.stageHeight - startBtn.height) * .8;
			player.addEventListener(MouseEvent.CLICK, onStartBtnHandler);
			player.visible = false;
			addChild(player);
		}
		
		private function initUI():void {
			startBtn = new Sprite();
			startBtn.graphics.beginFill(0xff0000);
			startBtn.graphics.drawCircle(0,0,25);
			startBtn.graphics.endFill();
			startBtn.x = (stage.stageWidth - startBtn.width) * .5;
			startBtn.y = (stage.stageHeight - startBtn.height) * .5;
			startBtn.buttonMode = true;
			startBtn.addEventListener(MouseEvent.CLICK, onStartBtnHandler);
			addChild(startBtn);
			
			_marks = 0;
			markBoard.text = '';
			addChild(markBoard);
		}
		
		public function set marks(value:int):void {			
			_marks = value;
			markBoard.text = _marks + '分'
		}
		
		public function get marks():int {			
			return _marks;
		}
		
		private function onStartBtnHandler(event:MouseEvent):void
		{
			// TODO Auto-generated method stub
			startBtn.visible = false;
			player.visible = true;
			state = "GAME";
			startBtn.removeEventListener(MouseEvent.CLICK, onStartBtnHandler);
			stage.addEventListener(Event.ENTER_FRAME, loop);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,handleKeyUp);
			_dropLists = new Vector.<Drops>();
			_dropsHolder = new Sprite();
			addChild(_dropsHolder);
		}
		
		protected function handleKeyUp(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub
			_isGoRight = _isGoLeft = false;
		}
		
		protected function handleKeyDown(event:KeyboardEvent):void
		{
			// TODO Auto-generated method stub
			_isGoRight = _isGoLeft = false;
			switch(event.keyCode){
				// <-
				case 37:
					_isGoLeft = true;
					break;
				case 39:
					_isGoRight = true;
					break;
				default:break;
			}
		}
		
		private var state:String = "MENU";
		private function loop(event:Event):void {
			switch(state){
				case "MENU":
					showMenu();
					break;
				case "GAME":
					onGameLoop();
					break;
				default:break;
			}
		}
		
		private function showMenu():void
		{
			// TODO Auto Generated method stub
			startBtn.visible = true;
		}
		
		private var t1:Number = 0;
		private var t2:Number = 0;
		private var t3:Number = 0;
		protected function onGameLoop():void
		{
			// TODO Auto-generated method stub
			var r:Number = Math.random();
			t2 = getTimer() - t1;
			t1 = getTimer();
			t3 += t2
			if(t3 > 1000){
				genDrops();
				t3 = 0;
			}
			updateDrops();
			updateplayer();
		}
		
		private function updateDrops():void
		{
			// TODO Auto Generated method stub
			var drop:Drops
			var i:int
			for(i = _dropLists.length-1; i >= 0; i--){
				drop = _dropLists[i];
				drop.update();
				if(drop.state == Drops.ACTIVATE && drop.hitTestObject(player)){
					drop.state = Drops.DIE;
					if(drop.type == 3){
						drop.state = Drops.BOWN;
						gameOver();
					}else {
						this.marks += drop.mark;
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
			
		}
		
		private var _dropLists:Vector.<Drops>;
		private var _dropsHolder:Sprite;
		private function genDrops():void
		{
			// TODO Auto Generated method stub
			var type:uint = Math.random()*5 >> 0;
			var drop:Drops = new Drops(type, player.y + player.height, player.y, stage.stageWidth);
			_dropsHolder.addChild(drop);
			_dropLists.push(drop);
		}
		
		private var dx:Number = 15;
		private function updateplayer():void
		{
			// TODO Auto Generated method stub
			if(_isGoLeft){
				player.x -= dx;
			}
			if(_isGoRight){
				player.x += dx;
			}
		}
	}
}