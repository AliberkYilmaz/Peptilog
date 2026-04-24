import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/data/pin_repository.dart';
import '../../features/auth/presentation/providers/pin_notifier.dart';
import '../../features/auth/presentation/screens/gdpr_consent_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/auth/presentation/screens/pin_setup_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/calculator/calculator_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

/// A [ChangeNotifier] that invalidates the router whenever auth state changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<dynamic>>(
      authStateChangesProvider,
      (_, next) => notifyListeners(),
    );
    _ref.listen<bool>(pinVerifiedProvider, (_, next) => notifyListeners());
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

/// Top-level router. Uses a redirect to implement the auth gate:
///
/// First launch flow:
///   → /gdpr (consent) → /onboarding → /auth/sign-in
///
/// Returning user flow:
///   → /auth/sign-in  (not authenticated)
///   → /auth/pin-setup (authenticated, no PIN set)
///   → /auth/pin-entry (authenticated, PIN set, not yet verified this session)
///   → /dashboard (authenticated + PIN verified)
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      // Let the splash through — it triggers the first redirect cycle.
      if (loc == '/splash') return null;

      final pinRepo = ref.read(pinRepositoryProvider);
      final authAsync = ref.read(authStateChangesProvider);

      // --- GDPR ---
      final hasConsent = await pinRepo.hasGdprConsent();
      if (!hasConsent) {
        return loc == '/gdpr' ? null : '/gdpr';
      }

      // --- Onboarding ---
      final seenOnboarding = await pinRepo.hasSeenOnboarding();
      if (!seenOnboarding) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // --- Auth state ---
      final user = authAsync.valueOrNull;
      final isAuthRoute = loc.startsWith('/auth/');

      if (user == null) {
        // Not signed in — send to sign-in (unless already there).
        return isAuthRoute ? null : '/auth/sign-in';
      }

      // Signed in — don't let them revisit auth screens.
      if (isAuthRoute) {
        final pinSet = await pinRepo.isPinSet();
        return pinSet ? '/auth/pin-entry' : '/auth/pin-setup';
      }

      // --- PIN gate ---
      final pinVerified = ref.read(pinVerifiedProvider);
      if (!pinVerified) {
        final pinSet = await pinRepo.isPinSet();
        if (pinSet) {
          return loc == '/auth/pin-entry' ? null : '/auth/pin-entry';
        } else {
          return loc == '/auth/pin-setup' ? null : '/auth/pin-setup';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/gdpr',
        builder: (context, state) => const GdprConsentScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/pin-setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/auth/pin-entry',
        builder: (context, state) => const PinEntryScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/quick-log',
        builder: (context, state) => const DashboardScreen(initialTab: 1),
      ),
      // Deep-link from notification tap → opens the Quick Log tab.
      GoRoute(
        path: '/log/new',
        builder: (context, state) => const DashboardScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
      // Health tab deep-links
      GoRoute(
        path: '/health',
        builder: (context, state) => const DashboardScreen(initialTab: 3),
      ),
      GoRoute(
        path: '/health/sleep',
        builder: (context, state) =>
            const DashboardScreen(initialTab: 3, initialHealthTab: 0),
      ),
      GoRoute(
        path: '/health/bp',
        builder: (context, state) =>
            const DashboardScreen(initialTab: 3, initialHealthTab: 1),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
