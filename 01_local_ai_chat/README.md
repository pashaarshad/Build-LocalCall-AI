# Local AI Chat (Phase 1 — LocalCall AI)

A production-grade, privacy-first Flutter AI chatbot designed for Android and iOS, built specifically as the conversational brain for **LocalCall AI**.

---

## 🌟 Why Qwen 2.5 for Mobile?

For on-device voice and call handling on mobile phones, model size, RAM footprint, and inference speed are paramount:
- **`qwen2.5:0.5b` (Recommended Default for All Phones):** Uses <500MB of RAM, responds in milliseconds, and fits even 2GB–3GB RAM Android budget devices.
- **`qwen2.5:1.5b`:** Exceptional reasoning, multi-turn memory, and conversational fluency for 4GB+ RAM phones.
- **`qwen2.5:3b`:** Deep intelligence and multilingual comprehension for flagship smartphones.

---

## 📱 Features

- **Token-by-Token Streaming:** Real-time character/word streaming with live latency counter.
- **Curated Mobile LLMs:** One-tap switching between Qwen 2.5 (0.5B, 1.5B, 3B) and Llama 3.2 (1B, 3B).
- **Phone Screener Persona Preset:** Includes an AI prompt specifically tuned to act as an incoming call screener.
- **Ollama Local Network Bridge:** Connects to Ollama running locally or on your home Wi-Fi network without third-party cloud APIs.
- **Multi-Session History & Local Storage:** Chats and settings are persisted locally on-device.
- **Material 3 UI:** Fluid animations, responsive bubble layout, Markdown code highlighting, and Dark/Light mode support.

---

## 🚀 Quick Start

### 1. Run on Android or iOS
```bash
cd "d:\Build LocalCall AI\01_local_ai_chat"
flutter pub get
flutter run
```

### 2. Connect to Local Ollama with Qwen 2.5
1. On your PC, launch Ollama bound to your local network:
   ```powershell
   # Windows PowerShell
   $env:OLLAMA_HOST = "0.0.0.0:11434"
   ollama run qwen2.5:0.5b
   ```
2. In the app:
   - Tap the **Settings (⚙️)** icon in the top right.
   - For an **Android Emulator**, use `http://10.0.2.2:11434`.
   - For a **Physical Android/iPhone on Wi-Fi**, enter your PC's local IP (e.g., `http://192.168.1.15:11434`).
   - Tap **Test Connection** — the badge will turn green (**Online**).

---

## 🧱 Architecture

```
lib/
├── models/
│   ├── chat_message.dart         # Message entity & serialization
│   ├── chat_session.dart         # Conversation session manager
│   └── llm_model_info.dart       # Curated mobile LLM metadata (Qwen 2.5 / Llama 3.2)
├── services/
│   ├── llm_service.dart          # Pluggable LLM interface
│   ├── ollama_service.dart       # Streaming HTTP client for Ollama
│   └── storage_service.dart      # Local SharedPreferences persistence
├── providers/
│   ├── settings_provider.dart    # Network, host, and model state
│   └── chat_provider.dart        # Reactive conversation & streaming controller
├── widgets/
│   ├── chat_bubble.dart          # Markdown-formatted message bubble with copy/regenerate
│   ├── chat_input_bar.dart       # Auto-expanding input with quick action chips
│   ├── connection_badge.dart     # Live host connection pill
│   └── model_selector_sheet.dart # Bottom sheet model picker with specs
├── screens/
│   ├── chat_screen.dart          # Main conversational screen
│   ├── settings_screen.dart      # Server, model, persona, and temperature config
│   └── history_screen.dart       # Conversation drawer with search & management
└── main.dart                     # App entry point with Material 3 theming
```
