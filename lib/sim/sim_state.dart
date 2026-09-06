enum SimCardStatus {
  absent, // SIM not inserted (+CME ERROR: 10 / SIM not inserted)
  ready, // SIM ready and unlocked (+CPIN: READY)
  pinRequired, // SIM PIN required (+CPIN: SIM PIN)
  pukRequired, // SIM PUK required (+CPIN: SIM PUK)
  blocked, // SIM permanently blocked
  error, // Hardware read error
  unknown, // Not yet checked
}

extension SimCardStatusExtension on SimCardStatus {
  String get displayNameAr {
    switch (this) {
      case SimCardStatus.ready:
        return 'الشريحة جاهزة وغير مقفولة (SIM Ready)';
      case SimCardStatus.pinRequired:
        return 'الشريحة تطلب رمز PIN';
      case SimCardStatus.pukRequired:
        return 'الشريحة مقفولة وتطلب رمز PUK';
      case SimCardStatus.absent:
        return 'لا توجد شريحة مركبة (No SIM)';
      case SimCardStatus.blocked:
        return 'الشريحة محظورة نهائياً (SIM Blocked)';
      case SimCardStatus.error:
        return 'خطأ في قراءة الشريحة (SIM Error)';
      case SimCardStatus.unknown:
        return 'غير محدد (Unknown)';
    }
  }

  bool get isOperational => this == SimCardStatus.ready;
}
