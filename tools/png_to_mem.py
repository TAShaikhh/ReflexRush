from PIL import Image
import sys
import os

# Convert 8-bit RGB to 4-bit RGB444 format
def rgb_to_rgb444(r, g, b):
    r4 = r >> 4
    g4 = g >> 4
    b4 = b >> 4
    return (r4 << 8) | (g4 << 4) | b4

def convert_image_to_mem(input_file, output_file):
    img = Image.open(input_file)
    img = img.convert("RGB")
    
    # Resize if needed
    if img.size != (64, 48):
        print(f"Resizing {input_file} to 64x48")
        img = img.resize((64, 48), Image.NEAREST)

    with open(output_file, 'w') as f:
        for y in range(48):
            for x in range(64):
                r, g, b = img.getpixel((x, y))
                rgb444 = rgb_to_rgb444(r, g, b)
                f.write(f"{rgb444:03X}\n")
    
    print(f"✅ Converted {input_file} → {output_file}")

# Command-line usage
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python png_to_mem.py input.png output.mem")
        sys.exit(1)

    convert_image_to_mem(sys.argv[1], sys.argv[2])
