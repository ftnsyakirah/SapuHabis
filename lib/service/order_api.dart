import 'dart:convert';

import 'package:http/http.dart' as http;

enum PaymentMethod {
  any('any', 'Choose at checkout'),
  fpx('fpx', 'Online banking (FPX)'),
  card('card', 'Credit or debit card'),
  grabpay('grabpay', 'GrabPay');

  final String apiValue;
  final String label;
  const PaymentMethod(this.apiValue, this.label);
}

class OrderListing {
  final int id;
  final String title;
  final String businessName;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;

  const OrderListing({
    required this.id,
    required this.title,
    required this.businessName,
    required this.pickupStart,
    required this.pickupEnd,
  });

  factory OrderListing.fromJson(Map<String, dynamic> j) => OrderListing(
        id: j['id'] as int,
        title: j['title'] as String,
        businessName: j['business_name'] as String,
        pickupStart: j['pickup_start'] == null
            ? null
            : DateTime.parse(j['pickup_start'] as String).toLocal(),
        pickupEnd: j['pickup_end'] == null
            ? null
            : DateTime.parse(j['pickup_end'] as String).toLocal(),
      );
}

class Order {
  final String id;

  /// pending | paid | failed | expired | cancelled | refund_required | refunded
  final String status;
  final OrderListing listing;
  final int quantity;
  final double unitPrice;
  final double amount;
  final String currency;
  final String? checkoutUrl; 
  final String? pickupCode;
  final DateTime holdExpiresAt;
  final DateTime? paidAt;

  const Order({
    required this.id,
    required this.status,
    required this.listing,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.currency,
    required this.checkoutUrl,
    required this.pickupCode,
    required this.holdExpiresAt,
    required this.paidAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isFree => amount == 0;

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        status: j['status'] as String,
        listing: OrderListing.fromJson(j['listing'] as Map<String, dynamic>),
        quantity: j['quantity'] as int,
        unitPrice: (j['unit_price'] as num).toDouble(),
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String,
        checkoutUrl: j['checkout_url'] as String?,
        pickupCode: j['pickup_code'] as String?,
        holdExpiresAt: DateTime.parse(j['hold_expires_at'] as String).toLocal(),
        paidAt: j['paid_at'] == null
            ? null
            : DateTime.parse(j['paid_at'] as String).toLocal(),
      );
}

class OrderApiException implements Exception {
  final int? statusCode;
  final String code; 
  final String message;

  const OrderApiException(this.message, {this.statusCode, this.code = 'error'});

  @override
  String toString() => message;
}

class OrderService {
  final String baseUrl;
  final http.Client _client;

  OrderService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<Order> createOrder({
    required int listingId,
    int quantity = 1,
    PaymentMethod method = PaymentMethod.any,
    String? buyerEmail,
  }) async {
    final res = await _send(
      'POST',
      '/api/orders',
      body: {
        'listing_id': listingId,
        'quantity': quantity,
        'payment_method': method.apiValue,
        if (buyerEmail != null && buyerEmail.isNotEmpty) 'buyer_email': buyerEmail,
      },
    );
    return Order.fromJson(res);
  }

  Future<Order> getOrder(String orderId) async =>
      Order.fromJson(await _send('GET', '/api/orders/$orderId'));

  Future<Order> cancelOrder(String orderId) async =>
      Order.fromJson(await _send('POST', '/api/orders/$orderId/cancel'));

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final http.Response res;
    try {
      final request = http.Request(method, uri)
        ..headers['Content-Type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);
      res = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 25)),
      );
    } catch (_) {
      throw const OrderApiException('Could not reach the server. Check your connection.');
    }

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300 && data != null) return data;

    throw OrderApiException(
      (data?['message'] as String?) ?? 'Something went wrong. Please try again.',
      statusCode: res.statusCode,
      code: (data?['error'] as String?) ?? 'error',
    );
  }

  void dispose() => _client.close();
}
