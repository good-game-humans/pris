/*
 * com/ngon/pris/Pipe.java
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

import com.ngon.app.App;
import com.ngon.gfx.FontPixels;
import com.ngon.gfx.PixelSurface;
import com.ngon.gfx.PixelDrawer;
import com.ngon.gfx.RGB;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Rectangle;
import java.util.Vector;

/**
 * class Pipe
 */
public final class Pipe extends App {
    
    static final Rectangle APP      = new Rectangle(  0,   0, 574, 320);
    
    static final int DT             =  100;
    static final int BEAT_INTERVAL  = 1000;
    static final int DATA_INTERVAL  = 5000;
    static final int CURSOR_T       =  500;
    static final int BLINK_T        =  500;
    
    static final int N_COLS         = 80;
    static final int N_ROWS         = 24;
    
    static final int LINE_H         = 13;
    static final int CHAR_W         =  7;
    
    static final int TEXT_X         =  7;
    static final int TEXT_Y         =  4;
    static final int TEXT_W         = CHAR_W * N_COLS;
    static final int TEXT_H         = LINE_H * N_ROWS;
    
    static final int BORDER_RGB     = 0x3A5C61;
    static final int TEXT_RGB       = 0xC0C0C0;
    static final int CURSOR_RGB     = RGB.RED;
    static final int BLINK_RGB      = 0xCC99FF;
    
    static final int N_FADE_STEPS   = 25;
    static final int BRIGHT_RGB     = 0xBBFF82;
    
    static final String PIPE_SRC    = "http://www.n-gon.com/pris/elbow.pl";
    
    private String pipeSrc = PIPE_SRC;
    private String id;
    
    private Parser parser;
    
    public void init() {
        super.init();
        getAppletParameters();
        parser = new Parser(this);
        setLayout(null);
        setBackground(new Color(43, 62, 67));
    }
    
    public void start() {
        parser.start();
        registerApplet();
        requestFocus();
        super.start();
        setVisible(true);
    }

