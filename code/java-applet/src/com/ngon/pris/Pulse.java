/*
 * com/ngon/pris/Pulse.java
 * Victor Liu > mailto:victor@n-gon.com
 *
 * Copyright (C) 2004 Victor Liu
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version. 
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details. 
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

package com.ngon.pris;

/**
 * class Pulse
 */
final class Pulse {
    
    String text;
    boolean hasEOL;
    int age;
    
    Pulse(String text, boolean hasEOL) {
        this.text = text;
        this.hasEOL = hasEOL;
    }
    
    Pulse(String text, boolean hasEOL, int age) {
        this(text, hasEOL);
        this.age = age;
    }
}
