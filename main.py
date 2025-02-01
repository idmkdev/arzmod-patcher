import os
import re
import sys
import time
import json
import yaml
import config
import shutil
import zipfile
import requests
import threading
import subprocess
from tqdm import tqdm
import xml.etree.ElementTree as ET

try:
    import arzmod_release
    arzmod_dev = True
except ImportError:
    arzmod_dev = False

os.chdir(os.path.dirname(os.path.abspath(__file__)))

working_dir = os.getcwd().replace('\\', '/')
name = "app"
app_dir, dist_dir, project, usearm64, arzmodbuild = None, None, 0, False, False
launcher_verlua, launcher_ver, launcher_vername = 0, 0, "None"
arz_src_path = "smali_classes3"
arz_ui_path = "smali_classes5"

ARIZONA_MOBILE = 0
RODINA_MOBILE = 1

if arzmod_dev:
    arzmod_release.check_connection()


############################# HELP FUNCTIONS #######################################

def get_app_version():
    try:
        with open(app_dir + "/apktool.yml", 'r', encoding='utf-8') as file:
            content = file.read()

            version_code_match = re.search(r"versionCode:\s*'(\d+)'", content)
            version_name_match = re.search(r"versionName:\s*([^']+)", content)

            version_code = int(version_code_match.group(1)) if version_code_match else None
            version_name = version_name_match.group(1).replace("\n", "") if version_name_match else 'Unknown'

            return version_code, version_name
    except Exception as e:
        print(f"Error reading {app_dir}/apktool.yml: {e}")
        return None, None

def replace_files(base_path, name):
    res_folder = f"{app_dir}/res"
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

                file_path = f"{dirpath}/{filename}"
                shutil.copy(source_file, file_path)
                files_replaced += 1

    if files_replaced > 0:
        print(f"Для {name} заменено файлов: {files_replaced}")
    else:
        print(f"Не было найдено файлов для замены {name}.")

def add_patched_lib(libname, arch):
    patched_lib = f"{working_dir}/libpatch/{arch}/{libname}"
    libpath = f"{app_dir}/lib/{arch}/{libname}"
    if os.path.exists(patched_lib):
        shutil.copy(patched_lib, libpath)
        print(f"Библиотека {libname} для {arch} успешно копирована!")
    elif os.path.exists(libpath):
        print(f"Библиотеки {libname} для копирования не найдено в libpatch. Используется исходная версия")
    else:
        exitWithError("Библиотеки для копирования не найдено")
    return libpath

def find_pattern(data: bytes, pattern: str) -> bool:
    pattern_bytes = []
    mask = []

    pattern = pattern.replace(" ", "").upper()
    i = 0
    while i < len(pattern):
        if pattern[i] == "?":
            pattern_bytes.append(0)
            mask.append(False)
            i += 1
            if i < len(pattern) and pattern[i] == "?":
                i += 1
        else:
            pattern_bytes.append(int(pattern[i:i+2], 16))
            mask.append(True)
            i += 2

    pattern_length = len(pattern_bytes)

    for i in range(len(data) - pattern_length + 1):
        found = True
        for j in range(pattern_length):
            if mask[j] and data[i + j] != pattern_bytes[j]:
                found = False
                break
        if found:
            return True

    return False

def add_game_version(version):
    try:
        if isinstance(version, str):
            version = ""

        profilepath = f"{working_dir}/resource/profile{str(version)}.json"
        libpath = add_patched_lib(f"libsamp{str(version)}.so", "armeabi-v7a")

        with open(profilepath, 'r', encoding='utf-8') as json_file:
            data = json.load(json_file)
        
        profile_name = data.get("profile_name")
        print(f"Проверяем профиль: {profile_name}")

        samp_name = data.get("samp_name")
        receiveignorerpc_pattern = data.get("receiveignorerpc_pattern")
        cnetgame_ctor_pattern = data.get("cnetgame_ctor_pattern")
            
        if libpath.endswith(samp_name):
            try:
                with open(libpath, 'rb') as lib_file:
                    lib_data = lib_file.read()
                    
                    if not find_pattern(lib_data, receiveignorerpc_pattern):
                        exitWithError(f"Паттерн ReceiveIgnoreRPC - {receiveignorerpc_pattern} не найден в {libpath}")
                    if not find_pattern(lib_data, cnetgame_ctor_pattern):
                        exitWithError(f"Паттерн CNetGame_ctor - {cnetgame_ctor_pattern} не найден в {libpath}")

                add_asset(profilepath)
            except Exception as e:
                exitWithError(f"Ошибка при проверке библиотеки: {e}")
        else:
            exitWithError("Файл библиотеки не совпадает с именем хука, проверка не возможна.")
    except Exception as e:
        exitWithError(f"Ошибка при обработке файлов: {e}")


