import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_schedule.dart';

/// Wraps every Firestore call the app needs for the WorkoutSchedule
/// collection, so no screen or provider ever calls FirebaseFirestore.instance
/// directly. Mirrors the WorkoutLogService pattern.
class WorkoutScheduleService {
  final CollectionReference<Map<String, dynamic>> _schedules = FirebaseFirestore
      .instance
      .collection('WorkoutSchedule');

  /// READ (select all, filtered by user) - a live stream, soonest first.
  /// The single query the Calendar screen (grid + Upcoming list) and the
  /// Home screen's "Today's Workout" card all read from.
  Stream<List<WorkoutSchedule>> streamSchedules(String userId) {
    return _schedules
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkoutSchedule.fromDoc).toList());
  }

  /// CREATE - Firestore auto-generates the document ID, same as WorkoutLog.
  Future<void> addSchedule(WorkoutSchedule schedule) {
    return _schedules.add(schedule.toMap());
  }

  /// DELETE - lets the user cancel a scheduled workout from the Calendar
  /// screen's Upcoming Workouts list.
  Future<void> deleteSchedule(String scheduleId) {
    return _schedules.doc(scheduleId).delete();
  }
}
