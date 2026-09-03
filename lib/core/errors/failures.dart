abstract class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class UsbReaderFailure extends Failure {
  const UsbReaderFailure(super.message, {super.code});
}

class SmartCardFailure extends Failure {
  const SmartCardFailure(super.message, {super.code});
}

class OperatorFailure extends Failure {
  final String operatorId;
  const OperatorFailure(super.message, {required this.operatorId, super.code});
}

class LicenseFailure extends Failure {
  const LicenseFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}
