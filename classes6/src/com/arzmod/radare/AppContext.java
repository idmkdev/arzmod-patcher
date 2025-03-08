package com.arzmod.radare;

import android.util.Log;
import android.content.Context;

public class AppContext {
    private static Context context;

    public static void setContext(Context ctx) {
        Log.d("arzmod-context-module", "-> ctx set");
        if (context != null) {
            Log.d("arzmod-radare-module", "Context class: " + context.getClass().getName());
            Log.d("arzmod-radare-module", "Context: " + String.valueOf(context));
        } else {
            Log.e("arzmod-context-module", "ctx == null");
        }
        context = ctx;
    }

    public static Context getContext() {
        return context;
    }
}