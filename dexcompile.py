import os
import sys
import shutil
import subprocess
import config

def compile_to_dex(src_dir):
    project_name = os.path.basename(os.path.normpath(src_dir))
    current_directory = os.getcwd()

    classes_dir = os.path.join(current_directory, 'arzmob-classes')

    jar_files = [os.path.join(classes_dir, f) for f in os.listdir(classes_dir) if f.endswith('.jar')]
    
    classpath = ";".join(jar_files)

    out_dir = src_dir + "\\out"
    dex_file = os.path.join(out_dir, f"{project_name}.dex")

    try:
        if not os.path.exists(out_dir):
            os.makedirs(out_dir)

        java_files = []
        for root, _, files in os.walk(src_dir + "\\src"):
            for file in files:
                if file.endswith(".java"):
                    java_files.append(os.path.join(root, file))

        if not java_files:
            raise FileNotFoundError("No .java files found in the source directory.")

        javac_command = (
            f'javac -source 8 -target 8 '
            f'-classpath "{classpath}" '
            f'-d {out_dir} ' + " ".join(f'"{java_file}"' for java_file in java_files)
        )
        print(f"Running: {javac_command}")
        subprocess.check_call(javac_command, shell=True)

        dx_command = f'dx --dex --output="{dex_file}" "{out_dir}"'
        print(f"Running: {dx_command}")
        subprocess.check_call(dx_command, shell=True)

        for root, dirs, files in os.walk(out_dir):
            for file in files:
                if not file.endswith(".dex"):
                    os.remove(os.path.join(root, file))
            for dir in dirs:
                shutil.rmtree(os.path.join(root, dir))

        print(f"Compilation successful! DEX file created at: {dex_file}")
    except subprocess.CalledProcessError as e:
        print(f"Error during compilation: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


if len(sys.argv) < 2:
    src_dir = input("Enter project path: ")
else: src_dir = sys.argv[1]

compile_to_dex(src_dir)
