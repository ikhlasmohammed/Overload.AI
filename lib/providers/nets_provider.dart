import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nets_state.dart';
import '../services/nets_service.dart';
import 'auth_provider.dart';
import 'user_profile_provider.dart';

final netsServiceProvider = Provider<NETSService>((ref) => NETSService());

/// Handles one NETS QR payment attempt from start to finish: request the
/// QR, run the 5-minute countdown, listen for a real-time result over the
/// SSE webhook, fall back to checkPayment() if the countdown runs out
/// first, and once payment succeeds, save isPremium on the user's profile.
///

///
/// isAutoDispose is set on netsProvider below because PremiumPlanScreen is
/// the only thing watching this - leaving that screen tears the provider
/// down and cancels its timer/stream automatically, so there's no need for
/// a separate cleanup call and no risk of a leaked timer if someone backs
/// out mid-payment.
class NETSNotifier extends Notifier<NETSState> {
  Timer? _countdownTimer;
  Timer? _completeTimer;
  StreamSubscription<String>? _webhookSub;
  bool _settled = false; // true once success/fail has been decided

  @override
  NETSState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
      _completeTimer?.cancel();
      _webhookSub?.cancel();
    });
    return const NETSState();
  }

  void _cancelActiveWork() {
    _countdownTimer?.cancel();
    _webhookSub?.cancel();
  }

  /// Requests a fresh QR for [amount] SGD and kicks off the countdown +
  /// webhook listener. Runs once when NETSWidget first loads, and again if
  /// the user hits retry after a failed payment.
  Future<void> generateQR(double amount) async {
    _cancelActiveWork();
    _completeTimer?.cancel();
    _settled = false;
    state = const NETSState(status: NETSStatus.loading);

    try {
      final service = ref.read(netsServiceProvider);
      final result = await service.requestQR(amount);
      final txnRef = result['txnRef'] as String;

      state = NETSState(
        qrCode: result['qrCode'],
        status: NETSStatus.idle,
        timeLeft: 300,
        txnRef: txnRef,
      );

      _startTimer(txnRef);
      _startWebhookListener(txnRef);
    } catch (e) {
      state = state.copyWith(status: NETSStatus.fail, message: '$e');
    }
  }

  void _startTimer(String txnRef) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.timeLeft - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(timeLeft: 0);
        checkPayment(txnRef);
      } else {
        state = state.copyWith(timeLeft: remaining);
      }
    });
  }

  void _startWebhookListener(String txnRef) {
    final service = ref.read(netsServiceProvider);
    _webhookSub?.cancel();
    _webhookSub = service
        .webhookStream(txnRef)
        .listen(
          (payload) {
            Map<String, dynamic> data;
            try {
              data = jsonDecode(payload) as Map<String, dynamic>;
            } catch (_) {
              return; // probably just a keep-alive frame, ignore it
            }

            final message = data['message'] as String?;
            if (message != null) {
              state = state.copyWith(message: message);
            }

            final responseCode = data['response_code'] as String?;
            if (responseCode != null) {
              _settle(responseCode);
            }
          },
          onError: (_) {
            // If the SSE connection drops, the countdown timer's
            // checkPayment() fallback is what ends up resolving this.
          },
        );
  }

  /// Calls the query API for [txnRef] and settles the transaction based on
  /// whatever response_code comes back. Used as the countdown's timeout
  /// fallback, but can also be called directly if something wants to poll.
  Future<void> checkPayment(String txnRef) async {
    if (_settled) return;
    try {
      final service = ref.read(netsServiceProvider);
      final result = await service.checkPayment(txnRef);
      _settle(result['response_code'] as String?);
    } catch (e) {
      _settle(null, errorMessage: '$e');
    }
  }

  /// "00" means success, anything else (or an error) means fail. Only the
  /// first call actually counts - both the webhook and the timeout
  /// fallback can fire, but only one of them should get to decide.
  void _settle(String? responseCode, {String? errorMessage}) {
    if (_settled) return;
    _settled = true;
    _cancelActiveWork();

    if (responseCode == '00') {
      state = state.copyWith(status: NETSStatus.success);
      // Stay on the success screen for 10s (NETSSuccessWidget shows its
      // own countdown for this too), then save isPremium and let
      // PremiumPlanScreen swap over to the unlocked content.
      _completeTimer?.cancel();
      _completeTimer = Timer(
        const Duration(seconds: 10),
        _markPremiumAndComplete,
      );
    } else {
      state = state.copyWith(
        status: NETSStatus.fail,
        message: errorMessage ?? state.message,
      );
    }
  }

  Future<void> _markPremiumAndComplete() async {
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        await ref.read(userProfileServiceProvider).setPremium(uid, true);
      }
    } catch (_) {
      // The payment already succeeded, so a failed profile write here
      // shouldn't leave the user stuck on the QR screen. userProfileProvider
      // will just keep saying isPremium is false until this gets retried -
      // that's a data-sync issue, not the payment failing.
    }
    state = state.copyWith(status: NETSStatus.complete);
  }
}

final netsProvider = NotifierProvider<NETSNotifier, NETSState>(
  NETSNotifier.new,
  isAutoDispose: true,
);
