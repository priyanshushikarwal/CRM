import '../models/payment_model.dart';
import 'supabase_service.dart';

class PaymentService {
  static const String _table = 'payments';

  static Future<List<PaymentModel>> fetchAllPayments() async {
    final response = await SupabaseService.from(_table)
        .select()
        .order('payment_date', ascending: false);

    return (response as List)
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PaymentModel>> fetchPayments(String applicationId) async {
    final response = await SupabaseService.from(_table)
        .select()
        .eq('application_id', applicationId)
        .order('payment_date', ascending: false);

    return (response as List)
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<PaymentModel> addPayment(PaymentModel payment) async {
    final response = await SupabaseService.from(_table)
        .insert(payment.toJson())
        .select()
        .single();

    return PaymentModel.fromJson(response);
  }

  static Future<void> deletePayment(String id) async {
    await SupabaseService.from(_table).delete().eq('id', id);
  }

  static Future<Map<String, double>> getPaymentStats(String applicationId, double totalAmount) async {
    final payments = await fetchPayments(applicationId);
    
    double advancePaid = 0;
    double totalPaid = 0;

    for (final payment in payments) {
      totalPaid += payment.amount;
      if (payment.paymentType == PaymentType.advance) {
        advancePaid += payment.amount;
      }
    }

    return {
      'totalAmount': totalAmount,
      'advancePaid': advancePaid,
      'totalPaid': totalPaid,
      'remainingAmount': totalAmount - totalPaid,
    };
  }
}
