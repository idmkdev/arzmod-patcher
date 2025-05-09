package com.arzmod.radare;

import java.util.HashMap;
import java.util.Map;
import com.arizona.game.BuildConfig;

public class GameVersions {
    private static Map<Integer, String> versions = new HashMap<>();

    static {
        versions.put(BuildConfig.VERSION_CODE, BuildConfig.VERSION_CODE + " actual");
        if (BuildConfig.IS_ARIZONA) {
            versions.put(1579, "1579 arz crash");
        }
        versions.put(1508, "1508 " + (BuildConfig.IS_ARIZONA ? "arz" : "rdn") + " crash");
    }

    public static Map<Integer, String> getVersions() {
        return versions;
    }

    public static boolean isVersionSupported(int version) {
        return versions.containsKey(version);
    }

    public static int getLatestVersion() {
        return BuildConfig.VERSION_CODE;
    }
} 