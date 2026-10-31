import os
import uuid
import asyncio
from typing import Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
import edge_tts

app = FastAPI(title="LocalCall AI - Voice Agent TTS Service", version="1.0.0")

# Enable CORS for Flutter app (Web, Mobile, Desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

AUDIO_CACHE_DIR = os.path.join(os.path.dirname(__file__), "audio_cache")
os.makedirs(AUDIO_CACHE_DIR, exist_ok=True)

# Curated Tier Mapping for human-like voices
RECOMMENDED_VOICES = {
    # Top Indian Voices
    "en-IN-NeerjaExpressiveNeural": {"tag": "Recommended (Ultra-Realistic)", "lang": "English (India)", "desc": "Most expressive and natural conversational Indian English voice"},
    "en-IN-NeerjaNeural": {"tag": "Recommended", "lang": "English (India)", "desc": "Clear, professional corporate assistant"},
    "en-IN-PrabhatNeural": {"tag": "Recommended", "lang": "English (India)", "desc": "Calm, confident male corporate voice"},
    "hi-IN-SwaraNeural": {"tag": "Recommended (Expressive)", "lang": "Hindi (India)", "desc": "Warm, emotional, realistic female Hindi speaker"},
    "hi-IN-MadhurNeural": {"tag": "Recommended", "lang": "Hindi (India)", "desc": "Deep, authoritative, pleasant male Hindi speaker"},
    "ta-IN-PallaviNeural": {"tag": "Recommended", "lang": "Tamil (India)", "desc": "Clear, natural female Tamil speaker"},
    "ta-IN-ValluvarNeural": {"tag": "Recommended", "lang": "Tamil (India)", "desc": "Classic, articulate male Tamil voice"},
    "te-IN-ShrutiNeural": {"tag": "Recommended", "lang": "Telugu (India)", "desc": "Friendly, fluid female Telugu speaker"},
    "te-IN-MohanNeural": {"tag": "Recommended", "lang": "Telugu (India)", "desc": "Professional male Telugu voice"},
    "kn-IN-SapnaNeural": {"tag": "Recommended", "lang": "Kannada (India)", "desc": "Natural, expressive female Kannada voice"},
    "kn-IN-GaganNeural": {"tag": "Recommended", "lang": "Kannada (India)", "desc": "Clear male Kannada voice"},
    "ml-IN-SobhanaNeural": {"tag": "Recommended", "lang": "Malayalam (India)", "desc": "Graceful female Malayalam speaker"},
    "ml-IN-MidhunNeural": {"tag": "Recommended", "lang": "Malayalam (India)", "desc": "Resonant male Malayalam speaker"},
    "mr-IN-AarohiNeural": {"tag": "Recommended", "lang": "Marathi (India)", "desc": "Polite female Marathi voice"},
    "mr-IN-ManoharNeural": {"tag": "Recommended", "lang": "Marathi (India)", "desc": "Distinct male Marathi voice"},
    "bn-IN-TanishaaNeural": {"tag": "Recommended", "lang": "Bengali (India)", "desc": "Melodic female Bengali voice"},
    "bn-IN-BashkarNeural": {"tag": "Recommended", "lang": "Bengali (India)", "desc": "Warm male Bengali speaker"},
    "gu-IN-DhwaniNeural": {"tag": "Recommended", "lang": "Gujarati (India)", "desc": "Lively female Gujarati speaker"},
    "gu-IN-NiranjanNeural": {"tag": "Recommended", "lang": "Gujarati (India)", "desc": "Articulate male Gujarati voice"},
    "ur-IN-GulNeural": {"tag": "Recommended", "lang": "Urdu (India)", "desc": "Elegant female Urdu speaker"},
    "ur-IN-SalmanNeural": {"tag": "Recommended", "lang": "Urdu (India)", "desc": "Clear male Urdu speaker"},
    # Top Global Voices
    "en-US-JennyMultilingualNeural": {"tag": "Best Human (Multilingual)", "lang": "English (US)", "desc": "Hollywood-grade conversational voice"},
    "en-US-GuyNeural": {"tag": "Best Human", "lang": "English (US)", "desc": "Dynamic, natural male conversationalist"},
    "en-US-AriaNeural": {"tag": "Expressive", "lang": "English (US)", "desc": "Polished, newsreader-grade female voice"},
    "en-GB-SoniaNeural": {"tag": "Best British", "lang": "English (UK)", "desc": "Sophisticated British female voice"},
    "en-GB-RyanNeural": {"tag": "Best British", "lang": "English (UK)", "desc": "Engaging British male voice"},
}

