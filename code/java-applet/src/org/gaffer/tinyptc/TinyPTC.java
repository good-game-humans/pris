//
// TinyPTC by Gaffer
// http://www.gaffer.org/tinyptc
//
// VL+++
// I updated stop() and start() to be thread-safe, and allowed _thread to be
// accessible by inheritors.
// VL---
//

package org.gaffer.tinyptc;

// import classes
import java.awt.Color;
import java.awt.Image;
import java.awt.Toolkit;
import java.awt.Graphics;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.image.ImageProducer;
import java.awt.image.ImageConsumer;
import java.awt.image.DirectColorModel;


public abstract class TinyPTC extends java.applet.Applet implements Runnable, ImageProducer
{
    public abstract void main(int width,int height);

    public synchronized void update(Object pixels)
    {
        update(pixels, 0, 0, _width, _height);
    }

    public synchronized void update(Object pixels, int x, int y, int w, int h)
    {
        // check consumer
        if (_consumer!=null)
        {
            // copy integer pixel data to image consumer
            _consumer.setPixels(x,y,w,h,_model,(int[])pixels,x+y*_width,_width);

            // notify image consumer that the frame is done
            _consumer.imageComplete(ImageConsumer.SINGLEFRAMEDONE);
        }

        // paint
        paint();
    }

    public void start()
    {
        if (_thread == null) {
            _thread = new Thread(this);
        }
        _thread.start();
    }

    public void run()
    {
        // get component size
        Dimension size = size();

        // setup data
        _width = size.width;
        _height = size.height;

        // setup color model
        _model = new DirectColorModel(32,0x00FF0000,0x000FF00,0x000000FF,0);

        // create image using default toolkit
        _image = Toolkit.getDefaultToolkit().createImage(this);

        // call user main
        main(_width,_height);
    }

    public void stop()
    {
        if (_thread != null) {
            Thread moribund = _thread;
            _thread = null;
            moribund.interrupt();
        }
    }

    private synchronized void paint()
    {
        // get component graphics object
        Graphics graphics = getGraphics();

        // draw image to graphics context
        graphics.drawImage(_image,0,0,_width,_height,null);
    }

    public synchronized void addConsumer(ImageConsumer ic) 
    {
        // register image consumer
        _consumer = ic;

        // set image dimensions
        _consumer.setDimensions(_width,_height);

        // set image consumer hints for speed
        _consumer.setHints(ImageConsumer.TOPDOWNLEFTRIGHT|ImageConsumer.COMPLETESCANLINES|ImageConsumer.SINGLEPASS|ImageConsumer.SINGLEFRAME);

        // set image color model
        _consumer.setColorModel(_model);
    }

    public synchronized boolean isConsumer(ImageConsumer ic) 
    {
        // check if consumer is registered
        return true;
    }

    public synchronized void removeConsumer(ImageConsumer ic) 
    {
        // remove image consumer
    }

    public void startProduction(ImageConsumer ic) 
    {
        // add consumer
        addConsumer(ic);
    }

    public void requestTopDownLeftRightResend(ImageConsumer ic) 
    {
        // ignore resend request
    }

    // data
    int _width;
    int _height;
    Image _image;
    protected Thread _thread;
    ImageConsumer _consumer;
    DirectColorModel _model;
}
