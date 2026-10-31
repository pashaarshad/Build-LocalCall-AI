import os
from PIL import Image, ImageDraw, ImageFont

ASSETS_DIR = r"d:\Build LocalCall AI\play_store_assets_voice"
SCREENSHOTS_DIR = os.path.join(ASSETS_DIR, "screenshots")
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

def get_font(size, bold=False):
    font_names = ["segoeui.ttf", "arial.ttf", "calibri.ttf"]
    if bold:
        font_names = ["segoeuib.ttf", "arialbd.ttf", "calibrib.ttf"]
    for name in font_names:
        try:
            return ImageFont.truetype(name, size)
        except:
            continue
    return ImageFont.load_default()

def create_app_icon():
    img = Image.new("RGBA", (512, 512), (15, 23, 42, 255))
    draw = ImageDraw.Draw(img)

    # Background gradient rounded rect
    for y in range(512):
        r = int(10 + (26 - 10) * (y / 512))
        g = int(15 + (40 - 15) * (y / 512))
        b = int(29 + (75 - 29) * (y / 512))
        draw.line([(0, y), (512, y)], fill=(r, g, b, 255))

    # Outer glowing circle
    draw.ellipse([80, 80, 432, 432], outline=(99, 102, 241, 180), width=12)
    draw.ellipse([100, 100, 412, 412], fill=(19, 27, 46, 255), outline=(6, 182, 212, 220), width=6)

    # Sound Wave Bars in Center
    center_x = 256
    bars = [
        (-90, 80), (-60, 140), (-30, 200), (0, 250), (30, 200), (60, 140), (90, 80)
    ]
    for dx, h in bars:
        x = center_x + dx
        y1 = 256 - h // 2
        y2 = 256 + h // 2
        color = (34, 211, 238, 255) if abs(dx) <= 30 else (99, 102, 241, 255)
        draw.rounded_rectangle([x - 8, y1, x + 8, y2], radius=8, fill=color)

    # Voice / Mic Accent icon
    font = get_font(28, bold=True)
    draw.text((256, 445), "AI VOICE", fill=(255, 255, 255, 230), font=font, anchor="mm")

    path = os.path.join(ASSETS_DIR, "app_icon_512.png")
    img.convert("RGB").save(path, "PNG")
    print(f"Created: {path}")

