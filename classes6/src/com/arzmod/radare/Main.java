package com.arzmod.radare;

import com.arzmod.radare.AppContext;
import android.app.Activity;
import android.content.Context;
import android.app.AlertDialog;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;
import android.util.Log;

public class Main {    
    public static void moduleToast(String msg) {
        Context context = AppContext.getContext();
        if (context == null || msg == null) {
            Log.e("arzmod-radare-module", "Context and message cannot be null");
            return;
        }
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(context, msg, Toast.LENGTH_SHORT).show();
            }
        });
    }

    public static void moduleDebug(String log) {
        Log.d("arzmod-radare-module", log);
    }

    public static void moduleDialog(String message) {
        Context context = AppContext.getContext();
        if (context == null || message == null) {
            Log.e("arzmod-radare-module", "Context and message cannot be null");
            return;
        }
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                try {
                    new AlertDialog.Builder(context)
                        .setTitle("Информация")
                        .setMessage(message)
                        .setPositiveButton("ОК", new android.content.DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(android.content.DialogInterface dialog, int which) {
                                dialog.dismiss();
                            }
                        })
                        .show();
                } catch (Exception e) {
                    e.printStackTrace();
                    Log.e("arzmod-radare-module", "Error creating dialog");
                    moduleToast(message);
                }
            }
        });
    }
}