class TTSRequest(BaseModel):
    text: str
    voice: Optional[str] = "en-IN-NeerjaExpressiveNeural"
    rate: Optional[int] = 0        # -50 to +100 (%)
    pitch: Optional[int] = 0       # -50 to +50 (Hz)
    volume: Optional[int] = 0      # -50 to +50 (%)

def format_rate(rate: int) -> str:
    return f"{'+' if rate >= 0 else ''}{rate}%"

def format_pitch(pitch: int) -> str:
    return f"{'+' if pitch >= 0 else ''}{pitch}Hz"

def format_volume(volume: int) -> str:
    return f"{'+' if volume >= 0 else ''}{volume}%"

@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "LocalCall AI Voice Studio"}

@app.get("/api/voices")
async def get_voices():
    raw_voices = await edge_tts.list_voices()
    formatted = []
    
    for v in raw_voices:
        short_name = v["ShortName"]
        locale = v.get("Locale", "")
        gender = v.get("Gender", "Unknown")
        is_indian = "-IN" in locale
        
        info = RECOMMENDED_VOICES.get(short_name, {})
        tag = info.get("tag", "Standard Neural")
        desc = info.get("desc", f"Neural {gender} voice for {locale}")
        lang_display = info.get("lang", locale)
        
        # Determine priority tier
        tier = "recommended" if short_name in RECOMMENDED_VOICES else ("indian" if is_indian else "standard")

        formatted.append({
            "short_name": short_name,
            "friendly_name": v.get("FriendlyName", short_name),
            "locale": locale,
            "gender": gender,
            "is_indian": is_indian,
            "tier": tier,
            "tag": tag,
            "description": desc,
            "lang_display": lang_display,
        })

    # Sort so Recommended & Indian voices are prioritized at the top
    def sort_key(item):
        if item["short_name"] in RECOMMENDED_VOICES:
            return (0, 0 if item["is_indian"] else 1, item["short_name"])
        elif item["is_indian"]:
            return (1, 0, item["short_name"])
        else:
            return (2, 0, item["short_name"])

    formatted.sort(key=sort_key)
    return {
        "total": len(formatted),
        "indian_count": sum(1 for v in formatted if v["is_indian"]),
        "recommended_count": len(RECOMMENDED_VOICES),
        "voices": formatted
    }

@app.post("/api/tts")
async def synthesize(req: TTSRequest):
    text = req.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    voice = req.voice or "en-IN-NeerjaExpressiveNeural"
    rate_str = format_rate(req.rate or 0)
    pitch_str = format_pitch(req.pitch or 0)
    volume_str = format_volume(req.volume or 0)

    audio_id = str(uuid.uuid4())
    filename = f"{audio_id}.mp3"
    filepath = os.path.join(AUDIO_CACHE_DIR, filename)

    try:
        communicate = edge_tts.Communicate(
            text=text,
            voice=voice,
            rate=rate_str,
            pitch=pitch_str,
            volume=volume_str
        )
        await communicate.save(filepath)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS synthesis failed: {str(e)}")

    file_size = os.path.getsize(filepath) if os.path.exists(filepath) else 0

    return {
        "status": "success",
        "audio_id": audio_id,
        "filename": filename,
        "voice": voice,
        "file_size": file_size,
        "audio_url": f"/api/audio/{audio_id}",
        "download_url": f"/api/download/{audio_id}"
    }

@app.get("/api/audio/{audio_id}")
async def get_audio(audio_id: str):
    filename = f"{audio_id}.mp3"
    filepath = os.path.join(AUDIO_CACHE_DIR, filename)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Audio not found")
    return FileResponse(filepath, media_type="audio/mpeg")

@app.get("/api/download/{audio_id}")
async def download_audio(audio_id: str, title: Optional[str] = None):
    filename = f"{audio_id}.mp3"
    filepath = os.path.join(AUDIO_CACHE_DIR, filename)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Audio not found")
    
    clean_title = (title or "LocalCall_AI_Voice").replace(" ", "_")
    download_filename = f"{clean_title}.mp3"

    return FileResponse(
        filepath,
        media_type="audio/mpeg",
        headers={"Content-Disposition": f'attachment; filename="{download_filename}"'}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
