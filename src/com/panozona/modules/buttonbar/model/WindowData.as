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
package com.panozona.modules.buttonbar.model {
	
	import com.panozona.modules.buttonbar.events.WindowEvent;
	import com.panozona.modules.buttonbar.model.structure.Window;
	import com.panozona.player.module.data.property.Size;
	import flash.events.EventDispatcher;
	
	public class WindowData extends EventDispatcher{
		
		public const window:Window = new Window();
		
		private var _open:Boolean;
		private var _size:Size;
		
		public function WindowData ():void {
			_size = new Size(1, 1);
		}
		
		public function get open():Boolean{return _open}
		public function set open(value:Boolean):void {
			if (value == _open) return;
			_open = value;
			dispatchEvent(new WindowEvent(WindowEvent.CHANGED_OPEN));
		}
		
		public function get size():Size { return _size;}
		public function set size(value:Size):void {
			_size = value;
			dispatchEvent(new WindowEvent(WindowEvent.CHANGED_SIZE));
		}
	}
}