import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
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

  static Future<Map<String, String>> uploadReceiptPdf({
    required String applicationId,
    required String paymentId,
    required Uint8List bytes,
  }) async {
    final storagePath =
        '${AppConstants.paymentReceiptsFolder}/$applicationId/${paymentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await SupabaseService.storage.from(AppConstants.documentsBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );

    final publicUrl = SupabaseService.storage
        .from(AppConstants.documentsBucket)
        .getPublicUrl(storagePath);

    return {
      'path': storagePath,
      'url': publicUrl,
    };
  }

  static Future<PaymentModel> updatePayment(PaymentModel payment) async {
    final response = await SupabaseService.from(_table)
        .update(payment.toJson())
        .eq('id', payment.id)
        .select()
        .single();

    return PaymentModel.fromJson(response);
  }

  static Future<void> updateReceiptFields({
    required String paymentId,
    required String receiptFilePath,
    required String receiptFileUrl,
  }) async {
    await SupabaseService.from(_table).update({
      'receipt_file_path': receiptFilePath,
      'receipt_file_url': receiptFileUrl,
    }).eq('id', paymentId);
  }

  static Future<void> deletePayment(String id, {String? receiptFilePath}) async {
    if (receiptFilePath != null && receiptFilePath.trim().isNotEmpty) {
      try {
        await SupabaseService.storage
            .from(AppConstants.documentsBucket)
            .remove([receiptFilePath]);
      } catch (_) {
        // Do not block payment deletion if receipt cleanup fails.
      }
    }
    final deletedRows = await SupabaseService.from(_table)
        .delete()
        .eq('id', id)
        .select('id');

    if (deletedRows is! List || deletedRows.isEmpty) {
      throw Exception(
        'Payment could not be deleted. Please check Supabase delete policy for payments.',
      );
    }
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
