class ChargingVerificationResult {
  const ChargingVerificationResult({
    required this.success,
    required this.sessionId,
    required this.message,
  });

  final bool success;
  final int? sessionId;
  final String message;

  factory ChargingVerificationResult.fromJson(Map<String, dynamic> json) {
    return ChargingVerificationResult(
      success: json['success'] == true,
      sessionId: _asIntOrNull(json['session_id'] ?? json['sessionId']),
      message: (json['message'] ?? '').toString(),
    );
  }

  static int? _asIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
