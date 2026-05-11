enum ConnectionType {
  spice,
  vnc,
  unknown;

  factory ConnectionType.fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'spice':
        return ConnectionType.spice;
      case 'vnc':
        return ConnectionType.vnc;
      default:
        return ConnectionType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectionType.spice:
        return 'SPICE';
      case ConnectionType.vnc:
        return 'VNC';
      case ConnectionType.unknown:
        return 'Unknown';
    }
  }
}
