# Recharge Manager DZ (مدير التعبئة الجزائر) 🇩🇿
### Professional Algerian Telecom POS & SIM Modem Management System
**Developed by VAST SOLUTIONS DZ**

---

## 📋 Overview / نظرة عامة
**Recharge Manager DZ** is a specialized, production-grade Windows Point of Sale (POS) application designed specifically for telecom kiosks, mobile shops, and retail stores in Algeria. It controls and communicates with **Mobilis**, **Djezzy**, and **Ooredoo** SIM cards installed inside **USB GSM / SIM Modems** (Huawei, ZTE, SIMCom, Quectel) directly from the PC.

The software strictly replicates real physical SIM/phone behavior over serial AT commands without inventing fake codes or bypassing telecom operator security systems.

---

## 🚀 Key Features / الميزات الرئيسية

### 1. 🔌 Hardware Abstraction Layer (HAL)
- **Automatic Device Classification**: Strictly distinguishes between **PC/SC Smart Card Readers** (file reading only, no network) vs **USB GSM/SIM Modems** (cellular network & AT serial interface).
- **OEM Vendor Drivers**: Specialized drivers for Huawei (E3531, E173, E303), ZTE (MF190, MF823, MF833), SIMCom (SIM800/900/7600), and Quectel (EC20/EC25), plus a universal 3GPP TS 27.007 Generic AT Driver.
- **Hardware Flow Control**: Enforces `DTR = true` and `RTS = true` to eliminate buffer deadlocks on USB modems.
- **Automatic COM Port Detection & Auto-Baud**: Scans Windows WMI and Registry to probe standard baud rates (115200, 57600, 38400, 9600).

### 2. 📱 Operator Profiles & USSD Engine
- **Configurable Templates**: Fully dynamic operator profiles stored in database (no hardcoded operator logic).
  - **Mobilis**: Uses commercial account code `04` (`*630*{phone}*04*{amount}*{pin}#`), Default PIN `11111`.
  - **Djezzy**: Flexy syntax (`*770*{phone}*{amount}*{pin}#`), Default PIN `00000`.
  - **Ooredoo**: Storm syntax (`*580*{phone}*{amount}*{pin}#`), Default PIN `0000`.
- **Dynamic USSD Menu Parser**: Multi-stage regex and semantic engine converting raw multi-lingual prompt texts (Arabic, French, English) and UCS2 Hex strings into clickable interactive buttons.
- **Full UCS2 Hex Decoding**: Seamless decoding of 16-bit Hex UCS2 strings sent by Algerian telecom networks for crystal-clear Arabic display.

### 3. 🛡️ Transaction Guard & Vendor Protection
- **Anti-Duplicate Safety**: Automatically blocks identical transactions (same phone + same amount within 45 seconds) to prevent accidental double-charging from the vendor's SIM balance.
- **Fail-Safe Timeout Handling**: If network connection drops or times out during processing, transactions are marked **`UNKNOWN`** (غير مؤكدة) rather than failed, alerting the vendor to verify SIM balance before retrying.

### 4. ✉️ SIM SMS Management Center
- Text Mode (`AT+CMGF=1`) and PDU support.
- List, read, compose, send, and delete messages on SIM card.
- Live `+CMTI` unsolicited notification listener for instant incoming delivery notifications.

### 5. 💻 Real-Time AT Debug Terminal
- Live command/response stream (`TX →` and `RX ←`) with millisecond execution latency timing.
- **Strict Security Sanitization**: Automatic masking of sensitive secrets (`AT+CPIN="****"`, PIN codes in USSD strings).

### 6. 🖨️ Thermal Receipt Printing
- ESC/POS monospace formatting for standard **80mm** Desktop POS and **58mm** Compact Mobile thermal printers.
- Official branding with **VAST SOLUTIONS DZ** header/footer, store details, transaction metadata, and verification QR code.

---

## 🏗️ Architecture / المعمارية البرمجية

```
lib/
├── core/                   # Design system, Colors, Utils, Localization (AR, FR, EN)
├── data/                   # SQLite (8 tables), Local & Remote Data Sources
├── debug/                  # AT Debug Logger & PIN Sanitizer
├── domain/                 # Domain Entities & Use Cases
├── modem/
│   ├── drivers/            # Huawei, ZTE, SIMCom, Quectel, GenericAT, MockDriver
│   ├── models/             # AtCommand, AtResponse, SerialPortInfo, UnsolicitedResponse
│   ├── hardware_detector.dart
│   └── modem_service.dart
├── network/                # Network registration (AT+CREG), Signal (AT+CSQ), Operator (AT+COPS)
├── operators/              # OperatorProfile, DefaultProfiles, OperatorRepository
├── presentation/
│   ├── providers/          # ModemProvider, AppStateProvider, RechargeProvider, etc.
│   ├── screens/            # Dashboard, Recharge, SMS Inbox, Debug Console, Settings
│   └── widgets/            # DynamicUssdMenuDialog, Sidebar, TopStatusBar, ReceiptPreview
├── printer/                # Thermal Receipt Printer Service (80mm / 58mm)
├── sim/                    # SimCardInfo, SimService, CPIN/IMSI/ICCID
├── sms/                    # SmsMessage, SmsService
├── transactions/           # PosTransaction, TransactionManager, TransactionGuard
└── ussd/                   # MenuParser, SessionEngine, UssdService, UssdResponse
```

---

## 🧪 Testing & Quality Assurance / الاختبارات

The project features a comprehensive test suite of 82 unit, widget, and integration tests:

```bash
# Run full test suite
flutter test --no-pub

# Run code analysis
flutter analyze --no-pub
```

### Test Coverage Highlights:
- `test/unit/menu_parser_test.dart`: Multi-language dynamic menu options parsing (Arabic numbers, French delimiters, inline prompts).
- `test/unit/transaction_manager_test.dart`: Duplicate transaction blocking, timeout UNKNOWN state transitions.
- `test/unit/modem_drivers_test.dart`: Driver lifecycle, AT ping, CPIN status, signal RSSI, USSD simulation.
- `test/integration/full_pos_flow_test.dart`: End-to-end flow from modem connect -> SIM check -> Network registration -> USSD menu negotiation -> Click choice -> Success confirmation -> DB storage -> Thermal receipt output.

---

## 📦 Building for Windows / بناء البرنامج للويندوز

```bash
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Build release executable
flutter build windows --release
```

The output executable and support binaries will be generated in:
`build/windows/x64/runner/Release/`

---

## 📄 License & Intellectual Property
Copyright © 2026 **VAST SOLUTIONS DZ**. All rights reserved.
Developed for professional telecom retail points of sale across Algeria.
