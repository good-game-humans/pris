/*
 * com/ngon/pris/Parser.java
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
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.util.Vector;

/**
 * class Parser
 */
final class Parser extends Thread {
    
    public static final String BEAT_STR  = "-=BEAT=-";
    
    private String pipeSrc;
    private App app;
    private String[] lines;
    
    public Parser(App app) {
        this.app = app;
        setDaemon(true);
        setPriority(MIN_PRIORITY);
    }
    
    public synchronized void setPipeSrc(String pipeSrc) {
        this.pipeSrc = pipeSrc;
        this.lines = null;
        notify();
    }
    
    public void run() {
        Thread currentThread = Thread.currentThread();
        while (this == currentThread) {
            try {
                if (pipeSrc == null) {
                    synchronized(this) {
                        while (pipeSrc == null) {
                            wait();
                        }
                    }
                }
            } catch (InterruptedException e) {}
            
            if (this != currentThread) {
                return;
            }
            
            InputStream pipe = app.getDataStream(pipeSrc);
            if (pipe == null) {
                continue;
            }
            
            try {
                BufferedReader reader = 
                    new BufferedReader(new InputStreamReader(pipe));
                Vector v = new Vector();
                if (reader.ready()) {
                    String s;
                    while ((s = reader.readLine()) != null) {
                        v.addElement(s);
                    }
                }
                reader.close();
                int len = v.size();
                if (len > 0) {
                    synchronized(this) {
                        lines = new String[len];
                        for (int i = 0; i < len; i++) {
                            lines[i] = (String) v.elementAt(i);
                        }
                    }
                }
//                v.removeAllElements();
                pipe.close();
            } catch (IOException e) {
                System.err.println(e);
            }
            pipeSrc = null;
        }
    }
    
    public synchronized String[] getLines() {
        return lines;
    }
    
    public synchronized void clear() {
        this.lines = null;
    }
    
    public static Vector parsePacks(String[] lines) {
        if (lines == null) {
            return null;
        }
        Vector packs = new Vector();
        Vector pack = new Vector();
        for (int i = 0; i < lines.length; i++) {
            // Check for demarcation.  
            if (lines[i].startsWith(BEAT_STR)) {
                // Look for previous pulse to update its EOL flag.
                // (Demarcation is bounded by new lines.)
                if (pack.size() > 0) {
                    Pulse prevPulse = (Pulse) pack.lastElement();
                    if (prevPulse.text.length() == 0) {
                        pack.removeElementAt(pack.size()-1);
                    } else {
                        prevPulse.hasEOL = false;
                    }
                }
                // Add a clone of this pack to packs.
                packs.addElement(pack.clone());
                pack.removeAllElements();
            } else {
                pack.addElement(new Pulse(lines[i], true));
            }
        }
        return packs;
    }
}
