import 'package:isar/isar.dart';

import '../domain/reminder.dart';
import 'reminder_repository.dart';

class IsarReminderRepository implements ReminderRepository {
  final Isar _isar;
  final void Function()? _onMutated;
  final String? Function()? _getCurrentUserId;

  const IsarReminderRepository(
    this._isar, {
    void Function()? onMutated,
    String? Function()? getCurrentUserId,
  })  : _onMutated = onMutated,
        _getCurrentUserId = getCurrentUserId;

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
  Future<int> save(Reminder reminder) async {
    reminder.userId ??= _getCurrentUserId?.call();
    final result =
        await _isar.writeTxn(() => _isar.reminders.put(reminder));
    _onMutated?.call();
    return result;
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.reminders.delete(id));
    _onMutated?.call();
  }

  @override
  Stream<List<Reminder>> watchAll() =>
      _isar.reminders.where().watch(fireImmediately: true);
}
