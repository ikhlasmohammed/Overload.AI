import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analysis.dart';
import '../models/recommendation.dart';
import '../providers/analysis_provider.dart';
import '../providers/recommendation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/advanced_queries_card.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal_sheet.dart';

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatShortDate(DateTime date) => '${_monthAbbr[date.month - 1]} ${date.day}';

class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progressive Overload Architect'),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.divider,
            tabs: [
              Tab(text: 'Analysis'),
              Tab(text: 'Recommendations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnalysisTab(context, ref),
            _buildRecommendationsTab(ref),
          ],
        ),
      ),
    );
  }

  // TAB 1: ANALYSIS

  Widget _buildAnalysisTab(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisProvider);

    return analysisAsync.when(
      data: (analysis) {
        if (analysis.selectedExercise == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Log a few sets and your analysis will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGraphCard(context, ref, analysis),
              const SizedBox(height: 16),
              _buildMuscleVolumeCard(analysis),
              const SizedBox(height: 16),
              _buildInsightsCard(analysis),
              const SizedBox(height: 16),
              const AdvancedQueriesCard(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Couldn't load your analysis right now: $error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  void _showExercisePicker(
    BuildContext context,
    WidgetRef ref,
    AnalysisData analysis,
  ) {
    AppModalSheet.show(
      context: context,
      title: 'Select Exercise',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: analysis.availableExercises.map((name) {
          final isSelected = name == analysis.selectedExercise;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              ref.read(selectedAnalysisExerciseProvider.notifier).select(name);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGraphCard(
    BuildContext context,
    WidgetRef ref,
    AnalysisData analysis,
  ) {
    final valueKg = analysis.currentOneRepMaxKg;
    final change = analysis.percentChangeSinceFirstLog;
    final isUp = change >= 0;
    final hasTrend = analysis.oneRmHistory.length > 1;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated 1RM',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showExercisePicker(context, ref, analysis),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      analysis.selectedExercise!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (hasTrend)
                Row(
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      color: isUp ? AppColors.primary : AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)}% since first log',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${valueKg % 1 == 0 ? valueKg.toInt() : valueKg.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          if (hasTrend)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: _OneRmLineChart(history: analysis.oneRmHistory),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Log this exercise on a couple more days to see a trend line.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(AnalysisData analysis) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final insight in analysis.keyInsights)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                insight,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Weekly Muscle Volume card ----
  // Rolls this week's real logs up by muscle group so the user can spot
  // which groups are being neglected.
  Widget _buildMuscleVolumeCard(AnalysisData analysis) {
    final rawVolume = analysis.weeklyVolumeByMuscleGroup;
    final maxVolume = rawVolume.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Muscle Volume',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Relative training volume by muscle group this week.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (maxVolume == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No sets logged in the last 7 days yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _MuscleVolumeBarChart(volumeByGroup: rawVolume),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: RECOMMENDATIONS
  // ==========================================
  Widget _buildRecommendationsTab(WidgetRef ref) {
    final recsAsync = ref.watch(recommendationsProvider);

    return recsAsync.when(
      data: (recs) {
        if (recs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Log a few sets and your recommendations will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final rec in recs) ...[
                _buildRecommendationCard(rec),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Couldn't reach the AI coach right now: $error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation rec) {
    // Helper to format decimals beautifully (e.g., 70.0 becomes 70, but 72.5 stays 72.5)
    String formatWeight(double weight) =>
        weight % 1 == 0 ? weight.toInt().toString() : weight.toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Session Recommendation',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            rec.exerciseName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // ROW 1: Labels only
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Current',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 24), // Space matching the arrow below
              Expanded(
                child: Text(
                  'Suggested',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ROW 2: Values and Arrow
          // NOTE: RichText/TextSpan does NOT inherit the app theme's
          // Montserrat font the way a plain Text widget does, so every
          // TextStyle below sets fontFamily explicitly.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Current Value
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: formatWeight(rec.currentWeight),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const TextSpan(
                        text: ' kg x ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      TextSpan(
                        text: '${rec.currentReps}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const TextSpan(
                        text: ' reps',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Icon(Icons.arrow_forward, color: AppColors.textSecondary),

              // Suggested Value (Highlighted in Primary Blue, Aligned to the right)
              Expanded(
                child: RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: formatWeight(rec.suggestedWeight),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const TextSpan(
                        text: ' kg x ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      TextSpan(
                        text: '${rec.suggestedReps}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const TextSpan(
                        text: ' reps',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec.reasoning,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ESTIMATED 1RM LINE CHART (fl_chart)
// ==========================================
// Draws a real line graph from the user's Firestore-derived 1RM history.
// Points are spaced evenly along X by index (not true time-scale) since
// training days are rarely evenly spaced - this keeps the line readable
// whether the user trained twice in a week or once a month.
class _OneRmLineChart extends StatelessWidget {
  final List<OneRmPoint> history;

  const _OneRmLineChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final values = history.map((p) => p.oneRepMaxKg).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Padding so the line never touches the very top/bottom edge, and a
    // flat line (minValue == maxValue) still renders mid-chart.
    final range = (maxValue - minValue) == 0 ? maxValue : (maxValue - minValue);
    final padding = range * 0.25;

    final spots = [
      for (var i = 0; i < history.length; i++)
        FlSpot(i.toDouble(), history[i].oneRepMaxKg),
    ];

    return LineChart(
      LineChartData(
        minY: minValue - padding,
        maxY: maxValue + padding,
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 1 : range / 2,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // Without this, fl_chart auto-picks its own tick spacing for
              // a continuous 0..N axis (e.g. every 0.2), calling
              // getTitlesWidget many times at fractional x-values that all
              // round down to the same index - that's what was producing
              // "Aug 2" and "Aug 9" repeated several times. Forcing the
              // step to exactly (last index - first index) means fl_chart
              // only ever asks for a title at x=0 and x=history.length-1.
              interval: (history.length - 1) == 0
                  ? 1
                  : (history.length - 1).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != history.length - 1) {
                  return const SizedBox.shrink();
                }
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatShortDate(history[index].date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.surfaceLight,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final index = spot.x.round();
              final date = _formatShortDate(history[index].date);
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} kg\n$date',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: AppColors.textPrimary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WEEKLY MUSCLE VOLUME BAR CHART (fl_chart)
// ==========================================
// One bar per canonical muscle group. Bar height is the real rolling-7-day
// kg volume (weight x reps x sets); the chart's own maxY autoscaling keeps
// whichever group trained hardest this week at the top of the chart.
class _MuscleVolumeBarChart extends StatelessWidget {
  final Map<String, double> volumeByGroup;

  const _MuscleVolumeBarChart({required this.volumeByGroup});

  @override
  Widget build(BuildContext context) {
    final groups = volumeByGroup.keys.toList();
    final maxVolume = volumeByGroup.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );
    final chartCeiling = maxVolume == 0 ? 1.0 : maxVolume * 1.2;

    return BarChart(
      BarChartData(
        maxY: chartCeiling,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1, // one tick per group - see line chart's fix above
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= groups.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    groups[index],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.surfaceLight,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${groups[groupIndex]}\n${rod.toY.round()} kg',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < groups.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: volumeByGroup[groups[i]]!,
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartCeiling,
                    color: AppColors.surfaceLight,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