def create_feature_graphic():
    img = Image.new("RGBA", (1024, 500), (10, 15, 29, 255))
    draw = ImageDraw.Draw(img)

    # Gradient background
    for x in range(1024):
        ratio = x / 1024
        r = int(10 + (25 - 10) * ratio)
        g = int(15 + (35 - 15) * ratio)
        b = int(29 + (70 - 29) * ratio)
        draw.line([(x, 0), (x, 500)], fill=(r, g, b, 255))

    # Glow highlights
    draw.ellipse([700, -50, 1100, 350], fill=(99, 102, 241, 40))
    draw.ellipse([60, 280, 400, 600], fill=(6, 182, 212, 35))

    # Title & Badge
    f_badge = get_font(20, bold=True)
    draw.rounded_rectangle([60, 70, 310, 110], radius=12, fill=(99, 102, 241, 60), outline=(99, 102, 241, 200))
    draw.text((185, 90), "🎙️ 100% LOCAL AI STUDIO", fill=(34, 211, 238), font=f_badge, anchor="mm")

    f_title = get_font(52, bold=True)
    draw.text((60, 140), "Text to Voice AI Audio", fill=(255, 255, 255), font=f_title)

    f_sub = get_font(24, bold=False)
    draw.text((60, 215), "Realistic Human-Grade Speech Synthesis", fill=(148, 163, 184), font=f_sub)

    # Feature Bullet Pills
    features = [
        "🇮🇳 Hindi, Tamil, Telugu & Regional",
        "⏸️ Real-Time Mid-Speech Pause & Seek",
        "💾 1-Tap Direct MP3 Download",
        "🔒 100% Private On-Device Execution"
    ]
    f_feat = get_font(21, bold=True)
    y_pos = 280
    for i, feat in enumerate(features):
        x_pos = 60 if i % 2 == 0 else 460
        y = y_pos if i < 2 else y_pos + 65
        draw.rounded_rectangle([x_pos, y, x_pos + 380, y + 48], radius=10, fill=(19, 27, 46, 220), outline=(51, 65, 85, 255))
        draw.text((x_pos + 20, y + 24), feat, fill=(241, 245, 249), font=f_feat, anchor="lm")

    # Right Side Graphic Display: Audio Wave card
    draw.rounded_rectangle([860, 80, 980, 420], radius=24, fill=(19, 27, 46, 240), outline=(99, 102, 241, 180), width=2)
    # Mini bars
    for idx, h in enumerate([40, 80, 130, 200, 140, 90, 50, 110, 170, 80]):
        by = 120 + idx * 26
        draw.rounded_rectangle([890, by, 890 + h // 2, by + 14], radius=6, fill=(34, 211, 238))

    path = os.path.join(ASSETS_DIR, "feature_graphic_1024x500.png")
    img.convert("RGB").save(path, "PNG")
    print(f"Created: {path}")

def create_screenshot(index, title, subtitle, main_card_text, footer_tag):
    width, height = 1080, 1920
    img = Image.new("RGBA", (width, height), (10, 15, 29, 255))
    draw = ImageDraw.Draw(img)

    # Background gradient
    for y in range(height):
        ratio = y / height
        r = int(10 + (22 - 10) * ratio)
        g = int(15 + (30 - 15) * ratio)
        b = int(29 + (55 - 29) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    # Ambient glow
    draw.ellipse([width - 400, 100, width + 200, 700], fill=(99, 102, 241, 35))
    draw.ellipse([-200, 900, 400, 1500], fill=(6, 182, 212, 30))

    # Top Tag
    f_tag = get_font(32, bold=True)
    draw.rounded_rectangle([80, 100, 420, 160], radius=18, fill=(99, 102, 241, 80), outline=(99, 102, 241, 200))
    draw.text((250, 130), footer_tag.upper(), fill=(34, 211, 238), font=f_tag, anchor="mm")

    # Headline
    f_h1 = get_font(68, bold=True)
    draw.text((80, 200), title, fill=(255, 255, 255), font=f_h1)

    # Subhead
    f_sub = get_font(34, bold=False)
    draw.text((80, 290), subtitle, fill=(148, 163, 184), font=f_sub)

    # Phone Frame representation
    phone_x1, phone_y1 = 80, 390
    phone_x2, phone_y2 = width - 80, height - 100
    draw.rounded_rectangle([phone_x1, phone_y1, phone_x2, phone_y2], radius=44, fill=(19, 27, 46, 255), outline=(51, 65, 85, 255), width=4)

    # Phone Header bar
    draw.rounded_rectangle([phone_x1 + 40, phone_y1 + 40, phone_x2 - 40, phone_y1 + 130], radius=20, fill=(15, 23, 42, 255))
    f_ph_title = get_font(38, bold=True)
    draw.text((phone_x1 + 80, phone_y1 + 85), "Text to Voice AI Audio", fill=(255, 255, 255), font=f_ph_title, anchor="lm")

    # Main Card
    draw.rounded_rectangle([phone_x1 + 40, phone_y1 + 170, phone_x2 - 40, phone_y1 + 950], radius=32, fill=(15, 23, 42, 255), outline=(99, 102, 241, 140), width=2)
    f_card_text = get_font(34, bold=False)
    
    # Draw text lines
    lines = main_card_text.split("\n")
    cur_y = phone_y1 + 230
    for line in lines:
        draw.text((phone_x1 + 80, cur_y), line, fill=(226, 232, 240), font=f_card_text)
        cur_y += 55

    # Waveform / Audio Player representation
    player_y = phone_y1 + 1000
    draw.rounded_rectangle([phone_x1 + 40, player_y, phone_x2 - 40, player_y + 360], radius=28, fill=(30, 41, 59, 255), outline=(6, 182, 212, 180), width=2)
    f_player = get_font(32, bold=True)
    draw.text((phone_x1 + 80, player_y + 60), "🎙️ Swara (Hindi - India) • 68 KB MP3", fill=(34, 211, 238), font=f_player)

    # Scrubber bar
    draw.rounded_rectangle([phone_x1 + 80, player_y + 130, phone_x2 - 80, player_y + 144], radius=7, fill=(51, 65, 85))
    draw.rounded_rectangle([phone_x1 + 80, player_y + 130, phone_x1 + 450, player_y + 144], radius=7, fill=(99, 102, 241))
    draw.ellipse([phone_x1 + 440, player_y + 125, phone_x1 + 464, player_y + 149], fill=(34, 211, 238))

    # Controls row: Rewind, Play/Pause, Forward, Download
    draw.ellipse([phone_x1 + 410, player_y + 190, phone_x1 + 510, player_y + 290], fill=(99, 102, 241))
    draw.text((phone_x1 + 460, player_y + 240), "⏸", fill=(255, 255, 255), font=get_font(42, bold=True), anchor="mm")
    draw.text((phone_x1 + 250, player_y + 240), "↺ 5s", fill=(148, 163, 184), font=get_font(32, bold=True), anchor="mm")
    draw.text((phone_x1 + 670, player_y + 240), "↻ 5s", fill=(148, 163, 184), font=get_font(32, bold=True), anchor="mm")
    draw.text((phone_x2 - 120, player_y + 240), "⋮", fill=(255, 255, 255), font=get_font(48, bold=True), anchor="mm")

    path = os.path.join(SCREENSHOTS_DIR, f"screenshot_{index}.png")
    img.convert("RGB").save(path, "PNG")
    print(f"Created: {path}")

def generate_all():
    create_app_icon()
    create_feature_graphic()
    create_screenshot(
        1,
        "Human-Grade AI Voice",
        "Convert any text to natural human speech instantly",
        "नमस्ते, लोकल कॉल एआई में आपका स्वागत है।\nमैं आपकी बुद्धिमान वॉयस असिस्टेंट हूँ।\n\nType or paste unlimited text in any language\nand hear realistic, expressive audio in seconds.",
        "Voice Studio"
    )
    create_screenshot(
        2,
        "Mid-Speech Pause & Seek",
        "Control playback seamlessly from any second",
        "• Instant Pause & Resume controls\n• Precision waveform scrubber\n• ↺ 5s Rewind and ↻ 5s Fast Forward\n• Variable speed from 0.75x to 2.0x\n• Clean dark glassmorphic player card",
        "Audio Controls"
    )
    create_screenshot(
        3,
        "Indian & Global Voices",
        "Full support for Hindi, Tamil, Telugu & English",
        "Recommended Neural Voice Agents:\n• Swara (Hindi - India) [Warm & Expressive]\n• Madhur (Hindi - India) [Authoritative]\n• Neerja (English - India) [Conversational]\n• Pallavi (Tamil) & Shruti (Telugu)\n• Jenny & Guy (Global English)",
        "Language Support"
    )
    create_screenshot(
        4,
        "1-Tap MP3 Downloads",
        "Save audios directly to your device storage",
        "• Tap the three-dot menu (⋮) to export\n• Direct high-quality MP3 format\n• Complete offline history list\n• 100% private: no tracking or external API",
        "Direct Export"
    )

if __name__ == "__main__":
    generate_all()
