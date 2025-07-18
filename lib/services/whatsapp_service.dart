import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static const String _defaultTemplate =
      'Hello {name}, your appointment on {date} at {time} has been cancelled. Please contact us to reschedule.';

  static Future<String> getMessageTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('whatsapp_cancel_template') ?? _defaultTemplate;
  }

  static String _formatMessage(String template, Map<String, String> data) {
    String message = template;

    // Replace placeholders with actual data
    message = message.replaceAll('{name}', data['name'] ?? '');
    message = message.replaceAll('{date}', data['date'] ?? '');
    message = message.replaceAll('{time}', data['time'] ?? '');
    message = message.replaceAll('{location}', data['location'] ?? '');

    return message;
  }

  static Future<String> _getDefaultCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone_number') ?? '';

    if (userPhone.isNotEmpty && userPhone.startsWith('+')) {
      // Extract country code from user's phone number
      final match = RegExp(r'^\+(\d{1,3})').firstMatch(userPhone);
      if (match != null) {
        return '+${match.group(1)}';
      }
    }

    // Default to US/Canada if no user phone number is set
    return '+230';
  }

  static Future<bool> sendCancellationMessage({
    required String phoneNumber,
    required String patientName,
    required String date,
    required String time,
    required String location,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Ensure phone number starts with country code
      if (!cleanPhone.startsWith('+')) {
        final defaultCountryCode = await _getDefaultCountryCode();
        cleanPhone = '$defaultCountryCode$cleanPhone';
      }

      final template = await getMessageTemplate();
      final message = _formatMessage(template, {
        'name': patientName,
        'date': date,
        'time': time,
        'location': location,
      });

      // Create WhatsApp URL
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      return false;
    }
  }

  static Future<List<bool>> sendBulkCancellationMessages({
    required List<Map<String, dynamic>> appointments,
    required String location,
  }) async {
    final List<bool> results = [];

    for (final appointment in appointments) {
      if (appointment['phoneNumber'] != null &&
          appointment['phoneNumber'].toString().isNotEmpty) {
        final patientName =
            '${appointment['patientFirstName']} ${appointment['patientLastName']}';

        final result = await sendCancellationMessage(
          phoneNumber: appointment['phoneNumber'].toString(),
          patientName: patientName,
          date: appointment['date'].toString(),
          time: appointment['time'].toString(),
          location: location,
        );

        results.add(result);

        // Add a small delay between messages to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        results.add(false); // No phone number available
      }
    }

    return results;
  }

  static Future<String> getUserPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone_number') ?? '';
  }

  static String formatPhoneForDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Basic phone number formatting for display
    // You can enhance this based on your region's phone number format
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    } else {
      return phone; // Return original if we can't format it
    }
  }
}
