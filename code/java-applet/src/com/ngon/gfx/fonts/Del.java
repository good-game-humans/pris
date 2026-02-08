/*
 * com/ngon/gfx/fonts/Del.java
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

package com.ngon.gfx.fonts;

import com.ngon.gfx.PixelDrawer;

/**
 * class Del
 */
public class Del {

    public static final int LETTER_E_CAP_MASK[] = 
            {1,1,1,1,1,1,
             1,0,0,0,0,0,
             1,0,0,0,0,0,
             1,1,1,1,1,0,
             1,0,0,0,0,0,
             1,0,0,0,0,0,
             1,0,0,0,0,0,
             1,1,1,1,1,1};
    
    public static final int LETTER_X_MASK[] = 
            {0,0,0,0,0,
             0,0,0,0,0,
             0,0,0,0,0,
             1,0,0,0,1,
             0,1,0,1,0,
             0,0,1,0,0,
             0,1,0,1,0,
             1,0,0,0,1};
    
    public static final int LETTER_I_MASK[] = 
            {0,0,0,
             1,1,0,
             0,0,0,
             0,1,0,
             0,1,0,
             0,1,0,
             0,1,0,
             0,1,1};
    
    public static final int LETTER_T_MASK[] = 
            {0,0,0,0,0,0,
             0,1,1,0,0,0,
             0,0,1,0,0,0,
             1,1,1,1,1,1,
             0,0,1,0,0,0,
             0,0,1,0,0,0,
             0,0,1,0,0,0,
             0,0,1,1,1,0};
    
    public static final int LETTER_D_MASK[] = 
            {0,0,0,0,0,1,1,
             0,0,0,0,0,1,0,
             0,0,0,0,0,1,0,
             1,1,1,1,1,1,0,
             1,0,0,0,0,1,0,
             1,0,0,0,0,1,0,
             1,0,0,0,0,1,0,
             1,1,1,1,1,1,0};
    
    public static final int LETTER_E_MASK[] = 
            {0,0,0,0,0,0,
             0,0,0,0,0,0,
             1,1,1,1,1,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,1,1,1,1,1,
             1,0,0,0,0,0,
             1,1,1,1,1,0};
    
    public static final int LETTER_L_MASK[] = 
            {1,1,0,0,
             0,1,0,0,
             0,1,0,0,
             0,1,0,0,
             0,1,0,0,
             0,1,0,0,
             0,1,0,0,
             0,1,1,1};
    
    public static final int LETTER_T_ALT_MASK[] = 
            {0,0,1,0,0,0,
             0,0,1,0,0,0,
             1,1,1,1,1,1,
             0,0,1,0,0,0,
             0,0,1,0,0,0,
             0,0,1,0,0,0,
             0,0,1,0,0,0,
             0,0,1,1,1,0};
    
    public static final int LETTER_R_MASK[] = 
            {0,0,0,0,0,0,
             0,0,0,0,0,0,
             1,1,0,0,0,0,
             0,1,1,1,1,1,
             0,1,0,0,0,1,
             0,1,0,0,0,0,
             0,1,0,0,0,0,
             0,1,0,0,0,0};
    
    public static final int LETTER_F_MASK[] = 
            {0,0,0,0,0,0,0,0,0,
             0,0,0,1,1,1,1,1,0,
             0,0,0,1,0,0,0,0,0,
             0,0,0,1,0,0,0,0,0,
             1,1,1,1,1,1,1,1,1,
             0,0,0,1,0,0,0,0,0,
             0,0,0,1,0,0,0,0,0,
             0,0,0,1,0,0,0,0,0};
    
    public static final int LETTER_A_MASK[] = 
            {0,0,0,0,0,0,
             0,0,0,0,0,0,
             0,1,1,1,1,0,
             0,0,0,0,1,0,
             1,1,1,1,1,0,
             1,0,0,0,1,0,
             1,0,0,0,1,0,
             1,1,1,1,1,1};
    
