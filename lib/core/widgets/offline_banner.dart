import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_providers.dart';
import '../theme/app_theme.dart';

/// Slim amber-on-dark banner that appears when [isOnlineProvider] emits false.
/// Animates in/out smoothly on connectivity changes.
///
/// Intended to be placed as [Scaffold.bottomNavigationBar] wrapper or inside
/// a [Column] just above the bottom navigation bar.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final isOffline = onlineAsync.valueOrNull == false;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: isOffline ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isOffline ? 1.0 : 0.0,
        child: ColoredBox(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 14,
                  color: AppTheme.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline — data saved locally',
                  style: TextStyle(
                    color: AppTheme.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a [child] widget in a [Column] that adds [OfflineBanner] below.
/// Use this to inject the banner above the bottom navigation bar.
class OfflineBannerScaffold extends StatelessWidget {
  const OfflineBannerScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [child, const OfflineBanner()],
    );
  }
}
