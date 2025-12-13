import 'dart:math';

class GUIDGen {
  static final _random = Random();

  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return '${timestamp}_$random';
  }
}

