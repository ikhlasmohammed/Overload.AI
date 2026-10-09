import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the WorkoutSchedule collection.
///
/// The Calendar screen uses this to mark scheduled/completed/missed days,
/// and to build the "Upcoming Workouts" list on Home and Calendar.
///

class WorkoutSchedule {
  final String scheduleId;
  final String userId;
  final String routineName; // e.g. "Push Day"
  final DateTime scheduledDate;
  final String status; // 'Scheduled' | 'Completed' | 'Missed'

  WorkoutSchedule({
    required this.scheduleId,
    required this.userId,
    required this.routineName,
    required this.scheduledDate,
    this.status = 'Scheduled',
  });

  /// Builds a WorkoutSchedule from a Firestore doc - scheduleId comes from
  /// the document's own ID, same as WorkoutLog.fromDoc.
  factory WorkoutSchedule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WorkoutSchedule(
      scheduleId: doc.id,
      userId: data['userId'] as String,
      routineName: data['routineName'] as String,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'Scheduled',
    );
  }

  /// Converts this schedule into a map for Firestore. No scheduleId field
  /// - it's already the document ID.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'routineName': routineName,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
    };
  }

  WorkoutSchedule copyWith({
    String? routineName,
    DateTime? scheduledDate,
    String? status,
  }) {
    return WorkoutSchedule(
      scheduleId: scheduleId,
      userId: userId,
      routineName: routineName ?? this.routineName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
    );
  }
}

/// Quick helper for display text - which muscle groups a routine name
/// targets. Used by Home's "Today's Workout" card and Calendar's
/// "Upcoming Workouts" list so they show the same wording.
String muscleGroupsForRoutine(String routineName) {
  switch (routineName) {
    case 'Push Day':
      return 'Chest • Shoulders • Triceps';
    case 'Pull Day':
      return 'Back • Biceps';
    case 'Leg Day':
      return 'Quads • Hamstrings • Glutes';
    default:
      return 'Recovery day';
  }
}

/// Same idea as muscleGroupsForRoutine() above, but returns an actual
/// filterable list of ExerciseLibrary.muscleGroups values instead of a
/// display string. Home's "Start Workout" button uses this to pull real
/// exercises for whatever's scheduled today. Keep the routine names in
/// sync with the function above.
List<String> routineMuscleGroups(String routineName) {
  switch (routineName) {
    case 'Push Day':
      return ['Chest', 'Shoulders', 'Arms'];
    case 'Pull Day':
      return ['Back', 'Arms'];
    case 'Leg Day':
      return ['Legs', 'Core'];
    default:
      return [];
  }
}
