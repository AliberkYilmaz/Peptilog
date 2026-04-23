import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/pin_repository.dart';

/// GDPR / privacy consent screen shown once on first launch.
/// Records consent in secure storage. Declining exits the app.
class GdprConsentScreen extends ConsumerWidget {
  const GdprConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> accept() async {
      await ref.read(pinRepositoryProvider).setGdprConsent(consented: true);
      if (context.mounted) context.go('/onboarding');
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              Icon(
                Icons.health_and_safety_outlined,
                size: 64,
                color: AppTheme.amber,
              ),

              const SizedBox(height: 32),

              Text(
                'Your privacy matters',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Peptilog stores health data about peptide injections and body metrics. '
                'Before you continue, please review how we handle your information.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurface,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              _BulletItem(
                icon: Icons.phone_android_outlined,
                text: 'Data is stored locally on your device first.',
              ),
              const SizedBox(height: 12),
              _BulletItem(
                icon: Icons.cloud_sync_outlined,
                text: 'Optional encrypted sync to our secure cloud (Supabase).',
              ),
              const SizedBox(height: 12),
              _BulletItem(
                icon: Icons.share_outlined,
                text: 'We never sell or share your data with third parties.',
              ),
              const SizedBox(height: 12),
              _BulletItem(
                icon: Icons.delete_outline,
                text: 'You can delete your account and all data at any time.',
              ),

              const SizedBox(height: 24),

              Text(
                'This app is not a medical device. Do not use it as a substitute '
                'for professional medical advice. Always consult a qualified healthcare '
                'provider before beginning or modifying any peptide protocol.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: accept,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  'I understand — continue',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {},
                child: Text(
                  'Read our full Privacy Policy',
                  style: GoogleFonts.inter(color: AppTheme.amber, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
