package com.example.todo; // Assurez-vous que ce package correspond à votre application

import android.content.Context;
import android.provider.Settings;

public class DeviceUtils {
    public static String getAndroidId(Context context) {
        return Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
    }
}
