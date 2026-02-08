/*
 * com/ngon/gfx/FontPixels.java
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

import java.awt.Color;
import java.awt.Component;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Point;
import java.util.Hashtable;

/*
 * class FontPixels
 */
public class FontPixels extends Hashtable {
    
    public static final char[] SUPPORTED_CHARS = {
        'a','b','c','d','e','f','g','h','i','j','k','l','m',
        'n','o','p','q','r','s','t','u','v','w','x','y','z',
        'A','B','C','D','E','F','G','H','I','J','K','L','M',
        'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
        '0','1','2','3','4','5','6','7','8','9',',','.','/',
        '<','>','?',';','\'',':','"','[',']','\\','{','}','|',
        '`','~','!','@','#','$','%','^','&','*','(',')','-',
        '=','_','+',' '
    };
    
    public int maxFontAscent, maxFontDescent, lineHeight;
    public Point padding;
    
    protected Font font;
    protected Component component;
    
    protected FontMetrics fm;
    
    public FontPixels(Font font, Component component) {
        super(SUPPORTED_CHARS.length, 1.0f);
        this.font = font;
        this.component = component;
        this.fm = component.getFontMetrics(font);
        this.maxFontAscent = fm.getMaxAscent();
        this.maxFontDescent = fm.getMaxDescent();
        this.lineHeight = maxFontAscent + maxFontDescent;
        this.padding = new Point();
    }
    
    public Object get(Object o) {
        Object getted = super.get(o);
        if (getted == null) {
            getted = super.get(new Character('?'));
        }
        return getted;
    }
    
    public Font getFont() {
        return this.font;
    }
    
    public FontMetrics getFontMetrics() {
        return this.fm;
    }
    
    public ImageBuffer getImageBuffer(char c) {
        return (ImageBuffer) get(new Character(c));
    }
    
    public void preparePixels() {
        ImageBufferFactory ibFactory = new ImageBufferFactory(component);
        for (int i = 0; i < SUPPORTED_CHARS.length; i++) {
            char c = SUPPORTED_CHARS[i];
            int w = fm.charWidth(c);
            ImageBuffer ib = ibFactory.create(w, lineHeight);
            Graphics g = ib.getGraphics();
            g.setColor(Color.black);
            g.fillRect(0, 0, w, lineHeight);
            g.setColor(Color.white);
            g.setFont(font);
            g.drawChars(SUPPORTED_CHARS, i, 1, 0, maxFontAscent);
            put(new Character(c), ib);
        }
    }
}