    public void main(int width, int height) {
        long t0 = System.currentTimeMillis();
        PixelSurface pixels = new PixelSurface(width, height);
        
        // Paint background.
        int[] cornerPix = PixelSurface.mapField(CORNER_PIX, CORNER_RGB, 
                                                CORNER_W * CORNER_H);
        int bkgdRGB = cornerPix[0];
        int scrnRGB = cornerPix[CORNER_W*CORNER_H-1];
        pixels.fillRect(1, 1, width-2, height-2, scrnRGB);
        pixels.fillRect(CORNER_W, 0, width-CORNER_W*2, 1, BORDER_RGB);
        pixels.fillRect(CORNER_W, height-1, width-CORNER_W*2, 1, BORDER_RGB);
        pixels.fillRect(0, CORNER_H, 1, height-CORNER_H*2, BORDER_RGB);
        pixels.fillRect(width-1, CORNER_H, 1, height-CORNER_H*2, BORDER_RGB);
        pixels.paintField(0, 0, cornerPix, CORNER_W, CORNER_H);
        pixels.copyRect(0, 0, CORNER_W, CORNER_H, width-CORNER_W, 0, 
                        PixelDrawer.COPY_FLIP_HORIZONTALLY);
        pixels.copyRect(0, 0, CORNER_W, CORNER_H, 0, height-CORNER_H, 
                        PixelDrawer.COPY_FLIP_VERTICALLY);
        pixels.copyRect(0, height-CORNER_H, CORNER_W, CORNER_H, 
                        width-CORNER_W, height-CORNER_H, 
                        PixelDrawer.COPY_FLIP_HORIZONTALLY);
        
        // Prepare font.
        Font font = new Font("Courier", Font.PLAIN, 11);
        FontPixels fontPixels = new FontPixels(font, this);
        fontPixels.preparePixels();
        
        // Generate fade colors.
        int[] fadeRGB = RGB.generateFade(BRIGHT_RGB, TEXT_RGB, N_FADE_STEPS);
        
        // Both screenLines and reserve are Vectors of Vectors of Pulses.
        // A member of screenLines represents a line (usually containing
        // one Pulse) on the screen.
        // A member of reserve represents a pack of pulses sent in a each
        // beat.
        Vector screenLines = new Vector();
        Vector reserve = new Vector();
        
        // Wait for registration.  
        // Don't do this wait in registerApplet() 
        // since we want to be able to paint.
        String[] response;
        while ((response = parser.getLines()) == null) {
            pixels.fillRect(TEXT_X, TEXT_Y, TEXT_W, LINE_H, scrnRGB);
            if (((System.currentTimeMillis() - t0) / BLINK_T) % 3 < 2) {
                pixels.drawString("Waiting to register", TEXT_X, TEXT_Y, 
                                  fontPixels, BLINK_RGB);
            }
            update(pixels.getPixels());
            try {
                Thread.sleep(DT);
            } catch (InterruptedException e) {}
        }
        
        // Registration should return with unique ID.
        if (response.length == 0 || response[0].startsWith("ERROR")) {
            while (true) {
                pixels.fillRect(TEXT_X, TEXT_Y, TEXT_W, LINE_H, scrnRGB);
                if (((System.currentTimeMillis() - t0) / BLINK_T) % 3 < 2) {
                    pixels.drawString(response[0], TEXT_X, TEXT_Y, 
                                      fontPixels, BLINK_RGB);
                }
                update(pixels.getPixels());
            }
        }
        id = new String(response[0]);
        
        // Retrieve first screen and paint.
        parser.setPipeSrc(getPipeSrc("screen"));
        while ((response = parser.getLines()) == null) {
            pixels.fillRect(TEXT_X, TEXT_Y, TEXT_W, LINE_H, scrnRGB);
            if (((System.currentTimeMillis() - t0) / BLINK_T) % 3 < 2) {
                pixels.drawString("Retrieving from pris...", TEXT_X, TEXT_Y, 
                                  fontPixels, BLINK_RGB);
            }
            update(pixels.getPixels());
            try {
                Thread.sleep(DT);
            } catch (InterruptedException e) {}
        }
        if (response.length > 0) {
            pixels.fillRect(TEXT_X, TEXT_Y, TEXT_W, LINE_H, scrnRGB);
            int j2 = response.length;
            int j1 = (j2 > N_ROWS) ? j2 - N_ROWS : 0;
            for (int j = j1; j < j2; j++) {
                pixels.drawString(response[j], TEXT_X, TEXT_Y + j * LINE_H, 
                                  fontPixels, TEXT_RGB);
                Vector line = new Vector();
                line.addElement(new Pulse(response[j], true, N_FADE_STEPS));
                screenLines.addElement(line);
            }
            update(pixels.getPixels());
        }
        
        // Now begin retrieving data in pulses.
        long beatInterval = BEAT_INTERVAL;
        long tBeat = System.currentTimeMillis() + beatInterval;
        String dataSrc = getPipeSrc("data");
        parser.setPipeSrc(dataSrc);
        int dataUpdateCount = 0;
       
        // Main loop.
        Thread currentThread = Thread.currentThread();
        while (_thread == currentThread) {
            
            long t = System.currentTimeMillis();
            
            // Pull new response.
            Vector packs; // Vector of Vectors, pulled into reserve().
            if ((packs = Parser.parsePacks(parser.getLines())) != null) {
                for (int i = 0; i < packs.size(); i++) {
                    reserve.addElement(packs.elementAt(i));
                }
//                packs.removeAllElements();
                parser.clear();
            }
            
            // Check for next beat.
            if (t > tBeat) {
                
                // Add next pack of lines.
                if (reserve.size() > 0) {
                    
                    Vector pack = (Vector) reserve.elementAt(0);
                    reserve.removeElementAt(0);
                    dataUpdateCount++;
                    
                    if (pack.size() > 0) {
                        
                        // If last screen line hasn't ended,
                        // add first line of pack to it.
                        Pulse lastPulse = getLastPulse(screenLines);
                        if (lastPulse != null && 
                            ! lastPulse.hasEOL && 
                            lastPulse.text.length() < N_COLS) {
                            
                            Vector lastLine = 
                                (Vector) screenLines.lastElement();
                            
                            // Before adding to the last line, first check
                            // that we don't spill over screen edge.  Although
                            // the throttle-data-d.pl daemon does some of this,
                            // it doesn't handle the case of a very long line
                            // spanning more than one beat.
                            int lineLen = getLineLength(lastLine);
                            Pulse cand = (Pulse) pack.elementAt(0);
                            int candLen = cand.text.length();
                            int overEdge = lineLen + candLen - N_COLS;
                            if (overEdge > 0) {
                                int chopPos = candLen - overEdge;
                                if (chopPos >= 0 && chopPos <= candLen) {
                                    lastLine.addElement(
                                        new Pulse(
                                            cand.text.substring(0, chopPos),
                                            true));
                                    cand.text = cand.text.substring(chopPos);
                                }
                            }
                            
                            lastLine.addElement(pack.elementAt(0));
                            pack.removeElementAt(0);
                        }
                        
                        // Add remaining response in pack.
                        for (int i = 0; i < pack.size(); i++) {
                            Vector v = new Vector();
                            v.addElement(pack.elementAt(i));
                            screenLines.addElement(v);
                        }
                        pack.removeAllElements();
                    }
                    
                    // If we're falling behind, decrease the beatInterval.
                    if (t - t0 < (long) (DATA_INTERVAL * (dataUpdateCount-2))) {
                        int tBehind = 
                            (int) (DATA_INTERVAL * dataUpdateCount - t + t0);
                        beatInterval = BEAT_INTERVAL * tBehind /
                                       (DATA_INTERVAL * dataUpdateCount);
                        beatInterval = Math.max(beatInterval, BEAT_INTERVAL/2);
                    } else {
                        beatInterval = BEAT_INTERVAL;
                    }
                }
                
                // If reserve is empty, refill.
                if (reserve.size() == 0 && parser.getLines() == null) {
                    parser.setPipeSrc(dataSrc);
                }
                
                // Advance beat.
                tBeat += beatInterval;
            }
            
            // Remove extra screen lines.
            while (screenLines.size() > N_ROWS) {
                screenLines.removeElementAt(0);
            }
            // If screen is full, and last line has EOL, 
            // remove one more line so last line on screen is clear.
            if (screenLines.size() == N_ROWS) {
                Pulse lastPulse = getLastPulse(screenLines);
                if (lastPulse != null && lastPulse.hasEOL) {
                    screenLines.removeElementAt(0);
                }
            }
            
            // Run through screenLines, painting and fading.
            pixels.fillRect(TEXT_X, TEXT_Y, TEXT_W, TEXT_H, scrnRGB);
            for (int j = 0; j < screenLines.size(); j++) {
                Vector screenLine = (Vector) screenLines.elementAt(j);
                int x = TEXT_X;
                int y = TEXT_Y + j * LINE_H;
                int lineLen = 0;
                for (int k = 0; k < screenLine.size(); k++) {
                    Pulse pulse = (Pulse) screenLine.elementAt(k);
                    int pulseLen = pulse.text.length();
                    int rgb = (pulse.age >= N_FADE_STEPS) ? TEXT_RGB 
                                                          : fadeRGB[pulse.age];
                    if (lineLen + pulseLen > N_COLS) {
                        // Try to diagnose
//                        println("Pipe line 312 :");
//                        println(" lineLen=" + lineLen);
//                        println(" pulse.text=[" + pulse.text + "]");
//                        println(" pulseLen=" + pulseLen);
                        pulse.text = 
                            pulse.text.substring(0, N_COLS - lineLen);
//                        println(" => pulse.text=[" + pulse.text + "]");
                        break;
                    }
                    pixels.drawString(pulse.text, x, y, fontPixels, rgb);
                    pulse.age++;
                    x += pulse.text.length() * CHAR_W;
                    lineLen += pulseLen;
                }
            }
            
            // Paint cursor.
            if (((t - t0) / CURSOR_T) % 2 == 0) {
                Pulse lastPulse = getLastPulse(screenLines);
                int n = screenLines.size();
                int x, y;
                if (lastPulse == null || lastPulse.hasEOL) {
                    x = TEXT_X; 
                    y = TEXT_Y + n * LINE_H;
                } else {
                    Vector lastLine = (Vector) screenLines.lastElement();
                    int nChars = 0;
                    for (int i = 0; i < lastLine.size(); i++) {
                        nChars += ((Pulse) lastLine.elementAt(i)).text.length();
                    }
                    x = TEXT_X + nChars * CHAR_W;
                    y = TEXT_Y + (n - 1) * LINE_H;
                }
                pixels.drawWuLine(x, y, x, y + LINE_H, CURSOR_RGB);
            }
            
            // Repaint screen.
            update(pixels.getPixels(), TEXT_X, TEXT_Y, TEXT_W, TEXT_H);
            
            // Rest.
            try {
                long elapsed = System.currentTimeMillis() - t;
                if (elapsed < DT) {
                    Thread.sleep(DT - elapsed);
                }
            } catch (InterruptedException e) {}
        }
    }
    
