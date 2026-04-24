import '../domain/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<List<Reminder>> getActive();
  Future<List<Reminder>> getByPeptide(int peptideId);
  Future<Reminder?> getById(int id);
  Future<int> save(Reminder reminder);
  Future<void> delete(int id);
  Stream<List<Reminder>> watchAll();
}
