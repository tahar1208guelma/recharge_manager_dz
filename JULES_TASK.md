# 🤖 Comprehensive Mission Prompt for Google Jules (14+ Hour Autonomous Deep Refactor & Verification)

---

### Instructions for Running this Task:
Copy and paste the entire prompt below into **Google Jules** (at [https://jules.google/](https://jules.google/)) or inside a GitHub Issue assigned to Jules.

---

```markdown
# MISSION: Autonomous Deep Audit, Error Resolution, Live SIM Monitoring, and Operator Engine Optimization for Recharge Manager DZ

You are tasked with an exhaustive, production-grade overhaul of **Recharge Manager DZ** (an Algerian Telecom POS Desktop application managing Mobilis, Djezzy, and Ooredoo SIM cards via USB GSM Modems and Smart Card readers).

Execute this comprehensive, multi-phase refactoring, testing, and hardening mission thoroughly without taking shortcuts.

---

## 🎯 OBJECTIVES & REQUIREMENTS

### 1. Hardware Abstraction Layer & Auto-Detection Engine (HAL)
- **Automatic Hotplug & Continuous Device Polling**: Implement a resilient background hardware watcher that detects USB GSM Modems (Huawei, ZTE, SIMCom, Quectel) and PC/SC smart card readers the moment they are plugged in or unplugged, without requiring manual app refresh.
- **Port Locking & Resource Arbitration**: Ensure serial COM ports and WinSCard contexts are cleanly opened, shared, and closed with proper `DTR=true` and `RTS=true` flow control, preventing `Access Denied` or device deadlock errors.
- **Auto-Recovery on Disconnect**: If a USB modem is accidentally disconnected during runtime, gracefully transition the connection state, notify the UI, and automatically reconnect once re-attached.

### 2. Live SIM SMS & Network Response Message Parsing Engine
- **Direct & Live Message Display**: When performing any recharge or USSD operation, the app MUST capture, decode, and immediately display the raw network response and confirmation SMS in an interactive, seller-friendly window.
- **16-bit Hex UCS2 Arabic Decoder**: Support 100% accurate decoding of UCS2 hexadecimal string payloads sent by Algerian cellular networks (`062A0645...` -> Arabic text), ensuring all Arabic characters render cleanly without garbage characters.
- **Intelligent Transaction Metadata Extraction**: Parse incoming confirmation SMS and USSD responses to automatically extract:
  - Transaction Reference Number (e.g., `Numéro de transaction`, `المرجع`)
  - Transferred Amount
  - New SIM Commercial Balance (e.g., `Nouveau Solde`, `الرصيد المتبقي`)
  - Exact timestamp and operator service fee (if any).

### 3. Dynamic Operator Profile & Web-Assisted Syntax Engine
- **No Hardcoded Operator Assumptions**: Ensure all USSD and SMS syntax rules are dynamically resolved from `OperatorProfile` templates stored in SQLite.
- **Algerian Operator Specifics**:
  - **Mobilis**: Commercial POS syntax `*630*{phone}*04*{amount}*{pin}#`, Account code `04`, default PIN `11111`, Solde check `*632*01*11111#` / `*600#`.
  - **Djezzy**: Flexy POS syntax `*770*{phone}*{amount}*{pin}#`, default PIN `00000`, Solde check `*710#`.
  - **Ooredoo**: Storm POS syntax `*580*{phone}*{amount}*{pin}#`, default PIN `0000`, Solde check `*585*0000#`.
- **Dynamic Syntax Updater / Remote Sync**: Implement an online / fallback operator template synchronization mechanism (with a fallback JSON remote configuration endpoint or built-in updater) so if Algerian operators alter their USSD codes, the system automatically suggests or applies updated templates without requiring binary re-compilation.
- **Multi-Stage Interactive Menu Parser**: Convert dynamic multi-line network prompts into clickable option buttons (e.g. `1: Confirmer`, `2: Annuler`, `١: تأكيد`) with support for numeric and text user inputs.

### 4. Vendor Transaction Guard & Anti-Double-Deduction
- **45-Second Duplicate Protection**: Strictly enforce blocking of identical recharge attempts (same phone + same amount) within 45 seconds.
- **Fail-Safe UNKNOWN State Handling**: If a network timeout or serial buffer disruption occurs, the transaction MUST be flagged as `UNKNOWN` (`غير مؤكدة`) and NEVER marked as failed blindly, preventing vendors from mistakenly double-charging customer numbers.

### 5. Hardware Diagnostic & Real-Time AT Terminal
- Ensure the **Hardware Diagnostic Tool** performs safe, read-only hardware inspection (`AT`, `ATE0`, `AT+CPIN?`, `AT+CSQ`, `AT+CREG?`, `AT+COPS?`, `AT+CMGF=?`, `AT+CUSD=?`) without sending sensitive recharge USSDs.
- Verify that `[ Export Diagnostic Report ]` properly produces clean `.json` and formatted `.txt` report files.

### 6. ESC/POS Thermal Receipt Printer Service
- Ensure 80mm and 58mm thermal receipt printing formats include official **VAST SOLUTIONS DZ** watermark, verification QR code, transaction metadata, and clean monospace table alignments.

---

## 🔬 QUALITY GATES & VERIFICATION PROTOCOL

Execute these verification gates sequentially:
1. **Static Analysis**: Run `flutter analyze` and resolve ALL warnings, errors, and deprecated API usages (Target: 0 issues).
2. **Exhaustive Automated Tests**:
   - Write and expand unit, widget, and integration tests for all new/modified services.
   - Cover edge cases: SIM busy (`+CME ERROR: 14`), SIM PIN locked, network unregistered (`+CREG: 0,2`), timeout during USSD reply, rapid double-click debounce.
   - Run `flutter test` and ensure 100% of tests pass cleanly (minimum 90+ comprehensive tests).
3. **Multi-Platform Build Verification**:
   - Ensure the app builds without errors across Windows, macOS, and Linux targets.
4. **Git Commit & Pull Request**:
   - Commit all changes with clear Conventional Commits messages (`feat:`, `fix:`, `refactor:`, `test:`).
   - Create a clean Pull Request on GitHub detailing all improvements, architecture decisions, and verification results.
```
