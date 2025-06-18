import requests
import os
import sys

projects = {
    "rodina": {
        "original": "https://mob.azinternal.com/release",
        "mod": "https://download.arzmod.com/rod_modclient",
        "package": "com.rodina.game"
    },
    "arizona": {
        "original": "https://mob.maz-ins.com/game/release",
        "mod": "https://download.arzmod.com/arz_modclient",
        "package": "com.arizona.game"
    }
}

def download_json(url):
    response = requests.get(url, headers={'accept': '*/*', 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0', 'Upgrade-Insecure-Requests': '1'})
    response.raise_for_status()
    return response.json()

def merge_json_files(json_files):
    merged_data = {"data": {"data": []}}
    seen_files = set()
    
    def process_item(item, current_dir=None, current_path=""):
        if not isinstance(item, dict):
            return
            
        if item.get("type") == "file":
            full_path = f"{current_path}/{item['name']}" if current_path else item['name']
            if full_path not in seen_files:
                seen_files.add(full_path)
                if current_dir:
                    current_dir["data"].append(item)
                else:
                    merged_data["data"]["data"].append(item)
        elif item.get("type") == "dir":
            target_dir = None
            new_path = f"{current_path}/{item['name']}" if current_path else item['name']
            
            if current_dir:
                for subitem in current_dir["data"]:
                    if subitem.get("type") == "dir" and subitem["name"] == item["name"]:
                        target_dir = subitem
                        break
                if not target_dir:
                    target_dir = {"type": "dir", "name": item["name"], "data": []}
                    current_dir["data"].append(target_dir)
            else:
                for subitem in merged_data["data"]["data"]:
                    if subitem.get("type") == "dir" and subitem["name"] == item["name"]:
                        target_dir = subitem
                        break
                if not target_dir:
                    target_dir = {"type": "dir", "name": item["name"], "data": []}
                    merged_data["data"]["data"].append(target_dir)
            
            if "data" in item:
                for subitem in item["data"]:
                    process_item(subitem, target_dir, new_path)
    
    for json_data in json_files:
        if "data" in json_data and "data" in json_data["data"]:
            for item in json_data["data"]["data"]:
                process_item(item)
    
    return merged_data

def process_files(data, prefix="", original_files=None, new_files=None, changed_files=None, package_name=None):
    if not isinstance(data, dict):
        return
    
    if data.get("type") == "file":
        file_path = f"{prefix}/{data['name']}" if prefix else data['name']
        
        if prefix.startswith(f"data/{package_name}/files"):
            if original_files:
                original_file = original_files.get(file_path.replace(f"data/{package_name}/", ""))
                if not original_file:
                    new_files.append({
                        "path": file_path,
                        "hash": data["hash"],
                        "size": data["size"]
                    })
                elif original_file["hash"] != data["hash"]:
                    changed_files.append({
                        "path": file_path,
                        "hash": data["hash"],
                        "size": data["size"]
                    })
        else:
            new_files.append({
                "path": file_path,
                "hash": data["hash"],
                "size": data["size"]
            })
    
    elif data.get("type") == "dir":
        new_prefix = f"{prefix}/{data['name']}" if prefix else data['name']
        if "data" in data:
            for item in data["data"]:
                process_files(item, new_prefix, original_files, new_files, changed_files, package_name)

def get_original_files(original_data):
    original_files = {}
    
    def process_original_files(data, prefix=""):
        if not isinstance(data, dict):
            return
        
        if data.get("type") == "file":
            file_path = f"{prefix}/{data['name']}" if prefix else data['name']
            original_files[file_path] = {
                "hash": data["hash"],
                "size": data["size"]
            }
        elif data.get("type") == "dir":
            new_prefix = f"{prefix}/{data['name']}" if prefix else data['name']
            if "data" in data:
                for item in data["data"]:
                    process_original_files(item, new_prefix)
    
    if "data" in original_data and "data" in original_data["data"]:
        for item in original_data["data"]["data"]:
            process_original_files(item)
    
    return original_files

def compare_files(original_data, arzmod_data, package_name):
    new_files = []
    changed_files = []
    
    original_files = get_original_files(original_data)
    
    if "data" in arzmod_data and "data" in arzmod_data["data"]:
        for item in arzmod_data["data"]["data"]:
            process_files(item, "", original_files, new_files, changed_files, package_name)
    
    return new_files, changed_files

def process_project(project_name):
    if project_name not in projects:
        print(f"Project {project_name} not found")
        return [], []
        
    project = projects[project_name]
    file_types = ['etc', 'dxt', 'pvr']

    original_jsons = []
    arzmod_jsons = []
    
    for file_type in file_types:
        original_url = f"{project['original']}/{file_type}.game.json"
        arzmod_url = f"{project['mod']}/{file_type}.game.json"
        
        try:
            print(f"Load {file_type} JSON from {original_url}")
            original_data = download_json(original_url)
            original_jsons.append(original_data)
            
            print(f"Load {file_type} JSON from {arzmod_url}")
            arzmod_data = download_json(arzmod_url)
            arzmod_jsons.append(arzmod_data)
        except Exception as e:
            print(f"Error when process {file_type}: {str(e)}")
    
    merged_original = merge_json_files(original_jsons)
    merged_arzmod = merge_json_files(arzmod_jsons)
    
    new_files, changed_files = compare_files(merged_original, merged_arzmod, project["package"])
    
    all_files = new_files + changed_files
    for file_info in all_files:
        file_path = file_info["path"]
        download_url = f"{project['mod']}/data/{file_path}"
        print(f"DOWNLOAD: {download_url} {file_path.replace(project['package'], '__app_package_set')}")
    
    return new_files, changed_files

def main():
    if len(sys.argv) < 2:
        print("select project (arizona or rodina)")
        return
        
    project_name = sys.argv[1]
    new_files, changed_files = process_project(project_name)
    
    print(f"Added files: {len(new_files)} | Modified files: {len(changed_files)}")

if __name__ == "__main__":
    main() 