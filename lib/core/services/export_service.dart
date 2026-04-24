import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/health/domain/blood_pressure_log.dart';
import '../../features/health/domain/sleep_log.dart';
import '../../features/injection_log/domain/injection_log.dart';
import '../../features/peptides/domain/peptide.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/weight/domain/weight_log.dart';
import '../providers/database_providers.dart';

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.watch(isarProvider)),
);

class ExportService {
  ExportService(this._isar);

  final Isar _isar;

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  // ---------------------------------------------------------------------------
  // Export methods
  // ---------------------------------------------------------------------------

  /// Exports all data types as separate CSV files via the system share sheet.
  Future<void> exportAll() async {
    final files = await Future.wait([
      _buildInjectionsCsv(),
      _buildWeightCsv(),
      _buildSleepCsv(),
      _buildBloodPressureCsv(),
    ]);
    await Share.shareXFiles(
      files,
      subject: 'Peptilog Data Export',
      text: 'All Peptilog health data',
    );
  }

  Future<void> exportInjections() async {
    final file = await _buildInjectionsCsv();
    await Share.shareXFiles([file], subject: 'Peptilog Injection Logs');
  }

  Future<void> exportWeight() async {
    final file = await _buildWeightCsv();
    await Share.shareXFiles([file], subject: 'Peptilog Weight Logs');
  }

  Future<void> exportSleep() async {
    final file = await _buildSleepCsv();
    await Share.shareXFiles([file], subject: 'Peptilog Sleep Logs');
  }

  Future<void> exportBloodPressure() async {
    final file = await _buildBloodPressureCsv();
    await Share.shareXFiles([file], subject: 'Peptilog Blood Pressure Logs');
  }

  // ---------------------------------------------------------------------------
  // Account deletion — wipes all local Isar collections
  // ---------------------------------------------------------------------------

  Future<void> deleteAllLocalData() async {
    await _isar.writeTxn(() async {
      await _isar.injectionLogs.clear();
      await _isar.weightLogs.clear();
      await _isar.sleepLogs.clear();
      await _isar.bloodPressureLogs.clear();
      await _isar.reminders.clear();
      await _isar.peptides.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // CSV builders
  // ---------------------------------------------------------------------------

  Future<XFile> _buildInjectionsCsv() async {
    final peptides = await _isar.peptides
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final peptideMap = <int, String>{for (final p in peptides) p.id: p.name};

    final logs = await _isar.injectionLogs
        .filter()
        .isDeletedEqualTo(false)
        .sortByLoggedAt()
        .findAll();

    final rows = <List<dynamic>>[
      ['Date', 'Time', 'Peptide', 'Dose (mg)', 'Units', 'Route', 'Notes'],
      ...logs.map(
        (l) => [
          _dateFormat.format(l.loggedAt),
          DateFormat('HH:mm').format(l.loggedAt),
          peptideMap[l.peptideId] ?? 'Unknown',
          l.doseMg,
          l.units ?? '',
          l.route,
          l.notes ?? '',
        ],
      ),
    ];

    return _writeCsv('peptilog_injections.csv', rows);
  }

  Future<XFile> _buildWeightCsv() async {
    final logs = await _isar.weightLogs
        .filter()
        .isDeletedEqualTo(false)
        .sortByDate()
        .findAll();

    final rows = <List<dynamic>>[
      ['Date', 'Weight (kg)'],
      ...logs.map((l) => [_dateFormat.format(l.date), l.weightKg]),
    ];

    return _writeCsv('peptilog_weight.csv', rows);
  }

  Future<XFile> _buildSleepCsv() async {
    final logs = await _isar.sleepLogs
        .filter()
        .isDeletedEqualTo(false)
        .sortByDate()
        .findAll();

    final rows = <List<dynamic>>[
      ['Date', 'Hours', 'Quality (1–5)'],
      ...logs.map(
        (l) => [_dateFormat.format(l.date), l.hours, l.qualityRating ?? ''],
      ),
    ];

    return _writeCsv('peptilog_sleep.csv', rows);
  }

  Future<XFile> _buildBloodPressureCsv() async {
    final logs = await _isar.bloodPressureLogs
        .filter()
        .isDeletedEqualTo(false)
        .sortByMeasuredAt()
        .findAll();

    final rows = <List<dynamic>>[
      ['Date & Time', 'Systolic', 'Diastolic', 'Pulse'],
      ...logs.map(
        (l) => [
          _dateTimeFormat.format(l.measuredAt),
          l.systolic,
          l.diastolic,
          l.pulse ?? '',
        ],
      ),
    ];

    return _writeCsv('peptilog_blood_pressure.csv', rows);
  }

  Future<XFile> _writeCsv(String filename, List<List<dynamic>> rows) async {
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    return XFile(file.path, mimeType: 'text/csv', name: filename);
  }
}
