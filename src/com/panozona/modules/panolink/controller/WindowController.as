﻿/*
Copyright 2011 Marek Standio.

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
package com.panozona.modules.panolink.controller{
	
	import caurina.transitions.Tweener;
	import com.panozona.modules.panolink.events.WindowEvent;
	import com.panozona.modules.panolink.view.WindowView;
	import com.panozona.player.module.data.property.Align;
	import com.panozona.player.module.data.property.Transition;
	import com.panozona.player.module.Module;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.ApplicationDomain;
	
	public class WindowController{
		
		private var _module:Module;
		private var _windowView:WindowView;
		
		private var _linkController:LinkController;
		
		public function WindowController(windowView:WindowView, module:Module) {
			
			_module = module;
			_windowView = windowView;
			
			_linkController = new LinkController(windowView.linkView, module);
			
			_windowView.windowData.addEventListener(WindowEvent.CHANGED_OPEN, onOpenChange, false, 0, true);
			
			//should be pano change
			_module.saladoPlayer.manager.addEventListener(MouseEvent.MOUSE_DOWN, handlePlayerClick, false, 0, true);
			
			var ViewEventClass:Class = ApplicationDomain.currentDomain.getDefinition("com.panosalado.events.ViewEvent") as Class;
			_module.saladoPlayer.manager.addEventListener(ViewEventClass.BOUNDS_CHANGED, handleResize, false, 0, true);
			handleResize();
			
			var panoramaEventClass:Class = ApplicationDomain.currentDomain.getDefinition("com.panozona.player.manager.events.PanoramaEvent") as Class;
			_module.saladoPlayer.manager.addEventListener(panoramaEventClass.PANORAMA_STARTED_LOADING, onPanoramaStartedLoading, false, 0, true);
		}
		
		private function onPanoramaStartedLoading(loadPanoramaEvent:Object):void {
			var panoramaEventClass:Class = ApplicationDomain.currentDomain.getDefinition("com.panozona.player.manager.events.PanoramaEvent") as Class;
			_module.saladoPlayer.manager.removeEventListener(panoramaEventClass.PANORAMA_STARTED_LOADING, onPanoramaStartedLoading);
			if (_windowView.windowData.open){
				_module.saladoPlayer.manager.runAction(_windowView.panoLinkData.windowData.window.onOpen);
			}else {
				_module.saladoPlayer.manager.runAction(_windowView.panoLinkData.windowData.window.onClose);
			}
		}
		
		private function handleResize(event:Event = null):void {
			placeWindow();
		}
		
		private function handlePlayerClick(event:Event = null):void {
			_windowView.panoLinkData.windowData.open = false;
		}
		
		private var initPan:Number;
		private var initTilt:Number;
		private var initFov:Number;
		private function onOpenChange(e:Event):void {
			if (_windowView.windowData.open) {
				_module.saladoPlayer.manager.runAction(_windowView.panoLinkData.windowData.window.onOpen);
				openWindow();
				
				initPan = _module.saladoPlayer.manager.pan;
				initTilt = _module.saladoPlayer.manager.tilt;
				initFov = _module.saladoPlayer.manager.fieldOfView;
				_module.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			}else {
				_module.saladoPlayer.manager.runAction(_windowView.panoLinkData.windowData.window.onClose);
				closeWindow();
			}
		}
		
		private function onEnterFrame(e:Event):void {
			if (_module.saladoPlayer.manager.pan != initPan ||
				_module.saladoPlayer.manager.tilt != initTilt ||
				_module.saladoPlayer.manager.fieldOfView != initFov) {
					_windowView.panoLinkData.windowData.open = false;
					_module.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		private function openWindow():void {
			_windowView.visible = true;
			_windowView.mouseEnabled = true;
			_windowView.mouseChildren = true;
			var tweenObj:Object = new Object();
			tweenObj["time"] = _windowView.panoLinkData.windowData.window.openTween.time;
			tweenObj["transition"] = _windowView.panoLinkData.windowData.window.openTween.transition;
			if (_windowView.panoLinkData.windowData.window.transition.type == Transition.FADE){
				tweenObj["alpha"] = 1;
			}else{
				tweenObj["x"] = getWindowOpenX();
				tweenObj["y"] = getWindowOpenY();
			}
			Tweener.addTween(_windowView, tweenObj);
		}
		
		private function closeWindow():void {
			var tweenObj:Object = new Object();
			tweenObj["time"] = _windowView.panoLinkData.windowData.window.closeTween.time;
			tweenObj["transition"] = _windowView.panoLinkData.windowData.window.closeTween.transition;
			tweenObj["onComplete"] = closeWindowOnComplete;
			if (_windowView.panoLinkData.windowData.window.transition.type == Transition.FADE) {
				tweenObj["alpha"] = 0;
			}else{
				tweenObj["x"] = getWindowCloseX();
				tweenObj["y"] = getWindowCloseY();
			}
			_windowView.mouseEnabled = false;
			_windowView.mouseChildren = false;
			Tweener.addTween(_windowView, tweenObj);
		}
		
		private function closeWindowOnComplete():void {
			_windowView.visible = false;
		}
		
		private function placeWindow(e:Event = null):void {
			if (_windowView.windowData.open) {
				Tweener.addTween(_windowView, {x:getWindowOpenX(), y:getWindowOpenY()});  // no time parameter
				_windowView.alpha = 1;
				_windowView.visible = true;
			}else {
				Tweener.addTween(_windowView, {x:getWindowCloseX(), y:getWindowCloseY()}); // no time parameter
				if(_windowView.panoLinkData.windowData.window.transition.type == Transition.FADE){
					_windowView.alpha = 0;
				}
				_windowView.visible = false;
			}
		}
		
		private function getWindowOpenX():Number {
			var result:Number = 0;
			switch(_windowView.panoLinkData.windowData.window.align.horizontal) {
				case Align.RIGHT:
					result += _module.saladoPlayer.manager.boundsWidth 
						- _windowView.panoLinkData.windowData.window.size.width 
						+ _windowView.panoLinkData.windowData.window.move.horizontal;
				break;
				case Align.LEFT:
					result += _windowView.panoLinkData.windowData.window.move.horizontal;
				break;
				default: // CENTER
					result += (_module.saladoPlayer.manager.boundsWidth 
						- _windowView.panoLinkData.windowData.window.size.width) * 0.5 
						+ _windowView.panoLinkData.windowData.window.move.horizontal;
			}
			return result;
		}
		
		private function getWindowOpenY():Number{
			var result:Number = 0;
			switch(_windowView.panoLinkData.windowData.window.align.vertical) {
				case Align.TOP:
					result += _windowView.panoLinkData.windowData.window.move.vertical;
				break;
				case Align.BOTTOM:
					result += _module.saladoPlayer.manager.boundsHeight 
						- _windowView.panoLinkData.windowData.window.size.height
						+ _windowView.panoLinkData.windowData.window.move.vertical;
				break;
				default: // MIDDLE
					result += (_module.saladoPlayer.manager.boundsHeight 
						- _windowView.panoLinkData.windowData.window.size.height) * 0.5
						+ _windowView.panoLinkData.windowData.window.move.vertical;
			}
			return result;
		}
		
		private function getWindowCloseX():Number {
			var result:Number = 0;
			switch(_windowView.panoLinkData.windowData.window.transition.type){
				case Transition.SLIDE_RIGHT:
					result = _module.saladoPlayer.manager.boundsWidth;
				break;
				case Transition.SLIDE_LEFT:
					result = -_windowView.panoLinkData.windowData.window.size.width;
				break;
				default: //SLIDE_UP, SLIDE_DOWN
					result = getWindowOpenX();
			}
			return result;
		}
		
		private function getWindowCloseY():Number{
			var result:Number = 0;
			switch(_windowView.panoLinkData.windowData.window.transition.type){
				case Transition.SLIDE_UP:
					result = -_windowView.panoLinkData.windowData.window.size.height;
				break;
				case Transition.SLIDE_DOWN:
					result = _module.saladoPlayer.manager.boundsHeight;
				break;
				default: //SLIDE_LEFT, SLIDE_RIGHT
					result = getWindowOpenY();
			}
			return result;
		}
	}
}