# Google Play Store Listing & Publishing Metadata

Use this document to quickly fill in each section of the **Google Play Console** during submission.

---

## 1. Store Listing Details

| Field | Limit | Text to Copy & Paste |
|---|---|---|
| **App Name** | 30 chars max | `LocalCall AI - Fast AI Chat` |
| **Short Description** | 80 chars max | `Ultra-fast AI chat powered by Qwen & Allam models with 100% private storage.` |

### Full Description (4000 characters limit)
```text
Experience lightning-fast artificial intelligence right in your pocket with LocalCall AI!

Powered by ultra-low-latency cloud LPU inference and leading open-weight LLMs, LocalCall AI gives you immediate answers, high-precision code generation, creative storytelling, and intelligent summaries in milliseconds.

⚡ KEY HIGHLIGHTS:

• ULTRA-FAST STREAMING RESPONSES:
Experience instant token generation with minimal latency powered by high-throughput Groq Cloud LPU inference.

• TOP OPEN-WEIGHT AI MODELS:
Switch seamlessly between curated models suited for every need:
- Qwen 3.8 (27B): Exceptional reasoning, debugging, math, and coding expert.
- Allam 2 (7B): Agile multi-lingual conversational intelligence.
- OpenAI GPT-OSS (20B): Creative writing, drafting, and detailed summarization.

• 100% PRIVATE LOCAL STORAGE:
Your conversations are yours alone. All chat history is stored exclusively on your device using an encrypted local SQLite database. We never upload your chats to external database servers or use them for training.

• CUSTOMIZABLE AI PERSONAS:
Tailor the assistant to your exact workflow with one-tap presets:
- Senior Software Engineer (clean code & architectural advice)
- Creative Storyteller (engaging copy & storytelling)
- Concise Executive (bullet points and direct takeaways)
- General Assistant (balanced, friendly everyday companion)

• FINE-GRAINED GENERATION CONTROL:
Easily adjust temperature sliders, system prompts, and custom API keys anytime.

• ZERO SUBSCRIPTIONS & NO LOCK-IN:
Use your own free Groq Cloud API key without recurring subscription fees or artificial daily message caps.

Download LocalCall AI today and unlock personal, blazing-fast AI intelligence with total privacy!
```

---

## 2. Store Assets Checklist

All required graphical assets are prepared and ready in your `play_store_assets` folder:

| Asset | Requirement | File Location | Status |
|---|---|---|---|
| **App Icon** | 512 x 512 PNG (max 1024KB, 32-bit color) | `play_store_assets/app_icon_512.png` | ✅ Generated |
| **Feature Graphic** | 1024 x 500 JPEG/PNG (max 15MB, 24-bit) | `play_store_assets/feature_graphic_1024x500.png` | ✅ Generated |
| **Screenshot 1** | Phone (1080 x 1920 PNG) - Chat Streaming | `play_store_assets/screenshots/screenshot_1_chat_stream.png` | ✅ Generated |
| **Screenshot 2** | Phone (1080 x 1920 PNG) - Model Selector | `play_store_assets/screenshots/screenshot_2_models.png` | ✅ Generated |
| **Screenshot 3** | Phone (1080 x 1920 PNG) - SQLite Privacy | `play_store_assets/screenshots/screenshot_3_privacy.png` | ✅ Generated |
| **Screenshot 4** | Phone (1080 x 1920 PNG) - Personas & Tuning | `play_store_assets/screenshots/screenshot_4_customization.png` | ✅ Generated |

---

## 3. App Content & Policy Questionnaire Guide

### A. Privacy Policy
- Provide the hosted URL of `PRIVACY_POLICY.md` (can be uploaded to GitHub Pages, GitHub Gist, or Notion).
- Example free URL hosting: create a public GitHub Gist or GitHub Repository Page with the contents of `PRIVACY_POLICY.md`.

### B. Ads
- Does your app contain ads? Select: **No, my app does not contain ads**.

### C. App Access
- Are any parts of the app restricted? Select: **All functionality is available without special access**.

### D. Content Rating (IARC)
- Category: **Utility, Productivity, Communication, or other**
- Does the app contain violence/offensive content? **No**
- Does the app collect location? **No**
- Can users interact/exchange messages with other human users? **No** (interactions are solely with automated AI).
- Result: **Rated for 3+ / Everyone** (or 13+ depending on regional AI guidance).

### E. Target Audience and Content
- Target age: **13-15, 16-17, 18 and over**
- Could your store listing appeal to children? **No**

### F. Data Safety Section
- **Does your app collect or share any user data?**
  - Select **Yes** (because chat prompts are transmitted to the API to generate responses).
- **Is user data encrypted in transit?**
  - Select **Yes** (transmitted over secure HTTPS).
- **Do you provide a way for users to request data deletion?**
  - Select **Yes** (users can delete chats from History or clear app data).
- **Data types:**
  - Category: *App functionality* -> *User Messages/Prompts*
  - Collected? Transmitted ephemerally to Groq Cloud API for completion generation.
  - Shared? Not shared with third parties for advertising or tracking.
  - Stored permanently on developer servers? **No**.

---

## 4. Release Track & Keystore Info

- **Artifact Format:** Android App Bundle (`.aab`)
- **Package Name:** `com.localcallai.local_ai_chat`
- **Keystore File:** `upload-keystore.jks`
- **Keystore Alias:** `upload`
- **Keystore Password:** `localcallai2026`
- **Key Password:** `localcallai2026`
