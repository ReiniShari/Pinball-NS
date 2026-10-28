/*
 * DualScreen.java - the second screen of the dual-screen devices (AYN Thor...), the only Java code
 * of the app.
 *
 * The app is a NativeActivity: its window is on the screen it was started on. A second display
 * can only be reached through Java (DisplayManager, Presentation): this class opens a Presentation
 * holding one SurfaceView on the first display that is not the activity's, and hands its Surface
 * to the C code (nativeSurface, registered by main_android.c), which draws it with the same
 * OpenGL ES context as the main screen. Called from the activity callbacks (UI thread).
 */
package fr.pinballtc.app;

import android.app.Activity;
import android.app.Presentation;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.hardware.display.DisplayManager;
import android.view.Display;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

public final class DualScreen {
    private static Presentation pres;
    private static DisplayManager dm;
    private static Activity owner;

    /* the window of the second screen: created (a Surface), destroyed (null) */
    static native void nativeSurface(Object surface);

    private DualScreen() {}

    private static final DisplayManager.DisplayListener LISTENER = new DisplayManager.DisplayListener() {
        @Override public void onDisplayAdded(int id) { if (owner != null && pres == null) open(owner); }
        @Override public void onDisplayRemoved(int id) {
            if (pres != null && pres.getDisplay().getDisplayId() == id) close(true);
        }
        @Override public void onDisplayChanged(int id) {}
    };

    /* the first display that is not the activity's, null: none */
    private static Display other(Activity act) {
        int own = act.getWindowManager().getDefaultDisplay().getDisplayId();
        Display[] ds = dm.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION);
        for (Display d : ds) if (d.getDisplayId() != own && d.getState() != Display.STATE_OFF) return d;
        for (Display d : dm.getDisplays()) if (d.getDisplayId() != own) return d;
        return null;
    }

    /* the activity comes to the front: the second screen opened (true: there is one) */
    public static boolean start(Activity act) {
        try {
            owner = act;
            if (dm == null) {
                dm = (DisplayManager) act.getSystemService(Context.DISPLAY_SERVICE);
                if (dm == null) return false;
                dm.registerDisplayListener(LISTENER, null);
            }
            open(act);
            return pres != null;
        } catch (Throwable t) {
            return false;
        }
    }

    /* the activity leaves the front: the second screen closed (its surface released first) */
    public static void stop() {
        close(false);
        owner = null;
    }

    private static void open(Activity act) {
        if (pres != null) return;
        Display d = other(act);
        if (d == null) return;
        try {
            Presentation p = new Presentation(act, d);
            p.requestWindowFeature(Window.FEATURE_NO_TITLE);
            Window w = p.getWindow();
            if (w != null) {
                /* never the focus: the activity keeps the keys, the gamepad and its own focus */
                w.addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                           | WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
            }
            SurfaceView sv = new SurfaceView(p.getContext());
            sv.getHolder().addCallback(new SurfaceHolder.Callback() {
                @Override public void surfaceCreated(SurfaceHolder h) { nativeSurface(h.getSurface()); }
                @Override public void surfaceChanged(SurfaceHolder h, int format, int width, int height) {}
                @Override public void surfaceDestroyed(SurfaceHolder h) { nativeSurface(null); }
            });
            p.setContentView(sv);
            p.setCancelable(false);
            p.show();
            if (w != null) {
                w.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
            }
            pres = p;
            /* the top half of the tables is wider than tall: the main screen in landscape */
            act.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        } catch (Throwable t) {
            pres = null;
        }
    }

    private static void close(boolean portrait) {
        Presentation p = pres;
        pres = null;
        if (p != null) {
            try { p.dismiss(); } catch (Throwable t) { /* already gone with its display */ }
            nativeSurface(null);      /* dismissed: its surface may already be destroyed (no-op then) */
        }
        if (portrait && owner != null) {
            try { owner.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT); } catch (Throwable t) { }
        }
    }
}
