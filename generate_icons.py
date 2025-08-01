#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

def create_adaptive_icon_foreground(input_path, output_path, size):
    """Create adaptive icon foreground with proper padding"""
    # Open the original image
    img = Image.open(input_path)
    
    # Convert to RGBA if not already
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Create a new image with the target size
    new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Calculate the size for the logo (should be about 60% of the total size for adaptive icons)
    logo_size = int(size * 0.6)
    
    # Resize the logo
    img_resized = img.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Calculate position to center the logo
    x = (size - logo_size) // 2
    y = (size - logo_size) // 2
    
    # Paste the logo onto the new image
    new_img.paste(img_resized, (x, y), img_resized)
    
    # Save the result
    new_img.save(output_path, 'PNG')

def create_regular_icon(input_path, output_path, size):
    """Create regular icon (full size)"""
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
    
    # Android icon sizes and paths
    android_icons = [
        # Regular icons (for older Android versions)
        ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48, False),
        ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72, False),
        ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96, False),
        ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144, False),
        ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192, False),
        
        # Adaptive icon foregrounds
        ('android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png', 108, True),
        ('android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png', 162, True),
        ('android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png', 216, True),
        ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png', 324, True),
        ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png', 432, True),
    ]
    
    print("Generating Android icons...")
    for path, size, is_adaptive in android_icons:
        output_path = path
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        if is_adaptive:
            create_adaptive_icon_foreground(input_image, output_path, size)
        else:
            create_regular_icon(input_image, output_path, size)
        
        print(f"Created: {output_path} ({size}x{size})")
    
    print("✅ All Android icons generated successfully!")
    print("\nNext steps:")
    print("1. Run: flutter clean")
    print("2. Run: flutter pub get")
    print("3. Build and test your app")

if __name__ == "__main__":
    main()