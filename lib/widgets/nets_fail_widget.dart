import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nets_provider.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';
import 'app_card.dart';

/// Shown while NETSNotifier's status is [NETSStatus.fail] - either the
/// sandbox returned a non-"00" response_code, or requestQR()/checkPayment()
/// itself threw (e.g. no network, bad sandbox credentials).
///
/// Unlike the labsheet's version (which auto-navigates back to root after
/// 10s), this offers an explicit "Try Again" action instead of silently
/// re-requesting a QR - "Buy Premium" isn't a forced gate the user has to
/// get through like Signup was, so there's no need to retry automatically.
class NETSFailWidget extends ConsumerWidget {
  final double amount;
  final String? message;

  const NETSFailWidget({super.key, required this.amount, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.cancel, color: AppColors.danger, size: 96),
            const SizedBox(height: 20),
            const Text(
              'Payment Failed',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'The transaction was not completed in time.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Try Again',
              onPressed: () =>
                  ref.read(netsProvider.notifier).generateQR(amount),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
