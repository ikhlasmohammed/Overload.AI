import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_log.dart';
import '../models/workout_schedule.dart';
import '../providers/workout_log_provider.dart';
import '../providers/workout_schedule_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_buttons.dart';
import 'schedule_workout_screen.dart';

/// The "Calendar" tab.
///
/// A day's dot color is DERIVED, never stored: a day counts as "Completed"
/// if the user has any real WorkoutLog that day (regardless of what was
/// originally planned), "Missed" if a WorkoutSchedule entry is still
/// 'Scheduled' but the day has already passed with no matching log, and
/// "Scheduled" otherwise. WorkoutSchedule.status in Firestore always stays
/// whatever the user set when they created it - this screen never writes
/// it - so the stored data represents "the plan", and this derivation is
/// "what actually happened", computed fresh every time from two real,
/// live Firestore streams (WorkoutLog + WorkoutSchedule).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  static const _weekdayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(workoutLogsProvider).value ?? const <WorkoutLog>[];
    final schedulesAsync = ref.watch(workoutScheduleProvider);
    final schedules = schedulesAsync.value ?? const <WorkoutSchedule>[];

    // Real per-day log timestamps (not just dates) - needed so a
    // schedule's exact time can be compared against exactly when the user
    // logged something, not just whether they logged anything that day.
    final logsByDay = <DateTime, List<DateTime>>{};
    for (final log in logs) {
      final day = DateTime(
        log.loggedAt.year,
        log.loggedAt.month,
        log.loggedAt.day,
      );
      logsByDay.putIfAbsent(day, () => []).add(log.loggedAt);
    }

    String? statusFor(DateTime day) {
      final clean = DateTime(day.year, day.month, day.day);
      final daySchedules = schedulesOn(schedules, clean);
      final dayLogs = logsByDay[clean] ?? const <DateTime>[];

      if (daySchedules.isEmpty) {
        // No plan for this day - any log at all counts as an ad-hoc
        // completed session.
        return dayLogs.isEmpty ? null : 'completed';
      }

      // WorkoutLog has no link back to a specific WorkoutSchedule entry,
      // so the earliest scheduled time that day is used as the reference
      // point: a log at or after it counts as "showed up for it", one
      // logged earlier doesn't. This is what stops an unrelated log
      // logged this morning from marking a 7pm session "Completed" hours
      // before it's even happened.
      final earliestScheduled = daySchedules
          .map((s) => s.scheduledDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      final showedUp = dayLogs.any((t) => !t.isBefore(earliestScheduled));
      if (showedUp) return 'completed';

      return DateTime.now().isAfter(earliestScheduled) ? 'missed' : 'scheduled';
    }

    final upcomingList = upcoming(schedules);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Surfaced instead of silently falling back to an empty
              // list - a genuine Firestore error (e.g. a missing
              // composite index on WorkoutSchedule's userId+scheduledDate
              // query) would otherwise look identical to "nothing
              // scheduled", on every screen that reads this provider.
              if (schedulesAsync.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Could not load your schedule: ${schedulesAsync.error}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              _buildCalendar(statusFor),
              const SizedBox(height: 12),
              _buildLegend(),
              const Divider(height: 32),
              _buildUpcomingHeader(),
              const SizedBox(height: 12),
              if (upcomingList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No upcoming workouts scheduled.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final schedule in upcomingList.take(5)) ...[
                  _UpcomingWorkoutCard(
                    schedule: schedule,
                    onDelete: () => ref
                        .read(workoutScheduleServiceProvider)
                        .deleteSchedule(schedule.scheduleId),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              PrimaryButton(
                label: 'Schedule Workout',
                onPressed: () => ScheduleWorkoutSheet.show(
                  context,
                  initialDate: _selectedDay ?? DateTime.now(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Real month grid ----
  Widget _buildCalendar(String? Function(DateTime) statusFor) {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      currentDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      daysOfWeekHeight: 24,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        // Per table_calendar's own docs: just store the value, no setState
        // needed here - the page swipe animation handles the rebuild.
        _focusedDay = focusedDay;
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) => Center(
          child: Text(
            _weekdayLabels[day.weekday - 1],
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        defaultBuilder: (context, day, focusedDay) =>
            _dayCell(day, status: statusFor(day)),
        outsideBuilder: (context, day, focusedDay) =>
            _dayCell(day, status: statusFor(day), isOutside: true),
        todayBuilder: (context, day, focusedDay) =>
            _dayCell(day, status: statusFor(day), isToday: true),
        selectedBuilder: (context, day, focusedDay) =>
            _dayCell(day, status: statusFor(day), isSelected: true),
      ),
    );
  }

  // One calendar cell: day number + an optional colored status dot below
  // it - same visual language as the original static grid, now driven by
  // real derived statuses instead of a hardcoded list.
  Widget _dayCell(
    DateTime day, {
    String? status,
    bool isOutside = false,
    bool isToday = false,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: (isToday && !isSelected)
            ? Border.all(color: AppColors.primary, width: 1.2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isOutside
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : isSelected
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          if (status != null)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(status),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.primary;
      case 'missed':
        return AppColors.danger;
      default:
        return AppColors.success;
    }
  }

  // ---- Legend row ----
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendDot(AppColors.primary, 'Completed'),
        _legendDot(AppColors.success, 'Scheduled'),
        _legendDot(AppColors.danger, 'Missed'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUpcomingHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Upcoming Workouts',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// One real upcoming-workout row, with a trash icon to cancel it (DELETE).
class _UpcomingWorkoutCard extends StatelessWidget {
  final WorkoutSchedule schedule;
  final VoidCallback onDelete;

  const _UpcomingWorkoutCard({required this.schedule, required this.onDelete});

  static const _weekdayShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _dateLabel {
    final d = schedule.scheduledDate;
    return '${_weekdayShort[d.weekday - 1]}, ${d.day} ${_monthShort[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.accessibility_new,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  schedule.routineName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  muscleGroupsForRoutine(schedule.routineName),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            onPressed: onDelete,
            tooltip: 'Cancel this workout',
          ),
        ],
      ),
    );
  }
}
