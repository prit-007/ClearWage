import 'package:url_launcher/url_launcher.dart';
import '../currency_format.dart';

class WhatsappService {
  Uri buildUri({required String phone, required String text}) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}');
  }

  Future<bool> launch({required String phone, required String text}) {
    return launchUrl(
      buildUri(phone: phone, text: text),
      mode: LaunchMode.externalApplication,
    );
  }

  String greeting({required String name}) => 'નમસ્તે $name!';

  String salaryMessage({
    required String name,
    required num salary,
    required num balance,
  }) {
    return 'નમસ્તે $name, આ મહિનાનો તમારો પગાર '
        '${AppCurrency.formatDecimal(salary)} છે અને બાકી જમા '
        '${AppCurrency.formatDecimal(balance)} છે.';
  }
}
