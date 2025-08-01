#!/usr/bin/env python3
import os
import json
from PIL import Image

def create_ios_icon(input_path, output_path, size):
    """Create iOS icon with exact size"""
    img = Image.open(input_path)
    
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Resize to exact size
    img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
    img_resized.save(output_path, 'PNG')

def main():
    # Input image path
    input_image = 'assets/images/new_logo.png'
    
    if not os.path.exists(input_image):
        print(f"Error: {input_image} not found!")
        return
    
    # iOS icon sizes and filenames
    ios_icons = [
        ('Icon-App-20x20@1x.png', 20),
        ('Icon-App-20x20@2x.png', 40),
        ('Icon-App-20x20@3x.png', 60),
        ('Icon-App-29x29@1x.png', 29),
        ('Icon-App-29x29@2x.png', 58),
        ('Icon-App-29x29@3x.png', 87),
        ('Icon-App-40x40@1x.png', 40),
        ('Icon-App-40x40@2x.png', 80),
        ('Icon-App-40x40@3x.png', 120),
        ('Icon-App-60x60@2x.png', 120),
        ('Icon-App-60x60@3x.png', 180),
        ('Icon-App-76x76@1x.png', 76),
        ('Icon-App-76x76@2x.png', 152),
        ('Icon-App-83.5x83.5@2x.png', 167),
        ('Icon-App-1024x1024@1x.png', 1024),
    ]
    
    base_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    
    print("Generating iOS icons...")
    for filename, size in ios_icons:
        output_path = os.path.join(base_path, filename)
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        create_ios_icon(input_image, output_path, size)
        print(f"Created: {output_path} ({size}x{size})")
    
    # Create Contents.json for iOS
    contents_json = {
        "images": [
            {"idiom": "iphone", "scale": "2x", "size": "20x20", "filename": "Icon-App-20x20@2x.png"},
            {"idiom": "iphone", "scale": "3x", "size": "20x20", "filename": "Icon-App-20x20@3x.png"},
            {"idiom": "iphone", "scale": "1x", "size": "29x29", "filename": "Icon-App-29x29@1x.png"},
            {"idiom": "iphone", "scale": "2x", "size": "29x29", "filename": "Icon-App-29x29@2x.png"},
            {"idiom": "iphone", "scale": "3x", "size": "29x29", "filename": "Icon-App-29x29@3x.png"},
            {"idiom": "iphone", "scale": "2x", "size": "40x40", "filename": "Icon-App-40x40@2x.png"},
            {"idiom": "iphone", "scale": "3x", "size": "40x40", "filename": "Icon-App-40x40@3x.png"},
            {"idiom": "iphone", "scale": "2x", "size": "60x60", "filename": "Icon-App-60x60@2x.png"},
            {"idiom": "iphone", "scale": "3x", "size": "60x60", "filename": "Icon-App-60x60@3x.png"},
            {"idiom": "ipad", "scale": "1x", "size": "20x20", "filename": "Icon-App-20x20@1x.png"},
            {"idiom": "ipad", "scale": "2x", "size": "20x20", "filename": "Icon-App-20x20@2x.png"},
            {"idiom": "ipad", "scale": "1x", "size": "29x29", "filename": "Icon-App-29x29@1x.png"},
            {"idiom": "ipad", "scale": "2x", "size": "29x29", "filename": "Icon-App-29x29@2x.png"},
            {"idiom": "ipad", "scale": "1x", "size": "40x40", "filename": "Icon-App-40x40@1x.png"},
            {"idiom": "ipad", "scale": "2x", "size": "40x40", "filename": "Icon-App-40x40@2x.png"},
            {"idiom": "ipad", "scale": "1x", "size": "76x76", "filename": "Icon-App-76x76@1x.png"},
            {"idiom": "ipad", "scale": "2x", "size": "76x76", "filename": "Icon-App-76x76@2x.png"},
            {"idiom": "ipad", "scale": "2x", "size": "83.5x83.5", "filename": "Icon-App-83.5x83.5@2x.png"},
            {"idiom": "ios-marketing", "scale": "1x", "size": "1024x1024", "filename": "Icon-App-1024x1024@1x.png"}
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = os.path.join(base_path, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents_json, f, indent=2)
    
    print(f"Created: {contents_path}")
    print("✅ All iOS icons generated successfully!")

if __name__ == "__main__":
    main()