package com.arzmod.radare;

import android.util.Log;
import android.content.Context;

public class AppContext {
    private static Context context;

    public static void setContext(Context ctx) {
        Log.d("arzmod-context-module", "-> ctx set");
        context = ctx;
    }

    public static Context getContext() {
        return context;
    }
}