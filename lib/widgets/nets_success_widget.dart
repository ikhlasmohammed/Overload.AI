import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Shown while NETSNotifier's status is [NETSStatus.success].
///
/// Purely a cosmetic countdown - netsProvider is separately running its own
/// real 10-second timer (see nets_provider.dart's _settle()) that persists
/// isPremium and flips status to complete, which is what actually swaps
/// PremiumPlanScreen over to the unlocked content. This widget's countdown
/// just mirrors that wait so the user isn't staring at a static screen.
class NETSSuccessWidget extends StatefulWidget {
  const NETSSuccessWidget({super.key});

  @override
  State<NETSSuccessWidget> createState() => _NETSSuccessWidgetState();
}

class _NETSSuccessWidgetState extends State<NETSSuccessWidget> {
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 96),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlocking your Premium Plan in ${_secondsLeft}s...',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
