import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService.instance;
});

final pendingPaymentsProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  final service = ref.read(paymentServiceProvider);
  return await service.getPendingPayments();
});
