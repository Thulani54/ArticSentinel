import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/Constants.dart';

class ProductEnquiry {
  const ProductEnquiry({
    required this.requestId,
    required this.name,
    required this.email,
    required this.productType,
    required this.message,
    this.phone = '',
    this.company = '',
  });

  final String requestId, name, email, productType, message, phone, company;

  Map<String, Object> toJson() => {
        'request_id': requestId,
        'name': name,
        'email': email,
        'phone': phone,
        'company': company,
        'product_type': productType,
        'message': message,
        'contact_consent': true,
      };
}

class ProductEnquiryReceipt {
  const ProductEnquiryReceipt({required this.reference});
  final String reference;
}

class ProductEnquiryException implements Exception {
  const ProductEnquiryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProductEnquiryApi {
  ProductEnquiryApi({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<ProductEnquiryReceipt> submit(ProductEnquiry enquiry) async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('${Constants.articBaseUrl2}api/products/enquiries/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(enquiry.toJson()),
          )
          .timeout(const Duration(seconds: 25));
      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } on FormatException {
        // A proxy error page is not a successful enquiry receipt.
      }
      final reference = body?['reference'];
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body?['success'] == true &&
          reference is String &&
          reference.isNotEmpty) {
        return ProductEnquiryReceipt(reference: reference);
      }
      if (response.statusCode == 429) {
        throw const ProductEnquiryException(
            'There have been several requests recently. Wait a few minutes, then try again.');
      }
      if (response.statusCode == 400) {
        throw const ProductEnquiryException(
            'Check your contact details and message, then try again.');
      }
      throw const ProductEnquiryException(
          'We could not confirm your request. Your details are still here. Please try again.');
    } on ProductEnquiryException {
      rethrow;
    } catch (_) {
      throw const ProductEnquiryException(
          'We could not reach ArticSentinel. Check your connection and try again.');
    } finally {
      if (_client == null) client.close();
    }
  }
}
