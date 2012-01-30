﻿/*
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
package com.panozona.modules.lensflare.model {	
	
	import com.panozona.player.module.data.property.Location;
	
	public class Panorama {
		
		public var id:String = null;		
		public var location:Location = new Location();
		
		// path to local flares png grid
		public var path:String = null;

		public var positions:String = null;
		
		public var brightness:SettingsBrightness = new SettingsBrightness( -1, -1);
	}
}