    public void stop() {
        unregisterApplet();
        super.stop();
        if (parser != null) {
            Thread moribund = parser;
            parser = null;
            moribund.interrupt();
        }
    }
    
    private void registerApplet() {
        parser.setPipeSrc(getPipeSrc("register"));
    }
    
    private void unregisterApplet() {
        parser.setPipeSrc(getPipeSrc("unregister"));
        String[] response;
        while ((response = parser.getLines()) == null) {
            println("Waiting to unregister");
            try {
                Thread.sleep(DT);
            } catch (InterruptedException e) {}
        }
    }
    
    private void getAppletParameters() {
        String s;
        if ((s = getParameter("pipeSrc")) != null) {
            pipeSrc = s;
        }
    }
    
    private String getPipeSrc(String req) {
        return new String(pipeSrc + "?id=" + id + "&req=" + req);
    }
    
    private Pulse getLastPulse(Vector pack) {
        if (pack.size() > 0) {
            Vector last = (Vector) pack.lastElement();
            if (last.size() > 0) {
                return (Pulse) last.lastElement();
            }
        }
        return null;
    }
    
    private int getLineLength(Vector line) {
        int sum = 0;
        for (int i = 0; i < line.size(); i++) {
            sum += ((Pulse) line.elementAt(i)).text.length();
        }
        return sum;
    }
    
