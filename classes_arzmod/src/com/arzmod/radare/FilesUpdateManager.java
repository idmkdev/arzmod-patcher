package com.arzmod.radare;

import android.content.Context;
import android.os.SystemClock;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class FilesUpdateManager {

    private static final String TAG = "arzmod-files-module";
    private static final AtomicBoolean running = new AtomicBoolean(false);

    private FilesUpdateManager() {
    }

    public static void start() {
        final Context ctx = AppContext.getContext();
        if (ctx == null) {
            Log.e(TAG, "Context is null, files update skipped");
            return;
        }

        if (!running.compareAndSet(false, true)) {
            Log.d(TAG, "Files update already running, skip");
            return;
        }

        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    boolean skipVerify = SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_SKIP_VERIFY);
                    process(ctx, skipVerify);
                } catch (Exception e) {
                    Log.e(TAG, "Files update failed", e);
                } finally {
                    running.set(false);
                }
            }
        }, "FilesUpdateManager").start();
    }

    private static void process(Context ctx, boolean skipVerify) {
        long startTime = SystemClock.elapsedRealtime();
        InputStream zipStream = null;
        ZipInputStream zis = null;
        try {
            zipStream = ctx.getAssets().open("arzmod/files.zip");
            zis = new ZipInputStream(zipStream);
            ZipEntry entry;
            int restored = 0;
            int skipped = 0;

            while ((entry = zis.getNextEntry()) != null) {
                if (entry.isDirectory()) continue;

                String entryName = entry.getName();
                if (!entryName.startsWith("data/") && !entryName.startsWith("media/")) {
                    zis.closeEntry();
                    continue;
                }

                File target = resolveTarget(ctx, entryName);
                if (target == null) {
                    zis.closeEntry();
                    continue;
                }

                if (needsRestore(zis, entry, target, skipVerify)) {
                    extract(zis, target);
                    restored++;
                    Log.d(TAG, "Restored: " + target.getAbsolutePath());
                } else {
                    skipped++;
                }
                zis.closeEntry();
            }

            Log.d(TAG, "Files update done. restored=" + restored + ", checked=" + skipped
                    + ", time=" + (SystemClock.elapsedRealtime() - startTime) + "ms");
        } catch (Exception e) {
            Log.e(TAG, "Files update error", e);
        } finally {
            if (zis != null) {
                try { zis.close(); } catch (IOException ignored) { }
            }
            if (zipStream != null) {
                try { zipStream.close(); } catch (IOException ignored) { }
            }
        }
    }

    private static File resolveTarget(Context ctx, String entryName) {
        String[] parts = entryName.split("/");
        if (parts.length < 3) return null;
        String packageName = parts[1];

        try {
            if (entryName.startsWith("data/")) {
                String relativePath = entryName.substring(5 + packageName.length() + 1);
                File parent = ctx.getExternalFilesDir(null).getParentFile();
                if (parent == null) return null;
                return new File(parent, relativePath);
            } else if (entryName.startsWith("media/")) {
                String relativePath = entryName.substring(6 + packageName.length() + 1);
                File[] mediaDirs = ctx.getExternalMediaDirs();
                if (mediaDirs == null || mediaDirs.length == 0 || mediaDirs[0] == null) return null;
                return new File(mediaDirs[0], relativePath);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to resolve path for: " + entryName, e);
        }
        return null;
    }

    private static boolean needsRestore(ZipInputStream zis, ZipEntry entry, File target, boolean skipVerify) {
        if (!target.exists()) {
            return true;
        }

        if (skipVerify) {
            return false;
        }

        return !matchesExpected(zis, entry, target);
    }

    private static boolean matchesExpected(ZipInputStream zis, ZipEntry entry, File target) {
        FileInputStream fis = null;
        try {
            long size = entry.getSize();
            if (target.length() != size) {
                return false;
            }

            long expectedCrc = entry.getCrc();

            fis = new FileInputStream(target);
            CRC32 crc = new CRC32();
            byte[] buffer = new byte[8192];
            int len;
            while ((len = fis.read(buffer)) > 0) {
                crc.update(buffer, 0, len);
            }
            return expectedCrc >= 0 && crc.getValue() == expectedCrc;
        } catch (Exception e) {
            return false;
        } finally {
            if (fis != null) {
                try { fis.close(); } catch (IOException ignored) { }
            }
        }
    }

    private static void extract(ZipInputStream zis, File target) throws IOException {
        File parent = target.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }

        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(target);
            byte[] buffer = new byte[8192];
            int len;
            while ((len = zis.read(buffer)) > 0) {
                fos.write(buffer, 0, len);
            }
            fos.flush();
        } finally {
            if (fos != null) {
                try { fos.close(); } catch (IOException ignored) { }
            }
        }
    }
}
