import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable clock so screens that depend on "today" stay testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
