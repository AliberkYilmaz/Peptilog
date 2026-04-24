import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/reminder.dart';
import 'reminder_repository.dart';

class IsarReminderRepository implements ReminderRepository {
  final Isar _isar;
  const IsarReminderRepository(this._isar);

  @override
  Future<List<Reminder>> getAll() => _isar.reminders.where().findAll();

  @override
  Future<List<Reminder>> getActive() =>
      _isar.reminders.filter().isActiveEqualTo(true).findAll();

  @override
  Future<List<Reminder>> getByPeptide(int peptideId) =>
      _isar.reminders.filter().peptideIdEqualTo(peptideId).findAll();

  @override
  Future<Reminder?> getById(int id) => _isar.reminders.get(id);

  @override
  Future<int> save(Reminder reminder) =>
      _isar.writeTxn(() => _isar.reminders.put(reminder));

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.reminders.delete(id));
  }

  @override
  Stream<List<Reminder>> watchAll() =>
      _isar.reminders.where().watch(fireImmediately: true);
}

final reminderRepositoryProvider =
    FutureProvider<ReminderRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarReminderRepository(isar);
});
