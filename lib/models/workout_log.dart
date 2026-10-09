import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the WorkoutLog collection.
class WorkoutLog {
  final String logId;
  final String userId;
  final String exerciseName;
  final String muscleGroup;
  final double weight; // in kg
  final int reps;
  final int sets;
  final DateTime loggedAt;

  WorkoutLog({
    required this.logId,
    required this.userId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.loggedAt,
  });

  /// Builds a WorkoutLog from a Firestore doc. logId comes from the
  /// document's own ID, not a field in the data.
  factory WorkoutLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WorkoutLog(
      logId: doc.id,
      userId: data['userId'] as String,
      exerciseName: data['exerciseName'] as String,
      muscleGroup: data['muscleGroup'] as String,
      weight: (data['weight'] as num).toDouble(),
      reps: data['reps'] as int,
      sets: data['sets'] as int,
      loggedAt: (data['loggedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this log into a map Firestore can write. logId is left out
  /// on purpose since it's already the document ID.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  /// Returns a copy of this log with some fields replaced.
  WorkoutLog copyWith({
    String? exerciseName,
    String? muscleGroup,
    double? weight,
    int? reps,
    int? sets,
  }) {
    return WorkoutLog(
      logId: logId,
      userId: userId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      loggedAt: loggedAt,
    );
  }
}
