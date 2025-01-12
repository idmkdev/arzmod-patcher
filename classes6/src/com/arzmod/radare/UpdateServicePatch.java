package com.arzmod.radare;

import com.arizona.launcher.UpdateService;

import com.arzmod.radare.Main;
import com.arzmod.radare.AppContext;
import android.os.StatFs;
import android.util.Log;
import android.content.Context;
import android.os.Environment;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.*;
import java.io.*;
import kotlin.jvm.internal.Intrinsics;
import kotlin.collections.CollectionsKt;

import android.content.Context;
import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.util.Objects;

public class UpdateServicePatch {
    class FileUpdateInfo {
        File sourceFile;
        File targetFile;
        boolean needUpdate;
        long size;

        public FileUpdateInfo(File sourceFile, File targetFile, boolean needUpdate, long size) {
            this.sourceFile = sourceFile;
            this.targetFile = targetFile;
            this.needUpdate = needUpdate;
            this.size = size;
        }
    }
    
    private static boolean costylToast = false;
    private static Context context;
    private static boolean DEBUG = false;

    public UpdateServicePatch() {
        context = AppContext.getContext();
        if (context == null) {
            Log.e("arzmod-updsrv-module", "Context is null (UpdateServicePatch)");
        }
    }

    public void checkUserFiles(JSONArray jsonArray) {
        if(SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_CLEAR_MODE)) 
        {
            Log.i("arzmod-updsrv-module", "Clean up files...");
            cleanUpFiles(jsonArray);
        }
        if(!SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_MODS_MODE)) 
        {
            Log.i("arzmod-updsrv-module", "User files is disabled. No check & update all files");
            return;
        }
        Log.i("arzmod-updsrv-module", "Start check user files...");
        
        String packageName = context.getPackageName();

        File mediaDir = new File(Environment.getExternalStorageDirectory(),
                "Android/media/" + packageName + "/files/");
        File dataDir = new File(Environment.getExternalStorageDirectory(),
                "Android/data/" + packageName + "/files/");

        if (!mediaDir.exists() && !mediaDir.mkdirs()) {
            Log.e("arzmod-updsrv-module", "Failed to create media/files directory.");
            return;
        }

        try {
            processFileUpdates(mediaDir, dataDir);
        } catch (Exception e) {
            e.printStackTrace();
            Log.e("arzmod-updsrv-module", "Error: " + e.getMessage());
            Main.moduleToast("Произошла ошибка, сообщите разработчику - arzmod.com/dev");
        }
    }

    public boolean isUserFile(File file) {
        if (!SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_MODS_MODE)) return false;

        String packageName = context.getPackageName();

        String dataPath = "/storage/emulated/0/Android/data/" + packageName + "/files/";
        String targetPath = "/storage/emulated/0/Android/media/" + packageName + "/files/";

        if (file.getPath().startsWith(dataPath)) {
            String relativePath = file.getPath().substring(dataPath.length());
            File correspondingFile = new File(targetPath, relativePath);

            if(isFileInFailedUpdatesList(correspondingFile)) {
                Log.v("arzmod-updsrv-module", file.getName() + " this file need to update! Current file in data is not user");
                return false;
            }

            if (correspondingFile.exists()) {
                Log.v("arzmod-updsrv-module", file.getName() + " is a user file");
                return true;
            }
        }

        return false;
    }

    private List<FileUpdateInfo> getFilesForUpdate(File sourceDir, File targetDir) throws IOException {
        List<FileUpdateInfo> filesToUpdate = new ArrayList<>();

        for (File file : Objects.requireNonNull(sourceDir.listFiles())) {
            if (file.isFile()) {
                if (file.getName().equals("failed_updates.json")) continue;
                File targetFile = new File(targetDir, file.getName());
                boolean needUpdate = false;
                StringBuilder logBuilder = new StringBuilder();

                if (!targetFile.exists()) {
                    needUpdate = true;
                    logBuilder.append(file.getName() + " does not exist in target directory. Default add.");
                } else if (file.lastModified() != targetFile.lastModified()) {
                    if (!compareFileHashes(file, targetFile)) {
                        needUpdate = true;
                        logBuilder.append(file.getName() + " hashes do not match ")
                                .append("(Source hash: ").append(calculateFileHash(file))
                                .append(", Target hash: ").append(calculateFileHash(targetFile))
                                .append(") Need update file.");
                    } else {
                        targetFile.setLastModified(file.lastModified());
                        logBuilder.append(file.getName() + " has mismatched last modified times ")
                                .append("(Source: ").append(file.lastModified())
                                .append(", Target: ").append(targetFile.lastModified())
                                .append(") but hashes are equal. Updated last modified time.");
                    }
                } else {
                    logBuilder.append(file.getName() + " file is ok (last modified time and hashes are equal)");
                }
                Log.v("arzmod-updsrv-module", logBuilder.toString());
                filesToUpdate.add(new FileUpdateInfo(file, targetFile, needUpdate, file.length()));
                if(!costylToast && needUpdate)
                {
                    Main.moduleToast("Идёт обновление пользовательских файлов...");
                    costylToast = true;
                }
            } else if (file.isDirectory()) {
                File subTargetDir = new File(targetDir, file.getName());
                if (!subTargetDir.exists() && !subTargetDir.mkdirs()) {
                    Log.e("arzmod-updsrv-module", "Failed to create directory: " + subTargetDir.getPath());
                    continue;
                }
                filesToUpdate.addAll(getFilesForUpdate(file, subTargetDir));
            }
        }

        return filesToUpdate;
    }

    private void processFileUpdates(File mediaDir, File dataDir) throws IOException {
        List<FileUpdateInfo> filesToUpdate = getFilesForUpdate(mediaDir, dataDir);

        long totalUpdateSize = 0;
        for (FileUpdateInfo fileInfo : filesToUpdate) {
            if (fileInfo.needUpdate) {
                totalUpdateSize += fileInfo.size;
            }
        }


        long freeSpace = getAvailableSpace(mediaDir);

        Log.d("arzmod-updsrv-module", "Free space: " + formatBytes(freeSpace) + " | Total update size: " + formatBytes(totalUpdateSize));

        if (totalUpdateSize > freeSpace) {
            long missingSpace = totalUpdateSize - freeSpace;
            String message = "Недостаточно места для копирования файлов! Не хватает: " + formatBytes(missingSpace);
            Log.e("arzmod-updsrv-module", message);
            Main.moduleDialog(message);
            Main.moduleToast(message);
            saveFailedUpdatesList(filesToUpdate);
            return;
        }

        int updatedFileCount = 0;
        int checkedFileCount = 0;

        for (FileUpdateInfo fileInfo : filesToUpdate) {
            checkedFileCount++;
            if (fileInfo.needUpdate) {
                try {
                    copyFile(fileInfo.sourceFile, fileInfo.targetFile);
                    fileInfo.targetFile.setLastModified(fileInfo.sourceFile.lastModified());
                    updatedFileCount++;
                } catch (Exception e) {
                    e.printStackTrace();
                    Log.v("arzmod-updsrv-module", "Failed to update file: " + fileInfo.sourceFile.getName() + " - " + e.getMessage());
                }
            }
        }

        if(updatedFileCount > 0) Main.moduleToast("Проверка завершена. Обновлено файлов: " + updatedFileCount + "/" + checkedFileCount);
        deleteFailedUpdatesList();
    }

    private void saveFailedUpdatesList(List<FileUpdateInfo> filesToUpdate) {
        String packageName = context.getPackageName();
        File failedUpdatesFile = new File("/storage/emulated/0/Android/media/" + packageName + "/files/failed_updates.json");

        JSONObject failedUpdates = new JSONObject();

        try {
            for (FileUpdateInfo fileInfo : filesToUpdate) {
                if (fileInfo.needUpdate) {
                    failedUpdates.put(fileInfo.sourceFile.getAbsolutePath(), true);
                }
            }
            try (BufferedWriter writer = new BufferedWriter(new FileWriter(failedUpdatesFile))) {
                writer.write(failedUpdates.toString());
            }
        } catch (IOException | JSONException e) {
            Log.e("arzmod-updsrv-module", "Error saving failed updates list: " + e.getMessage());
        }
    }

    private void deleteFailedUpdatesList() {
        String packageName = context.getPackageName();
        File failedUpdatesFile = new File("/storage/emulated/0/Android/media/" + packageName + "/files/failed_updates.json");
        if (failedUpdatesFile.exists() && !failedUpdatesFile.delete()) {
            Log.e("arzmod-updsrv-module", "Failed to delete failed updates list");
        }
    }

    private boolean isFileInFailedUpdatesList(File file) {
        String packageName = context.getPackageName();
        File failedUpdatesFile = new File("/storage/emulated/0/Android/media/" + packageName + "/files/failed_updates.json");
        if (!failedUpdatesFile.exists()) {
            return false;
        }

        try (BufferedReader reader = new BufferedReader(new FileReader(failedUpdatesFile))) {
            StringBuilder content = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                content.append(line);
            }

            JSONObject failedUpdates = new JSONObject(content.toString());
            return failedUpdates.has(file.getAbsolutePath());
        } catch (IOException | JSONException e) {
            Log.e("arzmod-updsrv-module", "Error reading failed updates list: " + e.getMessage());
        }

        return false;
    }

    private boolean compareFileHashes(File file1, File file2) throws IOException {
        return calculateFileHash(file1).equals(calculateFileHash(file2));
    }

    private String calculateFileHash(File file) throws IOException {
        try (FileInputStream fis = new FileInputStream(file)) {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                digest.update(buffer, 0, bytesRead);
            }
            byte[] hashBytes = digest.digest();
            StringBuilder hashString = new StringBuilder();
            for (byte b : hashBytes) {
                hashString.append(String.format("%02x", b));
            }
            return hashString.toString();
        } catch (Exception e) {
            throw new IOException("Failed to calculate file hash", e);
        }
    }

    private void copyFile(File source, File destination) throws IOException {
        Files.copy(source.toPath(), destination.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        destination.setLastModified(source.lastModified());
    }

    public void cleanUpFiles(JSONArray jsonStructure) {
        String packageName = context.getPackageName();
        File filesDir = new File("/storage/emulated/0/Android/data/" + packageName + "/files/");

        try {
            Map<String, JSONObject> jsonFileMap = buildJsonFileMap(jsonStructure);
            int deletedFiles = 0;

            deletedFiles = processDirectory(filesDir, jsonFileMap, filesDir, deletedFiles);
            if(deletedFiles > 0) Main.moduleToast("Очищено неиспользуемых файлов: " + deletedFiles);
        } catch (Exception e) {
            Log.e("arzmod-updsrv-module", "Error during cleanup", e);
        }
    }

    private Map<String, JSONObject> buildJsonFileMap(JSONArray jsonStructure) throws JSONException {
        Map<String, JSONObject> fileMap = new HashMap<>();
        for (int i = 0; i < jsonStructure.length(); i++) {
            JSONObject entry = jsonStructure.getJSONObject(i);
            buildFileMapRecursive(entry, "", fileMap);
        }
        return fileMap;
    }

    private void buildFileMapRecursive(JSONObject node, String currentPath, Map<String, JSONObject> fileMap) throws JSONException {
        String name = node.getString("name");
        String type = node.getString("type");
        String path = currentPath.isEmpty() ? name : currentPath + "/" + name;

        if (type.equals("file") || type.equals("res")) {
            fileMap.put(path, node);
        } else if (type.equals("dir")) {
            JSONArray children = node.optJSONArray("data");
            if (children != null) {
                for (int i = 0; i < children.length(); i++) {
                    buildFileMapRecursive(children.getJSONObject(i), path, fileMap);
                }
            }
        }
    }

    private int processDirectory(File dir, Map<String, JSONObject> jsonFileMap, File rootDir, int deletedFiles) {
        if (!dir.isDirectory()) return deletedFiles;

        File[] files = dir.listFiles();
        if (files == null) return deletedFiles;

        String packageName = context.getPackageName();
        
        for (File file : files) {
            String relativePath = "data/" + packageName + "/files/" + getRelativePath(rootDir, file);
            if(isExcludedFile(relativePath)) {
                continue;
            }

            if (file.isDirectory()) {
                deletedFiles = processDirectory(file, jsonFileMap, rootDir, deletedFiles);
                if (file.listFiles() != null && file.listFiles().length == 0) {
                    Log.v("arzmod-updsrv-module", "Deleting empty directory: " + file.getPath());
                    file.delete();
                }
            } else if (!jsonFileMap.containsKey(relativePath) && !isUserFile(file)) {
                Log.d("arzmod-updsrv-module", "Deleting unmatched file: " + file.getPath());
                if(deletedFiles == 0) Main.moduleToast("Удаление неиспользуемых файлов...");
                deletedFiles++;
                file.delete();
            }
        }
        return deletedFiles;
    }

    private boolean isExcludedFile(String relativePath) {
        String packageName = context.getPackageName();
        List<String> excludedFiles = Arrays.asList("data/" + packageName + "/files/modloader", 
                                                    "data/" + packageName + "/files/logcat",
                                                    "data/" + packageName + "/files/AZVoice",
                                                    "data/" + packageName + "/files/SAMP/settings.json",
                                                    "data/" + packageName + "/files/UserLimits.ini",
                                                    "data/" + packageName + "/files/gtasatelem.set",
                                                    "data/" + packageName + "/files/app-arizona-release_web.apk",
                                                    "data/" + packageName + "/files/CLEO/cleo.log"); 
        for (String excludedDir : excludedFiles) {
            if (relativePath.contains(excludedDir)) {
                return true;
            }
        }
        return false;
    }

    private String getRelativePath(File rootDir, File file) {
        return rootDir.toPath().relativize(file.toPath()).toString().replace("\\", "/");
    }

    public boolean deleteFolder(File folder) {
        if (folder != null && folder.isDirectory()) {
            File[] files = folder.listFiles();
            if (files != null) {
                for (File file : files) {
                    deleteFolder(file);
                }
            }
        }
        return folder != null && folder.delete();
    }

    public void deleteMods() {
        String packageName = context.getPackageName();

        File folder = new File("/storage/emulated/0/Android/media/" + packageName + "/files/");

        if (folder.exists()) {
            Main.moduleToast("Удаление сборки...");
            boolean result = deleteFolder(folder);
            if (result) {
                Main.moduleToast("Сборка удалена.");
                Log.v("arzmod-updsrv-module", "Mods folder successfuly removed.");
            } else {
                Main.moduleToast("Произошла ошибка при удалении сборки");
                Log.e("arzmod-updsrv-module", "Mods folder is not removed. Why?");
            }
        } else {
            Log.e("arzmod-updsrv-module", "Mods folder does not exist");
        }
    }

    private long getAvailableSpace(File dir) {
        StatFs stat = new StatFs(dir.getPath());
        long availableBlocks = stat.getAvailableBlocksLong();
        long blockSize = stat.getBlockSizeLong();
        return availableBlocks * blockSize;
    }

    private long calculateFolderSize(File dir) {
        long size = 0;
        if (dir.isDirectory()) {
            File[] files = dir.listFiles();
            if (files != null) {
                for (File file : files) {
                    size += calculateFolderSize(file);
                }
            }
        } else {
            size += dir.length();
        }
        return size;
    }
    
    public String formatBytes(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        int exp = (int) (Math.log(bytes) / Math.log(1024));
        String[] units = {"B", "KB", "MB", "GB", "TB", "PB", "EB"};
        return String.format("%.2f %s", bytes / Math.pow(1024, exp), units[exp]);
    }
}
