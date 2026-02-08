/*
 * com/ngon/gfx/PixelDrawer.java
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
 * class PixelDrawer
 */
public class PixelDrawer {
    
    public static final int COPY_DIRECT                 = 0;
    public static final int COPY_FLIP_HORIZONTALLY      = 1;
    public static final int COPY_FLIP_VERTICALLY        = 2;
    
    public static void drawWuLine(int x1, int y1, int x2, int y2, int rgb,
                                  int[] dst, int dstW, int dstH) {
        long x, y, inc;
        int dx = x2 - x1;
        int dy = y2 - y1;
        if (dx == 0 && dy == 0) {
            return;
        }
        int alpha;
        if (Math.abs(dx) > Math.abs(dy)) {
            if (dx < 0) {
                dx = -dx;
                dy = -dy;
                int save;
                save = x1; x1 = x2; x2 = save;
                save = y1; y1 = y2; y2 = save;
            }
            x = x1 << 16;
            y = y1 << 16;
            inc = (dy << 16) / dx;
            while ((x >> 16) < x2) {
                mixPixel((int) (x >> 16), (int) (y >> 16),
                         rgb, (int) (~y >> 8) & 0xFF, dst, dstW, dstH);
                mixPixel((int) (x >> 16), (int) (y >> 16) + 1, 
                         rgb, (int) (y >> 8) & 0xFF, dst, dstW, dstH);
                x += (1 << 16);
                y += inc;
            }
        } else {
            if (dy < 0) {
                dx = -dx;
                dy = -dy;
                int save;
                save = x1; x1 = x2; x2 = save;
                save = y1; y1 = y2; y2 = save;
            }
            x = x1 << 16;
            y = y1 << 16;
            inc = (dx << 16) / dy;
            while ((y >> 16) < y2) {
                mixPixel((int) (x >> 16), (int) (y >> 16), 
                         rgb, (int) (~x >> 8) & 0xFF, dst, dstW, dstH);
                mixPixel((int) (x >> 16) + 1, (int) (y >> 16), 
                         rgb, (int) (x >> 8) & 0xFF, dst, dstW, dstH);
                x += inc;
                y += (1 << 16);
            }
        }
    }
    
    public static void paintPixel(int x, int y, int rgb, int alpha, 
                                  int[] dst, int dstW, int dstH) {
        if (alpha == 0) {
            return;
        }
        if (alpha == 255) {
            setPixel(x, y, rgb, dst, dstW, dstH);
        } else {
            mixPixel(x, y, rgb, alpha, dst, dstW, dstH);
        }
    }
    
    public static void setPixel(int x, int y, int rgb, 
                                int[] dst, int dstW, int dstH) {
        if (x < 0 || y < 0 || x >= dstW || y >= dstH) {
            return;
        }
        dst[x + y * dstW] = rgb;
    }
    
    public static void mixPixel(int x, int y, int rgb, int alpha,
                                int[] dst, int dstW, int dstH) {
        if (x < 0 || y < 0 || x >= dstW || y >= dstH) {
            return;
        }
        int p = x + y * dstW;
        int rgb0 = dst[p];
        int a = alpha;
        int r = (rgb & RGB.RED) >> 16;
        int g = (rgb & RGB.GRN) >>  8;
        int b = (rgb & RGB.BLU);
        int r0 = (rgb0 & RGB.RED) >> 16;
        int g0 = (rgb0 & RGB.GRN) >>  8;
        int b0 = (rgb0 & RGB.BLU);
        int rMix = r0 + ((a * (r - r0)) >> 9);
        int gMix = g0 + ((a * (g - g0)) >> 9);
        int bMix = b0 + ((a * (b - b0)) >> 9);
        dst[p] = (rMix << 16) & RGB.RED | 
                 (gMix <<  8) & RGB.GRN | 
                  bMix        & RGB.BLU;
    }
    
    public static void paintMask(int[] mask, int maskW, int x, int y, int rgb,
                                 int[] dst, int dstW, int dstH) {
        int maskH = mask.length / maskW;
        int p = x + y * dstW;
        int k = 0;
        int r = rgb & RGB.RED;
        int g = rgb & RGB.GRN;
        int b = rgb & RGB.BLU;
        for (int j = 0; j < maskH; j++) {
            for (int i = 0; i < maskW; i++) {
                paintPixel(x + i, y + j, rgb, mask[k], dst, dstW, dstH);
                k++;
            }
        }
    }
    
    public static void copyRect(int srcX, int srcY, int srcW, int srcH, 
                                int[] srcField, int srcFieldW, int srcFieldH,
                                int dstX, int dstY, 
                                int[] dstField, int dstFieldW, int dstFieldH,
                                int copyMode) {
        int i, j, p, q;
        switch (copyMode) {
            case COPY_DIRECT:
                for (j = 0; j < srcH; j++) {
                    System.arraycopy(srcField, srcX + (srcY+j) * srcFieldW, 
                                     dstField, dstX + (dstY+j) * dstFieldW, 
                                     srcW);
                }
                break;
            case COPY_FLIP_HORIZONTALLY:
                for (j = 0; j < srcH; j++) {
                    p = srcX + (srcY+j) * srcFieldW;
                    q = dstX + (dstY+j) * dstFieldW + srcW - 1;
                    for (i = 0; i < srcW; i++) {
                        dstField[q--] = srcField[p++];
                    }
                }
                break;
            case COPY_FLIP_VERTICALLY:
                for (i = 0; i < srcW; i++) {
                    p = srcX + i + srcY * srcFieldW;
                    q = dstX + i + (dstY+srcH-1) * dstFieldW;
                    for (j = 0; j < srcH; j++) {
                        dstField[q] = srcField[p];
                        q -= dstFieldW; p += srcFieldW;
                    }
                }
                break;
        }
    }
}

