/*
 * com/ngon/app/App.java
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

package com.ngon.app;

import java.io.InputStream;
import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.URL;
import org.gaffer.tinyptc.TinyPTC;

/**
 * class App
 */
public abstract class App extends TinyPTC {
    
    protected boolean isRunningAsApplet;
    protected String appletSecurityEvader;
    
    public void init() {
        isRunningAsApplet = true;
    }
    
    public void kill() {
        if (! isRunningAsApplet) {
            System.exit(0);
        } else {
        }
    }
    
    /* ========================================================================
        IO OPS
       ========================================================================
     */
    public InputStream getDataStream(String file) {
        try {
            if (isRunningAsApplet) {
                URL u;
                if (file.startsWith("http://")) {
                    if (appletSecurityEvader != null) {
                        u = new URL(appletSecurityEvader + file);
                    } else {
                        u = new URL(file);
                    }
                } else {
                    u = new URL(getDocumentBase(), file);
                }
                return new BufferedInputStream(u.openStream());
            } else {
                return new BufferedInputStream(new FileInputStream(file));
            }
        } catch (NullPointerException npe) {
            // For some reason, this little catch fixes a one-time
            // java.lang.NullPointerException on Netscape 6.2 /
            // Mac OS 9.1 / MRJ 2.2.5 (no problem for IE on same system).
            // Does not happen if applet is re-run.
            System.out.println("Error opening stream -> retrying...");
            if (_thread == Thread.currentThread()) {
                return getDataStream(file);
            } else {
                return null;
            }
        } catch (IOException e) {
            System.err.println("Can't open " + file);
            kill();
        }
        return null;
    }
    
    public void print(String s) {
//        if (! isRunningAsApplet) {
            System.out.print(s);
//        } else {
//        }
    }
    
    public void println(String s) {
//        if (! isRunningAsApplet) {
            System.out.println(s);
//        } else {
//        }
    }
    
    public void println() {
        System.out.println();
    }
}
