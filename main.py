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
app_dir, name, project, usearm64, arzmodbuild, launcher_verlua, launcher_ver, launcher_vername = None, "app", 0, False, False, 0, 0, "None"

arz_miami_path = "smali_classes4"
arz_src_path = "smali_classes3"
arz_ui_path = "smali_classes5"

ARIZONA_MOBILE = 0
RODINA_MOBILE = 1


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

def update_app_version(new_version_code, new_version_name):
	try:
		with open(app_dir + "/apktool.yml", 'r', encoding='utf-8') as file:
			content = file.read()

		content = re.sub(r"versionCode:\s*'(\d+)'", f"versionCode: '{new_version_code}'", content)
		content = re.sub(r"versionName:\s*([^']+)", f"versionName: {new_version_name}", content)

		with open(app_dir + "/apktool.yml", 'w', encoding='utf-8') as file:
			file.write(content)

		print(f"Updated versionCode to {new_version_code} and versionName to '{new_version_name}'")
	except Exception as e:
		print(f"Error updating {app_dir}/apktool.yml: {e}")


def get_app_settings(package_name: str) -> dict[str, str] | None:
    try:
        result = subprocess.run(
            ["adb", "shell", "dumpsys", "package", package_name],
            capture_output=True, text=True, check=True
        )

        if f"Package [{package_name}]" not in result.stdout:
            print(f"Пакет {package_name} не найден.")
            return None

        settings = {}
        for line in result.stdout.splitlines():
            matches = re.findall(r'(\w+)=([^\s]+)', line)
            for key, value in matches:
                settings[key] = value

        return settings
    except subprocess.CalledProcessError:
        print("Ошибка при выполнении adb.")
    except FileNotFoundError:
        print("adb не найден в PATH.")

    return None

def is_app_installed(package_name: str):
    try:
        result = subprocess.run(
            ["adb", "shell", "dumpsys", "package", package_name],
            capture_output=True, text=True, check=True
        )

        if "Package [" + package_name + "]" not in result.stdout:
            return False

        return True

    except subprocess.CalledProcessError as e:
        print("Ошибка при выполнении adb:", e)
        return False
    except FileNotFoundError:
        print("adb не найден в PATH")
        return False

    return False

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
	patched_lib = f"{working_dir}/libpatch/{arch}/{'ARIZONA' if project == ARIZONA_MOBILE else 'RODINA'}/{libname}"
	libpath = f"{app_dir}/lib/{arch}/{libname}"
	if os.path.exists(patched_lib):
		shutil.copy(patched_lib, libpath)
		print(f"Библиотека {libname} для {arch} для проекта {'ARIZONA' if project == ARIZONA_MOBILE else 'RODINA'} успешно копирована!")
	elif os.path.exists(libpath):
		print(f"Библиотеки {libname} для копирования не найдено в libpatch. Используется исходная версия")
	else:
		exitWithError("Библиотеки для копирования не найдено")
	return libpath

def get_define_value(file_path: str, define_name: str) -> int | str | None:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line.startswith("#define"):
                    match = re.match(rf"#define\s+{re.escape(define_name)}\s+(.+)", line)
                    if match:
                        value = match.group(1).strip()
                        if value.startswith('"') and value.endswith('"'):
                            return value[1:-1]
                        if value.isdigit():
                            return int(value)
                        if re.fullmatch(r'0x[0-9a-fA-F]+', value):
                            return int(value, 16)
                        return value
    except FileNotFoundError:
        exitWithError(f"Файл не найден: {file_path}")
    except Exception as e:
        exitWithError(f"Ошибка при чтении файла: {e}")

    return None

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


# bypass checks: 0 = no bypass, 1 = bypass checking, 2 = try to check in native module
def add_game_version(version, bypasscheck=0):
	try:
		if isinstance(version, str):
			version = ""

		nativemodulepath = f"{working_dir}/native/jni/monetloader.h"
		profilepath = f"{working_dir}/resource/profile{str(version)}.json"
		libpath = add_patched_lib(f"libsamp{str(version)}.so", "armeabi-v7a")

		if bypasscheck == 1:
			add_asset(profilepath)
			return


		if bypasscheck == 2:
			print(f"Проверяем оффсеты: {nativemodulepath}")
			if not os.path.exists(nativemodulepath):
				print("Нативная реализация не найдена. Пропускаем проверку профиля...")
				add_asset(profilepath)
				return
			try:
				receiveignorerpc_pattern = get_define_value(nativemodulepath, f"ReceiveIgnoreRPCPattern{version}")
				cnetgame_ctor_pattern = get_define_value(nativemodulepath, f"CNetGame_ctorPattern{version}")
				with open(libpath, 'rb') as lib_file:
					lib_data = lib_file.read()
					
					print(f"Проверяем паттерн ReceiveIgnoreRPC - {receiveignorerpc_pattern}")
					if not find_pattern(lib_data, receiveignorerpc_pattern):
						exitWithError(f"Паттерн ReceiveIgnoreRPC - {receiveignorerpc_pattern} не найден в {libpath}")
					print(f"Проверяем паттерн CNetGame_ctor - {cnetgame_ctor_pattern}")
					if not find_pattern(lib_data, cnetgame_ctor_pattern):
						exitWithError(f"Паттерн CNetGame_ctor - {cnetgame_ctor_pattern} не найден в {libpath}")

				print("Библиотека проверена и доступна для использования. Обновление оффсетов не требуется")
				add_asset(profilepath)
			except Exception as e:
				exitWithError(f"Ошибка при проверке библиотеки: {e}")
			return

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

def add_game_version_nocheck(version):
	try:
		if isinstance(version, str):
			version = ""

		libpath = add_patched_lib(f"libsamp{str(version)}.so", "armeabi-v7a")
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
		exitWithError("При удалении строк произошла ошибка")


def search_and_replace(file_path, search_string, replacement_string, skip_found=None):
	try:
		if not os.path.exists(file_path):
			exitWithError(f"Файл не найден {file_path} (search_and_replace)")
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
			exitWithError("Строки для замены не найдено")
		else:
			return None
	except (UnicodeDecodeError, FileNotFoundError):
		return None

