class ReaderDeviceInfo {
  final String? vendorId; // e.g. "0x072F" (ACS) or "0x076B" (Omnikey)
  final String? productId; // e.g. "0x2200" (ACR38U) or "0x3021" (Omnikey 3021)
  final String? manufacturer; // e.g. "Advanced Card Systems Ltd."
  final String readerName; // e.g. "ACS ACR39U CCID Smart Card Reader 0"
  final String protocol; // "PC/SC", "CCID", "USB_HOST", "T=0 / T=1"
  final String connectionStatus; // "CONNECTED", "DISCONNECTED", "ERROR", "WAITING_CARD"
  final bool isCompatible;
  final String? errorMessage;
  final Map<String, dynamic> rawProperties;

  const ReaderDeviceInfo({
    this.vendorId,
    this.productId,
    this.manufacturer,
    required this.readerName,
    this.protocol = 'PC/SC (CCID)',
    this.connectionStatus = 'CONNECTED',
    this.isCompatible = true,
    this.errorMessage,
    this.rawProperties = const {},
  });

  String get formattedVendorId => vendorId != null ? '0x${vendorId!.replaceAll('0x', '').toUpperCase()}' : 'N/A';
  String get formattedProductId => productId != null ? '0x${productId!.replaceAll('0x', '').toUpperCase()}' : 'N/A';

  ReaderDeviceInfo copyWith({
    String? vendorId,
    String? productId,
    String? manufacturer,
    String? readerName,
    String? protocol,
    String? connectionStatus,
    bool? isCompatible,
    String? errorMessage,
    Map<String, dynamic>? rawProperties,
  }) {
    return ReaderDeviceInfo(
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      manufacturer: manufacturer ?? this.manufacturer,
      readerName: readerName ?? this.readerName,
      protocol: protocol ?? this.protocol,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isCompatible: isCompatible ?? this.isCompatible,
      errorMessage: errorMessage ?? this.errorMessage,
      rawProperties: rawProperties ?? this.rawProperties,
    );
  }
}
