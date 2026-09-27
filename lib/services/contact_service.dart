import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends contact form messages through EmailJS.
/// API Documentation: https://www.emailjs.com/docs/rest-api/send/
class ContactService {
  static const emailJsServiceId = String.fromEnvironment('EMAILJS_SERVICE_ID');
  static const emailJsTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_ID',
  );
  static const emailJsPublicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY');

  static const String _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';
  static const Duration _timeout = Duration(seconds: 15);

  static bool get isConfigured =>
      emailJsServiceId.isNotEmpty &&
      emailJsTemplateId.isNotEmpty &&
      emailJsPublicKey.isNotEmpty;

  Future<bool> send({required String subject, required String message}) async {
    if (!isConfigured) {
      debugPrint('[Contact] EmailJS is not configured');
      return false;
    }
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'origin': 'http://localhost',
            },
            body: jsonEncode({
              'service_id': emailJsServiceId,
              'template_id': emailJsTemplateId,
              'user_id': emailJsPublicKey,
              'template_params': {'subject': subject, 'message': message},
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) return true;
      debugPrint(
        '[Contact] EmailJS error ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('[Contact] Failed to send: $e');
      return false;
    }
  }
}
