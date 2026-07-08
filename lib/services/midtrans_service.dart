import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'pocketbase_service.dart';

class MidtransService {
  static final MidtransService instance = MidtransService._internal();
  MidtransService._internal();

  final _logger = Logger();

  /// Menghasilkan Snap Checkout URL dari PocketBase backend
  Future<String?> createCheckoutUrl(String userId, {String planType = "monthly"}) async {
    try {
      final pb = PocketBaseService.instance.pb;
      final response = await pb.send('/api/midtrans/checkout', method: 'POST', body: {
        'user_id': userId,
        'plan_type': planType,
      });

      if (response.containsKey('redirect_url')) {
        return response['redirect_url'] as String;
      }
      return null;
    } catch (e) {
      _logger.e('Gagal memanggil API checkout midtrans: $e');
      return null;
    }
  }

  /// Membuka URL Midtrans Snap di peramban web bawaan pengguna
  Future<void> openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _logger.e('Tidak dapat membuka URL pembayaran: $url');
    }
  }
}
