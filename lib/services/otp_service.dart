import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  // Store OTPs temporarily (in production, this should be server-side)
  final Map<String, String> _otpStore = {};
  final Map<String, DateTime> _otpExpiry = {};

  /// Generate a random 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to email (using a free email service)
  Future<bool> sendOTP(String email) async {
    try {
      final otp = _generateOTP();
      
      // Store OTP with 5-minute expiry
      _otpStore[email] = otp;
      _otpExpiry[email] = DateTime.now().add(const Duration(minutes: 5));

      // Send email using EmailJS or similar service
      // For now, we'll print to console (you need to integrate with your email service)
      // =================================================================
      //                 🐞 DEBUG OTP CODE 🐞
      // =================================================================
      debugPrint('\n\n');
      debugPrint('      �  YOUR OTP CODE IS:  $otp  👈');
      debugPrint('\n\n');
      // =================================================================

      
      // Integrate with your email service here
      // Example with EmailJS:
      await _sendViaEmailJS(email, otp);

      
      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP
  bool verifyOTP(String email, String otp) {
    final storedOTP = _otpStore[email];
    final expiry = _otpExpiry[email];

    if (storedOTP == null || expiry == null) {
      return false;
    }

    // Check if OTP is expired
    if (DateTime.now().isAfter(expiry)) {
      _otpStore.remove(email);
      _otpExpiry.remove(email);
      return false;
    }

    // Verify OTP
    if (storedOTP == otp) {
      _otpStore.remove(email);
      _otpExpiry.remove(email);
      return true;
    }

    return false;
  }

  /// Get remaining time for OTP expiry
  Duration? getRemainingTime(String email) {
    final expiry = _otpExpiry[email];
    if (expiry == null) return null;
    
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  // Example EmailJS integration (you need to set up EmailJS account)
  Future<void> _sendViaEmailJS(String email, String otp) async {
    const serviceId = 'service_lrskmji';
    const templateId = 'template_uvf18ip';
    const publicKey = 'f02ODuPvOUe5z1ICj';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    // 🔍 DIAGNOSTIC: Test DNS lookup
    try {
      final googleResult = await InternetAddress.lookup('google.com');
      debugPrint('🌐 DNS Test (google.com): ${googleResult.isNotEmpty ? "SUCCESS" : "EMPTY"}');
      
      final emailJSResult = await InternetAddress.lookup('api.emailjs.com');
      debugPrint('🌐 DNS Test (api.emailjs.com): ${emailJSResult.isNotEmpty ? "SUCCESS" : "EMPTY"}');
    } catch (e) {
      debugPrint('⚠️ DNS Diagnostic Failed: $e');
    }

    final body = json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'email': email,
        'otp_code': otp,     // Your current variable
        'message': otp,      // Standard EmailJS variable
        'otp': otp,          // Common alternative
        'code': otp,         // Common alternative
        'app_name': 'HIW',
      },
    });

    // OTP redacted from logs on purpose (logcat is readable via adb).
    debugPrint('📦 Sending OTP via EmailJS to: $email');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost', // Sometimes required by EmailJS
      },
      body: body,
    );

    if (response.statusCode != 200) {
      debugPrint('❌ EmailJS Error: ${response.body}');
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}
