package
{
	import flash.display.Sprite;

	public class LevelManager
	{
		private static var _instance:LevelManager;
		private var drops:Vector.<Drops>;
		
		public function LevelManager()
		{
		}
		public static function get instance():LevelManager {
			if(!_instance){
				_instance = new LevelManager();
			}
			return _instance;
		}
		
		public function setup(container:Sprite):void {
			drops = new Vector.<Drops>();
			
		}
		
	}
}