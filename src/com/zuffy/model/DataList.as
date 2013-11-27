package com.zuffy.model {
	
	import flash.display.Sprite;
	import com.zuffy.scroll.ScrollBar;
	import flash.display.Shape;
	import flash.text.TextField;
	import flash.text.StyleSheet;
	import flash.text.TextFieldAutoSize;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextFormat;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;

	public class DataList extends Sprite {
		
		private static var _instance:DataList
		public static function get instance():DataList {
			if(!_instance) {
				_instance = new DataList()
			}
			return _instance
		}

		private var flash_sb:ScrollBar;
		private var flash_item_group:Sprite;
		private var flash_mask:Sprite;
		private var item_width:Number = 120;
		private var list_height:Number = 120;

		private var item_padding:Number = 20;
		private var item_spacing:Number = 10;
		private var flash_style:StyleSheet;
		private var moreIndex:int = 5;
		private var showMoreHandler:String

		public function DataList() {
			flash_sb = new ScrollBar();
			flash_item_group = new Sprite();
			flash_mask = new Sprite();
			addChild(flash_mask);
			addChild(flash_item_group);
			addChild(flash_sb);
			moreIndex = 5;
			flash_sb.visible = false;
		}

		private	var lists:Array;
		private var tf:TextFormat = new TextFormat("Arial");			
		public function setData(t_lists:Array, data:String=''):void {
			flash_sb.visible = true;
			lists = t_lists
			//create_first_list(lists)
			create_item_list(lists)

			flash_style = new StyleSheet()
			tf.font = 'bold';
		}

		public function setup(container:Sprite, showMoreFunc:String, t_w:Number=0, t_h:Number=0, t_p:Number = 0):void {
			container.addChild(this)
			item_width = t_w ? t_w : item_width
			list_height = t_h ? t_h : list_height;
			showMoreHandler = showMoreFunc;
		}

		private function create_content(data:String):void {
			var fm_text:TextField = new TextField();
			fm_text.x = 0;
			fm_text.y = 0;
			fm_text.width = item_width - item_padding*2;
			fm_text.styleSheet = flash_style;
			fm_text.htmlText = data;
			fm_text.multiline = true;
			fm_text.wordWrap = true;
			fm_text.border = true;
			fm_text.selectable = false;
			fm_text.autoSize = TextFieldAutoSize.LEFT;
			addChild(fm_text);
		}
		
		private function create_item_list(lists:Array):void {
			var total:int = lists.length;
			var item_height:Number = 0;

			while(flash_item_group.numChildren > 0) {
				flash_item_group.removeChildAt(0);
			}

			for( var i:int = 0; i < total; i++ ) {
				var t_item:Sprite = new Sprite();
				if(lists[i].isMoreBtn){
					var more:More = new More();
					var index:int = i;
					more.btn.addEventListener(MouseEvent.CLICK, function __(me:MouseEvent):void {
						if(showMoreHandler)
						ExternalInterface.call(showMoreHandler, index)
					})
					if(lists[i].addLine){
						t_item.addChild(new SeprateLine())
					}
					t_item.addChild(more)
				}else {
					t_item.addChild( create_pre_icon(lists[i].id))
					t_item.addChild( create_item_text(lists[i].name, lists[i].color, 125) );
					t_item.addChild( create_item_text(lists[i].mark, lists[i].color, 75, 125) );
				}
				t_item.y = item_height;
				item_height += t_item.height + item_spacing;
				flash_item_group.addChild( t_item );
			}
				ExternalInterface.call('debug',this.y)
			flash_mask.graphics.clear();
			flash_mask.graphics.beginFill(0xff0000);
			flash_mask.graphics.drawRect(0,0,item_width,list_height);
			flash_mask.graphics.endFill();
			
			flash_item_group.graphics.clear();
			flash_item_group.graphics.beginFill(0xfefefe,0);
			flash_item_group.graphics.drawRect(0,0,item_width-30,item_height);
			flash_item_group.graphics.endFill();
			
			flash_sb.x = flash_item_group.x +flash_item_group.width
			flash_sb.height = flash_mask.height;
			flash_sb.scrolling(flash_item_group, flash_mask, 0.90);	// ScrollBar Added
		}
		
		private function create_pre_icon(index:int):MovieClip {
			var s:MovieClip;
			if(index == 0) {				
				s = new Icon();
			}
			else if(index == 1) {
				s = new Icon();
				s.gotoAndStop(2)
			}
			else if(index == 2) {
				s = new Icon();
				s.gotoAndStop(3)
			}
			else {
				s = new MovieClip();
				var bg:Shape = new Shape();
				var tx:TextField = new TextField();
				tx.text = (index + 1) +'';
				tx.textColor = 0xB8E1FF;
				tx.autoSize = TextFieldAutoSize.LEFT;
				tx.selectable = false;
				tx.setTextFormat(tf);
				s.addChild(tx)
				
				var rect:Rectangle = tx.getCharBoundaries(0);
				bg.graphics.beginFill(0x0E256B);
				tx.width = (rect.width)* tx.text.length;
				tx.height = rect.height;
				bg.graphics.drawRoundRect(0,0, (rect.width)* tx.text.length + 5, rect.height, 1,1);
				bg.graphics.endFill();
				bg.y = 2.5
				s.addChildAt(bg, 0);			
			}
			s.x = 5
			s.y = 5
			return s;

		}
		private var tf2:TextFormat = new TextFormat();
		private function create_item_text(item_desc:String, color:uint, t_width:Number, padding_left:Number = 45, isMark:Boolean = false ):TextField {
			var fm_text:TextField = new TextField();
			fm_text.x = padding_left;
			fm_text.y = 0;
			fm_text.width = t_width;
			fm_text.height = 25
			fm_text.text = item_desc || '';
			fm_text.textColor = color || 0x9DB7DF;
			fm_text.multiline = false;
			//fm_text.wordWrap = true;
			fm_text.selectable = true;
			if(isMark){
				fm_text.border = true;
				tf2.align = 'right';
				
			}
			else{
				tf2.align = 'left';
			}
			fm_text.defaultTextFormat = tf2;
			return fm_text;
		}

	}
}