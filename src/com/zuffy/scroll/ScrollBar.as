package com.zuffy.scroll {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.geom.Rectangle;

	public class ScrollBar extends Sprite{
		private var sd:Number;
		private var sr:Number;
		private var cd:Number;
		private var cr:Number;
		private var new_y:Number;
		private var drag_area:Rectangle;
		private var flash_content:Sprite;
		private var flash_content_area:Sprite;
		private var scrolling_speed:Number;// 0.00 to 1.00

		public function ScrollBar(){
			flash_scroller.buttonMode = true;
		}

		public function scrolling( ct:Sprite, ct_area:Sprite, speed:Number ):void {
			scrolling_speed=speed;
			if (scrolling_speed<0||scrolling_speed>1) {
				scrolling_speed=0.50;
			}

			flash_content=ct;
			flash_content_area=ct_area;

			flash_content.mask=flash_content_area;
			flash_content.x=flash_content_area.x;
			flash_content.y=flash_content_area.y;

			sr=flash_content_area.height/flash_content.height;
			//flash_scroller.height = flash_scrollable_area.height * sr;//滚动滑块的长度
			flash_scroller.height=60;

			sd=flash_scrollable_area.height-flash_scroller.height;
			cd=flash_content.height-flash_content_area.height;
			cr=cd/sd//*1.05;

			drag_area=new Rectangle(0,0,0,sd);

			if (flash_content.height<=flash_content_area.height) {
				flash_scroller.visible=flash_scrollable_area.visible=false;
			}
			else{
				flash_scroller.visible=flash_scrollable_area.visible=true;
			}
			flash_scroller.addEventListener( MouseEvent.MOUSE_DOWN, scroller_drag );
			flash_scroller.addEventListener( MouseEvent.MOUSE_UP, scroller_drop );
			//flash_content.addEventListener( MouseEvent.MOUSE_WHEEL, scroller_wheel );
			this.addEventListener( Event.ENTER_FRAME, on_scroll );
		}

		private function scroller_drag( me:MouseEvent ):void {
			me.target.startDrag(false, drag_area);
			stage.addEventListener(MouseEvent.MOUSE_UP, up);
		}

		private function scroller_drop( me:MouseEvent ):void {
			me.target.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, up);
		}

		private function up( me:MouseEvent ):void {
			flash_scroller.stopDrag();
		}
		private function on_scroll( e:Event ):void {
			new_y=flash_content_area.y+flash_scrollable_area.y*cr-flash_scroller.y*cr;
			flash_content.y += ( new_y - flash_content.y ) * scrolling_speed/4;

		}
		private function scroller_wheel( me:MouseEvent ):void {
			if (flash_scroller.y>=drag_area.height) {
				flash_scroller.y=drag_area.height;
			}
			if (flash_scroller.y<=0) {
				flash_scroller.y=0;
			}
			if (me.delta<0) {
				flash_scroller.y+=10;
			} else if (me.delta>0) {
				flash_scroller.y-=10;
			}

			flash_scroller.y = Math.min(Math.max(0, flash_scroller.y), sd);

		}
	}
	


}