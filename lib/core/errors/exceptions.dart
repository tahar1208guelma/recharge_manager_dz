class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}

class UsbReaderException implements Exception {
  final String message;
  final String? readerName;
  UsbReaderException(this.message, {this.readerName});
  @override
  String toString() => 'UsbReaderException: $message ($readerName)';
}

class SmartCardException implements Exception {
  final String message;
  final String? swCode;
  SmartCardException(this.message, {this.swCode});
  @override
  String toString() => 'SmartCardException: $message (SW: $swCode)';
}

class OperatorException implements Exception {
  final String message;
  final String operatorId;
  final String? errorCode;
  OperatorException(this.message, {required this.operatorId, this.errorCode});
  @override
  String toString() => 'OperatorException [$operatorId]: $message (Code: $errorCode)';
}

class LicenseException implements Exception {
  final String message;
  final String? code;
  LicenseException(this.message, {this.code});
  @override
  String toString() => 'LicenseException: $message (Code: $code)';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
