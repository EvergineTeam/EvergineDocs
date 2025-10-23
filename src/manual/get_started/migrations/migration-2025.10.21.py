import yaml
import argparse
import sys
import os
from pathlib import Path

def is_bin_or_obj_folder(path):
    return path.is_dir() and (path.name == 'bin' or path.name == 'obj')

def validate_weproj_file(path):  
    if not path.exists():
        print(f"Error: File '{path}' does not exist.")
        sys.exit(1)
    
    if not path.is_file():
        print(f"Error: '{path}' is not a file.")
        sys.exit(1)
    
    if path.suffix.lower() != '.weproj':
        print(f"Error: '{path}' is not a .weproj file.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Upgrade tool for .weproj files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 upgrade.py project.weproj
  python3 upgrade.py "C:\\path\\to\\my project.weproj"
        """
    )
    
    parser.add_argument(
        'weproj_file',
        help='Path to the .weproj file to process'
    )
    args = parser.parse_args()
    weproj_path = Path(args.weproj_file)
    validate_weproj_file(weproj_path)
    
    folder_path = weproj_path.parent

    visit_files_recursively(folder_path, ext='.wemt', process_fn=process_material_file)
    visit_files_recursively(folder_path, ext='.weps', process_fn=process_particle_system_file)  # Just to skip bin/obj folders
    visit_files_recursively(folder_path, ext='.wetx', process_fn=process_texture_file)

def visit_files_recursively(folder_path, ext, process_fn):
    try:
        for item in folder_path.iterdir():
            if item.name.startswith('.') or is_bin_or_obj_folder(item):
                continue
            
            if item.is_file() and item.suffix.lower() == ext:
                process_fn(item)
            elif item.is_dir():
                visit_files_recursively(item, ext, process_fn)
                
    except PermissionError as e:
        print(f"Permission denied accessing '{folder_path}': {e}")
    except Exception as e:
        print(f"Error accessing '{folder_path}': {e}")

textures_used_as_color = {}
textures_used_as_other = {}

def process_material_file(file_path):
    with open(file_path, 'r+', encoding='utf-8') as f:
        try:
            txt = "\n".join(f.readlines()[1:])
            y = yaml.safe_load(txt)
            textures = y["MaterialInfo"]["Textures"]
            for tex in textures:
                tex_id = tex["ID"]
                tex_usage = tex["Name"]
                info = (file_path, tex_usage)
                if tex_usage == "BaseColorTexture" or tex_usage == "EmissiveTexture":
                    textures_used_as_color[tex_id] = info
                else:
                    textures_used_as_other[tex_id] = info
        except yaml.YAMLError as e:
            print(f"Error parsing YAML in '{file_path}': {e}")
            return
        
def process_particle_system_file(file_path):
    with open(file_path, 'r+', encoding='utf-8') as f:
        for line in f.readlines():
            tag = "ParticleTexture:"
            ind = line.find(tag)
            if ind >= 0:
                tex_id = line[ind + len(tag):].strip()
                info = (file_path, "ParticleTexture")
                textures_used_as_color[tex_id] = info

def process_texture_file(file_path):
    newTxt = None
    modified = []
    with open(file_path, 'r+', encoding='utf-8') as f:
        try:
            lines = f.readlines()
            first_line = lines[0]
            tex_id = lines[1][4:-1]

            used_as_color = textures_used_as_color.get(tex_id, None)
            used_as_other = textures_used_as_other.get(tex_id, None)
            not_used = not used_as_color and not used_as_other
            name_lower = file_path.name.lower()
            is_ktx = file_path.name.split('.')[-2].lower() == 'ktx'

            name_suggests_is_color = ("color" in name_lower) or ("emissive" in name_lower)
            name_suggests_is_other = ("normal" in name_lower) or ("roughness" in name_lower) or ("metallic" in name_lower) or ("pbr" in name_lower)

            if is_ktx:
                target_format = "KTX"
            elif used_as_color and used_as_other:
                target_format = "R8G8B8A8_UNorm_SRgb"
                print(f"Warning: Texture '{tex_id}' in '{file_path}' is used both as {used_as_color[1]} in {used_as_color[0]} and as {used_as_other[1]} in {used_as_other[0]}. Will be considered as color.")
            elif not_used:
                if (not name_suggests_is_color and not name_suggests_is_other) or (name_suggests_is_color and name_suggests_is_other):
                    target_format = None
                    print(f"Warning: Texture '{tex_id}' in '{file_path}' is not used in any material and the name doesn't suggest any specific usage. Format won't be changed.")
                else:
                    target_format = "R8G8B8A8_UNorm_SRgb" if name_suggests_is_color else "R8G8B8A8_UNorm"
            else:
                target_format = "R8G8B8A8_UNorm_SRgb" if used_as_color else "R8G8B8A8_UNorm"

            def replace_format(label):
                for i in range(len(lines)):
                    if lines[i].find(label + ":") >= 0:
                        for srcFormat in ["R8G8B8A8_UNorm_SRgb", "R8G8B8A8_UNorm"]:
                            if srcFormat == target_format:
                                continue
                            j = lines[i].find(srcFormat)
                            if j != -1:
                                lines[i] = lines[i][:j] + target_format + "\n"
                                modified.append(f"{srcFormat} -> {target_format}")
                                break
                        
            if target_format:
                replace_format("Format")
                replace_format("PixelFormat")

            # HasData doesn't exist any more, it has been replaces by DataFormat
            for i in range(len(lines)):
                hasDataStart = lines[i].find("HasData:")
                if hasDataStart != -1:
                    hasData = lines[i].find("true") != -1
                    if hasData:
                        if is_ktx:
                            lines[i] = lines[i][:hasDataStart] + "DataFormat: KTX\n"
                            modified.append("DataFormat: KTX")
                        else:
                            lines[i] = lines[i][:hasDataStart] + "DataFormat: bitmap\n"
                            modified.append("DataFormat: bitmap")
                    else:
                        lines[i] = lines[i][:hasDataStart] + "DataFormat: none\n"
                        modified.append("DataFormat: none")
                    break

            if modified:
                newTxt = first_line + "".join(lines[1:])

        except Exception as e:
            print(f"Error processing texture file '{file_path}': {e}")
            return

        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.truncate(0)
                f.write(newTxt)
                print(f"Updated texture '{tex_id}' in '{file_path}': {modified}")

if __name__ == '__main__':
    main()