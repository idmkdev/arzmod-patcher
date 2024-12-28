import os
import subprocess

dex2jar_path = os.getcwd() + '/dex-tools-v2.4/d2j-dex2jar.bat'
dex_folder = os.getcwd()
print(f"Текущая рабочая директория: {os.getcwd()}")

for root, dirs, files in os.walk(dex_folder):
    for file in files:
        if file.endswith(".dex"):
            dex_file = os.path.join(root, file)
            jar_file = dex_file.replace(".dex", ".jar")
            
            subprocess.run([dex2jar_path, dex_file], check=True)
            
            os.remove(dex_file)
            print(f"Конвертирован и удален файл: {dex_file}")
