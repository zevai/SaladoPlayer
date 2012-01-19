/*
Copyright 2012 Igor Zevako.

This file is part of SaladoPlayer.

SaladoPlayer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

SaladoPlayer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with SaladoPlayer. If not, see <http://www.gnu.org/licenses/>.
*/
package com.panozona.modules.lensflare{
	
	import com.panozona.player.SaladoPlayer;
	import com.panozona.modules.lensflare.model.*;
	import com.panozona.player.module.data.ModuleData;	
	import com.panozona.player.module.Module;
	import flash.system.ApplicationDomain;
	import flash.geom.Rectangle;
	import flash.geom.ColorTransform;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.net.URLRequest;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class LensFlare extends Module {
		
		private var lensFlareData:LensFlareData;
		private var colorTransform:ColorTransform = new ColorTransform();
		private var brightness:int;
		
		private var panoramaEventClass:Class;
		
		/* 
		 * Current panorama data
		 */
		private var fPan:Number;
		private var fTilt:Number;
		
		/* 
		 * Global settings
		 */
		protected var _maxFlaresDistance:Number;
		protected var _maxBrightnessDistance:Number;
		protected var _maxBrightness:Number;
		
		/* 
		 * Panoramas and flares settings
		 */
		protected var _panos:Object = new Object();
		protected var _flares:Array = new Array();
		protected var _flaresLoaded:Boolean = false;
		
		/*
		 * Constructor
		 */
		public function LensFlare():void {
			
			super("LensFlare", "0.1", "http://panozona.com/wiki/Module:LensFlare");
		}
		
		override protected function moduleReady(moduleData:ModuleData):void {
			
			lensFlareData = new LensFlareData(moduleData, saladoPlayer);			
			panoramaEventClass = ApplicationDomain.currentDomain.getDefinition("com.panozona.player.manager.events.PanoramaEvent") as Class;
			
			// save global settings
			_maxFlaresDistance = lensFlareData.settings.maxFlaresDistance;
			_maxBrightnessDistance = lensFlareData.settings.maxBrightnessDistance;
			_maxBrightness = lensFlareData.settings.maxBrightness;
			
			// save panoramas settings
			for each (var panorama:Panorama in lensFlareData.panoramas.getChildrenOfGivenClass(Panorama)) {
				_panos[panorama.id] = {"pan": panorama.pan, "tilt": panorama.tilt};
			}
			
			// save flares images settings
			var i:int = 0;
			for each (var flare:Flare in lensFlareData.flares.getChildrenOfGivenClass(Flare)) {
				_flares[i] = { "path": flare.path, "pos": flare.pos, "image": flare.image };
				i++;
			}
			
			saladoPlayer.manager.addEventListener(panoramaEventClass.PANORAMA_LOADED, onPanoramaLoaded, false, 0, true);
		}
		
		private function onPanoramaLoaded(e:Event):void {
			var currentPano:String = saladoPlayer.manager.currentPanoramaData.id;
			if (_panos[currentPano]) {
				if (!_flaresLoaded) {
					loadImages();					
				}
				fPan = _panos[currentPano].pan;
				fTilt = _panos[currentPano].tilt;
				stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			} else {
				if (stage.hasEventListener(Event.ENTER_FRAME)) {
					stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				}
				if (_flaresLoaded) {
					hideFlares();
				}
			}
		}		
		
		private function enterFrameHandler(event:Event):void {
			if (_panos[saladoPlayer.manager.currentPanoramaData.id]) {
				lensFlareEffect(saladoPlayer.manager._pan, saladoPlayer.manager._tilt);			
			}			
		}
		
		private function loadImages():void {
			
			for (var key:int = 0; key < _flares.length; key++) {
				var loader:Loader = new Loader();				
				_flares[key].image.addChild(loader);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageLost);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);				
				loader.load(new URLRequest(_flares[key].path));
			}
			
			_flaresLoaded = true; //TODO: move to right place
		}
		
		public function imageLost(e:IOErrorEvent):void {
			(e.target as LoaderInfo).removeEventListener(IOErrorEvent.IO_ERROR, imageLost);
			(e.target as LoaderInfo).removeEventListener(Event.COMPLETE, imageLoaded);
			printError("Unable to load: " + (e.target as LoaderInfo).url);
		}		
		
		private function imageLoaded(e:Event):void {
			(e.target as LoaderInfo).removeEventListener(IOErrorEvent.IO_ERROR, imageLost);
			(e.target as LoaderInfo).removeEventListener(Event.COMPLETE, imageLoaded);
			
			e.target.loader.x = - (e.target as LoaderInfo).width * 0.5;
			e.target.loader.y = - (e.target as LoaderInfo).height * 0.5;
			e.target.loader.parent.alpha = 0;
			e.target.loader.mouseEnabled = false;
			saladoPlayer.manager.addChild(e.target.loader.parent);
		}		
		
		private function lensFlareEffect(pan:Number, tilt:Number):void {
			
			var fDistance:Number = Math.sqrt(Math.pow(pan - fPan, 2) + Math.pow(tilt - fTilt, 2));

			if (fDistance == 0) {
				if (brightness != _maxBrightness) {
					setBrightness(_maxBrightness);					
				}				
			} else if(fDistance <= _maxBrightnessDistance) {
				setBrightness(_maxBrightness - Math.round(fDistance * _maxBrightness / _maxBrightnessDistance));
				
			} else {
				if (brightness != 0) {
					setBrightness(0);					
				}
			}
			
			showFlares(pan, tilt, fDistance);			
		}
		
		private function showFlares(pan:Number, tilt:Number, fDistance:Number):void
		{		
			for each(var flare:Object in _flares) {
				var flarePan:Number = fPan + (pan - fPan) * flare.pos;
				var flareTilt:Number = fTilt + (tilt - fTilt) * flare.pos;				
				
				flare.image.x = panToX(flarePan);
				flare.image.y = tiltToY(flareTilt);

				if (fDistance <= 5) {
					flare.image.alpha = 0;				
				} else if (fDistance <= _maxFlaresDistance) {					
					flare.image.alpha = fDistance / _maxFlaresDistance;					
				} else if (fDistance <= _maxFlaresDistance * 1.3) {					
					flare.image.alpha = 1 - ((fDistance - _maxFlaresDistance) / (_maxFlaresDistance * 1.3 - _maxFlaresDistance));					
				} else {
					flare.image.alpha = 0;
				}
				printInfo(flare.image.alpha.toFixed(2));
			}
		}
		
		private function hideFlares():void 
		{
			for each(var flare:Object in _flares) {
				flare.image.alpha = 0;
			}			
		}
			
		/*
		 * Set flare brightness
		 * level == 0 -> default brightness
		 * level > 0 -> lighter
		 * level < 0 -> darker
		 */
		private function setBrightness(level:int):void {
			
			colorTransform.redOffset = level;
			colorTransform.greenOffset = level;
			colorTransform.blueOffset = level;
			saladoPlayer.manager.canvas.transform.colorTransform = colorTransform;
			brightness = level;
		}
		
		/*
		 * Convert pan to x coordinate
		 */
		private function panToX(pan:Number):int {
			var w:Number = saladoPlayer.manager.boundsWidth;
			var cPan:Number = saladoPlayer.manager._pan;
			var fov:Number = saladoPlayer.manager.fieldOfView;
			
			return Math.round(
				w * 0.5 + 
				(Math.tan((pan - cPan) * __toRadians) * w * 0.5) /
				(Math.tan(fov * 0.5 * __toRadians))
				);
		}
		
		/*
		 * Convert tilt to y coordinate
		 */		
		private function tiltToY(tilt:Number):int {
			var w:Number = saladoPlayer.manager.boundsWidth;
			var h:Number = saladoPlayer.manager.boundsHeight;
			var cTilt:Number = saladoPlayer.manager._tilt;
			var fov:Number = saladoPlayer.manager.fieldOfView;
			var vFov:Number = __toDegrees * 2 * Math.atan((h / w)
				* Math.tan(__toRadians * 0.5 * fov));
			
			return Math.round(
				h * 0.5 + 
				(Math.tan((cTilt - tilt) * __toRadians) * h * 0.5) /
				(Math.tan(vFov * 0.5 * __toRadians))
				);
		}		
		
		private var __toDegrees:Number = 180 / Math.PI;
		private var __toRadians:Number = Math.PI / 180;		
	}
}
