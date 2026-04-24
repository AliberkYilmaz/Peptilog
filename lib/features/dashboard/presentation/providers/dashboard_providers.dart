import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The currently active tab index in the dashboard bottom navigation.
///
/// Tab indices:
///   0 — Calendar
///   1 — Log (Quick Log)
///   2 — Weight
///   3 — Health
///   4 — Profile
final selectedTabProvider = StateProvider<int>((ref) => 0);
