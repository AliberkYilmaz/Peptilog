import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../injection_log/domain/injection_log.dart';
import '../../../injection_log/presentation/providers/quick_log_notifier.dart';
import '../../../injection_log/presentation/widgets/injection_form_widgets.dart';
import '../../../injection_log/presentation/widgets/peptide_chip.dart';
import '../../../peptides/domain/peptide.dart';

/// Bottom sheet for editing an existing [InjectionLog].
///
/// Pre-fills all fields from [log]. Save updates Isar (marks isDirty for sync).
/// Delete soft-deletes in Isar and propagates to Supabase on next sync.
class EditInjectionSheet extends ConsumerStatefulWidget {
  const EditInjectionSheet({
    super.key,
    required this.log,
    required this.peptide,
  });

  final InjectionLog log;
  final Peptide? peptide;

  @override
  ConsumerState<EditInjectionSheet> createState() => _EditInjectionSheetState();
}

class _EditInjectionSheetState extends ConsumerState<EditInjectionSheet> {
  late final TextEditingController _doseController;
  late final TextEditingController _notesController;
  final _doseFocus = FocusNode();

  late String _route;
  late DateTime _loggedAt;
  late Peptide? _selectedPeptide;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(
      text: _formatDose(widget.log.doseMg),
    );
    _notesController = TextEditingController(text: widget.log.notes ?? '');
    _route = widget.log.route;
    _loggedAt = widget.log.loggedAt;
    _selectedPeptide = widget.peptide;
  }

  @override
  void dispose() {
    _doseController.dispose();
    _notesController.dispose();
    _doseFocus.dispose();
    super.dispose();
  }

  String _formatDose(double d) {
    if (d == d.truncateToDouble()) return d.toStringAsFixed(0);
    return d.toString();
  }

  Future<void> _save() async {
    if (_selectedPeptide == null) {
      setState(() => _errorMessage = 'selectPeptide');
      return;
    }
    final dose = double.tryParse(_doseController.text);
    if (dose == null || dose <= 0) {
      setState(() => _errorMessage = 'invalidDose');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    widget.log
      ..peptideId = _selectedPeptide!.id
      ..doseMg = dose
      ..route = _route
      ..notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim()
      ..loggedAt = _loggedAt
      ..isDirty = true
      ..updatedAt = DateTime.now();

    await ref.read(injectionLogRepositoryProvider).save(widget.log);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.editInjectionUpdated),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.editInjectionDeleteConfirmTitle,
          style: const TextStyle(color: AppTheme.onBackground),
        ),
        content: Text(
          l10n.editInjectionDeleteConfirmBody,
          style: TextStyle(color: AppTheme.onSurface.withAlpha(179)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.editInjectionCancel,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.editInjectionDelete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    await ref.read(injectionLogRepositoryProvider).softDelete(widget.log.id);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop('deleted');
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.editInjectionDeleted),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final peptidesAsync = ref.watch(activePeptidesProvider);
    final busy = _isSaving || _isDeleting;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.editInjectionTitle,
                      style: const TextStyle(
                        color: AppTheme.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.onSurface,
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.divider, height: 24),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InjectionSectionLabel('Peptide'),
                    const SizedBox(height: 10),
                    _buildPeptideSelector(peptidesAsync),
                    if (_errorMessage == 'selectPeptide') ...[
                      const SizedBox(height: 6),
                      InjectionErrorText('Please select a peptide'),
                    ],

                    const SizedBox(height: 28),
                    InjectionSectionLabel('Dose'),
                    const SizedBox(height: 10),
                    InjectionDoseField(
                      controller: _doseController,
                      focusNode: _doseFocus,
                      onChanged: (_) => setState(() => _errorMessage = null),
                      hasError: _errorMessage == 'invalidDose',
                    ),
                    if (_errorMessage == 'invalidDose') ...[
                      const SizedBox(height: 6),
                      InjectionErrorText(
                        'Enter a valid dose greater than zero',
                      ),
                    ],

                    const SizedBox(height: 28),
                    InjectionSectionLabel('Route'),
                    const SizedBox(height: 10),
                    InjectionRouteToggle(
                      selected: _route,
                      onChanged: (r) => setState(() => _route = r),
                    ),

                    const SizedBox(height: 28),
                    InjectionSectionLabel('Notes'),
                    const SizedBox(height: 10),
                    InjectionNotesField(
                      controller: _notesController,
                      onChanged: (_) {},
                    ),

                    const SizedBox(height: 28),
                    InjectionTimestampRow(
                      loggedAt: _loggedAt,
                      onEdit: (dt) => setState(() => _loggedAt = dt),
                    ),

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: busy ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1A1714),
                                ),
                              )
                            : Text(
                                l10n.editInjectionSave,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: busy ? null : _confirmDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.error,
                                ),
                              )
                            : Text(
                                l10n.editInjectionDelete,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeptideSelector(AsyncValue<List<Peptide>> peptidesAsync) {
    return peptidesAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (peptides) {
        if (peptides.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No active peptides — add one in Profile',
              style: TextStyle(
                color: AppTheme.onSurface.withAlpha(153),
                fontSize: 13,
              ),
            ),
          );
        }
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: peptides.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = peptides[i];
              return PeptideChip(
                peptide: p,
                isSelected: _selectedPeptide?.id == p.id,
                onTap: () => setState(() {
                  _selectedPeptide = p;
                  _errorMessage = null;
                }),
              );
            },
          ),
        );
      },
    );
  }
}
