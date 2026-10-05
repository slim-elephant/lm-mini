# Changelog

All notable changes to LM Mini will be documented in this file.

## [1.9.13] - 2026-10-01

**Apple Watch & Shortcuts**

- Introducing the Apple Watch app for LM Mini
- Fixes Unsloth showing all models as loaded
- Fixes being unable to scroll the Unsloth model list
- Fixes Shortcuts failing over http, so Ask can speak the answer without opening the app
- Fixes Gemma 3 on-device models failing to load
- Fixes Feature Requests failing to load before sign-in finished

## [1.9.12] - 2026-09-28

**Unsloth context, ComfyUI workflows & clearer limits**

- Added Context Length for Unsloth — the Model Parameters slider loads the model at that size, and asks before reloading if it is already loaded at another size
- Added Load settings from a ComfyUI workflow, and a name so the next image is saved into that list
- Added Resize images for physical batch — shrinks a photo when it would be too big for a local model and crash the server
- Fixes the context bar sitting far below LM Studio — a finished reply uses LM Studio’s own token count, including thinking
- Fixes high thinking using up the whole reply — Mini tries again with low thinking, and tells you that you can raise max tokens to keep high thinking
- Fixes an unknown MCP looking like an app bug — Mini says the server rejected that tool, and does not offer Send to support unless it is Pro Search or Code Sandbox
- Fixes a camera photo disappearing when you come back to the chat
- Fixes “Loading model” showing again after the reply has already moved on
- Fixes ComfyUI graphs, including Z-Image, losing the prompt or ignoring the graph’s own sampler
- Fixes Connect / Share with phone sending image generation to the chat server instead of AUTOMATIC1111 or ComfyUI
- Fixes the app closing on the splash screen on older iPhones, such as the iPhone 8

## [1.9.10] - 2026-09-21

**Full-width chat, gallery & crash fixes**

- Added Unsloth Desktop as a free local OpenAI-compatible provider
- Added Generated images gallery in the chat ⋯ menu
- Added website-icon pile for web search sources (tap to expand, tap again for results)
- Added support tickets can attach the error log
- Full-width replies is now the default — your messages stay in a bubble, assistant text uses the whole row
- Improved the chat ⋯ menu (glass) and the streaming status shimmer
- Hides embedding models from Model Section
- Fixes attaching a file from Drive / Recents failing with an unknown path
- Fixes image generation crashing when the server isn't AUTOMATIC1111 (`Null` is not a `List`)
- Fixes two New Chat taps creating the same conversation id
- Fixes memory extraction still running after you stop a reply
- Fixes the Voice API-key sheet fighting the keyboard

## [1.9.8] - 2026-09-17

**Siri answers, Home personas & clearer host errors**

- Added Siri Ask / Summarize / Translate / Search / News that speak Mini’s reply (iOS 16.4+; stays in Siri on newer iOS)
- Added Sync personas when Home chat sync is on — pick which personas copy between phone and Mac, including photos and memories
- Added Full-width replies in Appearance — your messages stay in a bubble, assistant text uses the whole row
- Added Compress image and resend when LM Studio stops because an attached photo is huge
- Fixes Face ID / Touch ID unlocking then bouncing straight back to the lock screen
- Fixes Share with phone on Home dropping after you close the laptop lid and not reconnecting until you refresh
- Fixes Home sync replacing an existing chat title, and leftover image-prompt text showing in titles
- Fixes LM Studio / llama.cpp stopping mid-reply looking like a Mini crash — now says the model server stopped, and points at context / max tokens
- Fixes a sent chat that never reached LM Studio (proxy or tunnel) looking like a Mini bug
- Fixes Kokoro English voice generating silence

## [1.9.5] - 2026-09-15

**Face ID lock, image gen setup & clearer errors**

