#!/usr/bin/env python3
"""
GLTF to GLB Converter with Embedded Textures
Converts a GLTF file with external texture references to a self-contained GLB file.
"""

import json
import base64
import os
import struct
from pathlib import Path

def read_file_binary(filepath):
    """Read a file in binary mode."""
    with open(filepath, 'rb') as f:
        return f.read()

def gltf_to_glb_with_textures(gltf_path, output_glb_path):
    """
    Convert GLTF + external textures to GLB with embedded textures.
    
    Args:
        gltf_path: Path to the .gltf file
        output_glb_path: Path for the output .glb file
    """
    print(f"🔄 Converting GLTF to GLB with embedded textures...")
    print(f"   Input: {gltf_path}")
    print(f"   Output: {output_glb_path}")
    
    # Read the GLTF JSON
    with open(gltf_path, 'r', encoding='utf-8') as f:
        gltf_data = json.load(f)
    
    base_dir = Path(gltf_path).parent
    
    # Process images: embed texture files as base64 data URIs
    if 'images' in gltf_data:
        print(f"\n📦 Embedding {len(gltf_data['images'])} textures...")
        for idx, image in enumerate(gltf_data['images']):
            if 'uri' in image and not image['uri'].startswith('data:'):
                # External file reference
                texture_path = base_dir / image['uri']
                
                if not texture_path.exists():
                    print(f"   ⚠️  Warning: Texture not found: {texture_path}")
                    continue
                
                # Read texture file
                texture_data = read_file_binary(texture_path)
                
                # Determine MIME type
                ext = texture_path.suffix.lower()
                mime_types = {
                    '.png': 'image/png',
                    '.jpg': 'image/jpeg',
                    '.jpeg': 'image/jpeg',
                }
                mime_type = mime_types.get(ext, 'image/png')
                
                # Encode as base64 data URI
                base64_data = base64.b64encode(texture_data).decode('ascii')
                data_uri = f"data:{mime_type};base64,{base64_data}"
                
                # Replace uri with data URI
                image['uri'] = data_uri
                
                print(f"   ✅ Embedded: {texture_path.name} ({len(texture_data) / 1024:.1f} KB)")
    
    # Process buffers: embed .bin files if present
    if 'buffers' in gltf_data:
        for idx, buffer in enumerate(gltf_data['buffers']):
            if 'uri' in buffer and not buffer['uri'].startswith('data:'):
                buffer_path = base_dir / buffer['uri']
                
                if buffer_path.exists():
                    buffer_data = read_file_binary(buffer_path)
                    base64_data = base64.b64encode(buffer_data).decode('ascii')
                    buffer['uri'] = f"data:application/octet-stream;base64,{base64_data}"
                    print(f"   ✅ Embedded buffer: {buffer_path.name} ({len(buffer_data) / 1024:.1f} KB)")
    
    # Convert to GLB binary format
    print(f"\n🔧 Converting to GLB binary format...")
    
    # Serialize JSON
    json_data = json.dumps(gltf_data, separators=(',', ':')).encode('utf-8')
    
    # Pad JSON to 4-byte alignment
    json_padding = (4 - (len(json_data) % 4)) % 4
    json_chunk = json_data + (b' ' * json_padding)
    
    # GLB header
    magic = 0x46546C67  # 'glTF'
    version = 2
    
    # Chunk 0: JSON
    json_chunk_header = struct.pack('<II', len(json_chunk), 0x4E4F534A)  # 'JSON'
    
    # Calculate total length
    header_size = 12  # magic + version + length
    json_section_size = 8 + len(json_chunk)  # chunk header + data
    total_length = header_size + json_section_size
    
    # Write GLB file
    with open(output_glb_path, 'wb') as f:
        # Header
        f.write(struct.pack('<III', magic, version, total_length))
        
        # JSON chunk
        f.write(json_chunk_header)
        f.write(json_chunk)
    
    output_size = Path(output_glb_path).stat().st_size
    print(f"\n✅ GLB created successfully!")
    print(f"   Output file: {output_glb_path}")
    print(f"   File size: {output_size / (1024 * 1024):.2f} MB")
    print(f"   All textures are now embedded!")

if __name__ == '__main__':
    # Configuration
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    assets_dir = project_root / 'assets' / 'avatars' / '3d'
    
    gltf_file = assets_dir / 'scene_fixed.gltf'  # Use the fixed GLTF with material bindings
    output_glb = assets_dir / 'test_model.glb'  # Directly replace test_model.glb
    
    if not gltf_file.exists():
        print(f"❌ Error: GLTF file not found: {gltf_file}")
        exit(1)
    
    try:
        gltf_to_glb_with_textures(gltf_file, output_glb)
    except Exception as e:
        print(f"\n❌ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

