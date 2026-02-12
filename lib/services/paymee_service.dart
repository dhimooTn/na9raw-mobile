// services/paymee_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class PaymeeService {
  // Configuration
  static const String _sandboxUrl = 'https://sandbox.paymee.tn/api/v2/payments/create';
  static const String _liveUrl = 'https://app.paymee.tn/api/v2/payments/create';

  // Replace with your actual API key from Paymee dashboard
  static const String _apiKey = 'e6fd6601074bad695ed54d455ad77b03a05e6e38';

  // Use sandbox for testing, set to false for production
  static const bool _useSandbox = true;

  String get _baseUrl => _useSandbox ? _sandboxUrl : _liveUrl;

  /// Create a payment session with Paymee
  Future<PaymeePaymentResponse?> createPayment({
    required double amount,
    required String orderNote,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String webhookUrl,
    String? returnUrl,
    String? cancelUrl,
    String? orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_apiKey',
        },
        body: jsonEncode({
          'amount': amount,
          'note': orderNote,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'webhook_url': webhookUrl,
          if (returnUrl != null) 'return_url': returnUrl,
          if (cancelUrl != null) 'cancel_url': cancelUrl,
          if (orderId != null) 'order_id': orderId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          return PaymeePaymentResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Payment creation failed');
        }
      } else {
        throw Exception('Failed to create payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating payment: $e');
      return null;
    }
  }

  /// Verify payment integrity using checksum
  bool verifyPaymentChecksum({
    required String token,
    required bool paymentStatus,
    required String checksum,
  }) {
    // Build checksum: md5(token + payment_status + API_Token)
    final statusValue = paymentStatus ? '1' : '0';
    final checksumString = '$token$statusValue$_apiKey';
    final calculatedChecksum = md5.convert(utf8.encode(checksumString)).toString();

    return calculatedChecksum == checksum;
  }
}

/// Response model for Paymee payment creation
class PaymeePaymentResponse {
  final String token;
  final String? orderId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String note;
  final double amount;
  final String paymentUrl;

  PaymeePaymentResponse({
    required this.token,
    this.orderId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.note,
    required this.amount,
    required this.paymentUrl,
  });

  factory PaymeePaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymeePaymentResponse(
      token: json['token'] as String,
      orderId: json['order_id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      note: json['note'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentUrl: json['payment_url'] as String,
    );
  }
}

/// Webhook response model
class PaymeeWebhookResponse {
  final String token;
  final String checksum;
  final bool paymentStatus;
  final String? orderId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String note;
  final double amount;
  final int? transactionId;
  final double? receivedAmount;
  final double? cost;

  PaymeeWebhookResponse({
    required this.token,
    required this.checksum,
    required this.paymentStatus,
    this.orderId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.note,
    required this.amount,
    this.transactionId,
    this.receivedAmount,
    this.cost,
  });

  factory PaymeeWebhookResponse.fromJson(Map<String, dynamic> json) {
    return PaymeeWebhookResponse(
      token: json['token'] as String,
      checksum: json['check_sum'] as String,
      paymentStatus: json['payment_status'] as bool,
      orderId: json['order_id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      note: json['note'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionId: json['transaction_id'] as int?,
      receivedAmount: json['received_amount'] != null
          ? (json['received_amount'] as num).toDouble()
          : null,
      cost: json['cost'] != null
          ? (json['cost'] as num).toDouble()
          : null,
    );
  }
}