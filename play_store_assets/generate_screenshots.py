import math
import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = r"d:\Build LocalCall AI\play_store_assets\screenshots"
os.makedirs(OUT_DIR, exist_ok=True)

WIDTH = 1080
HEIGHT = 1920

def get_font(size, bold=False):
    font_names = [
        "C:\\Windows\\Fonts\\segoeuib.ttf" if bold else "C:\\Windows\\Fonts\\segoeui.ttf",
        "C:\\Windows\\Fonts\\arialbd.ttf" if bold else "C:\\Windows\\Fonts\\arial.ttf",
    ]
    for fn in font_names:
        if os.path.exists(fn):
            try:
                return ImageFont.truetype(fn, size)
            except Exception:
                pass
    return ImageFont.load_default()

def draw_gradient(draw, width, height, top_color, bottom_color):
    for y in range(height):
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * (y / height))
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * (y / height))
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * (y / height))
        draw.line([(0, y), (width, y)], fill=(r, g, b))

def draw_phone_frame(draw, x0, y0, x1, y1, border_radius=48):
    # Outer bezel shadow & border
    draw.rounded_rectangle([x0-6, y0-6, x1+6, y1+6], radius=border_radius+6, outline=(51, 65, 85), width=4)
    # Screen background
    draw.rounded_rectangle([x0, y0, x1, y1], radius=border_radius, fill=(15, 23, 42))

def draw_status_bar(draw, x0, y0, x1, font):
    # Time and battery
    draw.text((x0 + 40, y0 + 18), "9:41", font=font, fill=(203, 213, 225))
    draw.text((x1 - 90, y0 + 18), "5G 100%", font=font, fill=(203, 213, 225))

def draw_app_header(draw, x0, y0, x1, title, subtitle):
    # Header bar
    h_top = y0 + 55
    h_bot = y0 + 135
    draw.rounded_rectangle([x0 + 16, h_top, x1 - 16, h_bot], radius=16, fill=(30, 41, 59))
    
    # Title
    t_font = get_font(26, bold=True)
    draw.text((x0 + 80, h_top + 16), title, font=t_font, fill=(255, 255, 255))
    
    # Subtitle / active model pill
    s_font = get_font(18)
    draw.rounded_rectangle([x0 + 80, h_top + 48, x0 + 260, h_top + 72], radius=12, fill=(6, 182, 212, 40), outline=(6, 182, 212), width=1)
    draw.text((x0 + 90, h_top + 50), subtitle, font=s_font, fill=(34, 211, 238))
    
    # Settings icon placeholder (dot button)
    draw.ellipse([x1 - 65, h_top + 28, x1 - 35, h_top + 58], fill=(51, 65, 85))
    draw.text((x1 - 54, h_top + 30), "⚙", font=s_font, fill=(255, 255, 255))

