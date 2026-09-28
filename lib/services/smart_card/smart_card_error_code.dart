enum SmartCardErrorCode {
  none,
  noReader,            // لا يوجد قارئ متصل
  noCard,              // لا توجد شريحة في القارئ
  cardMuted,           // الشريحة صامتة ولا تستجيب للـ ATR
  pinLocked,           // الشريحة مقفلة برمز PIN / PUK
  protocolError,       // خطأ في بروتوكول التخاطب أو نقل أوامر APDU
  unsupportedPlatform, // المنصة الحالية غير مدعومة
}
