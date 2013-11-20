package
{
	import flash.display.Sprite;
	
	public class Drops extends Sprite
	{
		public var v:Number = 1;
		private var leaveStageY:Number;
		private var activateY:Number;
		public var state:uint;
		
		public static const ALIVE:uint = 0;
		public static const ACTIVATE:uint = 1;
		public static const DIE:uint = 2;
		public static const BOWN:uint =3;
		
		private var max_v:Number = 12;
		private var min_v:Number = 3;
		
		public var mark:int = 0;
		public var type:Number = -1;
		
		
		
		public function Drops(t_type:uint, t_leaveStageY:Number, t_activateY:Number, rangeX:Number = 300)
		{
			super();
			v = min_v + Math.random() * max_v;
			leaveStageY = t_leaveStageY;
			type = Math.max(0, Math.min(3, t_type));
			mark = type * 10;
			addChild(this['getType' + type]());
			activateY = t_activateY - this.height;
			this.x = Math.random() * rangeX;
			this.state = ALIVE;
		}
		
		private function getType0():Sprite{
			var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0xffff00);
			sp.graphics.drawRect(0,0, 20, 20);//5*(12-v),5*(12-v)
			sp.graphics.endFill();
			return sp;
		}
		
		private function getType1():Sprite{
			var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0x00ffff);
			sp.graphics.drawRect(0,0, 20, 20);//5*(12-v),5*(12-v)
			sp.graphics.endFill();
			return sp;
		}
		
		private function getType2():Sprite{
			var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0xff00ff);
			sp.graphics.drawRect(0,0, 20, 20);//5*(12-v),5*(12-v)
			sp.graphics.endFill();
			return sp;
		}
		
		private function getType3():Sprite{
			var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0x000000);
			sp.graphics.drawRect(0,0, 20, 20);//5*(12-v),5*(12-v)
			sp.graphics.endFill();
			return sp;
		}
		public function update():void {
			this.y += v;
			if(this.y > leaveStageY){
				this.state = DIE;
			}else if (this.y > activateY) {
				this.state = ACTIVATE;
			}
		}
		
	}
}