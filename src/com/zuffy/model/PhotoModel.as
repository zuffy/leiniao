package com.zuffy.model {
	import com.adobe.images.*;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	import flash.events.SecurityErrorEvent;

	public class PhotoModel extends EventDispatcher {
		private var p1:Sprite;
		public var avaterImage:Bitmap;
		public var picData_1:BitmapData;
		
		private static var _instance:PhotoModel;
		
		private var __upsave:URLLoader;
		private var okbitmapD:BitmapData;
		
		private var __file:FileReference;
		

		public function PhotoModel() {
		
		}

		public function photo(photo_1:Sprite,box_width:Number,box_height:Number):void {
		
			p1 = photo_1;
			
			var w:Number = box_width;
			var h:Number = box_height;
			
			picData_1 = new BitmapData(w,h,true,0);
			picData_1.draw(p1);
			/*var b:Bitmap = new Bitmap(picData_1)
			b.x = 30
			b.y = 30
			p1.stage.addChild(b)*/
		}
		
		public function save():void {
			var avaimgdata:Boolean = true;
			if (avaimgdata) {
				var imagebyte:ByteArray
				var jpgEncoder:JPGEncoder = new JPGEncoder(100);
				imagebyte = jpgEncoder.encode(picData_1);
				var aDate:Date = new Date();
				var str:String = aDate.toLocaleString();
				var r:RegExp = / /g;
				trace(imagebyte.length);
			}
		}
		
		private function saveLocalCimplete(e:Event):void {
			
		}
		private function saveIOEorror(e:IOErrorEvent):void {
			
		}
		
		public function updateWB():void {
			__upsave = new URLLoader();
			__upsave.dataFormat = URLLoaderDataFormat.BINARY;
			__upsave.addEventListener(Event.COMPLETE,onSaveComplete);
			__upsave.addEventListener(IOErrorEvent.IO_ERROR,onSaveError);
			__upsave.addEventListener(ProgressEvent.PROGRESS, onSaveGress);
			
		}
		private var _uploadRet:Function
		public function uploadPic(url:String, callback:Function):void {
			_uploadRet = callback;
			/**创建图片对应的字节流**/  
			var pngStream:ByteArray = PNGEncoder.encode(picData_1);  
			
			/**设置数据头信息**/  
			var header:URLRequestHeader = new URLRequestHeader("Content-type","application/octet-stream");  
			
			/**设置请求链接和图片文件名称**/  
			var pngURLRequest:URLRequest = new URLRequest(url);  
			pngURLRequest.requestHeaders.push(header);  
			pngURLRequest.method = URLRequestMethod.POST;  
			pngURLRequest.data = pngStream;  
			
			var loader:URLLoader = new URLLoader(pngURLRequest);  
			
			/**发送数据请求**/  
			loader.load(pngURLRequest);  
			
			/**添加数据发送结束的事件处理，服务器返回的数据会放入loader的data属性中**/  
			loader.addEventListener(Event.COMPLETE,picUploadCompleteHandler); 
			loader.addEventListener(IOErrorEvent.IO_ERROR,onSaveError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSaveError);
		}
		
		private function picUploadCompleteHandler(e:Event):void {
			trace(e.target.data);
			_uploadRet && _uploadRet(e.target.data);
		}
		
		private function onSaveError(event:Event):void {
			_uploadRet && _uploadRet({ret:-201});
		}

		private function onSaveGress(event:ProgressEvent):void {
			var per = event.bytesLoaded /event.bytesTotal;
			trace(per)
		}

		private function onSaveComplete(event:Event):void {
			trace(event.target.data);
			_uploadRet && _uploadRet(event.target.data);
		}
		
		public static function getCookies():Array {  
            if (!ExternalInterface.available) {  
                return [];  
            }  
          var cookieArr:Array=new Array();
          var obj:Object = ExternalInterface.call("function (){ return Cookie.get('uin')}");
		  var str:String = String(obj);
		  cookieArr.push(["uin",str]);
		  obj = ExternalInterface.call("function (){ return Cookie.get('skey')}");
		  str = String(obj)
		  cookieArr.push(["skey",str]);
            return cookieArr;            
        }  
	
		public static function  instance():PhotoModel {
			if (_instance==null) {
				_instance = new PhotoModel();
			}
			return _instance;
		}
	}

}