class OperatorInfo {
  final String id;
  final String name;
  final String fullName;
  final String mnc;
  final List<String> prefixes;
  final bool isConnected;
  final String? endpoint;

  const OperatorInfo({
    required this.id,
    required this.name,
    required this.fullName,
    required this.mnc,
    required this.prefixes,
    this.isConnected = true,
    this.endpoint,
  });
}
