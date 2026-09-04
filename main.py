# -*- coding: utf-8 -*-
"""
================================================================================
          RECHARGE MANAGER DZ - Interactive USSD Terminal Engine
================================================================================
السكربت التفاعلي الشامل لجميع شبكات الاتصالات الجزائرية:
- Mobilis (تعبئة مباشرة ببطاقة الشحن *111* + Arseli بالقوائم الفرعية + Flexy)
- Ooredoo (تعبئة مباشرة 222 + Flexy بالتفعيل والقوائم الفرعية)
- Djezzy (تعبئة مباشرة *700* + Flexy بالتفعيل والقوائم الفرعية)
================================================================================
"""

import os
import sys

# ============================================================
# 1. قاعدة البيانات: تحتوي على الأكواد والقوائم الفرعية
# ============================================================
OPERATORS = {
    "1": {
        "name": "Mobilis",
        "recharge_direct": {
            "desc": "تعبئة الرصيد (بطاقة شحن)",
            "code": "*111*{card_code}#",
            "fields": ["card_code"],
            "prompts": {"card_code": "💳 أدخل رمز البطاقة (14 رقم): "}
        },
        "services": {
            "1": {
                "desc": "📞 Arseli مع التفعيل",
                "base_code": "*696*{sub_option}*{receiver}*{amount}*{pin}#",
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
                    "pin": "🔑 أدخل الرمز السري (PIN): "
                }
            },
            "2": {
                "desc": "💳 تحويل رصيد Flexy",
                "base_code": "*630*{receiver}*{amount}*{pin}#",
                "fields": ["receiver", "amount", "pin"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): ",
                    "pin": "🔑 أدخل الرمز السري (PIN): "
                }
            },
            "3": {
                "desc": "📊 معرفة الرصيد",
                "base_code": "*632*01*{pin}#",
                "fields": ["pin"],
                "prompts": {"pin": "🔑 أدخل الرمز السري (PIN): "}
            }
        }
    },
    "2": {
        "name": "Ooredoo",
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
                "base_code": "*585*{sub_option}*{receiver}#",
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
                    "pin": "🔑 أدخل الرمز السري (PIN): "
                }
            },
            "3": {
                "desc": "📊 معرفة الرصيد",
                "base_code": "*570*{pin}#",
                "fields": ["pin"],
                "prompts": {"pin": "🔑 أدخل الرمز السري (PIN): "}
            }
        }
    },
    "3": {
        "name": "Djezzy",
        "recharge_direct": {
            "desc": "تعبئة الرصيد (بطاقة شحن)",
            "code": "*700*{card_code}#",
            "fields": ["card_code"],
            "prompts": {"card_code": "💳 أدخل رمز البطاقة (الرقم التسلسلي): "}
        },
        "services": {
            "1": {
                "desc": "📞 Flexy مع التفعيل (تفعيل حساب Flexy)",
                "base_code": "*770*{sub_option}*{receiver}*{amount}*00000#",
                "fields": ["receiver", "amount"],
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
                    "amount": "💰 أدخل المبلغ (دج): "
                }
            },
            "2": {
                "desc": "💳 تحويل رصيد عادي",
                "base_code": "*770*{receiver}*{amount}*00000#",
                "fields": ["receiver", "amount"],
                "prompts": {
                    "receiver": "📞 أدخل رقم المستلم: ",
                    "amount": "💰 أدخل المبلغ (دج): "
                }
            },
            "3": {
                "desc": "📊 معرفة الرصيد",
                "base_code": "*710#",
                "fields": []
            }
        }
    }
}

# ============================================================
# 2. وظائف المساعدة (العرض والتنظيف)
# ============================================================
def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header(title):
    print("=" * 60)
    print(f"   {title}")
    print("=" * 60)

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
# 3. الدالة الرئيسية (البرومبات التفاعلية)
# ============================================================
def main():
    saved_sim_pin = "0000"

    while True:
        clear_screen()
        print_header("📱 برنامج التعبئة الإلكتروني الجزائري (USSD Interactive)")
        print(f"🔑 رمز الـ PIN الحالي للشريحة: [{saved_sim_pin}] (اضغط P لتغييره)")

        # --- عرض المشغلين ---
        print("\n🔹 اختر الشبكة:")
        for key, op in OPERATORS.items():
            print(f"   {key}. {op['name']}")
        print("   P. 🔑 تعيين / تغيير رمز PIN للشريحة")
        print("   0. خروج")

        op_choice = get_input("\n>>> ")
        if op_choice == "0":
            print("👋 وداعاً ...")
            break
        
        if op_choice.upper() == "P":
            clear_screen()
            print_header("🔑 إدارة رمز الـ PIN للشريحة")
            new_pin = get_input("أدخل رمز PIN الجديد (4-8 أرقام): ")
            if len(new_pin) >= 4:
                saved_sim_pin = new_pin
                print(f"✅ تم حفظ رمز PIN بنجاح: {saved_sim_pin}")
            else:
                print("❌ رمز PIN يجب أن يتكون من 4 أرقام على الأقل.")
            input("\n📌 اضغط Enter للمتابعة...")
            continue

        if op_choice not in OPERATORS:
            input("❌ اختيار غير صحيح. اضغط Enter...")
            continue

        operator = OPERATORS[op_choice]
        clear_screen()
        print_header(f"📶 {operator['name']} - القائمة الرئيسية")

        # --- عرض خيارات الشبكة (تعبئة مباشرة + خدمات) ---
        print("\n🔹 اختر نوع العملية:")
        print("   1. 💰 تعبئة رصيد (بطاقة شحن / مباشر)")
        service_index = 2
        for key, svc in operator['services'].items():
            print(f"   {service_index}. {svc['desc']}")
            service_index += 1
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
            
            # معالجة خاصة لـ Ooredoo (طلب 222)
            if recharge['code'] == "222":
                print("\n📌 الإجراء: اطلب الرقم 222، ثم اختر 1، وأدخل رمز البطاقة.")
                print("✅ الكود النهائي: 222 (اتصال مباشر)")
            else:
                try:
                    final_code = recharge['code'].format(**values)
                    print("\n" + "=" * 60)
                    print("✅ كود USSD النهائي (جاهز للتنفيذ والطلب):")
                    print(f"   ➡️  {final_code}")
                    print("=" * 60)
                except Exception as e:
                    print(f"❌ خطأ في التوليد: {e}")
            
            input("\n📌 اضغط Enter للعودة...")
            continue

        # ----- الحالة 2: خدمات أخرى (بما فيها Arseli / Flexy) -----
        try:
            selected_index = int(action_choice) - 2
            services_list = list(operator['services'].keys())
            if selected_index < 0 or selected_index >= len(services_list):
                raise ValueError
            service_key = services_list[selected_index]
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

        # ----- جمع باقي المعاملات (رقم، مبلغ، PIN) -----
        for field in service.get('fields', []):
            if field == 'sub_option':
                continue
            if field == 'pin':
                use_saved = get_input(f"🔑 هل تريد استخدام الـ PIN المحفوظ [{saved_sim_pin}]؟ (Y/N): ", required=False)
                if use_saved.lower() != 'n':
                    values['pin'] = saved_sim_pin
                    continue
            
            prompt = service['prompts'].get(field, f"أدخل {field}: ")
            values[field] = get_input(prompt)

        # ----- توليد الكود النهائي -----
        try:
            final_code = service['base_code'].format(**values)
            print("\n" + "=" * 60)
            print("✅ كود USSD النهائي (جاهز للتنفيذ والطلب):")
            print(f"   ➡️  {final_code}")
            print("=" * 60)
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