- Added Face ID, Touch ID, and fingerprint unlock for App Lock
- Added PIN recovery — sign in and we can email a verification link if you forget the PIN
- Added Cancel on Hugging Face / LM Studio model downloads
- Added a prompt to reload the model when you change context length
- Added a prompt to update image generation when you change the chat server address (and the other way around)
- Fixes chat stalling or coming back empty while a model is downloading
- Fixes Live Activities not coming back after you open the app
- Fixes the chat ⋮ menu crashing
- Fixes a missing LM Studio MCP (like Playwright) showing up as a Pro Search outage
- Fixes image generation when ComfyUI or AUTOMATIC1111 isn't running — Mini now says it can't reach them
- Fixes ComfyUI when there's no checkpoint, or the graph needs your exported workflow
- Fixes Share with phone / Can't reach your Mac looking like a crash instead of setup help
- Fixes tools finishing with no reply when max tokens is too low — now says to increase it

## [1.9.1] - 2026-09-11

**Low battery, voice playback & Android scroll**

- Added Low battery mode in Appearance — no glass, plain text while the reply streams, Home/iCloud sync after the message finishes
- Fixes Android chat not following streaming replies (stayed on the start of the bubble until the model finished)
- Fixes voice mode leaving the mic open after send so Kokoro could not play (iOS CannotInterruptOthers)
- If the selected model is missing (HTTP 404), shows a banner to pick another model
- Fixes iOS showing a Local Network permission warning when LM Studio just wasn't serving
- Fixes app crashing when the PC drops off the network while loading models
- Fixes chat fonts failing to download — they now come with the app

## [1.9.0] - 2026-09-08

**App Lock, JAN AI & Persona Voices**

- Added App Lock (Pro) — set a 4 or 6 digit PIN and choose how long the app can stay closed before asking again
- Added JAN AI as a local provider
- Added Ability to assign Kokoro, ElevenLabs or Grok voices to Personas from one dropdown
- Improved composer tools bar — icons when collapsed, chips when expanded
- Improved Persona setup — tap Preferred Model to change it, edit avatar from the pencil
- Fixes tools being sent to models that don't support them
- Fixes Ollama regenerate going to the wrong backend
- Fixes App Lock toggle not updating after setting a PIN
- Fixes Pro tags showing for users who already have Pro
- Fixes mixed icon styles in Settings

## [1.8.20] - 2026-08-20

**LM Mini Home, sync & model params**

- Added Ability to connect with LM Mini Home
- Added Real-time sync to LM Mini iOS and macOS
- Added background model downloads and progress notification
- Added Rolling Conversation in Model Params
- Added Compact Conversation when Context is 90%
- Added toggle to disable Glass Effect
- Added Model Specific Parameters
- Added ability to save Models Parameters to Personas
- Fixes Apple Pencil Support
- Fixes Reasoning Tokens generation even when reasoning is off
- Fixes videos generation using ComfyUI
- Fixes long conversation keeps resending whole history
- Fixes Reasoning not appearing for Llama-server
- Fixes Title failing to generate for a chat
- Fixes llama-server reasoning model detection
- Fixes UI Bugs

## [1.8.12] - 2026-08-09

**Tools, SearXNG & ComfyUI LoRAs**

- Fixes MCP tools appearing on wrong bubble
- Fixes SearXNG silently failing
- Added Loras Support for ComfyUI
- Fixes Group chat scenario not being registered
- Fixes Regeneration Icon not appearing

## [1.8.10] - 2026-08-01

**Scroll to bottom, Gemma reasoning & context fixes**

- Fixes Keyboard not closing after sending a message
- Fixes Reasoning toggle not appearing for some models
- Fixes scroll getting stuck when reopening old chats
- Fixes Group chat not able to find certain models
- Added Scroll to bottom on chats
- Added ability to work with Gemma thought process
- Fixes model loading progress bar
- Fixes chat history not being sent in full for context
- Fixes invalid calculation of context tokens

## [1.8.8] - 2026-07-29

- Fixes context window conflicts with LM Studio
- Fixes Reasoning mode not appearing for some models
- Fixes Voice chat Reloading model

## [1.8.6] - 2026-07-27

- Fixes new Persona Screen loading loop
- Added Chinese app language
- Fixes Long errors blocking the screen

## [1.8.5] - 2026-07-27

**Settings Refresh & Beginner Mode**

