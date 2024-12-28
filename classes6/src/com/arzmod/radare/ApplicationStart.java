package com.arzmod.radare;

import com.arzmod.radare.AppContext;
import com.arzmod.radare.FirebaseAdd;
import android.widget.Toast;
import android.util.Log;
import android.content.Context;

public class ApplicationStart {
    private Context context;

    public ApplicationStart(Context context) {
        this.context = context;
    }

    public void start() {
        Log.d("arzmod-app-module", "-> Application started.");
        AppContext.setContext(context);
        FirebaseAdd.initializeAndSubscribe(context);
    }
}