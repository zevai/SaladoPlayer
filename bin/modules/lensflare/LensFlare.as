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
	import flash.geom.ColorTransform;
	import flash.events.Event;	
	
	public class LensFlare extends Module {
		
		private var lensFlareData:LensFlareData;
		private var colorTransform:ColorTransform = new ColorTransform();
		private var flareBrightness:int;
		
		private var panoramaEventClass:Class;
		
		/* 
		 * Current panorama data
		 */
		private var fPano:String;
		private var fPan:Number;
		private var fTilt:Number;		
		
		/* 
		 * Current distance from flare point
		 */
		private var fDistance:Number;
		
		/* 
		 * Global flare setings
		 */
		protected var _maxFlareBrightnessDistance:Number;
		protected var _maxFlareBrightness:Number;
		
		/* 
		 * Panoramas settings
		 */
		protected var _panos:Object = new Object();
		
		
		public function LensFlare():void {
			
			super("LensFlare", "0.1-dev", "http://panozona.com/wiki/Module:LensFlare");
		}
		
		override protected function moduleReady(moduleData:ModuleData):void {
			
			lensFlareData = new LensFlareData(moduleData, saladoPlayer);
			
			panoramaEventClass = ApplicationDomain.currentDomain.getDefinition("com.panozona.player.manager.events.PanoramaEvent") as Class;
			
			// save global settings
			_maxFlareBrightnessDistance = lensFlareData.settings.maxDistance;
			_maxFlareBrightness = lensFlareData.settings.maxBrightness;
			
			// save panoramas settings
			for each (var panorama:Panorama in lensFlareData.panoramas.getChildrenOfGivenClass(Panorama)) {
				_panos[panorama.id] = {"pan": panorama.pan, "tilt": panorama.tilt};
			}			
			
			saladoPlayer.manager.addEventListener(panoramaEventClass.PANORAMA_LOADED, onPanoramaLoaded, false, 0 , true);
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		private function onPanoramaLoaded(e:Event):void {
			var currentPano:String = saladoPlayer.manager.currentPanoramaData.id;
			if (_panos[currentPano]) {
				fPano = currentPano;
				fPan = _panos[currentPano].pan;
				fTilt = _panos[currentPano].tilt;
			} else {
				fPano = null;
			}
		}		
		
		private function enterFrameHandler(event:Event):void {
			if (fPano) {
				lensFlareEffect(saladoPlayer.manager._pan, saladoPlayer.manager._tilt);
			}			
		}
		
		private function lensFlareEffect(pan:Number, tilt:Number):void {
			
			fDistance = Math.sqrt(Math.pow(pan - fPan, 2) + Math.pow(tilt - fTilt, 2));
			
			if (fDistance == 0) {
				if (flareBrightness != _maxFlareBrightness) {
					setBrightness(_maxFlareBrightness);
				}				
			} else if(fDistance <= _maxFlareBrightnessDistance) {
				setBrightness(_maxFlareBrightness - Math.round(fDistance * _maxFlareBrightness / _maxFlareBrightnessDistance));
			} else {
				if (flareBrightness != 0) {
					setBrightness(0);
				}
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
			saladoPlayer.manager.transform.colorTransform = colorTransform;
			flareBrightness = level;
		}
	}
}
