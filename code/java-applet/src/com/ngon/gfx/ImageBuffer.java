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
import java.awt.Graphics;

public abstract class ImageBuffer {
    
    public int width;
    public int height;
    
    protected Component component;
    protected Graphics graphics = null;
    protected int[] pixels = null;
    protected int[][] mask = null;
    
    public abstract Graphics getGraphics();
    public abstract int[] grabPixels();
    
    public int[] getPixels() {
        if (pixels == null) {
            pixels = new int[width * height];
        }
        return pixels;
    }
    
    public void setComponent(Component component) {
        this.component = component;
    }
    
    public void setSize(int width, int height) {
        this.width = width;
        this.height = height;
    }
    
    public void setPixels(int[] pixels) {
        this.pixels = pixels;
    }
    
    /*
     * Assume all channels equal.
     */
    public int[] getMask() {
        return getChannelMask(RGB.BLU_CHAN, 0);
    }
    
    public int[] getChannelMask(int channel, int bitshift) {
        if (mask != null && mask[channel] != null) {
            return mask[channel];
        }
        if (pixels == null) {
            pixels = getPixels();
        }
        if (mask == null) {
            mask = new int[3][];
        }
        if (mask[channel] == null) {
            int n = pixels.length;
            mask[channel] = new int[n];
            for (int i = 0; i < n; i++) {
                mask[channel][i] = 
                    (pixels[i] & RGB.CHANNELS[channel]) << bitshift;
            }
        }
        return mask[channel];
    }
    
    public void reset() {
        pixels = null;
        mask = null;
    }
}
