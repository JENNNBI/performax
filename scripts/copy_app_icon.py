#!/usr/bin/env python3
"""Copy app icon to iOS AppIcon.appiconset"""
import shutil
import os
import sys

source = "assets/images/app_icon.png"
dest = "ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

if not os.path.exists(source):
    print(f"❌ Error: {source} not found!")
    sys.exit(1)

try:
    shutil.copy2(source, dest)
    print(f"✅ Successfully copied {source} to {dest}")
    print("✅ AppIcon setup complete!")
except Exception as e:
    print(f"❌ Error copying file: {e}")
    sys.exit(1)

