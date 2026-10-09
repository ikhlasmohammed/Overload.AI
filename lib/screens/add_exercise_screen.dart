import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/active_session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal_sheet.dart';
import '../widgets/app_buttons.dart';
import 'workout_screen.dart';

/// "Add Exercise" modal: search bar, muscle-group filter chips, and a
/// list of exercises the user can tap to select (single selection for
/// simplicity), then confirm with "Add Exercise".

class AddExerciseSheet extends ConsumerStatefulWidget {
  const AddExerciseSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return AppModalSheet.show(
      context: context,
      title: 'Add Exercise',
      child: const AddExerciseSheet(),
    );
  }

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _searchController = TextEditingController();
  String _selectedMuscleGroup = 'All';
  Exercise? _selectedExercise;

  static const _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
  ];

  List<Exercise> get _filteredExercises {
    final byGroup = ExerciseLibrary.byMuscleGroup(_selectedMuscleGroup);
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return byGroup;
    return byGroup.where((e) => e.name.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmAdd() {
    if (_selectedExercise == null) return;

    // Actually extend the live session (previously this only closed the
    // sheet and showed a snackbar without changing anything).
    ref.read(activeSessionProvider.notifier).addExercise(_selectedExercise!);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedExercise!.name} added'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search exercises...',
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 12),

        // Muscle group filter chips
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _muscleGroups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final group = _muscleGroups[index];
              final isSelected = group == _selectedMuscleGroup;
              return GestureDetector(
                onTap: () => setState(() => _selectedMuscleGroup = group),
                child: Center(
                  child: Text(
                    group,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Exercise list (scrollable, capped height so modal doesn't overflow)
        SizedBox(
          height: 220,
          child: _filteredExercises.isEmpty
              ? const Center(
                  child: Text(
                    'No exercises found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredExercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    final isSelected = exercise.name == _selectedExercise?.name;
                    return ExerciseListTile(
                      exercise: exercise,
                      onTap: () => setState(() => _selectedExercise = exercise),
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Add Exercise',
          onPressed: _selectedExercise == null ? null : _confirmAdd,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
