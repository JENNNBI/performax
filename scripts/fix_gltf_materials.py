#!/usr/bin/env python3
"""
Fix GLTF Material Bindings
Properly connects materials to textures in the scene.gltf file
"""

import json
from pathlib import Path

def fix_gltf_materials(gltf_path):
    """
    Fix material-texture bindings in GLTF file
    
    Args:
        gltf_path: Path to the .gltf file
    """
    print(f"🔧 Fixing GLTF material bindings...")
    print(f"   Input: {gltf_path}")
    
    # Read the GLTF JSON
    with open(gltf_path, 'r', encoding='utf-8') as f:
        gltf_data = json.load(f)
    
    # Check existing structure
    num_materials = len(gltf_data.get('materials', []))
    num_textures = len(gltf_data.get('textures', []))
    num_images = len(gltf_data.get('images', []))
    
    print(f"\n📊 Current State:")
    print(f"   Materials: {num_materials}")
    print(f"   Textures: {num_textures}")
    print(f"   Images: {num_images}")
    
    # Create texture references for materials
    if 'materials' in gltf_data and 'textures' in gltf_data:
        print(f"\n🔗 Connecting materials to textures...")
        
        for idx, material in enumerate(gltf_data['materials']):
            mat_name = material.get('name', f'Material_{idx}')
            
            # Ensure PBR block exists
            if 'pbrMetallicRoughness' not in material:
                material['pbrMetallicRoughness'] = {}
            
            pbr = material['pbrMetallicRoughness']
            
            # Set base color factor if missing
            if 'baseColorFactor' not in pbr:
                pbr['baseColorFactor'] = [1.0, 1.0, 1.0, 1.0]
            
            # Connect to texture based on material name
            texture_mapping = {
                'Weapon_01': 0,   # MI_1048301_Weapon_01_diffuse
                'Weapon_02': 13,  # MI_1048301_Weapon_02_diffuse
                'Hair_01': 2,     # MI_1048301_Hair_01_diffuse
                'Hair_02': 4,     # MI_1048301_Hair_02_diffuse
                'Body': 5,        # MI_1048301_Body_diffuse
                'Head': 7,        # MI_1048301_Head_diffuse
                'Eyes_01': 9,     # MI_1048301_Eyes_01_diffuse
                'Eyes_02': 10,    # MI_1048301_Eyes_02_diffuse
                'Equip_01': 11,   # MI_1048301_Equip_01_diffuse
                'Equip_02': 15,   # MI_1048301_Equip_02_diffuse
            }
            
            # Find matching texture
            texture_index = None
            for key, tex_idx in texture_mapping.items():
                if key in mat_name:
                    texture_index = tex_idx
                    break
            
            if texture_index is not None and texture_index < num_textures:
                # Add base color texture reference
                pbr['baseColorTexture'] = {
                    'index': texture_index
                }
                print(f"   ✅ {mat_name} → Texture {texture_index}")
            else:
                print(f"   ⚠️  {mat_name} → No matching texture found")
        
        # Save modified GLTF
        output_path = gltf_path.parent / 'scene_fixed.gltf'
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(gltf_data, f, indent=2)
        
        print(f"\n✅ Fixed GLTF saved to: {output_path}")
        print(f"   All materials now have texture bindings!")
        return output_path
    else:
        print(f"\n❌ Error: Missing materials or textures in GLTF")
        return None

if __name__ == '__main__':
    # Configuration
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    assets_dir = project_root / 'assets' / 'avatars' / '3d'
    
    gltf_file = assets_dir / 'scene.gltf'
    
    if not gltf_file.exists():
        print(f"❌ Error: GLTF file not found: {gltf_file}")
        exit(1)
    
    try:
        fixed_file = fix_gltf_materials(gltf_file)
        if fixed_file:
            print(f"\n🎯 Next Steps:")
            print(f"1. Run: python3 scripts/gltf_to_glb_with_textures.py")
            print(f"   (Update it to use scene_fixed.gltf)")
            print(f"2. Replace test_model.glb with the new GLB")
            print(f"3. Hot restart Flutter app")
    except Exception as e:
        print(f"\n❌ Error during fixing: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

