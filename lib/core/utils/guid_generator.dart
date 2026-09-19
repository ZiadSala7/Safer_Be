import 'dart:math';

/// Generates an RFC 4122 compliant version 4 GUID / UUID string.
String generateGuid() {
  final random = Random();
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
    RegExp(r'[xy]'),
    (match) {
      final r = random.nextInt(16);
      final v = match[0] == 'x' ? r : (r & 0x3 | 0x8);
      return v.toRadixString(16);
    },
  );
}
