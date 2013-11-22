package
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	
	public class Drops extends Sprite
	{
		public var v:Number = 1;
		private var leaveStageY:Number;
		private var activateY:Number;
		private var deactivateY:Number;
		public var state:uint;
		
		public static const ALIVE:uint = 0;
		public static const ACTIVATE:uint = 1;
		public static const DIE:uint = 2;
		public static const BOWN:uint =3;
		
		public var mark:int = 20;
		public var type:Number = -1;
		
		public var PropAndTrapLine:int = 2;
		
		
		public function Drops(t_type:uint, t_v:Number, t_leaveStageY:Number, t_activateY:Number, t_deactivateY:Number, rangeX:Number, stageW:Number, stageH:Number) {
			super();
			v = t_v;
			leaveStageY = t_leaveStageY;
			type = t_type;//Math.max(0, Math.min(3, t_type));
			//addChild(this['getType' + type]());
			addChild(getObj(t_type));
			activateY = t_activateY - this.height*.5;
			deactivateY = t_deactivateY - this.height*.5;
			this.x = Math.min(Math.random() * rangeX, stageW-this.width);
			this.state = ALIVE;
		}
		
		private function getObj(index:int):MovieClip {
			var sp:MovieClip;
			if(index > PropAndTrapLine){
				index = 1;
				sp = new Trap();
			}
			else{
				var txt:MovieClip;
				var ind:int = 1 + Math.random()*17
				sp = new Prop();
				if(index == 1) {
					txt = new PropNameW();
					txt.y = 25;
				}
				else {
					txt = new PropNameY();
					txt.y = 15;
				}
				txt.gotoAndStop(ind)
				sp.gotoAndStop(index)
				sp.addChild(txt)
				txt.x = 15;
			}
			return sp;
		}

		public function update():void {
			this.y += v;
			if(this.y > leaveStageY){
				this.state = DIE;
			}else if (this.y > deactivateY) {
				this.state = ALIVE;
			}else if (this.y > activateY && this.y < deactivateY) {
				this.state = ACTIVATE;
			}
		}
		
	}
}