    public static final int LETTER_Z_MASK[] = 
            {0,0,0,0,0,
             1,1,1,1,1,
             1,0,0,0,1,
             0,0,0,1,0,
             0,0,1,0,0,
             0,1,0,0,0,
             1,0,0,0,1,
             1,1,1,1,1};
    
    public static final int LETTER_O_MASK[] = 
            {0,0,0,0,0,0,
             0,0,0,0,0,0,
             0,0,0,0,0,0,
             1,1,1,1,1,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,1,1,1,1,1};
    
    public static final int LETTER_M_MASK[] = 
            {0,0,0,0,0,0,0,0,
             0,0,0,0,0,0,0,0,
             1,1,1,1,1,1,1,1,
             0,1,0,0,1,0,0,1,
             0,1,0,0,1,0,0,1,
             0,1,0,0,1,0,0,1,
             0,1,0,0,1,0,0,1,
             0,1,0,0,1,0,0,1};
    
    public static final int LETTER_Y_MASK[] = 
            {0,0,0,0,0,0,
             0,0,0,0,0,0,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,1,1,1,1,1,
             0,0,0,0,0,1,
             0,0,1,1,1,1};
    
    public static final int LETTER_C_MASK[] = 
            {0,0,0,0,0,0,
             0,0,0,0,0,0,
             1,1,1,1,1,1,
             1,0,0,0,0,1,
             1,0,0,0,0,0,
             1,0,0,0,0,0,
             1,0,0,0,0,1,
             1,1,1,1,1,1};
    
    public static final int SM_LETTER_O_CAP_MASK[] = 
            {1,1,1,1,1,1,1,
             1,0,0,0,0,0,1,
             1,0,0,0,0,0,1,
             1,0,0,0,0,0,1,
             1,0,0,0,0,0,1,
             1,0,0,0,0,0,1,
             1,1,1,1,1,1,1};
    
    public static final int SM_LETTER_F_MASK[] = 
            {0,0,0,0,0,
             0,1,1,1,0,
             0,1,0,0,0,
             1,1,1,1,1,
             0,1,0,0,0,
             0,1,0,0,0,
             0,1,0,0,0};
    
    public static final int SM_LETTER_N_MASK[] = 
            {0,0,0,0,0,
             0,0,0,0,0,
             1,0,0,0,0,
             1,1,1,1,1,
             1,0,0,0,1,
             1,0,0,0,1,
             1,0,0,0,1};
    
    public static final int SM_NUMBER_1_MASK[] = 
            {1,1,0,
             0,1,0,
             0,1,0,
             0,1,0,
             0,1,0,
             0,1,0,
             1,1,1};
    
    public static final int SM_NUMBER_2_MASK[] = 
            {1,1,1,1,0,
             1,0,0,1,0,
             0,0,0,1,0,
             0,0,1,0,0,
             0,1,0,0,0,
             1,0,0,0,1,
             1,1,1,1,1};
    
    public static final int SM_NUMBER_3_MASK[] = 
            {1,1,1,1,
             1,0,0,1,
             0,0,0,1,
             0,1,1,1,
             0,0,0,1,
             1,0,0,1,
             1,1,1,1};
    
    public static final int SM_NUMBER_4_MASK[] = 
            {1,0,0,1,0,
             1,0,0,1,0,
             1,0,0,1,0,
             1,1,1,1,1,
             0,0,0,1,0,
             0,0,0,1,0,
             0,0,0,1,0};
    
    public static final int SM_NUMBER_5_MASK[] = 
            {1,1,1,1,
             1,0,0,0,
             1,0,0,0,
             1,1,1,1,
             0,0,0,1,
             1,0,0,1,
             1,1,1,1};
    
    public static final int SM_NUMBER_6_MASK[] = 
            {1,1,0,0,0,
             1,0,0,0,0,
             1,0,0,0,0,
             1,1,1,1,1,
             1,0,0,0,1,
             1,0,0,0,1,
             1,1,1,1,1};
    
    public static final int SM_NUMBER_7_MASK[] = 
            {1,1,1,1,1,
             1,0,0,0,1,
             0,0,0,0,1,
             0,0,0,0,1,
             0,0,0,0,1,
             0,0,0,0,1,
             0,0,0,0,1};
    