def search_and_replace_line(file_path, search_line, replacement_line, skip_found=None):
	try:
		if not os.path.exists(file_path):
			exitWithError(f"Файл не найден {file_path} (search_and_replace_line)")
		with open(file_path, 'r') as file:
			lines = file.readlines()

		found = any(search_line in line for line in lines)
		replacement_count = 0

		if found:
			with open(file_path, 'w') as file:
				for line in lines:
					if search_line in line:
						new_line = replacement_line
						replacement_count += 1
					else:
						new_line = line
					file.write(new_line)
			print(f"Строка заменена в файле {file_path}. Количество замен: {replacement_count}")
			return True
		elif skip_found is None:
			print("-------------------DEBUG-------------------")
			print("file_path:", file_path)
			print("search_line:", search_line)
			print("Строки для замены не найдено")
			print("-------------------------------------------")
			exitWithError("Строки для замены не найдено")
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
			exitWithError("Не найдена строка для замены после заданной строки")
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
		exitWithError(f"Произошла ошибка: {e}")

def replace_block_in_file(file_path, old_block, new_line, after_line=None):
	try:
		remove_line_numbers(file_path)
		time.sleep(1)

		with open(file_path, 'r', encoding='utf-8') as file:
			content = file.read()

		old_block = re.sub(r'\s+', ' ', old_block.strip())
		pattern = re.escape(old_block)
		pattern = re.sub(r'\\ ', r'\\s+', pattern)
		new_line = new_line.strip()

		if after_line is not None:
			after_line = re.escape(after_line.strip())
			after_line_pattern = re.compile(after_line, re.DOTALL | re.IGNORECASE)
			match = after_line_pattern.search(content)
			if match:
				start_pos = match.end()
				content_after = content[start_pos:]
				new_content_after, count = re.subn(pattern, new_line, content_after, count=1, flags=re.DOTALL | re.IGNORECASE)
				new_content = content[:start_pos] + new_content_after
			else:
				exitWithError("Строка после которой нужно выполнить замену не найдена.")
				return
		else:
			new_content, count = re.subn(pattern, new_line, content, flags=re.DOTALL | re.IGNORECASE)

		if count == 0:
			print("-------------------DEBUG-------------------")
			print("file_path:", file_path)
			print("old_block:", old_block)
			print("new_line:", new_line)
			print("Замена не выполнена: блок не найден.")
			print("-------------------------------------------")
			exitWithError("Замена не выполнена: блок не найден.")
		else:
			print(f"Произведено {count} замен блоков кода в файле {file_path}")

		with open(file_path, 'w', encoding='utf-8') as file:
			file.write(new_content)

	except Exception as e:
		exitWithError(f"Произошла ошибка: {e}")


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
			exitWithError("Замена не выполнена: блок не найден.")

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
		exitWithError(f"Произошла ошибка: {e}")


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
		exitWithError("Ошибка: строка не найдена!")
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
		exitWithError("Ошибка: одна или обе строки не найдены!")
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
		exitWithError(f"Произошла ошибка: {e}")

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
		exitWithError("Атрибут не найден")

def count_methods_in_smali(file_path):
	method_pattern = re.compile(r'^\.method')
	count = 0
	with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
		for line in file:
			if method_pattern.match(line.strip()):
				count += 1
	return count

def count_methods_in_dir(directory):
	total_methods = 0
	smali_files = []
	for root, _, files in os.walk(directory):
		for file in files:
			if file.endswith('.smali'):
				file_path = os.path.join(root, file)
				method_count = count_methods_in_smali(file_path)
				total_methods += method_count
				smali_files.append((file_path, method_count))
	return total_methods, smali_files

def get_new_smali_dir_index(base_dir):
	index = 2
	while os.path.exists(os.path.join(base_dir, f"smali_classes{index}")):
		index += 1
	return index

def redistribute_smali_files(source_folder, base_dir, method_limit=50000):
	current_methods, smali_files = count_methods_in_dir(source_folder)
	if current_methods <= method_limit:
		return
	
	new_smali_dir = os.path.join(base_dir, f"smali_classes{get_new_smali_dir_index(base_dir)}") 
	new_smali_path = os.path.join(base_dir, new_smali_dir)
	os.makedirs(new_smali_path, exist_ok=True)
	
	moved_methods = 0
	for file_path, method_count in sorted(smali_files, key=lambda x: -x[1]):
		if current_methods - moved_methods <= method_limit:
			break
		rel_path = os.path.relpath(file_path, source_folder)
		new_path = os.path.join(new_smali_path, rel_path)
		os.makedirs(os.path.dirname(new_path), exist_ok=True)
		shutil.move(file_path, new_path)
		moved_methods += method_count
	
	print(f"Часть smali-файлов из {source_folder} перемещена в {new_smali_path}")

def build_native_lib(folder_name, arch):
    folder_path = os.path.join(working_dir, folder_name)
    if not os.path.exists(folder_path):
        exitWithError(f"Папка {folder_name} не найдена")

    jni_path = os.path.join(folder_path, "jni")
    libs_path = os.path.join(folder_path, "libs", arch)
    target_lib_path = os.path.join(app_dir, "lib", arch)

    os.makedirs(target_lib_path, exist_ok=True)

    if os.path.exists(jni_path):
        try:
            run_command("ndk-build", cwd=folder_path)
        except Exception as e:
            print(f"Ошибка при сборке через ndk-build: {str(e)}")
            print("Возьмем готовую библиотеку из папки libs/{arch} (если вы хотите собрать библиотеку самостоятельно, попробуйте прочитать native/README.md)")

        if not os.path.exists(libs_path):
            exitWithError(f"После сборки не найдена папка libs/{arch}")
    else:
        if not os.path.exists(libs_path):
            exitWithError(f"Не найдена папка libs/{arch} с готовыми библиотеками")

    found_libs = False
    for file in os.listdir(libs_path):
        if file.endswith(".so"):
            src_file = os.path.join(libs_path, file)
            dst_file = os.path.join(target_lib_path, file)
            shutil.copy2(src_file, dst_file)
            found_libs = True
            print(f"Скопирована библиотека: {file}")

    if not found_libs:
        exitWithError(f"Не найдено .so файлов в {libs_path}")


def set_package_name(old, new):
	print(f"Меняем имя пакета с {old} на {new}")
	search_and_replace(app_dir + '/AndroidManifest.xml', old, new)
	apply_function_to_files(search_and_replace, app_dir + f'/{arz_src_path}/', old, new, True)