    /* ========================================================================
        DATA
       ========================================================================
     */
    static final int[] CORNER_PIX = {
        21,21,21,21,21,21,21,21,21,11, 1, 0, 6, 9,14,
        21,21,21,21,21,21,21, 2, 7,18,10,20, 4, 5,12,
        21,21,21,21,21,21, 8,16,20,15,22,22,22,22,22,
        21,21,21,21,13, 0,17, 3,22,22,22,22,22,22,22,
        21,21,21,13,19,20,22,22,22,22,22,22,22,22,22,
        21,21,21, 0,20,22,22,22,22,22,22,22,22,22,22,
        21,21, 8,17,22,22,22,22,22,22,22,22,22,22,22,
        21, 2,16, 3,22,22,22,22,22,22,22,22,22,22,22,
        21, 7,20,22,22,22,22,22,22,22,22,22,22,22,22,
        11,18,15,22,22,22,22,22,22,22,22,22,22,22,22,
         1,10,22,22,22,22,22,22,22,22,22,22,22,22,22,
         0,20,22,22,22,22,22,22,22,22,22,22,22,22,22,
         6, 4,22,22,22,22,22,22,22,22,22,22,22,22,22,
         9, 5,22,22,22,22,22,22,22,22,22,22,22,22,22,
        14,12,22,22,22,22,22,22,22,22,22,22,22,22,22
    };
    
    static final int[] CORNER_RGB = {
        0x35555C, 0x325156, 0x2F494E, 0x2E505B, 0x2F515B, 0x2C4F5A, 
        0x38595E, 0x34545B, 0x335359, 0x395B60, 0x35575E, 0x2D454B, 
        0x2C4E59, 0x2D454A, 0x395B61, 0x2D505B, 0x385A5F, 0x34565D, 
        0x385B60, 0x35575D, 0x32545C, 0x2B3E43, 0x2B4D59
    };
    
    static final int CORNER_W       = 15;
    static final int CORNER_H       = 15;
}