def add_asset(base_path):
    asset_folder = f"{app_dir}/assets"
    armod_asset = f"{asset_folder}/arzmod"

    if not os.path.exists(asset_folder):
        print("Ошибка: папка 'assets' не найдена.")
        return

    os.makedirs(armod_asset, exist_ok=True)

    try:
        if os.path.isdir(base_path):
            destination_path = f"{armod_asset}/{os.path.basename(base_path)}"
            shutil.copytree(base_path, destination_path, dirs_exist_ok=True)
            print(f"Папка {base_path} успешно скопирована в {armod_asset}!")
        elif os.path.isfile(base_path):
            shutil.copy(base_path, armod_asset)
            print(f"Файл {base_path} успешно скопирован в {armod_asset}!")
        else:
            print(f"Ошибка: путь {base_path} не существует или недоступен.")
    except Exception as e:
        raise RuntimeError(f"Произошла ошибка: {e}")


def delete_lines(file_path, substring):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()

        filtered_lines = [line for line in lines if substring not in line]

        removed_count = len(lines) - len(filtered_lines)

        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(filtered_lines)
        
        print(f"Удалено строк: {removed_count}")
    except Exception as e:
        print("-------------------DEBUG-------------------")
        print("file_path:", file_path)
        print("substring:", substring)
        print(f"Ошибка: {e}")
        print("-------------------------------------------")
        exit()


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
    search_and_replace(app_dir + '/AndroidManifest.xml', old, new)

    for foldername, subfolders, filenames in os.walk(app_dir + f'/{arz_src_path}/'):
        for filename in filenames:
            file_path = f"{foldername}/{filename}"
            search_and_replace(file_path, old, new, True)


def set_xml_string(string_id, new_string):
    print(f"Set XML string of id {string_id} = {new_string}")
    file_path = app_dir + '/res/values/strings.xml'
    tree = ET.parse(file_path)
    root = tree.getroot()
    xml_string = root.find(f"./string[@name='{string_id}']")
    xml_string.text = new_string
    tree.write(file_path, encoding="utf-8")

def download_file(url, filepath):
    try:
        print(f"Скачиваем файл: {url}")
        response = requests.get(url, stream=True)
        response.raise_for_status()
        total_size = int(response.headers.get('content-length', 0))
        
        with open(filepath, 'wb') as file, tqdm(
            desc=filepath,
            total=total_size,
            unit='B',
            unit_scale=True,
            unit_divisor=1024
        ) as bar:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
                bar.update(len(chunk))
        
        print(f"Файл успешно скачан и сохранён как {filepath}")
    except requests.RequestException as e:
        exitWithError(f"Ошибка при скачивании файла: {e}")

def get_version(url):
    try:
        response = requests.get(url)
        response.raise_for_status() 
        data = response.json()
        version = int(data.get("launcherVersion"))
        return version
    except requests.RequestException as e:
        exitWithError(f"Ошибка запроса: {e}")
        return None
    except json.JSONDecodeError as e:
        exitWithError(f"Ошибка при парсинге JSON: {e}")
        return None


def decompile_apk():
    print("Decompiling APK...")
    run_command(f"apktool d {name}.apk -f", cwd=working_dir)

def build_apk():
    print("Building APK...")
    search_and_replace(app_dir + "/AndroidManifest.xml", '<property android:name="android.adservices.AD_SERVICES_CONFIG" android:resource="@xml/ga_ad_services_config" />', "", True)
    run_command(f"apktool b {name} --use-aapt2", cwd=working_dir)

