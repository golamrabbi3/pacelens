class ArDepthCapability {
  const ArDepthCapability({
    required this.supported,
    required this.reason,
    required this.platform,
  });

  final bool supported;
  final String reason;
  final String platform;

  factory ArDepthCapability.fromMap(Map<Object?, Object?> map) {
    return ArDepthCapability(
      supported: map['supported'] == true,
      reason: map['reason']?.toString() ?? 'AR depth support is unknown.',
      platform: map['platform']?.toString() ?? 'unknown',
    );
  }
}
