import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_schedule.dart';
import '../services/workout_schedule_service.dart';
import 'auth_provider.dart';

final workoutScheduleServiceProvider = Provider<WorkoutScheduleService>(
  (ref) => WorkoutScheduleService(),
);

/// Live stream of the signed-in user's WorkoutSchedule entries, soonest
/// first.
///
/// This is where planned workouts come from everywhere - the Calendar
/// screen's grid + "Upcoming Workouts" list, and Home's "Today's Workout"
/// card. Emits an empty list if nobody's signed in.
final workoutScheduleProvider = StreamProvider<List<WorkoutSchedule>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <WorkoutSchedule>[]);
  return ref.watch(workoutScheduleServiceProvider).streamSchedules(user.uid);
});

/// All the schedules that fall on one calendar day.
List<WorkoutSchedule> schedulesOn(
  List<WorkoutSchedule> schedules,
  DateTime day,
) {
  return schedules
      .where(
        (s) =>
            s.scheduledDate.year == day.year &&
            s.scheduledDate.month == day.month &&
            s.scheduledDate.day == day.day,
      )
      .toList();
}

/// Everything still Scheduled for today or later, soonest first.
List<WorkoutSchedule> upcoming(List<WorkoutSchedule> schedules) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final list = schedules
      .where((s) => s.status == 'Scheduled' && !s.scheduledDate.isBefore(todayOnly))
      .toList();
  list.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  return list;
}
