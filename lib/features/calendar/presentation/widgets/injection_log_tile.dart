import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../injection_log/domain/injection_log.dart';
import '../../../peptides/domain/peptide.dart';

/// A single row representing one injection log in the day detail view.
class InjectionLogTile extends StatelessWidget {
  const InjectionLogTile({super.key, required this.log, required this.peptide});

  final InjectionLog log;

  /// May be null if the peptide was deleted.
  final Peptide? peptide;

  @override
  Widget build(BuildContext context) {
    final color = peptide != null ? _parseHex(peptide!.color) : AppTheme.amber;
    final name = peptide?.name ?? 'Unknown peptide';
    final time = DateFormat.jm().format(log.loggedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.onBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.doseMg} mg · ${log.route}',
                  style: TextStyle(
                    color: AppTheme.onSurface.withAlpha(179),
                    fontSize: 13,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.notes!,
                    style: TextStyle(
                      color: AppTheme.onSurface.withAlpha(128),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: AppTheme.onSurface.withAlpha(153),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    }
    return AppTheme.amber;
  }
}
