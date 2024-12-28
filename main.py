import os
import re
import sys
import time
import json
import yaml
import shutil
import requests
import threading
import subprocess
import telebot
from telebot import types
import ftplib
import mysql.connector
import config
import xml.etree.ElementTree as ET

try:
    import arzmod_release
    arzmod_dev = True
except ImportError:
    arzmod_dev = False

os.chdir(os.path.dirname(os.path.abspath(__file__)))

working_dir = os.getcwd() + "\\"
patcher_dir = os.getcwd()
name = "app"
app_dir, res_folder, dist_dir, lib_path = None, None, None, None
launcher_verlua, launcher_ver, launcher_vername = 0, 0, "None"
arz_src_path = "smali_classes3"
arz_ui_path = "smali_classes5"

print("Connect MySQL's")

headers = {
    'accept': '*/*',
    'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0',
    'Upgrade-Insecure-Requests': '1',
}




if arzmod_dev:
    bot = telebot.TeleBot(arzmod_release.TELEGRAM_BOT_TOKEN)
    print("Set MySQL timeout")
    db = arzmod_release.connect_to_db()
    cursor = db.cursor()
    cursor.execute("SELECT 1")
    if cursor.fetchone()[0] == 1:
        print("Connection is alive!")
        cursor.execute("SELECT status FROM settings WHERE var = 'arizona_verjson'")
        result = cursor.fetchone()
        print("Current launcher version:", int(result[0]))
    else:
        print("Connection failed!")
    print("MySQL connect successfully!")
    cursor.close()
    db.close()


############################# HELP FUNCTIONS #######################################

def get_app_version():
    try:
        with open(app_dir + "\\apktool.yml", 'r', encoding='utf-8') as file:
            content = file.read()

            version_code_match = re.search(r"versionCode:\s*'(\d+)'", content)
            version_name_match = re.search(r"versionName:\s*([^']+)", content)

            version_code = int(version_code_match.group(1)) if version_code_match else None
            version_name = version_name_match.group(1).replace("\n", "") if version_name_match else 'Unknown'

            return version_code, version_name
    except Exception as e:
        print(f"Error reading {app_dir}\\apktool.yml: {e}")
        return None, None

def replace_files(base_path, name):
    if not os.path.exists(res_folder):
        print("Ошибка: папка 'res' не найдена.")
        return

    files_replaced = 0 

    for dirpath, dirnames, filenames in os.walk(res_folder):
        for filename in filenames:
            if filename.startswith(name):
                file_ext = os.path.splitext(filename)[1]

                source_file = f"{base_path}{file_ext}"

                if not os.path.exists(source_file):
                    print(f"Ошибка: файл {source_file} для {name} не найден. Пропускаем.")
                    continue

                file_path = os.path.join(dirpath, filename)
                shutil.copy(source_file, file_path)
                files_replaced += 1

    if files_replaced > 0:
        print(f"Для {name} заменено файлов: {files_replaced}")
    else:
        print(f"Не было найдено файлов для замены {name}.")


def search_and_replace(file_path, search_string, replacement_string, skip_found=None):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        found = any(search_string in line for line in lines)
        replacement_count = 0

        if found:
            with open(file_path, 'w') as file:
                for line in lines:
                    if search_string in line:
                        new_line = line.replace(search_string, replacement_string)
                        replacement_count += 1
                    else:
                        new_line = line
                    file.write(new_line)
            print(f"Строка заменена в файле {file_path}. Количество замен: {replacement_count}")
            return True
        elif skip_found is None:
            print("-------------------DEBUG-------------------")
            print("file_path:", file_path)
            print("search_string:", search_string)
            print("Строки для замены не найдено")
            print("-------------------------------------------")
            exit()
        else:
            return None
    except (UnicodeDecodeError, FileNotFoundError):
        return None


def replace_file(source_path, target_path):
    if not os.path.exists(source_path):
        raise FileNotFoundError(f"Исходный файл '{source_path}' не найден.")
    
    target_dir = os.path.dirname(target_path)
    if not os.path.exists(target_dir):
        raise FileNotFoundError(f"Целевая директория '{target_dir}' не существует.")
    
    try:
        shutil.copy2(source_path, target_path)
        print(f"Файл успешно заменён: {target_path}")
    except PermissionError as e:
        raise PermissionError(f"Ошибка доступа: {e}")
    except Exception as e:
        raise RuntimeError(f"Произошла ошибка: {e}")


def search_and_replace_after(file_path, search_before, search_string, replacement_string, skip_found=None):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        found_before = False
        replacement_made = False

        with open(file_path, 'w') as file:
            for line in lines:
                if search_before in line:
                    found_before = True

                if found_before and search_string in line and not replacement_made:
                    new_line = line.replace(search_string, replacement_string, 1)
                    replacement_made = True 
                else:
                    new_line = line

                file.write(new_line)

        if replacement_made:
            print(f"Одна замена произведена в файле {file_path}.")
            return True
        elif skip_found is None:
            print("-------------------DEBUG-------------------")
            print("file_path:", file_path)
            print("search_before:", search_before)
            print("search_string:", search_string)
            print("Не найдена строка для замены после заданной строки")
            print("-------------------------------------------")
            exit()
        else:
            return None

    except (UnicodeDecodeError, FileNotFoundError):
        return None

