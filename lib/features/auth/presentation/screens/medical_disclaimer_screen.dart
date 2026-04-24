import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/pin_repository.dart';

/// One-time medical disclaimer screen shown on first app launch after GDPR
/// consent. The acknowledgement is persisted in flutter_secure_storage so it
/// is only presented once per device.
class MedicalDisclaimerScreen extends ConsumerWidget {
  const MedicalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> acknowledge() async {
      await ref.read(pinRepositoryProvider).markMedicalDisclaimerSeen();
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

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.amber.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.medical_information_outlined,
                    size: 40,
                    color: AppTheme.amber,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                l10n.medicalDisclaimerTitle,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Intro
              Text(
                l10n.medicalDisclaimerIntro,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurface,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Bullet points
              _DisclaimerItem(
                icon: Icons.warning_amber_outlined,
                text: l10n.medicalDisclaimerBullet1,
              ),
              const SizedBox(height: 12),
              _DisclaimerItem(
                icon: Icons.person_search_outlined,
                text: l10n.medicalDisclaimerBullet2,
              ),
              const SizedBox(height: 12),
              _DisclaimerItem(
                icon: Icons.gavel_outlined,
                text: l10n.medicalDisclaimerBullet3,
              ),
              const SizedBox(height: 12),
              _DisclaimerItem(
                icon: Icons.emergency_outlined,
                text: l10n.medicalDisclaimerBullet4,
              ),

              const SizedBox(height: 24),

              // Fine print
              Text(
                l10n.medicalDisclaimerFinePrint,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const Spacer(),

              // CTA
              FilledButton(
                onPressed: acknowledge,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  l10n.medicalDisclaimerAcceptButton,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem({required this.icon, required this.text});
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
