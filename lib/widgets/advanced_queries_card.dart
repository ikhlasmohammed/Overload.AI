import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_log_provider.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// "Explore Queries" card for the Analysis tab.
///
/// Each button below fires a genuine Firestore query defined in
/// WorkoutLogService (not a filter/sort on the already-streamed list from
/// workoutLogsProvider) so the app has real, demonstrable examples of:
/// filter on a non-identifier field, multiple filters on the same field,
/// multiple filters on different fields, an explicit sort order, and a
/// server-side count() aggregation.
class AdvancedQueriesCard extends ConsumerStatefulWidget {
  const AdvancedQueriesCard({super.key});

  @override
  ConsumerState<AdvancedQueriesCard> createState() =>
      _AdvancedQueriesCardState();
}

enum _QueryKind {
  muscleGroup,
  weightRange,
  muscleGroupSince,
  heaviest,
  totalCount,
}

class _AdvancedQueriesCardState extends ConsumerState<AdvancedQueriesCard> {
  bool _loading = false;
  String? _label;
  String? _error;
  List<WorkoutLog>? _resultLogs;
  int? _resultCount;
  String _selectedMuscleGroup = 'Chest';

  String get _userId => ref.read(authStateProvider).value?.uid ?? '';

  Future<void> _run(_QueryKind kind) async {
    if (_userId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _resultLogs = null;
      _resultCount = null;
    });

    final service = ref.read(workoutLogServiceProvider);
    try {
      switch (kind) {
        case _QueryKind.muscleGroup:
          _label = 'Showing sets for: $_selectedMuscleGroup';
          _resultLogs = await service.logsByMuscleGroup(
            _userId,
            _selectedMuscleGroup,
          );
          break;
        case _QueryKind.weightRange:
          _label = 'Sets between 20kg and 60kg';
          _resultLogs = await service.logsInWeightRange(_userId, 20, 60);
          break;
        case _QueryKind.muscleGroupSince:
          _label = '$_selectedMuscleGroup sets from the last 7 days';
          _resultLogs = await service.recentLogsByMuscleGroup(
            _userId,
            _selectedMuscleGroup,
            DateTime.now().subtract(const Duration(days: 7)),
          );
          break;
        case _QueryKind.heaviest:
          _label = 'Your 5 heaviest sets';
          _resultLogs = await service.heaviestSets(_userId, limit: 5);
          break;
        case _QueryKind.totalCount:
          _label = 'Total sets logged';
          _resultCount = await service.totalSetsLogged(_userId);
          break;
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Queries',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick a muscle group to filter, or tap a button below to run '
            'another Firestore query.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Muscle group:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMuscleGroup,
                    isDense: true,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    iconEnabledColor: AppColors.textSecondary,
                    items: ExerciseLibrary.muscleGroups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedMuscleGroup = value);
                      _run(_QueryKind.muscleGroup);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _queryChip('Weight Range', () => _run(_QueryKind.weightRange)),
              _queryChip(
                'Muscle Group + Date',
                () => _run(_QueryKind.muscleGroupSince),
              ),
              _queryChip('Heaviest Sets', () => _run(_QueryKind.heaviest)),
              _queryChip('Total Sets (count)', () => _run(_QueryKind.totalCount)),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              'Query failed: $_error\n(If this mentions an index, open the '
              'link Firestore prints in the debug console to create it.)',
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          if (!_loading && _error == null && _label != null) ...[
            const SizedBox(height: 16),
            Text(
              _label!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_resultCount != null)
              Text(
                '$_resultCount total sets',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (_resultLogs != null)
              _resultLogs!.isEmpty
                  ? const Text(
                      'No matching sets yet - log a few and try again.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _resultLogs!
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${log.exerciseName} - ${log.weight}kg x '
                                '${log.reps} (${log.muscleGroup})',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
          ],
        ],
      ),
    );
  }

  Widget _queryChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.surfaceLight,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      onPressed: _loading ? null : onTap,
    );
  }
}
