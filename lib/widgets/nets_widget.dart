import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nets_state.dart';
import '../providers/nets_provider.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';
import 'app_card.dart';
import 'nets_fail_widget.dart';
import 'nets_success_widget.dart';

/// Displays the live NETS QR payment flow for a one-time purchase of
/// [amount] SGD dollars. Requests a QR as soon as it's first shown, then
/// renders whichever sub-view matches netsProvider's current status.
///
/// Used in place of PremiumPlanScreen's old mock QR card - see
/// Mini-Project #10 labsheet Section G5 (nets_widget.dart).
class NETSWidget extends ConsumerStatefulWidget {
  final double amount;

  const NETSWidget({super.key, required this.amount});

  @override
  ConsumerState<NETSWidget> createState() => _NETSWidgetState();
}

class _NETSWidgetState extends ConsumerState<NETSWidget> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback so the first QR request fires after the initial
    // build, not while the widget tree is still being constructed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(netsProvider.notifier).generateQR(widget.amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(netsProvider);

    switch (state.status) {
      case NETSStatus.loading:
        return const _CenteredSpinner();
      case NETSStatus.success:
        return const NETSSuccessWidget();
      case NETSStatus.fail:
        return NETSFailWidget(amount: widget.amount, message: state.message);
      case NETSStatus.complete:
        // PremiumPlanScreen swaps this widget out as soon as status flips
        // to complete - this case only guards against one leftover frame.
        return const SizedBox.shrink();
      case NETSStatus.idle:
        return state.qrCode == null
            ? const _CenteredSpinner()
            : _QrCard(amount: widget.amount, state: state);
    }
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _QrCard extends StatelessWidget {
  final double amount;
  final NETSState state;

  const _QrCard({required this.amount, required this.state});

  String get _countdownLabel {
    final minutes = (state.timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Scan to pay with\nNETS QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.memory(state.qrCode as Uint8List, fit: BoxFit.contain),
          ),

          const SizedBox(height: 24),
          Text(
            'Open TWallet and scan this code to complete your payment.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (state.message != null) ...[
            const SizedBox(height: 8),
            Text(
              state.message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Total Amount',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'SGD ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time left: $_countdownLabel',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: 'Cancel Payment',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