- Improved Settings interface — clearer desktop-class layout on Mac and iPad
- Improved Providers management — easier server and model setup
- Easy mode for beginners — simpler defaults when Advanced Mode is off
- Fixed missing quantization labels in Model Management

## [1.5.0] - 2026-04-26

### New Features

- **USB Mode (beta, iOS only, free)**: Connect your iPhone to your Mac with a USB cable and run LM Studio without Wi-Fi.
  - Available on every iPhone — no Pro subscription required.
  - Lives inside Settings → API Token → USB Mode (toggle revealed when you expand the API token row).
  - Pairs with **LM Mini Connect 1.4.0+** on the Mac, which uses Apple's `usbmuxd` daemon to detect the iPhone over the cable.
  - Mutually exclusive with Remote Access; the relay pauses while USB Mode is on.
  - Friendly "Waiting for Mac" dialog replaces the generic server-not-configured popup when the Mac peer hasn't attached yet.

## [1.0.3] - 2025-12-26

### New Features

- **Chat-Level Settings Overrides**: Override global settings on a per-chat basis
  - Override model, system prompt, temperature, max tokens, top-p, top-k, min-p, and repeat penalty
  - Visual indicator shows which settings are overridden in each chat
  - Settings icon in chat app bar changes color when overrides are active
  - Easy toggle switches to enable/disable individual overrides
  - "Reset All" button to quickly clear all overrides
- **Chat Export System**: Export individual conversations or all chats
  - Export single chats as PDF or TXT from the chat screen menu
  - Export all conversations as a ZIP file from settings
  - Native share dialog integration for easy file sharing
  - Automatic filtering of tool call messages from exports
  - Professional PDF formatting with markdown rendering, images, and attachments
- Markdown and rich text rendering in messages with syntax highlighting for code blocks
- Tool use support: Models can now call functions like web search and get current time
- SearXNG integration for enhanced web search with privacy-focused metasearch
- Test connection button for SearXNG configuration with detailed status feedback
- Comprehensive SearXNG setup guide with Docker installation instructions
- Option to hide user and assistant avatars in chat interface
- Search results count slider (2-10 results) for tool-based web searches

### Improvements

- Fixed chat auto-scrolling during message streaming and when loading conversations
- Tool call results now display as interactive badges on assistant messages
- Models now support text-based tool calling when API format is unavailable
- Search chain: Pro Search (hosted), or self-hosted SearXNG
- Stop button now properly cancels ongoing message generation
- Better handling of orphaned tool results when iteration limits are reached

### UI/UX Enhancements

- Tool badges show clickable icons with "Tool" and "Result" labels
- Improved settings organization with Tool Calling and Data sections
- Added visual feedback for connection testing with color-coded status messages
- Collapsible tool details dialog with copy functionality
- Export progress indicators with conversation count
- Success/error feedback for all export operations

---

## [1.0.2] - 2025-12-08

- Redesigned app icon with larger, more readable "LM" and "MINI" text
- Added Vision badge (purple) for vision-capable models in model selection
- Added Tools badge (orange) for models that support function calling
- Fixed folder view preference not persisting on app restart
- Added background overlay opacity slider for chat backgrounds (0-100% darkness)
- Added streaming thinking indicator that shows model's reasoning process in real-time
- Thinking content now displayed in collapsible section after message completion
- Improved semantic search UI with bottom sheet results and scroll-to-message navigation
- Message highlighting when navigating to search results
- Switched from legacy v0 to v1 embeddings endpoint
- Removed deprecated v0 API parameters (frequencyPenalty, presencePenalty)

---

## [1.0.1] - 2025-12-03

### 🎉 Major Features

#### Stateful Chat System
- **Token-Efficient Conversations**: New streaming chat system uses LM Studio's v1 API with stateful sessions
- **Real-Time Progress**: See exactly what's happening with live status indicators:
  - Model loading progress (0-100%)
  - Prompt processing stages
  - Chain-of-thought reasoning display
  - Token generation streaming
- **Smart Context Management**: Only sends new messages, not entire conversation history
- **Event-Driven UX**: Beautiful progress indicators show model loading, thinking, and writing stages

