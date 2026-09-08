# AI Agent & Developer Guidelines: Recharge Manager DZ

## 📖 Project Overview
**Recharge Manager DZ** is a professional desktop Point of Sale (POS) application for Algerian telecom retail kiosks. It controls and communicates with **Mobilis**, **Djezzy**, and **Ooredoo** SIM cards through **USB GSM/SIM Modems** (Huawei, ZTE, SIMCom, Quectel) via serial AT commands.

---

## 🏛️ Core Architectural Rules
1. **Hardware Abstraction Layer (HAL)**:
   - Always distinguish between **PC/SC Smart Card Readers** (file reading only, ISO 7816-4 APDU) vs **GSM Modems** (serial AT commands with `DTR=true` & `RTS=true`).
   - All modem communication passes through `IModemDriver` (`lib/modem/drivers/`).
2. **Operator Profiles**:
   - **Mobilis**: Commercial account code `04`, PIN `11111`, template `*630*{phone}*04*{amount}*{pin}#`.
   - **Djezzy**: Flexy syntax, PIN `00000`, template `*770*{phone}*{amount}*{pin}#`.
   - **Ooredoo**: Storm syntax, PIN `0000`, template `*580*{phone}*{amount}*{pin}#`.
   - Never hardcode operator conditions; always use `OperatorProfile` and `OperatorRepository`.
3. **Transaction Guard**:
   - Blocks duplicate transactions for same phone + same amount within 45 seconds.
   - Network timeout transitions to `UNKNOWN` (`PosTransactionStatus.unknown`) to prevent accidental double deduction from SIM.
4. **USSD Menu Engine**:
   - Parses multi-lingual prompts (Arabic, French, English) into structured `MenuOption`s.
   - Decodes 16-bit Hex UCS2 strings into Arabic.
5. **Hardware Diagnostic Tool**:
   - Read-only safe inspection (`AT`, `ATE0`, `AT+CPIN?`, `AT+CSQ`, `AT+CREG?`, `AT+COPS?`, `AT+CMGF=?`, `AT+CUSD=?`). Never sends sensitive or recharge USSD commands during diagnostics.

---

## 🧪 Testing & Verification Commands
Before submitting any Pull Request:
```bash
# 1. Verify code formatting and linting
flutter analyze

# 2. Run all 86 unit and integration tests
flutter test
```