# ==================== SCREENSHOT 1: LIGHTNING FAST AI CHAT ====================
def generate_screenshot_1():
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 15, 30))
    draw = ImageDraw.Draw(img)
    draw_gradient(draw, WIDTH, HEIGHT, (15, 23, 42), (5, 8, 20))

    # Marketing Tagline
    f_tag = get_font(32, bold=True)
    f_title = get_font(60, bold=True)
    f_sub = get_font(30)
    
    # Badge
    draw.rounded_rectangle([WIDTH//2 - 180, 70, WIDTH//2 + 180, 120], radius=25, fill=(99, 102, 241, 40), outline=(99, 102, 241), width=2)
    draw.text((WIDTH//2 - 130, 78), "⚡ ULTRA-FAST STREAMING", font=f_tag, fill=(165, 180, 252))

    draw.text((WIDTH//2, 185), "Instant AI Responses", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.text((WIDTH//2, 240), "Powered by high-speed Groq LPU Cloud Inference", font=f_sub, fill=(148, 163, 184), anchor="mm")

    # Phone Frame
    px0, py0, px1, py1 = 90, 310, 990, 1860
    draw_phone_frame(draw, px0, py0, px1, py1)
    draw_status_bar(draw, px0, py0, px1, get_font(18))
    draw_app_header(draw, px0, py0, px1, "LocalCall AI Assistant", "● qwen3.8-27b (Active)")

    # Chat Messages
    # User message
    u_top = py0 + 170
    u_w = 560
    draw.rounded_rectangle([px1 - 40 - u_w, u_top, px1 - 40, u_top + 100], radius=20, fill=(79, 70, 229))
    draw.text((px1 - 40 - u_w + 24, u_top + 18), "Write a python function to compute", font=get_font(22), fill=(255, 255, 255))
    draw.text((px1 - 40 - u_w + 24, u_top + 48), "Fibonacci numbers with memoization.", font=get_font(22), fill=(255, 255, 255))
    draw.text((px1 - 40 - 75, u_top + 78), "09:42", font=get_font(14), fill=(199, 210, 254))

    # AI message
    a_top = u_top + 125
    a_w = 640
    draw.rounded_rectangle([px0 + 40, a_top, px0 + 40 + a_w, a_top + 420], radius=20, fill=(30, 41, 59))
    draw.text((px0 + 64, a_top + 18), "Here is an optimized recursive solution using", font=get_font(21), fill=(241, 245, 249))
    draw.text((px0 + 64, a_top + 46), "Python's built-in @functools.lru_cache:", font=get_font(21), fill=(241, 245, 249))

    # Code Box inside AI message
    c_top = a_top + 85
    draw.rounded_rectangle([px0 + 55, c_top, px0 + 40 + a_w - 15, c_top + 230], radius=12, fill=(15, 23, 42), outline=(51, 65, 85), width=1)
    code_font = get_font(19)
    draw.text((px0 + 75, c_top + 18), "from functools import lru_cache", font=code_font, fill=(244, 114, 182))
    draw.text((px0 + 75, c_top + 52), "@lru_cache(maxsize=None)", font=code_font, fill=(129, 140, 248))
    draw.text((px0 + 75, c_top + 86), "def fibonacci(n: int) -> int:", font=code_font, fill=(56, 189, 248))
    draw.text((px0 + 105, c_top + 120), "if n < 2: return n", font=code_font, fill=(250, 204, 21))
    draw.text((px0 + 105, c_top + 154), "return fibonacci(n-1) + fibonacci(n-2)", font=code_font, fill=(203, 213, 225))
    draw.text((px0 + 75, c_top + 192), "# Time complexity: O(n)", font=code_font, fill=(100, 116, 139))

    draw.text((px0 + 64, a_top + 330), "⚡ Tokens/sec: 280+ | Latency: 220ms", font=get_font(18, bold=True), fill=(6, 182, 212))
    draw.text((px0 + 40 + a_w - 70, a_top + 385), "09:42", font=get_font(14), fill=(100, 116, 139))

    # Chat Input Bar at bottom
    in_top = py1 - 100
    draw.rounded_rectangle([px0 + 25, in_top, px1 - 25, in_top + 70], radius=35, fill=(30, 41, 59), outline=(71, 85, 105), width=1)
    draw.text((px0 + 60, in_top + 22), "Ask LocalCall AI anything...", font=get_font(21), fill=(100, 116, 139))
    # Send button
    draw.ellipse([px1 - 85, in_top + 10, px1 - 35, in_top + 60], fill=(79, 70, 229))
    draw.text((px1 - 67, in_top + 18), "➤", font=get_font(24), fill=(255, 255, 255))

    img.save(os.path.join(OUT_DIR, "screenshot_1_chat_stream.png"))
    print("Saved screenshot 1")

# ==================== SCREENSHOT 2: CUTTING EDGE MODELS ====================
def generate_screenshot_2():
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 15, 30))
    draw = ImageDraw.Draw(img)
    draw_gradient(draw, WIDTH, HEIGHT, (15, 23, 42), (5, 8, 20))

    # Marketing Tagline
    f_tag = get_font(32, bold=True)
    f_title = get_font(60, bold=True)
    f_sub = get_font(30)
    
    # Badge
    draw.rounded_rectangle([WIDTH//2 - 200, 70, WIDTH//2 + 200, 120], radius=25, fill=(6, 182, 212, 40), outline=(6, 182, 212), width=2)
    draw.text((WIDTH//2 - 155, 78), "🧠 TOP OPEN-WEIGHT LLMS", font=f_tag, fill=(103, 232, 249))

    draw.text((WIDTH//2, 185), "Switch Models Instantly", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.text((WIDTH//2, 240), "Qwen 3.8, Allam 2 & OpenAI GPT-OSS on tap", font=f_sub, fill=(148, 163, 184), anchor="mm")

    # Phone Frame
    px0, py0, px1, py1 = 90, 310, 990, 1860
    draw_phone_frame(draw, px0, py0, px1, py1)
    draw_status_bar(draw, px0, py0, px1, get_font(18))

    # Bottom Sheet Overlay Mockup
    # Dark dimmed backdrop
    draw.rounded_rectangle([px0, py0 + 55, px1, py1], radius=48, fill=(10, 15, 26))
    
    # Sheet modal
    s_top = py0 + 260
    draw.rounded_rectangle([px0, s_top, px1, py1], radius=32, fill=(24, 34, 53), outline=(51, 65, 85), width=2)
    # Sheet handle
    draw.rounded_rectangle([WIDTH//2 - 40, s_top + 16, WIDTH//2 + 40, s_top + 22], radius=3, fill=(100, 116, 139))
    
    # Sheet Title
    draw.text((px0 + 40, s_top + 45), "Select AI Model", font=get_font(28, bold=True), fill=(255, 255, 255))
    draw.text((px0 + 40, s_top + 85), "Choose the optimal model for your workflow", font=get_font(18), fill=(148, 163, 184))

    # Model Card 1: Qwen (Active)
    m1_top = s_top + 130
    draw.rounded_rectangle([px0 + 30, m1_top, px1 - 30, m1_top + 160], radius=18, fill=(30, 41, 59), outline=(6, 182, 212), width=2)
    draw.text((px0 + 55, m1_top + 22), "Qwen 3.8 27B", font=get_font(24, bold=True), fill=(255, 255, 255))
    draw.rounded_rectangle([px1 - 160, m1_top + 20, px1 - 50, m1_top + 52], radius=10, fill=(6, 182, 212))
    draw.text((px1 - 145, m1_top + 25), "ACTIVE", font=get_font(16, bold=True), fill=(15, 23, 42))
    draw.text((px0 + 55, m1_top + 62), "qwen/qwen3.8-27b", font=get_font(18), fill=(148, 163, 184))
    draw.text((px0 + 55, m1_top + 98), "⭐ Best for complex coding, reasoning & long context", font=get_font(18), fill=(226, 232, 240))
    draw.text((px0 + 55, m1_top + 126), "Speed: 280 tok/s  |  Context: 128k", font=get_font(15), fill=(34, 211, 238))

    # Model Card 2: Allam 2
    m2_top = m1_top + 180
    draw.rounded_rectangle([px0 + 30, m2_top, px1 - 30, m2_top + 160], radius=18, fill=(30, 41, 59), outline=(51, 65, 85), width=1)
    draw.text((px0 + 55, m2_top + 22), "Allam 2 7B", font=get_font(24, bold=True), fill=(255, 255, 255))
    draw.text((px0 + 55, m2_top + 62), "allam-2-7b", font=get_font(18), fill=(148, 163, 184))
    draw.text((px0 + 55, m2_top + 98), "⭐ Ultra-fast general intelligence & multi-language chat", font=get_font(18), fill=(226, 232, 240))
    draw.text((px0 + 55, m2_top + 126), "Speed: 350 tok/s  |  Context: 8k", font=get_font(15), fill=(148, 163, 184))

    # Model Card 3: GPT-OSS
    m3_top = m2_top + 180
    draw.rounded_rectangle([px0 + 30, m3_top, px1 - 30, m3_top + 160], radius=18, fill=(30, 41, 59), outline=(51, 65, 85), width=1)
    draw.text((px0 + 55, m3_top + 22), "OpenAI GPT-OSS 20B", font=get_font(24, bold=True), fill=(255, 255, 255))
    draw.text((px0 + 55, m3_top + 62), "openai/gpt-oss-20b", font=get_font(18), fill=(148, 163, 184))
    draw.text((px0 + 55, m3_top + 98), "⭐ Balanced creative writing, drafting & summarization", font=get_font(18), fill=(226, 232, 240))
    draw.text((px0 + 55, m3_top + 126), "Speed: 210 tok/s  |  Context: 32k", font=get_font(15), fill=(148, 163, 184))

    # Save button
    draw.rounded_rectangle([px0 + 40, py1 - 100, px1 - 40, py1 - 30], radius=24, fill=(79, 70, 229))
    draw.text((WIDTH//2, py1 - 65), "Confirm Selection", font=get_font(22, bold=True), fill=(255, 255, 255), anchor="mm")

    img.save(os.path.join(OUT_DIR, "screenshot_2_models.png"))
    print("Saved screenshot 2")

# ==================== SCREENSHOT 3: 100% PRIVATE LOCAL STORAGE ====================
def generate_screenshot_3():
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 15, 30))
    draw = ImageDraw.Draw(img)
    draw_gradient(draw, WIDTH, HEIGHT, (15, 23, 42), (5, 8, 20))

    # Marketing Tagline
    f_tag = get_font(32, bold=True)
    f_title = get_font(60, bold=True)
    f_sub = get_font(30)
    
    # Badge
    draw.rounded_rectangle([WIDTH//2 - 210, 70, WIDTH//2 + 210, 120], radius=25, fill=(16, 185, 129, 40), outline=(16, 185, 129), width=2)
    draw.text((WIDTH//2 - 170, 78), "🔒 ZERO DATA TRACKING", font=f_tag, fill=(110, 231, 183))

    draw.text((WIDTH//2, 185), "Private & Local Always", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.text((WIDTH//2, 240), "Encrypted on-device SQLite database. No telemetry.", font=f_sub, fill=(148, 163, 184), anchor="mm")

    # Phone Frame
    px0, py0, px1, py1 = 90, 310, 990, 1860
    draw_phone_frame(draw, px0, py0, px1, py1)
    draw_status_bar(draw, px0, py0, px1, get_font(18))
    draw_app_header(draw, px0, py0, px1, "Chat History & Sessions", "Encrypted Local Storage")

    # Session items list
    s_top = py0 + 160
    sessions = [
        ("Mobile App Architecture Planning", "Yesterday • 28 messages", "Qwen 3.8 27B", (6, 182, 212)),
        ("Flutter SQLite Database Migration", "Oct 24 • 14 messages", "Qwen 3.8 27B", (6, 182, 212)),
        ("Arabic Language Translation Study", "Oct 23 • 9 messages", "Allam 2 7B", (168, 85, 247)),
        ("Creative Tech Blog Drafts", "Oct 22 • 32 messages", "GPT-OSS 20B", (249, 115, 22)),
        ("Docker Container Configuration", "Oct 20 • 6 messages", "Qwen 3.8 27B", (6, 182, 212)),
    ]

    for title, meta, tag, tag_col in sessions:
        draw.rounded_rectangle([px0 + 25, s_top, px1 - 25, s_top + 115], radius=16, fill=(30, 41, 59), outline=(51, 65, 85), width=1)
        draw.text((px0 + 50, s_top + 22), title, font=get_font(22, bold=True), fill=(255, 255, 255))
        draw.text((px0 + 50, s_top + 60), meta, font=get_font(17), fill=(148, 163, 184))
        # Tag badge
        draw.rounded_rectangle([px1 - 180, s_top + 55, px1 - 50, s_top + 85], radius=8, fill=(tag_col[0], tag_col[1], tag_col[2], 40))
        draw.text((px1 - 170, s_top + 62), tag, font=get_font(14, bold=True), fill=tag_col)
        s_top += 135

    # Storage Security Callout Card
    draw.rounded_rectangle([px0 + 25, s_top + 30, px1 - 25, py1 - 40], radius=20, fill=(16, 185, 129, 20), outline=(16, 185, 129), width=1)
    draw.text((px0 + 50, s_top + 60), "🛡️ Privacy First Architecture", font=get_font(24, bold=True), fill=(110, 231, 183))
    draw.text((px0 + 50, s_top + 105), "• Conversations never leave your device for training", font=get_font(18), fill=(226, 232, 240))
    draw.text((px0 + 50, s_top + 145), "• Secure isolated SQLite sandbox on Android", font=get_font(18), fill=(226, 232, 240))
    draw.text((px0 + 50, s_top + 185), "• Delete any conversation or reset anytime with 1-tap", font=get_font(18), fill=(226, 232, 240))

    img.save(os.path.join(OUT_DIR, "screenshot_3_privacy.png"))
    print("Saved screenshot 3")

# ==================== SCREENSHOT 4: CUSTOMIZABLE AI PERSONAS ====================
def generate_screenshot_4():
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 15, 30))
    draw = ImageDraw.Draw(img)
    draw_gradient(draw, WIDTH, HEIGHT, (15, 23, 42), (5, 8, 20))

    # Marketing Tagline
    f_tag = get_font(32, bold=True)
    f_title = get_font(60, bold=True)
    f_sub = get_font(30)
    
    # Badge
    draw.rounded_rectangle([WIDTH//2 - 210, 70, WIDTH//2 + 210, 120], radius=25, fill=(236, 72, 153, 40), outline=(236, 72, 153), width=2)
    draw.text((WIDTH//2 - 175, 78), "🎛️ FULL CONTROL & STYLES", font=f_tag, fill=(244, 114, 182))

    draw.text((WIDTH//2, 185), "Tailored AI Personas", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.text((WIDTH//2, 240), "Coding Expert, Creative, Concise, or Custom Prompts", font=f_sub, fill=(148, 163, 184), anchor="mm")

    # Phone Frame
    px0, py0, px1, py1 = 90, 310, 990, 1860
    draw_phone_frame(draw, px0, py0, px1, py1)
    draw_status_bar(draw, px0, py0, px1, get_font(18))
    draw_app_header(draw, px0, py0, px1, "Settings & Parameters", "Preferences")

    # Settings Cards
    s_top = py0 + 160
    # API Key Card
    draw.rounded_rectangle([px0 + 25, s_top, px1 - 25, s_top + 130], radius=18, fill=(30, 41, 59), outline=(51, 65, 85), width=1)
    draw.text((px0 + 50, s_top + 20), "Groq API Key (Cloud Fast Mode)", font=get_font(20, bold=True), fill=(255, 255, 255))
    draw.rounded_rectangle([px0 + 50, s_top + 58, px1 - 50, s_top + 105], radius=12, fill=(15, 23, 42))
    draw.text((px0 + 70, s_top + 70), "gsk_your_groq_api_key_here...", font=get_font(18), fill=(34, 211, 238))

    # Persona Presets Card
    p_top = s_top + 155
    draw.rounded_rectangle([px0 + 25, p_top, px1 - 25, p_top + 280], radius=18, fill=(30, 41, 59), outline=(51, 65, 85), width=1)
    draw.text((px0 + 50, p_top + 20), "AI Persona Presets", font=get_font(20, bold=True), fill=(255, 255, 255))

    personas = [
        ("General Assistant", "Helpful, balanced responses", True),
        ("Senior Developer", "Optimized clean code, zero fluff", False),
        ("Creative Writer", "Engaging narratives & marketing", False),
        ("Concise Analyst", "Direct bullet points & executive summaries", False),
    ]

    p_item_y = p_top + 60
    for name, desc, selected in personas:
        outline_col = (79, 70, 229) if selected else (51, 65, 85)
        bg_col = (49, 46, 129, 60) if selected else (15, 23, 42)
        draw.rounded_rectangle([px0 + 45, p_item_y, px1 - 45, p_item_y + 45], radius=10, fill=bg_col, outline=outline_col, width=1)
        draw.text((px0 + 65, p_item_y + 10), name, font=get_font(17, bold=True), fill=(255, 255, 255))
        draw.text((px0 + 240, p_item_y + 12), f"- {desc}", font=get_font(15), fill=(148, 163, 184))
        if selected:
            draw.text((px1 - 85, p_item_y + 10), "✓", font=get_font(18, bold=True), fill=(129, 140, 248))
        p_item_y += 52

    # Temperature Slider Card
    t_top = p_top + 305
    draw.rounded_rectangle([px0 + 25, t_top, px1 - 25, t_top + 160], radius=18, fill=(30, 41, 59), outline=(51, 65, 85), width=1)
    draw.text((px0 + 50, t_top + 20), "Creativity & Temperature", font=get_font(20, bold=True), fill=(255, 255, 255))
    draw.text((px1 - 110, t_top + 20), "0.7", font=get_font(20, bold=True), fill=(6, 182, 212))
    # Slider track
    draw.rounded_rectangle([px0 + 50, t_top + 75, px1 - 50, t_top + 85], radius=5, fill=(51, 65, 85))
    draw.rounded_rectangle([px0 + 50, t_top + 75, px0 + 50 + int((px1-px0-100)*0.7), t_top + 85], radius=5, fill=(6, 182, 212))
    # Thumb
    tx = px0 + 50 + int((px1-px0-100)*0.7)
    draw.ellipse([tx - 16, t_top + 64, tx + 16, t_top + 96], fill=(255, 255, 255))
    draw.text((px0 + 50, t_top + 108), "Precise (0.2)", font=get_font(15), fill=(148, 163, 184))
    draw.text((px1 - 160, t_top + 108), "Creative (1.0)", font=get_font(15), fill=(148, 163, 184))

    img.save(os.path.join(OUT_DIR, "screenshot_4_customization.png"))
    print("Saved screenshot 4")

if __name__ == "__main__":
    generate_screenshot_1()
    generate_screenshot_2()
    generate_screenshot_3()
    generate_screenshot_4()
    print("All screenshots generated successfully!")