def sign_apk(rename, keypass):
    print("Aligning APK...")
    cname = name
    if name == rename:
        os.rename(f"{dist_dir}/{name}.apk", f"{dist_dir}/{name}-nosign.apk")
        cname = f"{name}-nosign"

    aligned_apk = f"{dist_dir}/{rename}.apk"
    if os.path.exists(aligned_apk):
        os.remove(aligned_apk)
        print(f"Removed file {aligned_apk}")

    run_command(f"zipalign -p 4 {dist_dir}/{cname}.apk {aligned_apk}", cwd=working_dir)

    print("Signing APK...")
    keystore = f"{working_dir}/key/{config.key_name}"
    if os.path.exists(keystore):
        run_command(f"apksigner sign --ks {keystore} --v4-signing-enabled true --ks-pass pass:{keypass} {aligned_apk}", cwd=working_dir)
        print("Delete cache")
        os.remove(f"{dist_dir}/{cname}.apk")
        os.remove(f"{aligned_apk}.idsig")
    else:
        exitWithError("Key at path: workdir + key/keystore.jks doesn't found")

def compile_dex_additions(dex_name):
    run_command(f"python dexcompile.py {dex_name}", cwd=working_dir)
    shutil.move(f"{working_dir}/{dex_name}/out/{dex_name}.dex", app_dir)

def update_classes(apk_path):
    if not os.path.isfile(apk_path):
        exitWithError(f"Файл {apk_path} не найден.")
        return

    classes_dir = f"{working_dir}/arzmob-classes"
    
    try:
        with zipfile.ZipFile(apk_path, 'r') as apk:
            for file in apk.namelist():
                if file.startswith("classes") and file.endswith(".dex"):
                    print(f"Извлекаем {file}...")
                    apk.extract(file, classes_dir)
        print(f"Все файлы classes*.dex извлечены в папку {classes_dir}.")
        run_command(f"python dex2jar.py", cwd=classes_dir)
    except zipfile.BadZipFile:
        print("Ошибка: APK-файл поврежден или не является архивом ZIP.")
        sys.exit(1)

