/*
 * com/ngon/gfx/ImageBuffer.java
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

package com.ngon.gfx;

import java.awt.Component;
import java.util.StringTokenizer;

public class ImageBufferFactory {
    
    private Component c;
    private Class cl;
    
    public ImageBufferFactory(Component c) {
        this.c = c;
        String javaVersion = System.getProperty("java.version");
        StringTokenizer st = new StringTokenizer(javaVersion, ".");
        int majorVersion = Integer.parseInt(st.nextToken());
        int minorVersion = Integer.parseInt(st.nextToken());
        if (!(majorVersion >= 1 && minorVersion >= 1)) {
            System.err.println("You must be running Java version 1.1+");
        } else if (majorVersion == 1 && minorVersion == 1) {
            try {
                cl = Class.forName("com.ngon.gfx.ImageBuffer11");
            } catch (ClassNotFoundException e) {
                System.err.println(e);
            }
        } else {
            try {
                cl = Class.forName("com.ngon.gfx.ImageBuffer12");
            } catch (ClassNotFoundException e) {
                System.err.println(e);
            }
        }
    }
    
    public ImageBuffer create(int width, int height) {
        ImageBuffer imgBuf = null;
        try {
            imgBuf = (ImageBuffer) cl.newInstance();
            imgBuf.setSize(width, height);
            imgBuf.setComponent((Component) this.c);
        } catch (Exception e) {
            System.err.println(e);
        }
        return imgBuf;
    }
}