def apply_function_to_files(function, dir_path, *args):
	for foldername, subfolders, filenames in os.walk(dir_path):
		for filename in filenames:
			file_path = os.path.join(foldername, filename)
			function(file_path, *args)

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
		response = requests.get(url, headers={'accept': '*/*', 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0', 'Upgrade-Insecure-Requests': '1'})
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
		os.rename(f"{app_dir}/dist/{name}.apk", f"{app_dir}/dist/{name}-nosign.apk")
		cname = f"{name}-nosign"

	aligned_apk = f"{app_dir}/dist/{rename}.apk"
	if os.path.exists(aligned_apk):
		os.remove(aligned_apk)
		print(f"Removed file {aligned_apk}")

	run_command(f"zipalign -p 4 {app_dir}/dist/{cname}.apk {aligned_apk}", cwd=working_dir)

	print("Signing APK...")
	keystore = f"{working_dir}/key/{arzmod_release.key_name if arzmod_dev else config.key_name}"
	if os.path.exists(keystore):
		run_command(f"apksigner sign --ks {keystore} --v4-signing-enabled true --ks-pass pass:{keypass} {aligned_apk}", cwd=working_dir)
		print("Delete cache")
		os.remove(f"{app_dir}/dist/{cname}.apk")
		os.remove(f"{aligned_apk}.idsig")
	else:
		exitWithError("Key at path: workdir + key/keystore.jks doesn't found")

def compile_dex_additions(dex_name, file_name=None):
	run_command(f"python dexcompile.py {dex_name}", cwd=working_dir)
	if file_name is not None and os.path.exists(f"{app_dir}/{file_name}"):
		print("Файл уже существует, заменяем")
	shutil.move(f"{working_dir}/{dex_name}/out/{dex_name}.dex", f"{app_dir}/{file_name if file_name is not None else dex_name + '.dex'}")


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
		exitWithError("Ошибка: APK-файл поврежден или не является архивом ZIP.")

def download_apk(rename):
	aligned_apk = f"{app_dir}/dist/{rename}.apk"
	print(f"Installing APK ({aligned_apk}) on device...")
	run_command(f"adb install {aligned_apk}", cwd=f"{app_dir}/dist")



####################################################################################


def run_command(command, cwd=None, check=True):
	try:
		subprocess.run(command, cwd=cwd, check=check, shell=True)
	except subprocess.CalledProcessError as e:
		exitWithError(f"Error: {e}")


def arzmod_patch():
	miami_path = app_dir + f"/{arz_miami_path}"
	src_path = app_dir + f"/{arz_src_path}"
	ui_path = app_dir + f"/{arz_ui_path}"
	manifest_path = app_dir + '/AndroidManifest.xml'

	# PACKAGE NAME PATCH
	package_name = f"{'com.arizona.game' if project == ARIZONA_MOBILE else 'com.rodina.game'}{'.git' if not arzmodbuild  else ''}"
	set_package_name("com.arizona21.game.web" if project == ARIZONA_MOBILE else "com.rodina21.game.web", package_name)
	set_xml_string("app_name", "ARIZONA MOD" if project == ARIZONA_MOBILE else "RODINA MOD")

	# TEXT PATCH
	search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", r"\u041f\u0440\u043e\u0432\u0435\u0440\u043a\u0430 \u0444\u0430\u0439\u043b\u043e\u0432 \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u0430, \u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u043f\u0435\u0440\u0435\u0437\u0430\u043f\u0443\u0441\u043a", r"\u041f\u0440\u043e\u0432\u0435\u0440\u043a\u0430\u0020\u0444\u0430\u0439\u043b\u043e\u0432\u0020\u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u0430\u002c\u0020\u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f\u0020\u043f\u0435\u0440\u0435\u0437\u0430\u043f\u0443\u0441\u043a\u002e\u0020\u041f\u043e\u0441\u043b\u0435\u0020\u043f\u0435\u0440\u0435\u0437\u0430\u043f\u0443\u0441\u043a\u0430\u002c\u0020\u043e\u0431\u043d\u043e\u0432\u0438\u0442\u0435\u0020\u0438\u0433\u0440\u0443\u0020\u0434\u043b\u044f\u0020\u043a\u043e\u0440\u0440\u0435\u043a\u0442\u043d\u043e\u0439\u0020\u0440\u0430\u0431\u043e\u0442\u044b\u002e")
	search_and_replace(miami_path + "/com/miami/game/feature/download/dialog/ui/setup/DescriptionTextKt.smali", r". \u0412\u044b \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043b\u044c\u043d\u043e \u0445\u043e\u0442\u0438\u0442\u0435 \u043f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c?", r" \u002e\u0020\u0412\u044b\u0020\u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043b\u044c\u043d\u043e\u0020\u0445\u043e\u0442\u0438\u0442\u0435\u0020\u043f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c\u003f\u0020\u0415\u0441\u043b\u0438\u0020\u0432\u044b\u0020\u0445\u043e\u0442\u0438\u0442\u0435\u0020\u043f\u0440\u043e\u043f\u0443\u0441\u0442\u0438\u0442\u044c\u0020\u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435\u0020\u002d\u0020\u043d\u0430\u0436\u043c\u0438\u0442\u0435\u0020\u043a\u043d\u043e\u043f\u043a\u0443\u0020\u041e\u0422\u041c\u0415\u041d\u0410\u002e\u0020\u0020\u0422\u0430\u043a\u0020\u0436\u0435\u0020\u043c\u043e\u0436\u043d\u043e\u0020\u043f\u043e\u043b\u043d\u043e\u0441\u0442\u044c\u044e\u0020\u043e\u0442\u043a\u043b\u044e\u0447\u0438\u0442\u044c\u0020\u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0443\u0020\u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0439\u0020\u043a\u0435\u0448\u0430\u0020\u0438\u0433\u0440\u044b\u0020\u0432\u0020\u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0430\u0445\u0020\u002d\u0020\u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438\u0020\u0041\u0052\u005a\u004d\u004f\u0044")

	if arzmodbuild:		
		# TEXT PATCH
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", r"\u0414\u0430\u043d\u043d\u0430\u044f \u0432\u0435\u0440\u0441\u0438\u044f \u0443\u0441\u0442\u0430\u0440\u0435\u043b\u0430, \u043d\u0435\u043e\u0431\u0445\u043e\u0434\u0438\u043c\u043e \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u043d\u043e\u0432\u0443", r"\u0422\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f\u0020\u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435\u0020\u043a\u043b\u0438\u0435\u043d\u0442\u0430\u002e\u0020\u0412\u043e\u0437\u043c\u043e\u0436\u043d\u043e\u0020\u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f\u0020\u043e\u0437\u043d\u0430\u043a\u043e\u043c\u0438\u0442\u0441\u044f\u0020\u0441\u0020\u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u043c\u002c\u0020\u0447\u0442\u043e\u0431\u044b\u0020\u0443\u0020\u0432\u0430\u0441\u0020\u043d\u0435\u0020\u0431\u044b\u043b\u043e\u0020\u043b\u0438\u0448\u043d\u0438\u0445\u0020\u0432\u043e\u043f\u0440\u043e\u0441\u043e\u0432\u002e\u0020\u041f\u0440\u043e\u0447\u0438\u0442\u0430\u0442\u044c\u0020\u043f\u043e\u0434\u0440\u043e\u0431\u043d\u043e\u0441\u0442\u0438\u0020\u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f\u0020\u043c\u043e\u0436\u043d\u043e\u0020\u0432\u0020\u0074\u002e\u006d\u0065\u002f\u0043\u006c\u0065\u006f\u0041\u0072\u0069\u007a\u006f\u006e\u0061")
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", r"\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0432\u0430\u0448\u0435 \u0438\u043d\u0442\u0435\u0440\u043d\u0435\u0442 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435 \u0438 \u043f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0441\u043d\u043e\u0432\u0430", r"\u041b\u0430\u0443\u043d\u0447\u0435\u0440\u0443\u0020\u043d\u0435\u0020\u0443\u0434\u0430\u043b\u043e\u0441\u044c\u0020\u043f\u043e\u043b\u0443\u0447\u0438\u0442\u044c\u0020\u043d\u0443\u0436\u043d\u0443\u044e\u0020\u0435\u043c\u0443\u0020\u0438\u043d\u0444\u043e\u0440\u043c\u0430\u0446\u0438\u044e\u002e\u0020\u0412\u043e\u0437\u043c\u043e\u0436\u043d\u043e\u002c\u0020\u0441\u0435\u0440\u0432\u0435\u0440\u0430\u0020\u0041\u0052\u005a\u004d\u004f\u0044\u0020\u0432\u0440\u0435\u043c\u0435\u043d\u043d\u043e\u0020\u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b\u0020\u0415\u0441\u043b\u0438\u0020\u0441\u0020\u0432\u0430\u0448\u0435\u043c\u0020\u0438\u043d\u0442\u0435\u0440\u043d\u0435\u0442\u0020\u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435\u043c\u0020\u0432\u0441\u0451\u0020\u0445\u043e\u0440\u043e\u0448\u043e\u002c\u0020\u043d\u0430\u0436\u043c\u0438\u0442\u0435\u0020\u043a\u043d\u043e\u043f\u043a\u0443\u0020\u0027\u0432\u044b\u0439\u0442\u0438\u0027\u0020\u0415\u0441\u043b\u0438\u0020\u0443\u0020\u0432\u0430\u0441\u0020\u043e\u0441\u0442\u0430\u043b\u0438\u0441\u044c\u0020\u0432\u043e\u043f\u0440\u043e\u0441\u044b\u002c\u0020\u043d\u0430\u043f\u0438\u0448\u0438\u0442\u0435\u0020\u0432\u0020\u0433\u0440\u0443\u043f\u043f\u0443\u0020\u002d\u0020\u0074\u002e\u006d\u0065\u002f\u0063\u006c\u0065\u006f\u0064\u0069\u0073")
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", r"\u0412\u044b\u0439\u0442\u0438", r"\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c")
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", r"\u041e\u0448\u0438\u0431\u043a\u0430 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f \u043a \u0441\u0435\u0440\u0432\u0435\u0440\u0443 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f", r"\u041b\u0430\u0443\u043d\u0447\u0435\u0440\u0443\u0020\u043d\u0435\u0020\u0443\u0434\u0430\u043b\u043e\u0441\u044c\u0020\u043f\u043e\u043b\u0443\u0447\u0438\u0442\u044c\u0020\u043d\u0443\u0436\u043d\u0443\u044e\u0020\u0435\u043c\u0443\u0020\u0438\u043d\u0444\u043e\u0440\u043c\u0430\u0446\u0438\u044e\u002e\u0020\u0412\u043e\u0437\u043c\u043e\u0436\u043d\u043e\u002c\u0020\u0441\u0435\u0440\u0432\u0435\u0440\u0430\u0020\u0041\u0052\u005a\u004d\u004f\u0044\u0020\u0432\u0440\u0435\u043c\u0435\u043d\u043d\u043e\u0020\u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b\u0020\u0415\u0441\u043b\u0438\u0020\u0441\u0020\u0432\u0430\u0448\u0435\u043c\u0020\u0438\u043d\u0442\u0435\u0440\u043d\u0435\u0442\u0020\u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435\u043c\u0020\u0432\u0441\u0451\u0020\u0445\u043e\u0440\u043e\u0448\u043e\u002c\u0020\u043d\u0430\u0436\u043c\u0438\u0442\u0435\u0020\u043a\u043d\u043e\u043f\u043a\u0443\u0020\u0027\u0432\u044b\u0439\u0442\u0438\u0027\u0020\u0415\u0441\u043b\u0438\u0020\u0443\u0020\u0432\u0430\u0441\u0020\u043e\u0441\u0442\u0430\u043b\u0438\u0441\u044c\u0020\u0432\u043e\u043f\u0440\u043e\u0441\u044b\u002c\u0020\u043d\u0430\u043f\u0438\u0448\u0438\u0442\u0435\u0020\u0432\u0020\u0433\u0440\u0443\u043f\u043f\u0443\u0020\u002d\u0020\u0074\u002e\u006d\u0065\u002f\u0063\u006c\u0065\u006f\u0064\u0069\u0073")

		# FIREBASE PATCH + classes_arzmod/src/com/arzmod/radare/FirebaseAdd.java (back arz connection)
		replace_code_between_lines(src_path + "/com/arizona/launcher/MessagingService.smali", "invoke-direct {p0}, Lcom/arizona/launcher/MessagingService;->getSettingsPreferences()Landroid/content/SharedPreferences;", "invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V", "")
		set_xml_string("gcm_defaultSenderId", "982519605362")
		set_xml_string("google_api_key", "AIzaSyAIav21gmzddU7GlZL-4oodtbAzkzclCmg")
		set_xml_string("google_app_id", "1:982519605362:android:e9d9e2b84af6dd0601baeb")
		set_xml_string("google_crash_reporting_api_key", "AIzaSyAIav21gmzddU7GlZL-4oodtbAzkzclCmg")
		set_xml_string("google_storage_bucket", "arzmod.firebasestorage.app")
		set_xml_string("project_id", "arzmod")
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
		insert_smali_code_after_line(src_path + "/com/arizona/launcher/MessagingService.smali", ".method public onMessageReceived", "check-cast v1, Landroid/content/Context;", """
			invoke-static {v1, p1}, Lcom/arzmod/radare/FirebaseAdd;->createNotification(Landroid/content/Context;Lcom/google/firebase/messaging/RemoteMessage;)V
			return-void
		""")


		# ARZMOD TECH PATCH
		search_and_replace(src_path + "/com/arizona/launcher/di/ArizonaLauncherAPIModule.smali", "https://api.arizona-five.com/", "https://api.arzmod.com/")
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench.smali", " release_web\"", " arzmod\"")
		search_and_replace(miami_path + "/com/miami/game/feature/home/ui/model/HomeUiState$Companion.smali", "https://arizona-rp.com/shop" if project == ARIZONA_MOBILE else "https://rodina-rp.com/shop", "https://t.me/cleodis")
		search_and_replace(ui_path + "/ru/mrlargha/commonui/elements/hud/presentation/Hud.smali", "arizona-rp.com" if project == ARIZONA_MOBILE else "rodina-rp.com", "arzmod.com")
		if project == ARIZONA_MOBILE: search_and_replace(ui_path + "/ru/mrlargha/commonui/elements/hud/presentation/api/HudApi.smali", "desktop/ping/Arizona/ping.json", "https://radarebot.hhos.net/api/serverlist")
		search_and_replace_after(miami_path + "/com/miami/game/core/connection/resolver/data/ServersList.smali", ".method public final newsServers", "main_api", "main_arizona_news")
		search_and_replace_after(miami_path + "/com/miami/game/core/connection/resolver/data/ServersList.smali", ".method public final newsServers", "reserve_api", "main_arizona_news")
		insert_smali_code_after_line(src_path + "/com/arizona/launcher/MainEntrench.smali", ".method protected onCreate", "invoke-super {p0, p1}, Lcom/arizona/launcher/Hilt_MainEntrench;->onCreate(Landroid/os/Bundle;)V", """
			invoke-static {}, Lcom/arzmod/radare/ApplicationStart;->showBanner()V
		""")


		# UPDATESERVICE PATCH (ARZMOD FILESERVERS)
		search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", "data/files", "data")
		append_to_file(src_path + "/com/arizona/launcher/UpdateService.smali", """
			.method public getARZMODPatchedPath(Ljava/lang/String;)Ljava/io/File;
				.locals 2
				const-string v0, "/storage/emulated/0/Android"
				new-instance v1, Ljava/io/File;
				invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V
				return-object v1
			.end method
		""")
		apply_function_to_files(search_and_replace, src_path + "/com/arizona/launcher", "Lcom/arizona/launcher/UpdateService;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;", "Lcom/arizona/launcher/UpdateService;->getARZMODPatchedPath(Ljava/lang/String;)Ljava/io/File;", True)
		replace_code_between_lines(src_path + "/com/arizona/launcher/UpdateService.smali", ".method private static final checkUpdate$lambda$1$lambda$0(Lorg/json/JSONObject;Ljava/lang/String;Ljava/lang/String;)Lorg/json/JSONArray;", ".end method", """
			.method private static final checkUpdate$lambda$1$lambda$0(Lorg/json/JSONObject;Ljava/lang/String;Ljava/lang/String;)Lorg/json/JSONArray;
				.locals 1
				const-string v2, "data"
				invoke-virtual {p0, v2}, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
				move-result-object v1
				invoke-virtual {v1, v2}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
				move-result-object v1
				return-object v1
			.end method
		""")
		replace_code_between_lines(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", ".method private static final handleMessage$lambda$0(Lcom/arizona/launcher/MainEntrench;)Lkotlin/Unit;", ".end method", """
			.method private static final handleMessage$lambda$0(Lcom/arizona/launcher/MainEntrench;)Lkotlin/Unit;
				.locals 1
				invoke-static {p0}, Lcom/arizona/launcher/MainEntrench;->access$hideDialog(Lcom/arizona/launcher/MainEntrench;)V
				const/4 v0, 0x0
				invoke-static {v0}, Lcom/arzmod/radare/UpdateServicePatch;->setHomeUi(Z)V
				sget-object p0, Lkotlin/Unit;->INSTANCE:Lkotlin/Unit;
				return-object p0
			.end method
		""")
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench$IncomingHandler.smali", "Lcom/arizona/launcher/MainEntrench$IncomingHandler$$ExternalSyntheticLambda4", "Lcom/arizona/launcher/MainEntrench$IncomingHandler$$ExternalSyntheticLambda0")

		replace_block_in_file(src_path + "/com/arizona/launcher/UpdateService.smali", """
		invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

		invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

		move-result-object v0

		const-string v3, ".apk"

		invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

		move-result-object v0

		invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

		move-result-object v0
		""", "")

		search_and_replace(src_path + "/com/arizona/launcher/util/FileServers.smali", "/game/release/" if project == ARIZONA_MOBILE else "/release/", "/")
		search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", "launcher_new/app-arizona-release_web" if project == ARIZONA_MOBILE else "launcher_new/app-rodina-release_web", "launcher_new/app-debug")
		search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", "const-string v4, \"app-arizona-release_web-\"" if project == ARIZONA_MOBILE else "const-string v4, \"app-rodina-release_web-\"", f"const-string v0, \"/data/{package_name}/files/app-debug.apk\"")
		search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", "app-arizona-release_web" if project == ARIZONA_MOBILE else "app-rodina-release_web", f"/data/{package_name}/files/app-debug")
		search_and_replace(src_path + "/com/arizona/launcher/UpdateActivity$IncomingHandler.smali", "app-arizona-release_web" if project == ARIZONA_MOBILE else "app-rodina-release_web", "app-debug")

		

	else:
		search_and_replace(src_path + "/com/arizona/launcher/MainEntrench.smali", " release_web\"", " arzmod_community\"")

	# CONNECTSERVER PATCH
	if not usearm64:
		search_and_replace(miami_path + "/com/miami/game/core/settings/ConnectionData.smali", "192.168.0.133", "join.arzfun.com")
		search_and_replace_after(miami_path + "/com/miami/game/feature/settings/ui/model/SettingsUiState.smali", ".method public constructor <init>", "iput-boolean p7, p0, Lcom/miami/game/feature/settings/ui/model/SettingsUiState;->isDebug:Z", """
				const/4 p7, 0x1
				iput-boolean p7, p0, Lcom/miami/game/feature/settings/ui/model/SettingsUiState;->isDebug:Z
			""") 
		replace_block_in_file(miami_path + "/com/miami/game/core/settings/ConnectionData.smali", "const-string p3, \"password\"", """
			invoke-static {}, Lcom/miami/game/core/settings/ConnectionData;->getRandomNickname()Ljava/lang/String;
			move-result-object p3
		""")
		append_to_file(miami_path + "/com/miami/game/core/settings/ConnectionData.smali", """
			.method public static getRandomNickname()Ljava/lang/String;
				.locals 8
				invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
				move-result-object v0
				invoke-virtual {v0}, Ljava/util/UUID;->toString()Ljava/lang/String;
				move-result-object v1
				const-string v0, "toString(...)"
				invoke-static {v1, v0}, Lkotlin/jvm/internal/Intrinsics;->checkNotNullExpressionValue(Ljava/lang/Object;Ljava/lang/String;)V
				const/4 v5, 0x4
				const/4 v6, 0x0
				const-string v2, "-"
				const-string v3, ""
				const/4 v4, 0x0
				invoke-static/range {v1 .. v6}, Lkotlin/text/StringsKt;->replace$default(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ZILjava/lang/Object;)Ljava/lang/String;
				move-result-object v0
				const/4 v1, 0x0
				const/16 v2, 0xc
				invoke-virtual {v0, v1, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;
				move-result-object v0
				const-string v1, "substring(...)"
				invoke-static {v0, v1}, Lkotlin/jvm/internal/Intrinsics;->checkNotNullExpressionValue(Ljava/lang/Object;Ljava/lang/String;)V
				new-instance v1, Ljava/lang/StringBuilder;
				const-string v2, "Player_"
				invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
				invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
				invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
				move-result-object v0
				return-object v0
			.end method
		""")
		replace_block_in_file(src_path + "/com/arizona/launcher/MainEntrench.smali", """
			sget-object v7, Lcom/miami/game/feature/download/dialog/ui/connection/ConnectionHolder;->INSTANCE:Lcom/miami/game/feature/download/dialog/ui/connection/ConnectionHolder;

			invoke-virtual {v7}, Lcom/miami/game/feature/download/dialog/ui/connection/ConnectionHolder;->getSettingsData()Lcom/miami/game/feature/download/dialog/ui/connection/SettingsData;

			move-result-object v7

			invoke-virtual {v7}, Lcom/miami/game/feature/download/dialog/ui/connection/SettingsData;->getPassword()Ljava/lang/String;

			move-result-object v7

			const-string v9, "pass"

			invoke-virtual {v6, v9, v7}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

			move-result-object v6""", "")
		replace_block_in_file(src_path + "/com/arizona/launcher/MainEntrench.smali", """
			invoke-direct {p0}, Lcom/arizona/launcher/MainEntrench;->getMainViewModel()Lcom/arizona/launcher/MainViewModel;

			move-result-object v6

			invoke-virtual {v6}, Lcom/arizona/launcher/MainViewModel;->getPlayerNick()Ljava/lang/String;

			move-result-object v6""", 
			"""
			sget-object v6, Lcom/miami/game/feature/download/dialog/ui/connection/ConnectionHolder;->INSTANCE:Lcom/miami/game/feature/download/dialog/ui/connection/ConnectionHolder;

			invoke-virtual {v6}, Lcom/miami/game/feature/download/dialog/ui/connection/ConnectionHolder;->getSettingsData()Lcom/miami/game/feature/download/dialog/ui/connection/SettingsData;

			move-result-object v6

			invoke-virtual {v6}, Lcom/miami/game/feature/download/dialog/ui/connection/SettingsData;->getPassword()Ljava/lang/String;

			move-result-object v6
		""", ".method private final connectToTestServer")

		ET.register_namespace("android", "http://schemas.android.com/apk/res/android")
		tree = ET.parse(manifest_path)
		root = tree.getroot()
		application = root.find('.//application')
		
		main_entrench = None
		for activity in application.findall('.//activity'):
			activity_name = activity.attrib.get('{http://schemas.android.com/apk/res/android}name')
			if activity_name and ('MainEntrench' in activity_name or 'com.arizona.launcher.MainEntrench' in activity_name):
				main_entrench = activity
				break
		
		if main_entrench is not None:
			intent_filter = ET.SubElement(main_entrench, 'intent-filter')
		
			action = ET.SubElement(intent_filter, 'action')
			action.attrib['{http://schemas.android.com/apk/res/android}name'] = 'android.intent.action.VIEW'
		
			category1 = ET.SubElement(intent_filter, 'category')
			category1.attrib['{http://schemas.android.com/apk/res/android}name'] = 'android.intent.category.DEFAULT'
			
			category2 = ET.SubElement(intent_filter, 'category')
			category2.attrib['{http://schemas.android.com/apk/res/android}name'] = 'android.intent.category.BROWSABLE'
			
			data = ET.SubElement(intent_filter, 'data')
			data.attrib['{http://schemas.android.com/apk/res/android}scheme'] = 'samp' if project == ARIZONA_MOBILE else 'crmp'
			
			tree.write(manifest_path, encoding='utf-8', xml_declaration=True)
			print("Intent-filter успешно добавлен")
		else:
			print("Activity MainEntrench не найдена")
			print("\nНайденные activity:")
			for activity in application.findall('.//activity'):
				print(activity.attrib.get('{http://schemas.android.com/apk/res/android}name'))
		insert_smali_code_after_line(src_path + "/com/arizona/launcher/MainEntrench.smali", ".method protected onCreate", "invoke-super {p0, p1}, Lcom/arizona/launcher/Hilt_MainEntrench;->onCreate(Landroid/os/Bundle;)V", """
			new-instance v2, Lcom/arzmod/radare/ApplicationStart;
            invoke-direct {v2, p0}, Lcom/arzmod/radare/ApplicationStart;-><init>(Landroid/content/Context;)V
            invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
            move-result-object v3
            invoke-virtual {v2, v3}, Lcom/arzmod/radare/ApplicationStart;->handleSampLink(Landroid/content/Intent;)V
		""")

		append_to_file(src_path + "/com/arizona/launcher/MainEntrench.smali", """
			.method protected onNewIntent(Landroid/content/Intent;)V
				.locals 2
				.param p1, "intent"    # Landroid/content/Intent;

				.prologue
				invoke-super {p0, p1}, Landroid/app/Activity;->onNewIntent(Landroid/content/Intent;)V
				new-instance v0, Lcom/arzmod/radare/ApplicationStart;
				invoke-direct {v0, p0}, Lcom/arzmod/radare/ApplicationStart;-><init>(Landroid/content/Context;)V
				invoke-virtual {v0, p1}, Lcom/arzmod/radare/ApplicationStart;->handleSampLink(Landroid/content/Intent;)V
				return-void
			.end method
		""")

	# UPDATESERVICE PATCH + classes_arzmod/src/com/arzmod/radare/UpdateServicePatch.java
	search_and_replace(src_path + "/com/arizona/launcher/UpdateService$isAllFilesOk$1.smali", "iget-boolean v6, p0, Lcom/arizona/launcher/UpdateService$isAllFilesOk$1;->$purgeExtraFiles:Z", "const/4 v6, 0x0")	
	insert_smali_code_after_line(src_path + "/com/arizona/launcher/MainEntrench.smali", ".method private final checkGameUpdate", ".locals", """
		invoke-static {}, Lcom/arzmod/radare/UpdateServicePatch;->isModeMods()Z
		move-result v0
		if-eqz v0, :continue_execution
		return-void
		:continue_execution
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
	insert_smali_code_after_line(src_path + "/com/arizona/launcher/UpdateService.smali", ".method private final checkGameDataUpdate", "move-object/from16 v4, p1", """
		new-instance v8, Lcom/arzmod/radare/UpdateServicePatch;
		invoke-direct {v8}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V
		invoke-virtual {v8, v4}, Lcom/arzmod/radare/UpdateServicePatch;->checkUserFiles(Lorg/json/JSONArray;)V
	""")
	insert_smali_code_after_line(miami_path + "/com/miami/game/core/app/root/nav/main/MainComponent.smali", ".method public final navigateBackDialog", ".locals", """
		const/4 v0, 0x0
		invoke-static {v0}, Lcom/arzmod/radare/UpdateServicePatch;->setHomeUi(Z)V
	""")
	insert_smali_code_after_line(miami_path + "/com/miami/game/feature/home/ui/HomeComponent.smali", ".method public final onClickGame", "if-eqz v0, :cond_0", """
		invoke-static {}, Lcom/arzmod/radare/UpdateServicePatch;->isFreeLaunch()Z
		move-result v0
		if-nez v0, :cond_0
	""")
	insert_smali_code_after_line(miami_path + "/com/miami/game/feature/home/ui/HomeComponent.smali", ".method public final onClickGame", "if-nez v0, :cond_2", """
		invoke-static {}, Lcom/arzmod/radare/UpdateServicePatch;->isFreeLaunch()Z
		move-result v0
		if-nez v0, :cond_2
	""")

	# GAMEARCHIVE 1508 COMPATIBLE
	append_to_file(src_path + "/com/arizona/game/GTASA.smali", """
		.method public InstallHud(III)V
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
	insert_code_before_line(src_path + "/com/arizona/game/GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", """
		.method public static native InitModloaderConfig(I)V
		.end method
	""")
	insert_code_before_line(src_path + "/com/arizona/game/GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", """
		.method public static native InitSetting(ZIZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V
		.end method
	""")
	search_and_replace(src_path + "/com/arizona/game/GTASA.smali", ".method private native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V", ".method public static native InitSetting(ZIZZLjava/lang/String;ILjava/lang/String;Ljava/lang/String;)V") 

	# SETTINGS PATCH + classes_arzmod/src/com/arzmod/radare/SettingsPatch.java
	insert_smali_code_after_line(src_path + "/com/arizona/launcher/MainEntrench.smali", ".method private static final onCreate$lambda$4", ".locals", """
		new-instance v0, Lcom/arzmod/radare/UpdateServicePatch;
		invoke-direct {v0}, Lcom/arzmod/radare/UpdateServicePatch;-><init>()V
		invoke-virtual {v0}, Lcom/arzmod/radare/UpdateServicePatch;->deleteMods()V
	""")
	replace_code_between_lines(miami_path + "/com/miami/game/feature/settings/ui/SettingsComponent.smali", ".method public final onPrivacyPolicy()V", ".end method", """.method public final onPrivacyPolicy()V
		.locals 1
		invoke-static {}, Lcom/arzmod/radare/SettingsPatch;->openSettingsMenu()V
		return-void
	.end method""")
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
		.end method
	""")
	replace_code_between_lines(src_path + "/com/arizona/game/GTASA.smali", ".method private InitSettingWrapper(I)V", ".end method", """
		.method private InitSettingWrapper(I)V
			.locals 2
			invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->InitSettingWrapper()V
			return-void
		.end method
	""")
	insert_smali_code_after_line(src_path + "/com/arizona/game/GTASAInternal.smali", ".method public onCreate", ".end annotation", """
		invoke-static {}, Lcom/arzmod/radare/InitGamePatch;->firstTimePatches()V
	""")


	# SAVECONTEXT FOR COMPATIBLE + classes_arzmod/src/com/arzmod/radare/AppContext.java
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

	# REPLACE PHOTO
	replace_files(working_dir + "/resource/mod_settings_btn", "privacy_policy")
	replace_files(working_dir + "/resource/input_name", "input_password")
	if arzmodbuild:
		replace_files(working_dir + "/resource/ic_chat_button", "ic_btn_shop")
		replace_files(working_dir + "/resource/remote_config_defaults", "remote_config_defaults")

	# CHECK OFFSETS IN NATIVE MODULE
	libsamppath = f"{app_dir}/lib/armeabi-v7a/libsamp.so"
	nativeoffsetspath = f"{working_dir}/native/jni/offsets.h"
	with open(libsamppath, 'rb') as lib_file:
		lib_data = lib_file.read()

		patterns = ["INSTALL_VERSION_STRING_PATTERN", "CHAT_RENDER_PATTERN", "SOCKET_LAYER_SENDTO_PATTERN"]

		for pattern in patterns:
			pattern_value = get_define_value(nativeoffsetspath, pattern).replace("\\x", "")
			print(f"Проверяем паттерн {pattern} - {pattern_value}")
			if not find_pattern(lib_data, pattern_value):
				exitWithError(f"Паттерн {pattern} - {pattern_value} не найден в {libsamppath}")

	# ADD GAME LIBS
	if usearm64:
		add_asset(f"{working_dir}/resource/profile.json")
		add_patched_lib("libluajit-5.1.so", "arm64-v8a")
		add_patched_lib("libmonetloader.so", "arm64-v8a")
	else:
		shutil.rmtree(app_dir + "/lib/arm64-v8a")
		add_patched_lib("libluajit-5.1.so", "armeabi-v7a")
		add_patched_lib("libmonetloader.so", "armeabi-v7a")
		add_patched_lib("libAML.so", "armeabi-v7a")
		build_native_lib("native", "armeabi-v7a")
	
		# ADD GAME VERSION
		add_game_version("actual", 2)
		if project == ARIZONA_MOBILE:
			add_game_version(1601)
			add_game_version(1579)
		add_game_version(1508)

	# SET UPDATE VERSION
	global launcher_ver, launcher_vername, launcher_verlua
	launcher_ver, launcher_vername = get_app_version()

	if "-lockversion" in sys.argv:
		settings = get_app_settings(package_name)
		if settings:
			print(f"Текущая версия приложения {settings.get('versionCode')} ({settings.get('versionName')}). Последнее обновление {settings.get('lastUpdateTime')}")
			update_app_version(int(settings.get("versionCode")), settings.get("versionName"))
			launcher_verlua = int(settings.get("versionCode"))
		else:
			exitWithError("Произошла ошибка при получении текущей версии, возможно приложение не установлено.")
	else:
		if arzmodbuild:
			currentversion = get_version(f"https://radarebot.hhos.net/{'arz_modclient' if project == ARIZONA_MOBILE else 'rod_modclient'}/update.json")
			if arzmod_dev:
				launcher_verlua = launcher_ver if currentversion + 1 < launcher_ver else currentversion + 1 
			else:
				launcher_verlua = currentversion
		elif not arzmodbuild:
			launcher_verlua = 0x7FFF
			update_app_version(1, f"{launcher_vername}_without_updates")

	print(f"Set update version from {launcher_ver} to {launcher_verlua}")
	search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", str(hex(int(launcher_ver))), str(hex(int(launcher_verlua))))
	# search_and_replace(src_path + "/com/arizona/launcher/UpdateService.smali", "app_version.json", "app_version_test.json")
	
	for folder in os.listdir(app_dir):
		folder_path = os.path.join(app_dir, folder)
		if os.path.isdir(folder_path) and folder.startswith("smali"):
			redistribute_smali_files(folder_path, app_dir)

	# REBUILD JAR CLASSES FOR COMPATIBLE BUILDING ADDITIONAL JAVA CODE
	build_apk()
	update_classes(working_dir + f"/{name}/dist/{name}.apk")
	compile_dex_additions("classes_arzmod", f"classes{get_new_smali_dir_index(app_dir)}.dex")




def exitWithError(msg):
	print(msg)
	print(f"Build settings: Project = {'ARIZONA' if project == ARIZONA_MOBILE else 'RODINA'} | ARZMOD = {arzmodbuild} | UseARM64 = {usearm64}")
	print("Press Enter for exit.")
	if input() != "continue": 
		exit(1)


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
	print("Название файла:", name)
	print("Папка проекта:", app_dir)

	if (arzmod_release.build_download if arzmod_dev else config.build_download) or "-lockversion" in sys.argv:
		try:
			devices = subprocess.run(['adb', 'devices'], capture_output=True, text=True).stdout.split('\n')[1:]
			devices = [d.split('\t')[0] for d in devices if d.strip() and 'List of devices' not in d]
			
			if not devices or len(devices) > 1:
				print("Устройства не найдены" if not devices else f"Найдено несколько устройств: {', '.join(devices)}")
				subprocess.run(['adb', 'disconnect'], capture_output=True)
				
				while True:
					ip_port = input("Введите IP:PORT для подключения (например, 192.168.1.100:5555): ")
					if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$', ip_port):
						if 'connected' in subprocess.run(['adb', 'connect', ip_port], capture_output=True, text=True).stdout.lower():
							print(f"Успешно подключено к {ip_port}")
							break
						print("Не удалось подключиться. Попробуйте снова.")
					else:
						print("Неверный формат. Используйте формат IP:PORT")
			else:
				print(f"Подключено устройство: {devices[0]}")
		except Exception as e:
			exitWithError(f"Ошибка при работе с ADB: {e}")
		

	testmode = False

	if "-testjava" in sys.argv:
		if not os.path.exists(app_dir):
				exitWithError("The project path doesn't exists, you can't running tests")
		testmode = True
		dexname = next(f for f in os.listdir(app_dir) if f.endswith('.dex'))
		compile_dex_additions("classes_arzmod", dexname)

	if "-testnative" in sys.argv:
		if not os.path.exists(app_dir):
				exitWithError("The project path doesn't exists, you can't running tests")
		testmode = True
		build_native_lib("native", "armeabi-v7a")

	if not testmode:
		if "-arzmod" in sys.argv or (arzmod_dev and not "-undsgn" in sys.argv):
			arzmodbuild = True
		
		if arzmod_dev and arzmodbuild and "-release" in sys.argv:
			arzmod_release.check_connection()

		if "-rodina" in sys.argv:
			project = RODINA_MOBILE
		else:
			project = ARIZONA_MOBILE

		if "-actual" in sys.argv:
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
	 
		print(f"Build settings: Project = {'ARIZONA' if project == ARIZONA_MOBILE else 'RODINA'} | ARZMOD = {arzmodbuild} | UseARM64 = {usearm64}")

		decompile_apk()

		if not os.path.exists(app_dir):
			exitWithError("The project path doesn't exists after try decompile_apk. Why?")
			
		arzmod_patch()
		rename = "app-debug"

	build_apk()

	if (arzmod_release.build_sign if arzmod_dev else config.build_sign):
		sign_apk(rename, arzmod_release.key_password if arzmod_dev else config.key_password)
		
	if (arzmod_release.build_download if arzmod_dev else config.build_download):
		download_apk(rename)

	if arzmodbuild and "-release" in sys.argv:
		if arzmod_dev:
			arzmod_release.create_release(launcher_ver, launcher_vername, launcher_verlua, name, rename, working_dir, project)
		else: print("why you use release tag, but you dont have release module?")

	print("Process completed successfully.")
