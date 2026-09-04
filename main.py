# -*- coding: utf-8 -*-
"""
================================================================================
          RECHARGE MANAGER DZ - Interactive USSD Terminal Engine (v2.0)
================================================================================
السكربت النهائي المصحح لجميع شبكات الاتصالات الجزائرية:
- Mobilis (إضافة 04 رقم الحساب في Flexy و Arseli + PIN افتراضي 11111)
- Ooredoo (Flexy مع التفعيل + PIN افتراضي 0000)
- Djezzy (Flexy بالقوائم الفرعية + PIN افتراضي 00000)
================================================================================
"""

import os
import sys

# ============================================================
# 1. قاعدة البيانات المصححة (مع الرقم 04 لـ Mobilis)
# ============================================================
OPERATORS = {
    "1": {
        "name": "Mobilis",
        "default_pin": "11111",
        "recharge_direct": {
            "desc": "تعبئة الرصيد (بطاقة شحن)",
            "code": "*111*{card_code}#",
            "fields": ["card_code"],
            "prompts": {"card_code": "💳 أدخل رمز البطاقة (14 رقم): "}
        },
        "services": {
            "1": {
                "desc": "📞 Arseli مع التفعيل",
                "base_code": "*696*1*{receiver}*04*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "sub_menu": {
                    "title": "📋 اختر نوع Arseli:",
                    "options": {
                        "1": "محلي (Local)",
                        "2": "دولي (International)",
                        "3": "استشارة الرصيد"
                    }
                },
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "2": {
                "desc": "💳 تحويل Flexy",
                "base_code": "*630*{receiver}*04*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "3": {
                "desc": "🌍 Arseli دولي / دفع الفاتورة",
                "base_code": "*633*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المشترك/الفاتورة: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "4": {
                "desc": "💸 تحويل الرصيد (Transfert)",
                "base_code": "*631*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "5": {
                "desc": "📊 معرفة الرصيد (Solde)",
                "base_code": "*632*01*{pin}#",
                "fields": ["pin"],
                "prompts": {
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "6": {
                "desc": "📋 قائمة أرقام Flexy",
                "base_code": "*632*03*{pin}#",
                "fields": ["pin"],
                "prompts": {
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "7": {
                "desc": "📋 قائمة التحويلات",
                "base_code": "*631*01*{pin}#",
                "fields": ["pin"],
                "prompts": {
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "8": {
                "desc": "🔑 تغيير الرمز السري (PIN)",
                "base_code": "*632*02*{old_pin}*{new_pin}#",
                "fields": ["old_pin", "new_pin"],
                "prompts": {
                    "old_pin": "🔑 أدخل الرمز السري القديم: ",
                    "new_pin": "🔑 أدخل الرمز السري الجديد: "
                }
            }
        }
    },
    "2": {
        "name": "Ooredoo",
        "default_pin": "0000",
        "recharge_direct": {
            "desc": "تعبئة الرصيد (بطاقة شحن)",
            "code": "222",
            "fields": ["card_code"],
            "prompts": {"card_code": "💳 اطلب 222، ثم اختر 1 وأدخل رمز البطاقة: "},
            "note": "⚠️ هذه خدمة تفاعلية (اتصال بصوت)، الكود النهائي سيكون مجرد طلب الاتصال بالرقم 222."
        },
        "services": {
            "1": {
                "desc": "📞 Flexy مع التفعيل",
                "base_code": "*585*{receiver}#",
                "fields": ["receiver"],
                "sub_menu": {
                    "title": "📋 اختر نوع تفعيل Flexy:",
                    "options": {
                        "1": "تفعيل برقم هاتف",
                        "2": "إلغاء التفعيل",
                        "3": "قائمة الأرقام المفعلة"
                    }
                },
                "prompts": {
                    "receiver": "📞 أدخل رقم الهاتف: "
                }
            },
            "2": {
                "desc": "💳 تحويل رصيد Flexy",
                "base_code": "*580*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "3": {
                "desc": "📊 معرفة الرصيد",
                "base_code": "*570*{pin}#",
                "fields": ["pin"],
                "prompts": {
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "4": {
                "desc": "📋 قائمة أرقام Flexy",
                "base_code": "*221*{pin}#",
                "fields": ["pin"],
                "prompts": {
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "5": {
                "desc": "📋 قائمة أرقام Flexy (بدون PIN)",
                "base_code": "*762#",
                "fields": []
            },
            "6": {
                "desc": "💳 تحويل Flexy (بديل)",
                "base_code": "*660*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "7": {
                "desc": "🎁 Flexy مع مكافأة (Bonus)",
                "base_code": "*764*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            }
        }
    },
    "3": {
        "name": "Djezzy",
        "default_pin": "00000",
        "recharge_direct": {
            "desc": "تعبئة الرصيد (بطاقة شحن)",
            "code": "*700*{card_code}#",
            "fields": ["card_code"],
            "prompts": {"card_code": "💳 أدخل رمز البطاقة (الرقم التسلسلي): "}
        },
        "services": {
            "1": {
                "desc": "📞 Flexy مع التفعيل",
                "base_code": "*770*{sub_option}*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "sub_menu": {
                    "title": "📋 اختر خدمة Flexy:",
                    "options": {
                        "1": "تحويل رصيد (إرسال)",
                        "2": "تفعيل رقم Flexy جديد",
                        "3": "قائمة الأرقام المقيدة"
                    }
                },
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "2": {
                "desc": "💳 تحويل رصيد عادي",
                "base_code": "*770*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN الافتراضي: {default_pin}): "
                }
            },
            "3": {
                "desc": "📊 معرفة الرصيد",
                "base_code": "*710#",
                "fields": []
            },
            "4": {
                "desc": "📋 قائمة أرقام Flexy",
                "base_code": "*777#",
                "fields": []
            },
            "5": {
                "desc": "💳 تحويل رصيد (بديل)",
                "base_code": "*770*{receiver}*{amount}*00000#",
                "fields": ["receiver", "amount"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): "
                }
            }
        }
    }
}

# ============================================================
# 2. وظائف المساعدة
# ============================================================
def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header(title):
    print("=" * 65)
    print(f"   {title}")
    print("=" * 65)

def get_input(prompt, required=True):
    while True:
        try:
            val = input(prompt).strip()
        except (KeyboardInterrupt, EOFError):
            print("\n👋 تم الإلغاء.")
            sys.exit(0)
        if val or not required:
            return val
        print("⚠️ هذا الحقل مطلوب، يرجى إدخال قيمة.")

# ============================================================
# 3. الدالة الرئيسية
# ============================================================
def main():
    while True:
        clear_screen()
        print_header("📱 برنامج التعبئة الإلكتروني الجزائري - USSD Engine (المصحح)")

        # --- عرض المشغلين ---
        print("\n🔹 اختر الشبكة:")
        for key, op in OPERATORS.items():
            print(f"   {key}. {op['name']} (PIN الافتراضي: {op['default_pin']})")
        print("   0. خروج")

        op_choice = get_input("\n>>> ")
        if op_choice == "0":
            print("👋 وداعاً ...")
            break
        if op_choice not in OPERATORS:
            input("❌ اختيار غير صحيح. اضغط Enter...")
            continue

        operator = OPERATORS[op_choice]
        default_pin = operator.get("default_pin", "0000")
        clear_screen()
        print_header(f"📶 {operator['name']} - القائمة الرئيسية (PIN: {default_pin})")

        # --- عرض الخيارات ---
        print("\n🔹 اختر نوع العملية:")
        print("   1. 💰 تعبئة رصيد (بطاقة شحن / مباشر)")
        
        service_num = 2
        service_keys = list(operator['services'].keys())
        for key in service_keys:
            print(f"   {service_num}. {operator['services'][key]['desc']}")
            service_num += 1
        
        print("   0. رجوع")

        action_choice = get_input("\n>>> ")
        if action_choice == "0":
            continue

        # ----- الحالة 1: تعبئة مباشرة -----
        if action_choice == "1":
            recharge = operator['recharge_direct']
            clear_screen()
            print_header(f"💳 {operator['name']} - {recharge['desc']}")
            
            values = {}
            for field in recharge.get('fields', []):
                prompt = recharge['prompts'].get(field, f"أدخل {field}: ")
                values[field] = get_input(prompt)
            
            if recharge['code'] == "222":
                print("\n📌 الإجراء: اطلب الرقم 222، ثم اختر 1، وأدخل رمز البطاقة.")
                print("✅ الكود النهائي: 222 (اتصال مباشر)")
            else:
                try:
                    final_code = recharge['code'].format(**values)
                    print("\n" + "=" * 65)
                    print("✅ كود USSD النهائي (انسخه واطلبه):")
                    print(f"   ➡️  {final_code}")
                    print("=" * 65)
                except Exception as e:
                    print(f"❌ خطأ في التوليد: {e}")
            
            input("\n📌 اضغط Enter للعودة...")
            continue

        # ----- الحالة 2: الخدمات -----
        try:
            selected_index = int(action_choice) - 2
            if selected_index < 0 or selected_index >= len(service_keys):
                raise ValueError
            service_key = service_keys[selected_index]
            service = operator['services'][service_key]
        except:
            input("❌ خدمة غير صالحة. اضغط Enter...")
            continue

        clear_screen()
        print_header(f"⚙️ {operator['name']} - {service['desc']}")

        # ----- معالجة القوائم الفرعية (Sub-menus) -----
        values = {}
        if 'sub_menu' in service:
            print(f"\n{service['sub_menu']['title']}")
            for opt_key, opt_desc in service['sub_menu']['options'].items():
                print(f"   {opt_key}. {opt_desc}")
            print("   0. إلغاء")
            
            sub_choice = get_input("\n>>> اختر الخيار: ")
            if sub_choice == "0":
                continue
            if sub_choice not in service['sub_menu']['options']:
                input("❌ خيار غير صحيح. اضغط Enter...")
                continue
            
            values['sub_option'] = sub_choice

        # ----- جمع باقي المعاملات -----
        for field in service.get('fields', []):
            if field == 'sub_option':
                continue
            prompt = service['prompts'].get(field, f"أدخل {field}: ")
            if '{default_pin}' in prompt:
                prompt = prompt.replace('{default_pin}', default_pin)
            
            entered_val = get_input(prompt, required=(field != 'pin'))
            if field == 'pin' and not entered_val:
                entered_val = default_pin
            values[field] = entered_val

        # ----- توليد الكود النهائي -----
        try:
            final_code = service['base_code'].format(**values)
            print("\n" + "=" * 65)
            print("✅ كود USSD النهائي (جاهز للتنفيذ والطلب):")
            print(f"   ➡️  {final_code}")
            if 'pin' in values:
                print(f"\n📌 الرمز السري المستخدم: {values['pin']}")
            print("=" * 65)
        except KeyError as e:
            print(f"❌ خطأ: الحقل {e} غير موجود في المدخلات.")
        except Exception as e:
            print(f"❌ خطأ غير متوقع: {e}")

        input("\n📌 اضغط Enter للعودة إلى القائمة الرئيسية...")


# ============================================================
# 4. تشغيل البرنامج
# ============================================================
if __name__ == "__main__":
    main()