def download_apk(rename):
    aligned_apk = f"{dist_dir}/{rename}.apk"
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
    package_name = "com.arizona.game" if project == ARIZONA_MOBILE else "com.rodina.game"
    set_package_name("com.arizona21.game.web" if project == ARIZONA_MOBILE else "com.rodina21.game.web", package_name)

    if arzmodbuild:
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

    src_path = app_dir + f"/{arz_src_path}"
    ui_path = app_dir + f"/{arz_ui_path}"

    if arzmodbuild:
        if project == ARIZONA_MOBILE:
            search_and_replace(src_path + "/com/arizona/launcher/util/FileServers.smali", "https://mob.maz-ins.com/game/release/", "https://download.arzmod.com/arz_modclient/")
            search_and_replace(src_path + "/com/arizona/launcher/util/FileServers.smali", "https://arz-mob.react-group.tech/game/release/", "https://radarebot.hhos.net/arz_modclient/")
        elif project == RODINA_MOBILE:
            search_and_replace(src_path + "/com/arizona/launcher/util/FileServers.smali", "https://mob.azinternal.com/release/", "https://download.arzmod.com/rod_modclient/")
            search_and_replace(src_path + "/com/arizona/launcher/util/FileServers.smali", "https://rod-mob.react-group.tech/release/", "https://radarebot.hhos.net/rod_modclient/")
        else:
            exitWithError("project == null?")
        search_and_replace(src_path + "/com/arizona/launcher/di/ArizonaLauncherAPIModule.smali", "https://api.arizona-five.com/", "https://api.arzmod.com/")
        search_and_replace(src_path + "/com/arizona/launcher/MainEntrench.smali", " release_web\"", " arzmod\"")
        search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", f"/data/{package_name}/files", "")
        search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", f"/data/{package_name}", "")
        search_and_replace(src_path + "/com/arizona/launcher/UpdateService$isAllFilesOk$1.smali", f"/data/{package_name}/files", "")
        search_and_replace(src_path + "/com/arizona/launcher/ui/information_main/InformationPageFragment.smali", "https://arizona-rp.com/shop" if project == ARIZONA_MOBILE else "https://rodina-rp.com/shop", "https://t.me/cleodis")
        search_and_replace(ui_path + "/ru/mrlargha/commonui/elements/hud/presentation/Hud.smali", "arizona-rp.com" if project == ARIZONA_MOBILE else "rodina-rp.com", "arzmod.com")
        if project == ARIZONA_MOBILE:
            search_and_replace(ui_path + "/ru/mrlargha/commonui/elements/hud/presentation/api/HudApi.smali", "desktop/ping/Arizona/ping.json", "https://radarebot.hhos.net/api/serverlist")

    else:
        search_and_replace(src_path + "/com/arizona/launcher/MainEntrench.smali", " release_web\"", " arzmod_community\"")

    search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$14$lambda$12(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$14$lambda$13(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V")
    search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$1(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V", "invoke-static {p0, p1, p2}, Lcom/arizona/launcher/MainEntrench$IncomingHandler;->handleMessage$lambda$14$lambda$13(Lcom/arizona/launcher/MainEntrench;Landroid/content/DialogInterface;I)V")    
    search_and_replace(src_path + "/com/arizona/launcher/UpdateService$isAllFilesOk$1.smali", "iget-boolean v6, p0, Lcom/arizona/launcher/UpdateService$isAllFilesOk$1;->$purgeExtraFiles:Z", "const/4 v6, 0x0")
    search_and_replace(src_path + "/com/arizona/launcher/ui/settings/SettingsPageFragment.smali", "135.181.129.36", "join.arzfun.com")
    search_and_replace(src_path + "/com/arizona/launcher/ui/settings/SettingsPageFragment.smali", "invoke-virtual {v0, v1}, Landroid/widget/ImageView;->setVisibility(I)V", "")
    search_and_replace(src_path + "/com/arizona/launcher/data/database/NotificationHistoryDAO_Impl.smali", "SELECT * FROM notifications ORDER BY date LIMIT 5", "SELECT * FROM notifications ORDER BY id DESC")
    search_and_replace(src_path + "/com/arizona/launcher/data/database/NotificationHistoryDAO_Impl$1.smali", "INSERT OR REPLACE INTO `notifications` (`id`,`date`,`title`,`text`,`imageUrl`) VALUES (nullif(?, 0),?,?,?,?)", "WITH Params AS (SELECT ? AS id, ? AS date, ? AS title, ? AS text, ? AS imageUrl) INSERT INTO notifications (date, title, text, imageUrl) SELECT date, title, text, imageUrl FROM Params WHERE NOT EXISTS (SELECT 1 FROM notifications WHERE (title || text || imageUrl) = (SELECT title || text || imageUrl FROM Params))")
    search_and_replace(src_path + "/com/arizona/launcher/data/database/NotificationHistoryDAO_Impl$2.smali", "DELETE FROM notifications", "SELECT 1")    
    replace_code_between_lines(src_path + "/com/arizona/launcher/MessagingService.smali", "invoke-direct {p0}, Lcom/arizona/launcher/MessagingService;->getSettingsPreferences()Landroid/content/SharedPreferences;", "invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V", "")

    insert_code_before_line(src_path + "/com/arizona/game/GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", """.method public static native InitModloaderConfig(I)V
        .end method""")

    insert_code_before_line(src_path + "/com/arizona/game/GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", """.method public static native InitSetting(ZIZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V
        .end method""")

    search_and_replace(src_path + "/com/arizona/game/GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", ".method public static native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V") 

    manifest_path = app_dir + '/AndroidManifest.xml'

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



    update_xml_attribute(app_dir + "/res/layout/test_server_dialog.xml", "app", ".//com.google.android.material.textfield.TextInputLayout[@android:id='@id/textInputLayout3']", 'helperText', 'Никнейм')
    update_xml_attribute(app_dir + "/res/layout/test_server_dialog.xml", "android", ".//com.google.android.material.textfield.TextInputEditText[@android:id='@id/server_password_input']", 'inputType', 'text')
    update_xml_attribute(app_dir + "/res/layout/test_server_dialog.xml", "android", ".//TextView[@android:id='@id/textView12']", 'text', 'Подключение к SA:MP серверу')

    replace_block_in_file(src_path + "/com/arizona/launcher/ui/settings/SettingsPageFragment.smali", "const-string v1, \"CFTqKf40\"", """invoke-direct {p0}, Lcom/arizona/launcher/ui/settings/SettingsPageFragment;->getViewModel()Lcom/arizona/launcher/MainViewModel;

    move-result-object v1

    invoke-virtual {v1}, Lcom/arizona/launcher/MainViewModel;->getPlayerNick()Ljava/lang/String;

    move-result-object v1""")

    replace_block_in_file(src_path + "/com/arizona/launcher/ui/settings/SettingsPageFragment.smali", """
    const-string/jumbo p2, "pass"

    invoke-virtual {p1, p2, p3}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object p1""", "")

    replace_block_in_file(src_path + "/com/arizona/launcher/ui/settings/SettingsPageFragment.smali", """
    invoke-direct {p0}, Lcom/arizona/launcher/ui/settings/SettingsPageFragment;->getViewModel()Lcom/arizona/launcher/MainViewModel;

    move-result-object p3

    invoke-virtual {p3}, Lcom/arizona/launcher/MainViewModel;->getPlayerNick()Ljava/lang/String;

    move-result-object p3""", "")

    if arzmodbuild:
        search_and_replace_after(src_path + "/com/arizona/launcher/MainActivity.smali", ".method protected onCreate", "return-void","""    invoke-virtual {p0}, Lcom/arizona/launcher/MainActivity;->fixLoadBG()Ljava/lang/String;
            move-result-object v1
            invoke-direct {p0, v1}, Lcom/arizona/launcher/MainActivity;->installBackground(Ljava/lang/String;)V
            return-void
        """)

    insert_code_before_line(src_path + "/com/arizona/launcher/MainActivity.smali", ".method protected onCreate", """.method private final installBackground(Ljava/lang/String;)V
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

        const-string v2, "https://radarebot.hhos.net/apis/launcher_bg.php?project=""" + ("ARIZONA" if project == ARIZONA_MOBILE else "RODINA") + """&sign="

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

    append_to_file(src_path + "/com/arizona/game/GTASA.smali", """.method public InstallHud(III)V
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
    .end method""")

    search_and_replace(src_path + "/com/arizona/launcher/data/repository/settings/SettingsRepository.smali", "invoke-direct {p0, p1}, Lcom/arizona/launcher/data/repository/settings/SettingsRepository;->getSettingsList(Landroid/content/SharedPreferences;)Ljava/util/List;", "invoke-static {p1}, Lcom/arzmod/radare/SettingsPatch;->getSettingsList(Landroid/content/SharedPreferences;)Ljava/util/List;")

    delete_lines(src_path + "/com/arizona/game/GTASAInternal.smali", "Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V")


    append_to_file(src_path + "/com/arizona/game/GTASAInternal.smali", """
.method public static loadLibraryFromPath(Ljava/lang/String;)V
    .locals 1

    if-nez p0, :valid_path

    new-instance v0, Ljava/lang/NullPointerException;
    invoke-direct {v0}, Ljava/lang/NullPointerException;-><init>()V
    throw v0

    :valid_path
    const-class v0, Ljava/lang/System;
    invoke-static {p0}, Ljava/lang/System;->load(Ljava/lang/String;)V

    return-void
.end method""")





    replace_code_between_lines(src_path + "/com/arizona/game/GTASA.smali", ".method private InitSettingWrapper(I)V", ".end method", """.method private InitSettingWrapper(I)V
    .locals 2
    invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->InitSettingWrapper()V
    return-void
.end method""")

    if arzmodbuild:
        replace_code_between_lines(src_path + "/com/arizona/launcher/UpdateService.smali", ".method private static final checkUpdate$lambda$1$lambda$0(Lorg/json/JSONObject;Ljava/lang/String;Ljava/lang/String;)Lorg/json/JSONArray;", ".end method", """.method private static final checkUpdate$lambda$1$lambda$0(Lorg/json/JSONObject;Ljava/lang/String;Ljava/lang/String;)Lorg/json/JSONArray;
            .locals 1

            const-string v2, "data"

            invoke-virtual {p0, v2}, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;

            move-result-object v1

            invoke-virtual {v1, v2}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;

            move-result-object v1

            return-object v1
        .end method
        """)

    insert_smali_code_after_line(src_path + "/com/arizona/launcher/ui/settings/SettingsPageFragment.smali", ".method private final checkGame", "Landroid/app/ProgressDialog;->show()V", """
    new-instance v0, Lcom/arzmod/radare/UpdateServicePatch;

    invoke-direct {v0}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V

    invoke-virtual {v0}, Lcom/arzmod/radare/UpdateServicePatch;->deleteMods()V
    """)


    insert_smali_code_after_line(src_path + "/com/arizona/launcher/UpdateService.smali", ".method private final checkSingleFile", "move-object/from16 v1, p1", """
    new-instance v3, Lcom/arzmod/radare/UpdateServicePatch;
    invoke-direct {v3}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V

    invoke-virtual {v3, v1}, Lcom/arzmod/radare/UpdateServicePatch;->isUserFile(Ljava/io/File;)Z

    move-result v3

    if-eqz v3, :continue_execution

    const/4 v3, 0x1
    
    return v3

    :continue_execution
    """)

    insert_smali_code_after_line(src_path + "/com/arizona/launcher/UpdateService.smali", ".method private final checkGameDataUpdate", "move-object/from16 v7, p1", """
        new-instance v8, Lcom/arzmod/radare/UpdateServicePatch;
        invoke-direct {v8}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V
        invoke-virtual {v8, v7}, Lcom/arzmod/radare/UpdateServicePatch;->checkUserFiles(Lorg/json/JSONArray;)V
    """)


    insert_smali_code_after_line(src_path + "/com/arizona/game/GTASAInternal.smali", ".method public onCreate", ".end annotation", """
        invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->firstTimePatches()V""")

    insert_smali_code_after_line(src_path + "/com/arizona/game/GTASA.smali", ".method public onCreate", ".locals", """
    invoke-virtual {p0}, Lcom/arizona/launcher/MainActivity;->getApplicationContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0}, Lcom/arzmod/radare/AppContext;->setContext(Landroid/content/Context;)V
    """)

    insert_smali_code_after_line(src_path + "/com/arizona/launcher/ArizonaApplication.smali", ".method public onCreate", ".locals", """
    invoke-virtual {p0}, Lcom/arizona/launcher/ArizonaApplication;->getApplicationContext()Landroid/content/Context;

    move-result-object v1

    new-instance v0, Lcom/arzmod/radare/ApplicationStart;

    invoke-direct {v0, v1}, Lcom/arzmod/radare/ApplicationStart;-><init>(Landroid/content/Context;)V

    invoke-virtual {v0}, Lcom/arzmod/radare/ApplicationStart;->start()V
    """)

    insert_smali_code_after_line(src_path + "/com/arizona/launcher/MainActivity.smali", ".method protected onCreate", ".locals", """
    invoke-virtual {p0}, Lcom/arizona/launcher/MainActivity;->getApplicationContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {v0}, Lcom/arzmod/radare/AppContext;->setContext(Landroid/content/Context;)V
    """)

    insert_smali_code_after_line(src_path + "/com/arizona/launcher/MainEntrench.smali", ".method protected onCreate", "invoke-super {p0, p1}, Lcom/arizona/launcher/Hilt_MainEntrench;->onCreate(Landroid/os/Bundle;)V", """

    invoke-static {p0}, Lcom/arzmod/radare/AppContext;->setContext(Landroid/content/Context;)V
    """)

    if arzmodbuild:
        replace_files(working_dir + "/resource/ic_chat_hello", "launcher_donate_rodina_ic")
        replace_files(working_dir + "/resource/ic_chat_hello", "launcher_donate_arz_ic")
        replace_files(working_dir + "/resource/launcher_donate_bg_svg", "launcher_donate_bg_svg")


    shutil.copy(f'{app_dir}/lib/armeabi-v7a/libsamp.so', f'{app_dir}/lib/armeabi-v7a/libsampv.so')

    if usearm64:
        add_patched_lib("libluajit-5.1.so", "arm64-v8a")
        add_patched_lib("libmonetloader.so", "arm64-v8a")
    else:
        shutil.rmtree(app_dir + "/lib/arm64-v8a")

    add_patched_lib("libluajit-5.1.so", "armeabi-v7a")
    add_patched_lib("libmonetloader.so", "armeabi-v7a")
    add_patched_lib("libAML.so", "armeabi-v7a")
    add_game_version("actual")
    add_game_version(1508)


    global launcher_ver, launcher_vername, launcher_verlua
    launcher_ver, launcher_vername = get_app_version()

    if arzmodbuild:
        currentversion = get_version(f"https://radarebot.hhos.net/{ 'arz_modclient' if project == 'ARIZONA_MOBILE' else 'rod_modclient' }/update.json")
        if arzmod_dev:
            launcher_verlua = launcher_ver if currentversion + 1 < launcher_ver else currentversion + 1 
        else:
            launcher_verlua = currentversion
    elif not arzmodbuild:
        launcher_verlua = 0x7FFF

    print(f"Set update version from {launcher_ver} to {launcher_verlua}")
    search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", str(hex(int(launcher_ver))), str(hex(int(launcher_verlua))))


    build_apk()
    update_classes(working_dir + f"/{name}/dist/{name}.apk")
    compile_dex_additions("classes6")




def exitWithError(msg):
    print(msg)
    print("Press Enter for exit.")
    input()
    exit()


if __name__ == "__main__":
    name = "app-debug"
    if len(sys.argv) > 1:
        input_arg = sys.argv[1]

        file_path = input_arg.strip('"')

        if os.path.isfile(file_path):
            dest_path = f"{working_dir}/app-debug.apk"
            shutil.copy(file_path, dest_path)
            name = "app-debug"
        else:
            if not input_arg.startswith("-"):
                name = input_arg

    rename = name

    app_dir =  f"{working_dir}/{name}"
    dist_dir =  f"{app_dir}/dist"
    print("Название файла:", name)
    print("Папка проекта:", app_dir)
    print("Папка c APK:", dist_dir)

    if "-arzmod" in sys.argv or (arzmod_dev and not "-undsgn" in sys.argv):
        arzmodbuild = True

    if "-rodina" in sys.argv:
        project = RODINA_MOBILE
    else:
        project = ARIZONA_MOBILE

    if "-actual":
        name = "app-debug"
        if project == ARIZONA_MOBILE:
            download_file("https://mob.maz-ins.com/game/release/launcher_new/app-arizona-release_web.apk", working_dir + f"/{name}.apk")
        elif project == RODINA_MOBILE:
            download_file("https://mob.azinternal.com/release/launcher_new/app-rodina-release_web.apk", working_dir + f"/{name}.apk")
        else:
            exitWithError("project == null?")
    else:
        if not os.path.exists(working_dir + f"/{name}.apk"):
            exitWithError("The APK doesn't exists")


    if "-x64" in sys.argv:
        usearm64 = True
 
    print(f"Build settings: Project = {project} | ARZMOD = {arzmodbuild} | UseARM64 = {usearm64}")

    decompile_apk()

    if not os.path.exists(app_dir):
        exitWithError("The project path doesn't exists")
        
    arzmod_patch()
    rename = "app-debug"

    build_apk()
    if config.build_sign:
        sign_apk(rename, config.key_password)
        
    if config.build_download:
        download_apk(rename)

    if arzmodbuild and "-release" in sys.argv:
        if arzmod_dev:
            arzmod_release.create_release(launcher_ver, launcher_vername, launcher_verlua, name, rename, working_dir, project)
        else: print("why you use release tag, but you dont have release module?")

    print("Process completed successfully.")