    public static final int SM_NUMBER_8_MASK[] = 
            {0,1,1,1,1,
             0,1,0,0,1,
             0,1,0,0,1,
             1,1,1,1,1,
             1,0,0,0,1,
             1,0,0,0,1,
             1,1,1,1,1};
    
    public static final int SM_NUMBER_9_MASK[] = 
            {1,1,1,1,1,
             1,0,0,0,1,
             1,0,0,0,1,
             1,1,1,1,1,
             0,0,0,0,1,
             0,0,0,0,1,
             0,0,0,0,1};
    
    public static final int SM_NUMBER_0_MASK[] = 
            {1,1,1,1,
             1,0,0,1,
             1,0,0,1,
             1,0,0,1,
             1,0,0,1,
             1,0,0,1,
             1,1,1,1};
    
    public static final int SM_NUMBER_2_NARROW_MASK[] = 
            {1,1,1,1,
             1,0,0,1,
             0,0,0,1,
             0,0,1,0,
             0,1,0,0,
             1,0,0,1,
             1,1,1,1};
    
    public static final int SM_LETTER_B_CAP_MASK[] = 
            {1,1,1,1,1,0,
             1,0,0,0,1,0,
             1,0,0,0,1,0,
             1,1,1,1,1,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,1,1,1,1,1};
    
    public static final int SM_LETTER_W_CAP_MASK[] = 
            {1,1,0,0,0,0,0,0,0,1,
             0,1,0,0,0,1,0,0,0,1,
             0,1,0,0,0,1,0,0,0,1,
             0,1,0,0,0,1,0,0,0,1,
             0,1,0,0,0,1,0,0,0,1,
             0,1,0,0,0,1,0,0,0,1,
             0,1,1,1,1,1,1,1,1,1};
    
    public static final int SM_LETTER_R_CAP_MASK[] = 
            {1,1,1,1,1,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,1,1,1,1,1,
             1,0,0,0,1,0,
             1,0,0,0,1,0,
             1,0,0,0,1,1};
    
    public static final int SM_LETTER_G_CAP_MASK[] = 
            {1,1,1,1,1,0,
             1,0,0,0,0,0,
             1,0,0,0,0,0,
             1,0,0,1,1,1,
             1,0,0,0,0,1,
             1,0,0,0,0,1,
             1,1,1,1,1,1};
    
    public static void paintNumber(int n, int nrDigits, int x, int y, int rgb,
                                   int[] pixels, int pixelsW, int pixelsH) {
        int[] digits = new int[nrDigits];
        int sub = 0;
        for (int j = nrDigits-1; j >= 0; j--) {
            double f = Math.pow((double) 10, j);
            int i = nrDigits - 1 - j;
            digits[i] = (int) ((n - sub) / f);
            sub += digits[i] * f;
        }
        int[] mask;
        for (int i = 0; i < nrDigits; i++) {
            switch (digits[i]) {
            case 0:
                mask = Del.SM_NUMBER_0_MASK; 
                break;
            case 1:
                mask = Del.SM_NUMBER_1_MASK; 
                break;
            case 2:
                mask = Del.SM_NUMBER_2_MASK; 
                break;
            case 3:
                mask = Del.SM_NUMBER_3_MASK; 
                break;
            case 4:
                mask = Del.SM_NUMBER_4_MASK; 
                break;
            case 5:
                mask = Del.SM_NUMBER_5_MASK; 
                break;
            case 6:
                mask = Del.SM_NUMBER_6_MASK; 
                break;
            case 7:
                mask = Del.SM_NUMBER_7_MASK; 
                break;
            case 8:
                mask = Del.SM_NUMBER_8_MASK; 
                break;
            case 9:
                mask = Del.SM_NUMBER_9_MASK; 
                break;
            default:
                mask = Del.SM_NUMBER_0_MASK;
                break;
            }
            int w = mask.length / 7;
            PixelDrawer.paintMask(mask, w, x + 8*i + 7 - w, y, rgb, 
                                  pixels, pixelsW, pixelsH);
        }
    }
}