#### Vision Model Support
- **Multi-Modal Conversations**: Chat with vision-capable models using images
- **Image Attachment**: Pick images from gallery or camera
- **Base64 Encoding**: Automatic image optimization for API compatibility
- **Visual Feedback**: Images display above messages in chat bubbles

#### Chat Organization
- **Folder Management**: Organize conversations into custom folders
- **Drag & Drop**: Move chats between folders with intuitive gestures
- **Color Coding**: Assign colors to folders for quick visual identification
- **Nested Structure**: Keep your conversations organized and accessible

#### Per-Chat Customization
- **Custom Backgrounds**: Set unique backgrounds for each conversation
- **Avatar Personalization**: Custom user and assistant avatars per chat
- **Color Themes**: Customize bubble and text colors for each conversation
  - User bubble color
  - User text color
  - Assistant bubble color
  - Assistant text color
- **Visual Identity**: Each chat can have its own look and feel

### 🔧 New Features

#### Model Management
- **Hugging Face Integration**: Download models directly from Hugging Face
- **Quantization Selection**: Choose from available quantizations (Q4, Q8, etc.)
- **Download Progress**: Live tracking with FAB (Floating Action Button)
- **Smart Loading**: Configure context length, flash attention, and other advanced options when loading models

#### Advanced Settings
- **Generation Parameters** (v1 API):
  - Temperature (0.0-1.0)
  - Top P, Top K, Min P
  - Repeat Penalty (replaces frequency/presence penalty)
  - Max Output Tokens
  - Reasoning mode (off/low/medium/high/on)
  - System prompt support
- **Model Load Configuration**:
  - Custom context length override
  - Eval batch size
  - Flash attention toggle
  - Number of experts (for MoE models)
  - KV cache GPU offloading

#### Semantic Search
- **Embedding Models**: Use embedding models for intelligent message search
- **Context-Aware**: Find relevant messages based on meaning, not just keywords
- **Fast Retrieval**: Quickly locate important information in long conversations

#### Performance Stats
- **Detailed Metrics** (when "Show Runtime Info" is enabled):
  - Tokens per second
  - Input/output token counts
  - Reasoning token usage
  - Time to first token
  - Total generation time
- **Visual Display**: Stats appear as color-coded chips below messages

### 🎨 UI/UX Improvements

#### Settings Revamp
- **Organized Sections**: Clear categorization of settings
  - Server configuration
  - Model management
  - Generation parameters
  - Appearance options
  - Advanced features
  - Legal information
- **Connection Help**: Comprehensive troubleshooting dialog for server connection issues
- **Version Info**: App name and version displayed at bottom of settings

#### Enhanced Chat Interface
- **Streaming Status Bar**: Live updates showing:
  - "Loading model..." with progress
  - "Processing prompt..." with percentage
  - "Thinking..." with reasoning preview
  - "Writing response..." during generation
- **Message Statistics**: Optional nerdy stats display
- **Improved Bubbles**: Better text rendering with custom colors
- **Thinking Tags**: Support for `<think>` and `<thinking>` tags in responses

### 🐛 Bug Fixes
- Fixed connection test showing "Connected" on failure
- Improved error handling with proper exception rethrowing
- Corrected quantization display (Q8_0 vs Q8)
- Fixed temperature slider range for v1 API (0.0-1.0)

### 🔄 API Updates
- **LM Studio v1 API Support**:
  - `/api/v1/chat` for stateful conversations
  - `/api/v1/models/load` for advanced model loading
  - Server-Sent Events (SSE) for real-time streaming
  - Comprehensive event types (18 different events)
- **Backward Compatibility**: Legacy v0 API still supported as fallback

### 📚 Documentation
- Added connection troubleshooting guide
- Model management instructions
- Feature guide for new capabilities
- Marketing materials for App Store
- Build instructions for developers

---

## [1.0.0] - Initial Release

### Core Features
- Local LLM chat interface
- LM Studio integration
- Basic conversation management
- Message persistence with SQLite
- Dark/light theme support
- Model selection
- Basic generation parameters

