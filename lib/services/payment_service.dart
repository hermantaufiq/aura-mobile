import 'package:pocketbase/pocketbase.dart';
import '../models/payment_model.dart';
import 'pocketbase_service.dart';
import 'dart:math';

class PaymentService {
  PaymentService._();
  static final instance = PaymentService._();

  PocketBase get _pb => PocketBaseService.instance.pb;

  String _generateOrderId() {
    final rand = Random().nextInt(99999).toString().padLeft(5, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    return 'AURA-$timestamp-$rand';
  }

  int _getPriceForPlan(String planType) {
    if (planType == 'promo') return 29000;
    if (planType == 'yearly') return 499000;
    return 49000; // monthly default
  }

  Future<PaymentModel> createPendingPayment({
    required String userId,
    required String planType,
  }) async {
    final body = {
      'user': userId,
      'order_id': _generateOrderId(),
      'gross_amount': _getPriceForPlan(planType),
      'status': 'pending',
      'plan_type': planType,
    };

    final record = await _pb.collection('payments').create(body: body);
    return PaymentModel.fromRecord(record);
  }

  Future<List<PaymentModel>> getPendingPayments() async {
    final records = await _pb.collection('payments').getFullList(
      filter: 'status = "pending"',
      sort: '-created',
      expand: 'user',
    );
    return records.map((r) => PaymentModel.fromRecord(r)).toList();
  }

  Future<void> approvePayment(String paymentId) async {
    // We assume the admin is executing this, so the update rule allows it.
    await _pb.collection('payments').update(paymentId, body: {
      'status': 'success',
    });
  }

  Future<void> rejectPayment(String paymentId) async {
    await _pb.collection('payments').update(paymentId, body: {
      'status': 'failed',
    });
  }
}
