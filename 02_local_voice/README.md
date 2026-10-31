# LocalCall AI — Phase 2: Text-to-Voice AI Agent Studio

A high-fidelity Neural Text-to-Speech (TTS) Studio powered by Python neural voice synthesis and a Flutter mobile/desktop studio application.

---

## 🌟 Key Features

1. **320+ Ultra-Realistic Neural Human Voices:**
   - **Indian Languages & Accents:**
     - 🇮🇳 **English (India):** Neerja Expressive (Ultra-human conversational), Prabhat (Corporate male)
     - 🇮🇳 **Hindi:** Swara (Expressive female), Madhur (Authoritative male)
     - 🇮🇳 **Tamil:** Pallavi (Female), Valluvar (Male)
     - 🇮🇳 **Telugu:** Shruti (Female), Mohan (Male)
     - 🇮🇳 **Kannada:** Sapna (Female), Gagan (Male)
     - 🇮🇳 **Malayalam:** Sobhana (Female), Midhun (Male)
     - 🇮🇳 **Marathi:** Aarohi (Female), Manohar (Male)
     - 🇮🇳 **Bengali:** Tanishaa (Female), Bashkar (Male)
     - 🇮🇳 **Gujarati:** Dhwani (Female), Niranjan (Male)
     - 🇮🇳 **Urdu:** Gul (Female), Salman (Male)
     - Plus 300+ global voices (US, UK, Canadian, Australian, European).

2. **Categorized Voice Selection:**
   - **⭐ Recommended (Ultra-Realistic):** Handpicked human conversational agents.
   - **🇮🇳 Indian Regional:** All 21 official Indian language neural voices.
   - **All Voices:** 320+ international neural voices.
   - **Gender Filtering:** Female / Male voice tabs.

3. **Fine-Grained Parameter Tuning:**
   - **Speech Speed / Rate:** From -50% (0.5x slow) up to +100% (2.0x fast).
   - **Voice Pitch:** -50Hz to +50Hz for deeper or higher tones.
   - **Volume Control:** -50% to +50%.
   - Quick one-tap presets: Natural, Fast Narration, Calm & Slow, Deep Voice.

4. **Unlimited Text Input & Sample Scripts:**
   - Input text of unlimited length with live word & character counter.
   - Quick prompt templates: Support Agent, Hindi Welcome, Story Narration, Tech Announcement.

5. **Audio Player with 3-Dot (`⋮`) Download Menu:**
   - Visual waveform progress bar with scrubber.
   - Play, Pause, Replay, and 10-second skip forward/back.
   - Playback speed multiplier (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
   - **Three-Dot Menu (`⋮`):**
     - 📥 **Download Audio:** Automatically downloads and saves the generated `.mp3` file directly onto the phone storage (`/Download` or Documents).
     - 📋 **Copy Text:** One-tap clipboard copy.
     - ℹ️ **Audio Details:** Displays file size, voice model used, and tuning parameters.

6. **Voice Conversion History:**
   - Persisted session history with swipe-to-delete and instant re-download.

---

## 🚀 How to Run

### Step 1: Start the Python Backend Service
Open a terminal or double-click:
```powershell
d:\Build LocalCall AI\02_local_voice\backend\run_backend.bat
```
The server will start on port `8000` (`http://0.0.0.0:8000`).

### Step 2: Install or Run the Mobile App
- **Direct APK:** Install [`LocalVoice_Studio.apk`](../LocalVoice_Studio.apk) (16.9 MB) on any Android device.
- **Or Run with Flutter:**
```powershell
cd "d:\Build LocalCall AI\02_local_voice\local_voice_app"
flutter run
```
- In the app, tap the **Connection Status** pill at the top right to verify or update the backend IP address (e.g. `http://10.0.2.2:8000` on Android emulator, or `http://192.168.x.x:8000` on a physical phone connected over Wi-Fi).
