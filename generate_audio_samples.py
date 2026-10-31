import os
import asyncio
import edge_tts

OUTPUT_DIR = r"d:\Build LocalCall AI\02_local_voice\local_voice_app\assets\samples"
os.makedirs(OUTPUT_DIR, exist_ok=True)

SAMPLES = [
    ("hi_swara", "hi-IN-SwaraNeural", "नमस्ते, मैं स्वरा हूँ। आपकी हिंदी वॉयस असिस्टेंट।"),
    ("hi_madhur", "hi-IN-MadhurNeural", "नमस्कार, मैं मधुर हूँ। आपकी सेवा में तत्पर स्पष्ट हिंदी आवाज़।"),
    ("en_in_neerja", "en-IN-NeerjaExpressiveNeural", "Hello, I am Neerja, your expressive Indian English voice assistant."),
    ("en_in_prabhat", "en-IN-PrabhatNeural", "Hello, I am Prabhat, a confident male Indian English corporate voice."),
    ("ta_pallavi", "ta-IN-PallaviNeural", "வணக்கம், நான் பல்லவி. உங்கள் தமிழ் குரல் உதவியாளர்."),
    ("ta_valluvar", "ta-IN-ValluvarNeural", "வணக்கம், நான் வள்ளுவர். தெளிவான ஆண் தமிழ் குரல்."),
    ("te_shruti", "te-IN-ShrutiNeural", "నమస్కారం, నేను శృతి. మీ తెలుగు వాయిస్ అசிస్టెంట్."),
    ("te_mohan", "te-IN-MohanNeural", "నమస్కారం, నేను మోహన్. స్పష్టమైన తెలుగు పురుష వాయిస్."),
    ("kn_sapna", "kn-IN-SapnaNeural", "ನಮಸ್ಕಾರ, ನಾನು ಸಪ್ನಾ. ನಿಮ್ಮ ಕನ್ನಡ ವಾಯ್ಸ್ ಅಸಿಸ್ಟೆಂಟ್."),
    ("kn_gagan", "kn-IN-GaganNeural", "ನಮಸ್ಕಾರ, ನಾನು ಗಗನ್. ನಿಮ್ಮ ಕನ್ನಡ ವಾಯ್ಸ್."),
    ("bn_tanishaa", "bn-IN-TanishaaNeural", "নমস্কার, আমি তানিশা। আপনার বাংলা ভয়েস অ্যাসিস্ট্যান্ট।"),
    ("bn_bashkar", "bn-IN-BashkarNeural", "নমস্কার, আমি ভাস্কর। আপনার বাংলা পুরুষ ভয়েস।"),
    ("gu_dhwani", "gu-IN-DhwaniNeural", "નમસ્તે, હું ધ્વનિ છું. તમારી ગુજરાતી અવાજ સહાયક."),
    ("mr_aarohi", "mr-IN-AarohiNeural", "नमस्कार, मी आरोही आहे. तुमची मराठी व्हॉईस असिस्टंट."),
    ("ur_gul", "ur-IN-GulNeural", "السلام علیکم، میں گل ہوں۔ آپ کی اردو وائس اسسٹنٹ۔"),
    ("en_us_jenny", "en-US-JennyMultilingualNeural", "Hello! I am Jenny, a natural and friendly conversational voice."),
    ("en_us_guy", "en-US-GuyNeural", "Hey there! I am Guy, a warm and dynamic male voice."),
    ("en_gb_sonia", "en-GB-SoniaNeural", "Hello, I am Sonia, a polished and sophisticated British voice.")
]

async def generate():
    for key, voice, text in SAMPLES:
        file_path = os.path.join(OUTPUT_DIR, f"{key}.mp3")
        try:
            comm = edge_tts.Communicate(text=text, voice=voice)
            await comm.save(file_path)
            size = os.path.getsize(file_path)
            print(f"Generated {key}.mp3 ({size} bytes) with {voice}")
        except Exception as e:
            print(f"Error for {key}: {e}")

if __name__ == "__main__":
    asyncio.run(generate())
