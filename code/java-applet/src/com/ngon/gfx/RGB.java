/*
 * com/ngon/gfx/RGB.java
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

/*
 * class RGB
 */
public class RGB {
    
    public static final int BLK             = 0x000000;
    public static final int WHT             = 0xFFFFFF;
    public static final int RED             = 0xFF0000;
    public static final int GRN             = 0x00FF00;
    public static final int BLU             = 0x0000FF;
    public static final int YLW             = RED | GRN;
    public static final int CYN             = GRN | BLU;
    public static final int PRP             = BLU | RED;
    public static final int GRY             = 0x7F7F7F;
    
    public static final int[] CHANNELS = { RED, GRN, BLU };
    public static final int RED_CHAN        = 0;
    public static final int GRN_CHAN        = 1;
    public static final int BLU_CHAN        = 2;
    
    public int rgb;
    public int r;
    public int g;
    public int b;
    
    public RGB(int rgb) {
        this.rgb = rgb;
        this.r = getR(rgb);
        this.g = getG(rgb);
        this.b = getB(rgb);
    }
    
    public static int getR(int rgb) {
        return ((rgb & RED) >> 16) & 0xFF;
    }
    
    public static int getG(int rgb) {
        return ((rgb & GRN) >> 8) & 0xFF;
    }
    
    public static int getB(int rgb) {
        return (rgb & BLU) & 0xFF;
    }
    
    public static int mix(int rgb1, int rgb2) {
        return (((rgb1 & RED + rgb2 & RED) >> 1) & RED) |
               (((rgb1 & GRN + rgb2 & GRN) >> 1) & GRN) |
               (((rgb1 & BLU + rgb2 & BLU) >> 1) & BLU);
    }
    
    public static int[] generateFade(int rgb1, int rgb2, int nSteps) {
        int[] fadeRGB = new int[nSteps];
        int r1 = getR(rgb1);
        int g1 = getG(rgb1);
        int b1 = getB(rgb1);
        int dr = getR(rgb2) - r1;
        int dg = getG(rgb2) - g1;
        int db = getB(rgb2) - b1;
        int n = nSteps - 1;
        for (int i = 1; i < n; i++) {
            fadeRGB[i] = (((r1 + dr*i/n) << 16) & RED) |
                         (((g1 + dg*i/n) <<  8) & GRN) |
                          ((b1 + db*i/n)        & BLU);
        }
        fadeRGB[0] = rgb1;
        fadeRGB[n] = rgb2;
        return fadeRGB;
    }
}