def remove_line_numbers(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()

        with open(file_path, 'w', encoding='utf-8') as file:
            for line in lines:
                if not line.strip().startswith('.line'):
                    file.write(line)
    except Exception as e:
        print(f"Произошла ошибка: {e}")
        exit()

def replace_block_in_file(file_path, old_block, new_line):
    try:
        remove_line_numbers(file_path)
        time.sleep(1)
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content.replace(old_block, new_line)

        if content == new_content:
            print("-------------------DEBUG-------------------")
            print("file_path:", file_path)
            print("old_block:", old_block)
            print("new_line:", new_line)
            print("Замена не выполнена: блок не найден.")
            print("-------------------------------------------")
            exit()

        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(new_content)

    except Exception as e:
        print(f"Произошла ошибка: {e}")
        exit()


def insert_smali_code_after_line(file_path, method_name, target_line, smali_code):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()

        in_target_method = False
        modified_lines = []
        code_inserted = False

        for line in lines:
            if method_name + "(" in line:
                in_target_method = True

            modified_lines.append(line)
            if in_target_method and target_line in line:
                modified_lines.extend(smali_code.splitlines(keepends=True))
                code_inserted = True

            if in_target_method and line.strip() == '.end method':
                in_target_method = False

        if not code_inserted:
            print("-------------------DEBUG-------------------")
            print("file_path:", file_path)
            print("method_name:", method_name)
            print("target_line:", target_line)
            print("smali_code:", smali_code)
            print("in_target_method:", in_target_method)
            print("Замена не выполнена: блок не найден.")
            print("-------------------------------------------")
            exit()

        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(modified_lines)

    except Exception as e:
        print("-------------------DEBUG-------------------")
        print("file_path:", file_path)
        print("method_name:", method_name)
        print("target_line:", target_line)
        print("smali_code:", smali_code)
        print(e)
        print("-------------------------------------------")
        exit()


def insert_code_before_line(file_path, target_line_content, code_to_insert):
    code_lines = code_to_insert.strip().splitlines(keepends=True)

    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    found = False

    updated_lines = []
    for line in lines:
        if target_line_content in line:
            found = True
            updated_lines.extend(code_lines)
            updated_lines.append("\n\n")
        updated_lines.append(line)


    if not found:
        print("-------------------DEBUG-------------------")
        print("file_path:", file_path)
        print("target_line_content:", target_line_content)
        print("code_to_insert:", code_to_insert)
        print("Ошибка: строка не найдена!")
        print("-------------------------------------------")
        exit()
    else:
        print(f"Строка с содержимым '{target_line_content}' в файле {file_path} найдена и код был вставлен. ")

    with open(file_path, 'w', encoding='utf-8') as file:
        file.writelines(updated_lines)

def replace_code_between_lines(file_path, start_line_content, end_line_content, code_to_insert):
    code_lines = code_to_insert.strip().splitlines(keepends=True)

    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    found_start = False
    found_end = False

    updated_lines = []

    for line in lines:
        if not found_start and start_line_content in line:
            found_start = True
            updated_lines.extend(code_lines)
            continue
        if found_start and end_line_content in line and not found_end:
            found_end = True
            continue
        if not found_start or found_end:
            updated_lines.append(line)

    if not found_start or not found_end:
        print("-------------------DEBUG-------------------")
        print("file_path:", file_path)
        print("start_line_content:", start_line_content)
        print("end_line_content:", end_line_content)
        print("code_to_insert:", code_to_insert)
        print("Ошибка: одна или обе строки не найдены!")
        print("-------------------------------------------")
        exit()
    else:
        print(f"Содержимое между '{start_line_content}' и '{end_line_content}' в файле {file_path} успешно заменено.")

    with open(file_path, 'w', encoding='utf-8') as file:
        file.writelines(updated_lines)

def append_to_file(file_path, content_to_append):
    try:
        with open(file_path, 'a', encoding='utf-8') as file:
            file.write(content_to_append)
            if not content_to_append.endswith('\n'):
                file.write('\n')
        print(f"Добавлен код в файл {file_path}")

    except Exception as e:
        print("-------------------DEBUG-------------------")
        print("file_path:", file_path)
        print("content_to_append:", content_to_append)
        print(f"Произошла ошибка: {e}")
        print("-------------------------------------------")
        exit()

def update_xml_attribute(file_path, namespace, search_path, attribute, new_value):
    namespaces = {
        'android': 'http://schemas.android.com/apk/res/android',
        'app': 'http://schemas.android.com/apk/res-auto'
    }

    tree = ET.parse(file_path)
    root = tree.getroot()

    element = root.find(search_path, namespaces)

    if element is not None:
        element.set(f'{{{namespaces[namespace]}}}{attribute}', new_value)
        tree.write(file_path, encoding='utf-8', xml_declaration=True)
        print(f"Атрибут '{attribute} [{namespace}]' изменен на '{new_value}' в элементе '{search_path}' в файле {file_path}.")
    else:
        print("-------------------DEBUG-------------------")
        print("file_path:", file_path)
        print("namespace:", namespace)
        print("search_path:", search_path)
        print("attribute:", attribute)
        print("new_value:", new_value)
        print("-------------------------------------------")
        exit()


def set_package_name(old, new):
    search_and_replace(working_dir + f'{name}\\AndroidManifest.xml', old, new)

    for foldername, subfolders, filenames in os.walk(working_dir + f'{name}\\{arz_src_path}\\'):
        for filename in filenames:
            file_path = os.path.join(foldername, filename)
            search_and_replace(file_path, old, new, True)


def set_xml_string(string_id, new_string):
    print(f"Set XML string of id {string_id} = {new_string}")
    file_path = working_dir + f'{name}\\res\\values\\strings.xml'
    tree = ET.parse(file_path)
    root = tree.getroot()
    xml_string = root.find(f"./string[@name='{string_id}']")
    xml_string.text = new_string
    tree.write(file_path, encoding="utf-8")

def decompile_apk():
    print("Decompiling APK...")
    run_command(f"apktool d {name}.apk -f", cwd=patcher_dir)

def build_apk():
    print("Building APK...")
    search_and_replace(working_dir + f"{name}\\AndroidManifest.xml", '<property android:name="android.adservices.AD_SERVICES_CONFIG" android:resource="@xml/ga_ad_services_config" />', "", True)
    run_command(f"apktool b {name} --use-aapt2", cwd=patcher_dir)

def sign_apk(rename, keypass):
    print("Aligning APK...")
    cname = name
    if name == rename:
        os.rename(os.path.join(dist_dir, f"{name}.apk"), os.path.join(dist_dir, f"{name}-nosign.apk"))
        cname = f"{name}-nosign"

    aligned_apk = os.path.join(dist_dir, f"{rename}.apk")
    if os.path.exists(aligned_apk):
        os.remove(aligned_apk)
        print(f"Removed file {aligned_apk}")

    run_command(f"zipalign -p 4 {dist_dir}\\{cname}.apk {aligned_apk}", cwd=patcher_dir)

    print("Signing APK...")
    keystore = os.path.join(patcher_dir, "key", "keystore.jks")
    run_command(f"apksigner sign --ks {keystore} --v4-signing-enabled true --ks-pass pass:{keypass} {aligned_apk}", cwd=patcher_dir)
    print("Delete cache")
    os.remove(f"{dist_dir}\\{cname}.apk")
    os.remove(f"{aligned_apk}.idsig")

def compile_dex_additions(dex_name):
    run_command(f"dexcompile.py {dex_name}", cwd=patcher_dir)
    shutil.move(f"{patcher_dir}\\{dex_name}\\out\\{dex_name}.dex", app_dir)

    
def download_apk(rename):
    aligned_apk = os.path.join(dist_dir, f"{rename}.apk")
    print(f"Installing APK ({aligned_apk}) on device...")
    run_command(f"adb install {aligned_apk}", cwd=dist_dir)



####################################################################################


def run_command(command, cwd=None, check=True):
    try:
        subprocess.run(command, cwd=cwd, check=check, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        sys.exit(1)



def arzmod_patch():
    compile_dex_additions("classes6")
    set_package_name("com.arizona21.game.web", "com.arizona.game")

    set_xml_string("gcm_defaultSenderId", "982519605362")
    set_xml_string("google_api_key", "AIzaSyAIav21gmzddU7GlZL-4oodtbAzkzclCmg")
    set_xml_string("google_app_id", "1:982519605362:android:e9d9e2b84af6dd0601baeb")
    set_xml_string("google_crash_reporting_api_key", "AIzaSyAIav21gmzddU7GlZL-4oodtbAzkzclCmg")
    set_xml_string("google_storage_bucket", "arzmod.firebasestorage.app")
    set_xml_string("project_id", "arzmod")

    set_xml_string("need_app_update", "Требуется обновление клиента. Возможно требуется ознакомится с обновлением, чтобы у вас не было лишних вопросов. Прочитать подробности обновления можно в t.me/CleoArizona")
    set_xml_string("update_server_error", "Лаунчеру не удалось получить нужную ему информацию. Возможно, сервера ARZMOD временно недоступны\\nЕсли с вашем интернет соединением всё хорошо, нажмите кнопку \\'продолжить\\'\\nЕсли у вас остались вопросы, напишите в группу - t.me/cleodis")
    set_xml_string("exit", "Продолжить")
    set_xml_string("need_restart", "Требуется перезапуск. После перезапуска, обновите игру для корректной работы.")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\util\\FileServers.smali", "https://mob.maz-ins.com/game/release/", "https://download.arzmod.com/arz_modclient/")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\util\\FileServers.smali", "https://arz-mob.react-group.tech/game/release/", "https://radarebot.hhos.net/arz_modclient/")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\di\\ArizonaLauncherAPIModule.smali", "https://api.arizona-five.com/", "https://api.arzmod.com/")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainEntrench$IncomingHandler.smali", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$14$lambda$12(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$14$lambda$13(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainEntrench$IncomingHandler.smali", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$1(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$14$lambda$13(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainEntrench.smali", " release_web\"", " arzmod\"")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService.smali", "/data/com.arizona.game/files", "")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService.smali", "/data/com.arizona.game", "")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService$isAllFilesOk$1.smali", "/data/com.arizona.game/files", "")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService$isAllFilesOk$1.smali", "iget-boolean v6, p0, Lcom/arizona/launcher/UpdateService$isAllFilesOk$1;->$purgeExtraFiles:Z", "const/4 v6, 0x0")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com/arizona\\launcher\\ui\\information_main\\InformationPageFragment.smali", "https://arizona-rp.com/shop", "https://t.me/cleodis")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com/arizona\\launcher\\ui\\settings\\SettingsPageFragment.smali", "135.181.129.36", "join.arzfun.com")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ui\\settings\\SettingsPageFragment.smali", "invoke-virtual {v0, v1}, Landroid/widget/ImageView;->setVisibility(I)V", "")
    search_and_replace(working_dir + f"{name}\\{arz_ui_path}\\ru\\mrlargha\\commonui\\elements\\hud\\presentation\\Hud.smali", "arizona-rp.com", "arzmod.com")
    search_and_replace(working_dir + f"{name}\\{arz_ui_path}\\ru\\mrlargha\\commonui\\elements\\hud\\presentation\\api\\HudApi.smali", "desktop/ping/Arizona/ping.json", "https://radarebot.hhos.net/api/serverlist")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\data\\database\\NotificationHistoryDAO_Impl.smali", "SELECT * FROM notifications ORDER BY date LIMIT 5", "SELECT * FROM notifications ORDER BY id DESC")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\data\\database\\NotificationHistoryDAO_Impl$1.smali", "INSERT OR REPLACE INTO `notifications` (`id`,`date`,`title`,`text`,`imageUrl`) VALUES (nullif(?, 0),?,?,?,?)", "WITH Params AS (SELECT ? AS id, ? AS date, ? AS title, ? AS text, ? AS imageUrl) INSERT INTO notifications (date, title, text, imageUrl) SELECT date, title, text, imageUrl FROM Params WHERE NOT EXISTS (SELECT 1 FROM notifications WHERE (title || text || imageUrl) = (SELECT title || text || imageUrl FROM Params))")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\data\\database\\NotificationHistoryDAO_Impl$2.smali", "DELETE FROM notifications", "SELECT 1")    
    replace_code_between_lines(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MessagingService.smali", "invoke-direct {p0}, Lcom/arizona/launcher/MessagingService;->getSettingsPreferences()Landroid/content/SharedPreferences;", "invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V", "")

    insert_code_before_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", """.method public static native InitSetting(ZIZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V
        .end method
        """)
    insert_code_before_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", """.method public static native InitModloaderConfig(I)V
        .end method
        """)
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", ".method public static native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V")
    
    manifest_path = working_dir + f'{name}\\AndroidManifest.xml'

    tree = ET.parse(manifest_path)
    root = tree.getroot()

    ET.register_namespace("android", "http://schemas.android.com/apk/res/android")

    service = ET.Element("service", {
        "android:exported": "false",
        "android:name": "com.arzmod.radare.FirebaseAdd",
        "android:permission": "com.google.android.c2dm.permission.SEND"
    })

    intent_filter = ET.SubElement(service, "intent-filter")
    ET.SubElement(intent_filter, "action", {
        "android:name": "com.google.firebase.MESSAGING_EVENT"
    })

    application = root.find("application")
    application.append(service)

    tree.write(manifest_path, encoding="utf-8", xml_declaration=True)


    insert_code_before_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASA.smali", ".method public InstallHud(IIII)V", """.method public InstallHud(III)V
        .locals 7
        .annotation system Ldalvik/annotation/MethodParameters;
            accessFlags = {
                0x0,
                0x0,
                0x0,
                0x0
            }
            names = {
                "playerId",
                "serverId",
                "serverType",
                "isStreamerMode"
            }
        .end annotation

        .line 891
        new-instance v6, Lcom/arizona/game/GTASA$$ExternalSyntheticLambda36;

        move-object v0, v6

        move-object v1, p0

        move v2, p1

        move v3, p2

        move v4, p3

        const/4 v5, 0x0

        invoke-direct/range {v0 .. v5}, Lcom/arizona/game/GTASA$$ExternalSyntheticLambda36;-><init>(Lcom/arizona/game/GTASA;IIII)V

        invoke-virtual {p0, v6}, Lcom/arizona/game/GTASA;->runOnUiThread(Ljava/lang/Runnable;)V

        return-void
    .end method
        """)

    update_xml_attribute(working_dir + f"{name}\\res\\layout\\test_server_dialog.xml", "app", ".//com.google.android.material.textfield.TextInputLayout[@android:id='@id/textInputLayout3']", 'helperText', 'Никнейм')
    update_xml_attribute(working_dir + f"{name}\\res\\layout\\test_server_dialog.xml", "android", ".//com.google.android.material.textfield.TextInputEditText[@android:id='@id/server_password_input']", 'inputType', 'text')
    update_xml_attribute(working_dir + f"{name}\\res\\layout\\test_server_dialog.xml", "android", ".//TextView[@android:id='@id/textView12']", 'text', 'Подключение к SA:MP серверу')
    # update_xml_attribute(working_dir + f"{name}\\res\\layout\\fragment_information_page.xml", "app", ".//androidx.constraintlayout.widget.Guideline[@android:id='@id/donate_top_line']", 'layout_constraintGuide_percent', '0.0')

    replace_block_in_file(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ui\\settings\\SettingsPageFragment.smali", "const-string v1, \"CFTqKf40\"", """invoke-direct {p0}, Lcom/arizona/launcher/ui/settings/SettingsPageFragment;->getViewModel()Lcom/arizona/launcher/MainViewModel;

    move-result-object v1

    invoke-virtual {v1}, Lcom/arizona/launcher/MainViewModel;->getPlayerNick()Ljava/lang/String;

    move-result-object v1""")

    replace_block_in_file(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ui\\settings\\SettingsPageFragment.smali", """
    const-string/jumbo p2, "pass"

    invoke-virtual {p1, p2, p3}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object p1""", "")

    replace_block_in_file(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ui\\settings\\SettingsPageFragment.smali", """
    invoke-direct {p0}, Lcom/arizona/launcher/ui/settings/SettingsPageFragment;->getViewModel()Lcom/arizona/launcher/MainViewModel;

    move-result-object p3

    invoke-virtual {p3}, Lcom/arizona/launcher/MainViewModel;->getPlayerNick()Ljava/lang/String;

    move-result-object p3""", "")

    replace_code_between_lines(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ui\\servers\\ServerInfoActivity.smali", ".method private final startGame(Lcom/arizona/launcher/model/servers/SAMPServerInfo;)V", ".end method", """.method private final startGame(Lcom/arizona/launcher/model/servers/SAMPServerInfo;)V
        .locals 10

        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getServerType()Lcom/arizona/launcher/model/servers/ServerType;

        move-result-object v0

        invoke-virtual {v0}, Lcom/arizona/launcher/model/servers/ServerType;->getComingSoon()Z

        move-result v0

        const/4 v1, 0x0

        if-eqz v0, :cond_0

        new-instance p1, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;

        move-object v0, p0

        check-cast v0, Landroid/content/Context;

        invoke-direct {p1, v0}, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;-><init>(Landroid/content/Context;)V

        const-string/jumbo v0, "\u041f\u043e\u043a\u0430 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u043e"

        check-cast v0, Ljava/lang/CharSequence;

        invoke-virtual {p1, v0}, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;->setTitle(Ljava/lang/CharSequence;)Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;

        move-result-object p1

        const-string v0, "Coming soon..."

        check-cast v0, Ljava/lang/CharSequence;

        invoke-virtual {p1, v0}, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;->setMessage(Ljava/lang/CharSequence;)Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;

        move-result-object p1

        sget v0, Lcom/arizona/game/R$string;->ok:I

        new-instance v2, Lcom/arizona/launcher/ui/servers/ServerInfoActivity$$ExternalSyntheticLambda6;

        invoke-direct {v2, p0}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity$$ExternalSyntheticLambda6;-><init>(Lcom/arizona/launcher/ui/servers/ServerInfoActivity;)V

        invoke-virtual {p1, v0, v2}, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;->setPositiveButton(ILandroid/content/DialogInterface$OnClickListener;)Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;

        move-result-object p1

        invoke-virtual {p1, v1}, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;->setCancelable(Z)Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;

        move-result-object p1

        invoke-virtual {p1}, Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;->show()Landroidx/appcompat/app/AlertDialog;

        return-void

        :cond_0
        move-object v0, p0

        check-cast v0, Landroid/content/Context;

        invoke-static {v0}, Landroidx/preference/PreferenceManager;->getDefaultSharedPreferences(Landroid/content/Context;)Landroid/content/SharedPreferences;

        move-result-object v2

        invoke-direct {p0}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity;->getMainViewModel()Lcom/arizona/launcher/MainViewModel;

        move-result-object v3

        invoke-virtual {v3, p1}, Lcom/arizona/launcher/MainViewModel;->addServerToLastPlayed(Lcom/arizona/launcher/model/servers/SAMPServerInfo;)V

        new-instance v3, Ljava/io/File;

        invoke-static {}, Landroid/os/Environment;->getExternalStorageDirectory()Ljava/io/File;

        move-result-object v4

        const-string v5, "Android/data/com.arizona21.game.web/files/SAMP/"

        invoke-direct {v3, v4, v5}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

        invoke-virtual {v3}, Ljava/io/File;->mkdirs()Z

        new-instance v3, Ljava/io/File;

        invoke-static {}, Landroid/os/Environment;->getExternalStorageDirectory()Ljava/io/File;

        move-result-object v4

        const-string v5, "Android/data/com.arizona21.game.web/files/SAMP/settings.json"

        invoke-direct {v3, v4, v5}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

        invoke-virtual {v3}, Ljava/io/File;->exists()Z

        move-result v4

        if-eqz v4, :cond_1

        invoke-virtual {v3}, Ljava/io/File;->delete()Z

        :cond_1
        :try_start_0
        invoke-virtual {v3}, Ljava/io/File;->createNewFile()Z
        :try_end_0
        .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

        goto :goto_0

        :catch_0
        move-exception v4

        invoke-virtual {v4}, Ljava/io/IOException;->printStackTrace()V

        :goto_0
        new-instance v4, Ljava/io/BufferedWriter;

        new-instance v5, Ljava/io/FileWriter;

        invoke-direct {v5, v3}, Ljava/io/FileWriter;-><init>(Ljava/io/File;)V

        check-cast v5, Ljava/io/Writer;

        invoke-direct {v4, v5}, Ljava/io/BufferedWriter;-><init>(Ljava/io/Writer;)V

        check-cast v4, Ljava/io/Writer;
        
        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getId()I

        move-result v7
        
        const/16 v8, 0x1e
        
        new-instance v3, Lorg/json/JSONObject;

        invoke-direct {v3}, Lorg/json/JSONObject;-><init>()V

        new-instance v5, Lorg/json/JSONObject;

        invoke-direct {v5}, Lorg/json/JSONObject;-><init>()V
        
        if-le v7, v8, :cond_8
        
        new-instance v6, Lorg/json/JSONObject;

        invoke-direct {v6}, Lorg/json/JSONObject;-><init>()V

        const/4 v7, 0x0

        const-string v8, "id"

        invoke-virtual {v6, v8, v7}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

        move-result-object v6

        const-string/jumbo v7, "serverid"

        const/4 v8, 0x0

        invoke-virtual {v6, v7, v8}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

        move-result-object v6
        
        new-instance v8, Lorg/json/JSONObject;

        invoke-direct {v8}, Lorg/json/JSONObject;-><init>()V
        
        const-string v7, "ip"
        
        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getAddress()Ljava/net/InetAddress;

        move-result-object v9

        invoke-virtual {v9}, Ljava/net/InetAddress;->getHostAddress()Ljava/lang/String;

        move-result-object v9

        invoke-virtual {v8, v7, v9}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v8

        const-string v7, "port"
        
        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getPort()I

        move-result v9

        invoke-virtual {v8, v7, v9}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

        move-result-object v8

        const-string v7, "test"

        invoke-virtual {v5, v7, v8}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5
        
        const-string/jumbo v7, "server"

        invoke-virtual {v5, v7, v6}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5
       

        const-string v6, "client"

        invoke-virtual {v3, v6, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v3
        
        
        goto :cond_9
         
        :cond_8
        
        new-instance v6, Lorg/json/JSONObject;

        invoke-direct {v6}, Lorg/json/JSONObject;-><init>()V

        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getServerType()Lcom/arizona/launcher/model/servers/ServerType;

        move-result-object v7

        invoke-virtual {v7}, Lcom/arizona/launcher/model/servers/ServerType;->getBackendLaunchCode()I

        move-result v7

        const-string v8, "id"

        invoke-virtual {v6, v8, v7}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

        move-result-object v6

        const-string/jumbo v7, "serverid"

        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getId()I

        move-result v8

        invoke-virtual {v6, v7, v8}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

        move-result-object v6

        const-string/jumbo v7, "server"

        invoke-virtual {v5, v7, v6}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5
        

        const-string v6, "client"

        invoke-virtual {v3, v6, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v3
        
        :cond_9

        new-instance v5, Lorg/json/JSONObject;

        invoke-direct {v5}, Lorg/json/JSONObject;-><init>()V
        

        invoke-direct {p0}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity;->getMainViewModel()Lcom/arizona/launcher/MainViewModel;

        move-result-object v6

        invoke-virtual {v6}, Lcom/arizona/launcher/MainViewModel;->getPlayerNick()Ljava/lang/String;

        move-result-object v6

        const-string v7, "nickname"

        invoke-virtual {v5, v7, v6}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5

        const-string v6, "chat_pagesize"

        const/4 v7, 0x0

        if-eqz v2, :cond_2

        const/4 v8, 0x1

        invoke-interface {v2, v6, v8}, Landroid/content/SharedPreferences;->getInt(Ljava/lang/String;I)I

        move-result v8

        invoke-static {v8}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

        move-result-object v8

        goto :goto_1

        :cond_2
        move-object v8, v7

        :goto_1
        invoke-virtual {v5, v6, v8}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5

        const-string v6, "chat_fontsize"

        if-eqz v2, :cond_3

        const/4 v8, 0x2

        invoke-interface {v2, v6, v8}, Landroid/content/SharedPreferences;->getInt(Ljava/lang/String;I)I

        move-result v8

        invoke-static {v8}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

        move-result-object v8

        goto :goto_2

        :cond_3
        move-object v8, v7

        :goto_2
        invoke-virtual {v5, v6, v8}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5

        const-string v6, "chat_print_timestamp"

        if-eqz v2, :cond_4

        invoke-interface {v2, v6, v1}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

        move-result v8

        invoke-static {v8}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

        move-result-object v8

        goto :goto_3

        :cond_4
        move-object v8, v7

        :goto_3
        invoke-virtual {v5, v6, v8}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v5

        const-string v6, "head_moving"

        if-eqz v2, :cond_5

        invoke-interface {v2, v6, v1}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

        move-result v2

        invoke-static {v2}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

        move-result-object v7

        :cond_5
        invoke-virtual {v5, v6, v7}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v2

        const-string v5, "launcher"

        invoke-virtual {v3, v5, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

        move-result-object v2

        :try_start_1
        move-object v3, v4
        
        check-cast v3, Ljava/io/BufferedWriter;

        invoke-virtual {v2}, Lorg/json/JSONObject;->toString()Ljava/lang/String;

        move-result-object v2

        invoke-virtual {v3, v2}, Ljava/io/BufferedWriter;->write(Ljava/lang/String;)V

        check-cast v4, Ljava/io/BufferedWriter;

        invoke-virtual {v4}, Ljava/io/BufferedWriter;->close()V
        :try_end_1
        .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

        goto :goto_4

        :catch_1
        move-exception v2

        invoke-virtual {v2}, Ljava/lang/Exception;->printStackTrace()V

        const-string v2, "ServerInfoActivity"

        const-string/jumbo v3, "write failed: ENOSPC (No space left on device)"

        invoke-static {v2, v3}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

        :goto_4
        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getServerType()Lcom/arizona/launcher/model/servers/ServerType;

        move-result-object v2

        sget-object v3, Lcom/arizona/launcher/model/servers/ServerType;->ARIZONA_MOBILE:Lcom/arizona/launcher/model/servers/ServerType;

        if-eq v2, v3, :cond_6

        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getServerType()Lcom/arizona/launcher/model/servers/ServerType;

        move-result-object v2

        sget-object v3, Lcom/arizona/launcher/model/servers/ServerType;->RODINA:Lcom/arizona/launcher/model/servers/ServerType;

        if-eq v2, v3, :cond_6

        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getServerType()Lcom/arizona/launcher/model/servers/ServerType;

        move-result-object v2

        sget-object v3, Lcom/arizona/launcher/model/servers/ServerType;->RODINA_MOBILE:Lcom/arizona/launcher/model/servers/ServerType;

        if-ne v2, v3, :cond_7

        :cond_6
        invoke-virtual {p0}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity;->getApplicationContext()Landroid/content/Context;

        move-result-object v2

        invoke-static {v2}, Lcom/android/volley/toolbox/Volley;->newRequestQueue(Landroid/content/Context;)Lcom/android/volley/RequestQueue;

        move-result-object v2

        const-string v3, "newRequestQueue(...)"

        invoke-static {v2, v3}, Lkotlin/jvm/internal/Intrinsics;->checkNotNullExpressionValue(Ljava/lang/Object;Ljava/lang/String;)V

        sget-object v3, Lkotlin/random/Random;->Default:Lkotlin/random/Random$Default;

        const/4 v4, 0x3

        const/4 v5, 0x6

        invoke-virtual {v3, v4, v5}, Lkotlin/random/Random$Default;->nextInt(II)I

        move-result v3

        move v4, v1

        :goto_5
        if-ge v4, v3, :cond_7

        new-instance v5, Lcom/android/volley/toolbox/StringRequest;

        invoke-virtual {p1}, Lcom/arizona/launcher/model/servers/SAMPServerInfo;->getAddress()Ljava/net/InetAddress;

        move-result-object v6

        new-instance v7, Ljava/lang/StringBuilder;

        const-string v8, "http://"

        invoke-direct {v7, v8}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

        invoke-virtual {v7, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

        const-string v6, "/"

        invoke-virtual {v7, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

        invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

        move-result-object v6

        new-instance v7, Lcom/arizona/launcher/ui/servers/ServerInfoActivity$$ExternalSyntheticLambda7;

        invoke-direct {v7}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity$$ExternalSyntheticLambda7;-><init>()V

        new-instance v8, Lcom/arizona/launcher/ui/servers/ServerInfoActivity$$ExternalSyntheticLambda8;

        invoke-direct {v8}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity$$ExternalSyntheticLambda8;-><init>()V

        invoke-direct {v5, v1, v6, v7, v8}, Lcom/android/volley/toolbox/StringRequest;-><init>(ILjava/lang/String;Lcom/android/volley/Response$Listener;Lcom/android/volley/Response$ErrorListener;)V

        check-cast v5, Lcom/android/volley/Request;

        invoke-virtual {v2, v5}, Lcom/android/volley/RequestQueue;->add(Lcom/android/volley/Request;)Lcom/android/volley/Request;

        const-wide/16 v5, 0x12c

        invoke-static {v5, v6}, Ljava/lang/Thread;->sleep(J)V

        add-int/lit8 v4, v4, 0x1

        goto :goto_5

        :cond_7
        invoke-direct {p0}, Lcom/arizona/launcher/ui/servers/ServerInfoActivity;->getMainViewModel()Lcom/arizona/launcher/MainViewModel;

        move-result-object p1

        invoke-virtual {p1}, Lcom/arizona/launcher/MainViewModel;->setNotFirstRun()V

        new-instance p1, Landroid/content/Intent;

        const-class v1, Lcom/arizona/game/GTASA;

        invoke-direct {p1, v0, v1}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

        iget-object v0, p0, Lcom/arizona/launcher/ui/servers/ServerInfoActivity;->launchGTASA:Landroidx/activity/result/ActivityResultLauncher;

        invoke-virtual {v0, p1}, Landroidx/activity/result/ActivityResultLauncher;->launch(Ljava/lang/Object;)V

        return-void
    .end method
    """.replace("com.arizona21.game.web", "com.arizona.game"))


    search_and_replace_after(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainActivity.smali", ".method protected onCreate", "return-void","""    invoke-virtual {p0}, Lcom/arizona/launcher/MainActivity;->fixLoadBG()Ljava/lang/String;
        move-result-object v1
        invoke-direct {p0, v1}, Lcom/arizona/launcher/MainActivity;->installBackground(Ljava/lang/String;)V
        return-void
    """)

    insert_code_before_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainActivity.smali", ".method protected onCreate", """.method private final installBackground(Ljava/lang/String;)V
        .locals 1

        invoke-static {}, Lcom/squareup/picasso/Picasso;->get()Lcom/squareup/picasso/Picasso;

        move-result-object v0

        invoke-virtual {v0, p1}, Lcom/squareup/picasso/Picasso;->load(Ljava/lang/String;)Lcom/squareup/picasso/RequestCreator;

        move-result-object p1

        sget v0, Lcom/arizona/game/R$drawable;->launcher_bg:I

        invoke-virtual {p1, v0}, Lcom/squareup/picasso/RequestCreator;->placeholder(I)Lcom/squareup/picasso/RequestCreator;

        move-result-object p1

        iget-object v0, p0, Lcom/arizona/launcher/MainActivity;->binding:Lcom/arizona/game/databinding/ActivityMainBinding;

        iget-object v0, v0, Lcom/arizona/game/databinding/ActivityMainBinding;->imageView5:Landroid/widget/ImageView;

        check-cast v0, Landroid/widget/ImageView;

        invoke-virtual {p1, v0}, Lcom/squareup/picasso/RequestCreator;->into(Landroid/widget/ImageView;)V

        return-void
    .end method

    .method public final fixLoadBG()Ljava/lang/String;
        .locals 7

        invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

        move-result-object v0

        invoke-virtual {v0}, Ljava/util/UUID;->toString()Ljava/lang/String;

        move-result-object v1

        const-string v0, "randomUUID().toString()"

        invoke-static {v1, v0}, Lkotlin/jvm/internal/Intrinsics;->checkNotNullExpressionValue(Ljava/lang/Object;Ljava/lang/String;)V

        const-string v2, "-"

        const-string v3, ""

        const/4 v4, 0x0

        const/4 v5, 0x4

        const/4 v6, 0x0

        invoke-static/range {v1 .. v6}, Lkotlin/text/StringsKt;->replace$default(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ZILjava/lang/Object;)Ljava/lang/String;

        move-result-object v0

        new-instance v1, Ljava/lang/StringBuilder;

        const-string v2, "https://radarebot.hhos.net/apis/launcher_bg.php?project=ARIZONA&sign="

        invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

        const/4 v2, 0x0

        const/16 v3, 0xc

        invoke-virtual {v0, v2, v3}, Ljava/lang/String;->substring(II)Ljava/lang/String;

        move-result-object v0

        const-string v2, "this as java.lang.String\u2026ing(startIndex, endIndex)"

        invoke-static {v0, v2}, Lkotlin/jvm/internal/Intrinsics;->checkNotNullExpressionValue(Ljava/lang/Object;Ljava/lang/String;)V

        invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

        invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

        move-result-object v0

        return-object v0
    .end method

    """)


    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\data\\repository\\settings\\SettingsRepository.smali", r"\u041f\u043e\u043b\u043d\u044b\u0439 \u044d\u043a\u0440\u0430\u043d", r"\u041E\u0442\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0435 MonetLoader")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\data\\repository\\settings\\SettingsRepository.smali", "invoke-direct {p0, p1}, Lcom/arizona/launcher/data/repository/settings/SettingsRepository;->getSettingsList(Landroid/content/SharedPreferences;)Ljava/util/List;", "invoke-static {p1}, Lcom/arzmod/radare/SettingsPatch;->getSettingsList(Landroid/content/SharedPreferences;)Ljava/util/List;")

    replace_block_in_file(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASAInternal.smali", """invoke-static {v2, v0}, Ljava/util/Objects;->equals(Ljava/lang/Object;Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_0

    const-string v1, "SCAnd"

    invoke-static {v1}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    goto :goto_0

    :cond_0
    const-string v1, "ImmEmulatorJ"

    invoke-static {v1}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    :goto_0
    const-string v1, "GTASA"

    invoke-static {v1}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string/jumbo v1, "samp"

    invoke-static {v1}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    invoke-static {v2, v0}, Ljava/util/Objects;->equals(Ljava/lang/Object;Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    const-string v0, "bass"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "bass_fx"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "bass_ssl"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V""", "")



    append_to_file(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASAInternal.smali", """
.method public loadLibraries(Landroid/content/Context;)V
    .locals 2
    
    const-string v0, "ImmEmulatorJ"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "GTASA"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "bass"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "bass_fx"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "bass_ssl"
    
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
    
    const-string v0, "monetloader_work"

    invoke-static {v0}, Lcom/arzmod/radare/SettingsPatch;->getSettingsKeyValue(Ljava/lang/String;)Z

    move-result v0
    
    if-nez v0, :cond_0
    
    const-string v0, "sampv"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->firstTimePatches()V
    
    goto :goto_0

    :cond_0
    
    const-string v0, "samp"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->firstTimePatches()V

    const-string v0, "monetloader"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "AML"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
 
    :goto_0
    return-void
.end method""")

    replace_code_between_lines(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASA.smali", ".method private InitSettingWrapper(I)V", ".end method", """.method private InitSettingWrapper(I)V
    .locals 2
    invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->InitSettingWrapper()V
    return-void
.end method""")


    replace_code_between_lines(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService.smali", ".method private static final checkUpdate$lambda$1$lambda$0(Lorg/json/JSONObject;Ljava/lang/String;Ljava/lang/String;)Lorg/json/JSONArray;", ".end method", """.method private static final checkUpdate$lambda$1$lambda$0(Lorg/json/JSONObject;Ljava/lang/String;Ljava/lang/String;)Lorg/json/JSONArray;
        .locals 1

        const-string v2, "data"

        invoke-virtual {p0, v2}, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;

        move-result-object v1

        invoke-virtual {v1, v2}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;

        move-result-object v1

        return-object v1
    .end method
    """)

    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ui\\settings\\SettingsPageFragment.smali", ".method private final checkGame", "Landroid/app/ProgressDialog;->show()V", """
    new-instance v0, Lcom/arzmod/radare/UpdateServicePatch;

    invoke-direct {v0}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V

    invoke-virtual {v0}, Lcom/arzmod/radare/UpdateServicePatch;->deleteMods()V
    """)


    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService.smali", ".method private final checkSingleFile", "move-object/from16 v1, p1", """
    new-instance v3, Lcom/arzmod/radare/UpdateServicePatch;
    invoke-direct {v3}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V

    invoke-virtual {v3, v1}, Lcom/arzmod/radare/UpdateServicePatch;->isUserFile(Ljava/io/File;)Z

    move-result v3

    if-eqz v3, :continue_execution

    const/4 v3, 0x1
    
    return v3

    :continue_execution
    """)

    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService.smali", ".method private final checkGameDataUpdate", "move-object/from16 v7, p1", """
        new-instance v8, Lcom/arzmod/radare/UpdateServicePatch;
        invoke-direct {v8}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V
        invoke-virtual {v8, v7}, Lcom/arzmod/radare/UpdateServicePatch;->checkUserFiles(Lorg/json/JSONArray;)V
    """)


    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASAInternal.smali", ".method public onCreate", ".end annotation", "\n    invoke-virtual {p0, p0}, Lcom/arizona/game/GTASAInternal;->loadLibraries(Landroid/content/Context;)V")

    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\game\\GTASA.smali", ".method public onCreate", ".locals", """
    invoke-virtual {p0}, Lcom/arizona/launcher/MainActivity;->getApplicationContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0}, Lcom/arzmod/radare/AppContext;->setContext(Landroid/content/Context;)V
    """)

    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\ArizonaApplication.smali", ".method public onCreate", ".locals", """
    invoke-virtual {p0}, Lcom/arizona/launcher/ArizonaApplication;->getApplicationContext()Landroid/content/Context;

    move-result-object v1

    new-instance v0, Lcom/arzmod/radare/ApplicationStart;

    invoke-direct {v0, v1}, Lcom/arzmod/radare/ApplicationStart;-><init>(Landroid/content/Context;)V

    invoke-virtual {v0}, Lcom/arzmod/radare/ApplicationStart;->start()V
    """)

    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainActivity.smali", ".method protected onCreate", ".locals", """
    invoke-virtual {p0}, Lcom/arizona/launcher/MainActivity;->getApplicationContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0}, Lcom/arzmod/radare/AppContext;->setContext(Landroid/content/Context;)V
    """)

    insert_smali_code_after_line(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\MainEntrench.smali", ".method protected onCreate", "invoke-super {p0, p1}, Lcom/arizona/launcher/Hilt_MainEntrench;->onCreate(Landroid/os/Bundle;)V", """

    invoke-static {p0}, Lcom/arzmod/radare/AppContext;->setContext(Landroid/content/Context;)V
    """)

    replace_files(working_dir + "resource\\ic_chat_hello", "launcher_donate_arz_ic")
    replace_files(working_dir + "resource\\launcher_donate_bg_svg", "launcher_donate_bg_svg")


    shutil.copy(working_dir + f'{name}/lib/armeabi-v7a/libsamp.so', working_dir + f'{name}/lib/armeabi-v7a/libsampv.so')

    shutil.copy(working_dir + 'libpatch\\libluajit-5.1.so', working_dir + f'{name}\\lib\\armeabi-v7a/')
    shutil.copy(working_dir + 'libpatch\\libmonetloader.so', working_dir + f'{name}\\lib\\armeabi-v7a/')
    shutil.copy(working_dir + 'libpatch\\libAML.so', working_dir + f'{name}\\lib\\armeabi-v7a/')
    shutil.rmtree(working_dir + f'{name}/lib/arm64-v8a/')

    if arzmod_dev:
        db = arzmod_release.connect_to_db()
        cursor = db.cursor()

        global launcher_ver, launcher_vername, launcher_verlua
        launcher_ver, launcher_vername = get_app_version()
        cursor.execute("SELECT status FROM settings WHERE var = 'arizona_verjson'")
        result = cursor.fetchone() 
        result = int(result[0])
        launcher_verlua = launcher_ver if result + 1 < launcher_ver else result + 1
        set_version(launcher_ver, launcher_verlua)

        cursor.close()
        db.close()

def set_version(version, need):
    print(f"Set update version from {version} to {need}")
    search_and_replace(working_dir + f"{name}\\{arz_src_path}\\com\\arizona\\launcher\\UpdateService.smali", str(hex(int(version))), str(hex(int(need))))



if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "app-debug"
    rename = name

    app_dir = os.path.join(patcher_dir, name)
    res_folder = os.path.join(app_dir, 'res')
    dist_dir = os.path.join(app_dir, "dist")
    lib_path = os.path.join(app_dir, "lib")
    print(f"Название файла: {name}")
    print("Папка проекта:", app_dir)
    print("Папка ресурсов:", res_folder)
    print("Папка билбиотек:", lib_path)
    print("Папка c APK:", dist_dir)

    decompile_apk()

    if not os.path.exists(working_dir + "\\" + name):
        print("The project path doesn't exists")
        exit()
        
    arzmod_patch()
    rename = "app-debug"

    if "-test" in sys.argv:
        print("None")

    build_apk()
    if config.build_sign:
        sign_apk(rename, config.key_password)
        
    if config.build_download:
        download_apk(rename)

    if "-release" in sys.argv:
        if arzmod_dev:
            arzmod_release.create_release()
        else: print("why you use release tag, but you dont have release module?")

    print("Process completed successfully.")
