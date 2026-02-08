/*
 * com/ngon/gfx/PixelSurface.java
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

import com.ngon.gfx.fonts.Del;
import java.awt.FontMetrics;

/*
 * class PixelSurface
 */
public class PixelSurface {
    
    int width;
    int height;
    int[] pixels;
    
    public PixelSurface(int width, int height) {
        this.width = width;
        this.height = height;
        pixels = new int[width * height];
    }
    
    public int[] getPixels() {
        return pixels;
    }
    
    public void copy(PixelSurface mirror) {
        System.arraycopy(mirror.pixels, 0, pixels, 0, width * height);
    }
    
    public void paintField(int x, int y, int[] rgbField, 
                           int fieldWidth, int fieldHeight) {
        for (int j = 0; j < fieldHeight; j++) {
            System.arraycopy(rgbField, j * fieldWidth, 
                             pixels, x + (y+j) * width, fieldWidth);
        }
    }
    
    public void fillRect(int x, int y, int w, int h, int rgb) {
        for (int j = y; j < y + h; j++) {
            for (int i = x; i < x + w; i++) {
                PixelDrawer.setPixel(i, j, rgb, pixels, width, height);
            }
        }
    }
    
    public void copyRect(int srcX, int srcY, int srcW, int srcH, 
                         int dstX, int dstY, int copyMode) {
        PixelDrawer.copyRect(srcX, srcY, srcW, srcH, pixels, width, height,
                             dstX, dstY, pixels, width, height, copyMode);
    }
                
    public void drawWuLine(int x1, int y1, int x2, int y2, int rgb) {
        PixelDrawer.drawWuLine(x1, y1, x2, y2, rgb, pixels, width, height);
    }
    
    public void paintMask(int[] mask, int maskW, int x, int y, int rgb) {
        PixelDrawer.paintMask(mask, maskW, x, y, rgb, pixels, width, height);
    }
    
    public void paintNumber(int nr, int precision, int x, int y, int rgb) {
        // TODO Generalize to other fonts.
        Del.paintNumber(nr, precision, x, y, rgb, pixels, width, height);
    }
    
    public void drawString(String s, int x, int y, FontPixels font, int rgb) {
        char[] chars = s.toCharArray();
        int p = x;
        FontMetrics fm = font.getFontMetrics();
        for (int i = 0; i < chars.length; i++) {
            char c = chars[i];
            ImageBuffer ib = font.getImageBuffer(c);
            ib.grabPixels();
            paintMask(ib.getMask(), ib.width, 
                      p - font.padding.x, y - font.padding.y, rgb);
            p += fm.charWidth(c);
        }
    }
    
    public static int[] mapField(int[] intField, int[] rgbMap, int len) {
        int[] rgbField = new int[len];
        for (int p = 0; p < len; p++) {
            rgbField[p] = rgbMap[intField[p]];
        }
        return rgbField;
    }
}
