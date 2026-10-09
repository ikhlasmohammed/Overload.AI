import 'dart:typed_data';

/// The different states a NETS QR payment can be in, managed by NETSNotifier.
enum NETSStatus {
  idle, // no QR requested yet, or it's on screen waiting to be scanned
  loading, // requestQR() is running
  success, // got response_code "00" back
  fail, // got a non-"00" code, or the request just failed
  complete, // success screen finished its wait and isPremium is saved now
}

/// State for one NETS QR payment attempt, held by netsProvider.
///
/// qrCode is the decoded PNG from NETSService.requestQR() - stays null
/// until a request actually succeeds. timeLeft counts down from 300
/// seconds (matches how long the sandbox keeps a QR valid for) and drives
/// both the on-screen countdown and the checkPayment() fallback once it
/// hits zero.
class NETSState {
  final Uint8List? qrCode;
  final NETSStatus status;
  final int timeLeft;
  final String? message;
  final String? txnRef;

  const NETSState({
    this.qrCode,
    this.status = NETSStatus.idle,
    this.timeLeft = 300,
    this.message,
    this.txnRef,
  });

  NETSState copyWith({
    Uint8List? qrCode,
    NETSStatus? status,
    int? timeLeft,
    String? message,
    String? txnRef,
  }) {
    return NETSState(
      qrCode: qrCode ?? this.qrCode,
      status: status ?? this.status,
      timeLeft: timeLeft ?? this.timeLeft,
      message: message ?? this.message,
      txnRef: txnRef ?? this.txnRef,
    );
  }
}
