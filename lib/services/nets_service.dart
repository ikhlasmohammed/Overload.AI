import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wraps every call to the NETS QR sandbox (OpenAPIPAAS) - same pattern as
/// GroqService and WorkoutLogService: the app never calls http directly
/// from a provider or screen.
///

/// RequestAPI (generate a QR), the S2S webhook (SSE stream of scan/payment
/// events), and QueryAPI (poll the final status as a fallback).
class NETSService {
  static const String _apiKey = String.fromEnvironment('NETS_API_KEY');
  static const String _projectId = String.fromEnvironment('NETS_PROJECT_ID');

  static const String _baseUrl =
      'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr';

  // The webhook (SSE) route lives under a different path segment ("nets",
  // not "nets-qr") to the other two endpoints - confirmed against the
  // course-provided reference implementation.
  static const String _webhookUrl =
      'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets/webhook';

  // every request needs this exact txn_id, not a freshly generated one, or
  // the backend 500s with "Cannot read property 'split' of undefined".
  static const String _txnId = String.fromEnvironment('NETS_TXN_ID');

  Map<String, String> get _headers => {
    'api-key': _apiKey,
    'project-id': _projectId,
    'Content-Type': 'application/json',
  };

  void _assertConfigured() {
    if (_apiKey.isEmpty || _projectId.isEmpty || _txnId.isEmpty) {
      throw NETSException(
        'NETS payment service is not configured for this build.',
      );
    }
  }

  /// Sends a NETS QR payment request for [amount] SGD dollars.
  ///
  /// Returns a map with:
  /// - 'qrCode': the decoded QR PNG (Uint8List), ready for Image.memory()
  /// - 'txnRef': the txn_retrieval_ref used to track this transaction via
  ///   the webhook stream and/or checkPayment()
  Future<Map<String, dynamic>> requestQR(double amount) async {
    _assertConfigured();

    final response = await http
        .post(
          Uri.parse('$_baseUrl/request'),
          headers: _headers,
          body: jsonEncode({
            'txn_id': _txnId,
            'amt_in_dollars': amount,
            'notify_mobile': 0,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw NETSException(
        'NETS request failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    final qrData = result is Map<String, dynamic>
        ? result['data'] as Map<String, dynamic>?
        : null;

    if (data['status'] != 'success' || qrData == null) {
      throw NETSException('NETS did not return a QR code.');
    }

    final txnRef = qrData['txn_retrieval_ref'] as String?;
    final qrCodeBase64 = qrData['qr_code'] as String?;
    if (txnRef == null || qrCodeBase64 == null) {
      throw NETSException(
        'NETS response was missing txn_retrieval_ref/qr_code.',
      );
    }

    return {'qrCode': base64Decode(qrCodeBase64), 'txnRef': txnRef};
  }

  /// Connects to the NETS Server-Sent Events webhook for [txnRef] and
  /// yields the raw JSON payload of each "data:" event as it arrives (e.g.
  /// '{"message":"QR code scanned","response_code":"00"}'). SSE comment
  /// lines (":keep-alive" etc) and blank lines are ignored.
  ///
  /// Closes its own http.Client when the stream ends or is cancelled, so
  /// callers don't need to manage the connection themselves.
  Stream<String> webhookStream(String txnRef) async* {
    _assertConfigured();

    final client = http.Client();
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_webhookUrl?txn_retrieval_ref=$txnRef'),
      );
      request.headers.addAll({
        ..._headers,
        'Accept': 'text/event-stream',
        'Connection': 'keep-alive',
      });

      final response = await client.send(request);
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.startsWith('data:')) {
          final payload = line.substring(5).trim();
          if (payload.isNotEmpty) yield payload;
        } else if (line.startsWith('{')) {
          // Defensive: this sandbox doesn't consistently follow the SSE
          // "data:" prefix convention (confirmed via curl - keep-alives
          // arrive as ":keep-alive" comment lines, but real events may be
          // raw JSON lines instead), so accept bare JSON lines too rather
          // than silently dropping a real payment update.
          yield line;
        }
      }
    } finally {
      client.close();
    }
  }

  /// Final payment status check for [txnRef] - used as a fallback when the
  /// SSE stream times out, the QR expires, or no real-time update arrives.
  /// Returns the 'data' object from the query response (response_code,
  /// txn_status, etc).
  Future<Map<String, dynamic>> checkPayment(String txnRef) async {
    _assertConfigured();

    final response = await http
        .post(
          Uri.parse('$_baseUrl/query'),
          headers: _headers,
          body: jsonEncode({
            'txn_retrieval_ref': txnRef,
            'frontend_timeout_status': 1,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw NETSException(
        'NETS query failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    final txnData = result is Map<String, dynamic>
        ? result['data'] as Map<String, dynamic>?
        : null;

    if (data['status'] != 'success' || txnData == null) {
      throw NETSException('NETS query result was missing transaction data.');
    }

    return txnData;
  }
}

class NETSException implements Exception {
  final String message;
  NETSException(this.message);

  @override
  String toString() => message;
}
