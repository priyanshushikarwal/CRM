import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../models/payment_model.dart';
import '../../providers/app_providers.dart';
import '../../services/payment_service.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentRecordsProvider);
    final canManagePayments = ref.watch(currentUserProvider).value?.canEdit ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, ref, paymentsAsync.value ?? const []),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: paymentsAsync.when(
                loading:
                    () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Text('Error loading payments'),
                      ),
                    ),
                data: (records) {
                  if (records.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(64),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 48,
                              color: Color(0xFFE2E8F0),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No payments recorded yet',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardRadius,
                      ),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final payment = record.payment;
                        final app = record.application;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      app?.fullName ?? '-',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs.${NumberFormat('#,##,###', 'en_IN').format(payment.amount)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 18,
                                runSpacing: 8,
                                children: [
                                  _buildPaymentMeta(
                                    'KW',
                                    app?.proposedCapacity.toStringAsFixed(1) ??
                                        '-',
                                  ),
                                  _buildPaymentMeta('Mobile', app?.mobile ?? '-'),
                                  _buildPaymentMeta(
                                    'Receipt Date',
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(payment.paymentDate),
                                  ),
                                  _buildPaymentMeta(
                                    'Mode',
                                    payment.paymentMode.name.toUpperCase(),
                                  ),
                                  _buildPaymentMeta(
                                    'Transaction',
                                    (payment.transactionNumber
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                        ? payment.transactionNumber!
                                        : '-',
                                  ),
                                  _buildPaymentMeta(
                                    'Collected By',
                                    payment.collectedBy ?? '-',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 18,
                                    ),
                                    onPressed:
                                        app == null
                                            ? null
                                            : () => _downloadPaymentReceipt(
                                              context,
                                              ref,
                                              app,
                                              payment,
                                            ),
                                    tooltip: 'Download Receipt',
                                  ),
                                  if (canManagePayments)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () => _showEditPaymentDialog(
                                            context,
                                            ref,
                                            payment,
                                          ),
                                    ),
                                  if (canManagePayments)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppTheme.errorColor,
                                      ),
                                      onPressed:
                                          () => _confirmDeletePayment(
                                            context,
                                            ref,
                                            payment,
                                          ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                    onPressed:
                                        () => context.go(
                                          '/applications/${payment.applicationId}',
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    List<PaymentRecordRow> records,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage and track all client transaction history',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.invalidate(paymentRecordsProvider);
                  ref.invalidate(allPaymentsProvider);
                },
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed:
                    records.isEmpty ? null : () => _exportToPDF(context, records),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text(
                  'Export PDF',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.bar_chart_rounded, size: 20),
                label: const Text(
                  'View Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMeta(String label, String value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePayment(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
          'Delete payment of Rs.${NumberFormat('#,##,###', 'en_IN').format(payment.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PaymentService.deletePayment(
        payment.id,
        receiptFilePath: payment.receiptFilePath,
      );
      ref.invalidate(paymentRecordsProvider);
      ref.invalidate(allPaymentsProvider);
      await ref.refresh(paymentRecordsProvider.future);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showEditPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) async {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(0),
    );
    final transactionController = TextEditingController(
      text: payment.transactionNumber ?? '',
    );
    final remarksController = TextEditingController(
      text: payment.remarks ?? '',
    );
    PaymentMode selectedMode = payment.paymentMode;
    PaymentType selectedType = payment.paymentType;
    DateTime selectedPaymentDate = payment.paymentDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Rs.)',
                    prefixText: 'Rs. ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Payment Type'),
                  items: PaymentType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMode>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: PaymentMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedMode = value!),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedPaymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate == null) return;
                    setDialogState(() {
                      selectedPaymentDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                      );
                    });
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selectedPaymentDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: transactionController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Number / Reference',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid payment amount.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                await PaymentService.updatePayment(
                  payment.copyWith(
                    amount: amount,
                    paymentMode: selectedMode,
                    paymentType: selectedType,
                    paymentDate: selectedPaymentDate,
                    transactionNumber: transactionController.text.trim(),
                    remarks: remarksController.text.trim(),
                  ),
                );

                ref.invalidate(paymentRecordsProvider);
                ref.invalidate(allPaymentsProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment updated successfully.'),
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeReceiptFileName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Uint8List _buildPaymentReceiptPdfBytes(
    ApplicationModel app,
    PaymentModel payment,
  ) {
    final document = PdfDocument();
    final page = document.pages.add();
    final pageSize = page.getClientSize();

    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      18,
      style: PdfFontStyle.bold,
    );
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      11,
      style: PdfFontStyle.bold,
    );
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    double y = 0;
    page.graphics.drawString(
      AppConstants.companyName,
      titleFont,
      brush: PdfSolidBrush(PdfColor(30, 64, 175)),
      bounds: Rect.fromLTWH(0, y, pageSize.width, 24),
    );
    y += 28;

    page.graphics.drawString(
      'Payment Receipt',
      PdfStandardFont(
        PdfFontFamily.helvetica,
        14,
        style: PdfFontStyle.bold,
      ),
      bounds: Rect.fromLTWH(0, y, pageSize.width, 18),
    );
    y += 26;

    final rows = <List<String>>[
      ['Consumer Name', app.fullName],
      ['Application No.', app.applicationNumber],
      ['Mobile Number', app.mobile],
      ['Payment Date', DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate)],
      ['Payment Type', payment.paymentType.name.toUpperCase()],
      ['Payment Mode', payment.paymentMode.name.toUpperCase()],
      ['Transaction No.', (payment.transactionNumber?.trim().isNotEmpty ?? false) ? payment.transactionNumber! : '-'],
      ['Amount Received', 'Rs.${NumberFormat('#,##,###', 'en_IN').format(payment.amount)}'],
      ['Collected By', payment.collectedBy ?? '-'],
      ['Remarks', (payment.remarks?.trim().isNotEmpty ?? false) ? payment.remarks! : '-'],
    ];

    for (final row in rows) {
      page.graphics.drawString(
        row[0],
        headerFont,
        bounds: Rect.fromLTWH(0, y, 140, 16),
      );
      page.graphics.drawString(
        row[1],
        bodyFont,
        bounds: Rect.fromLTWH(150, y, pageSize.width - 150, 16),
      );
      y += 22;
    }

    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  Future<PaymentModel> _ensurePaymentReceipt(
    WidgetRef ref,
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    if ((payment.receiptFileUrl?.trim().isNotEmpty ?? false) &&
        (payment.receiptFilePath?.trim().isNotEmpty ?? false)) {
      return payment;
    }

    final bytes = _buildPaymentReceiptPdfBytes(app, payment);
    final upload = await PaymentService.uploadReceiptPdf(
      applicationId: app.id,
      paymentId: payment.id,
      bytes: bytes,
    );

    final updatedPayment = payment.copyWith(
      receiptFilePath: upload['path'],
      receiptFileUrl: upload['url'],
    );

    await PaymentService.updateReceiptFields(
      paymentId: payment.id,
      receiptFilePath: updatedPayment.receiptFilePath!,
      receiptFileUrl: updatedPayment.receiptFileUrl!,
    );
    ref.invalidate(paymentRecordsProvider);
    ref.invalidate(allPaymentsProvider);
    return updatedPayment;
  }

  Future<void> _downloadPaymentReceipt(
    BuildContext context,
    WidgetRef ref,
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    try {
      final ensuredPayment = await _ensurePaymentReceipt(ref, app, payment);
      final bytes = _buildPaymentReceiptPdfBytes(app, ensuredPayment);
      final consumerName = _sanitizeReceiptFileName(app.fullName);
      final receiptDate = DateFormat('yyyyMMdd_HHmm').format(
        ensuredPayment.paymentDate,
      );

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Download Payment Receipt',
        fileName: '${consumerName}_payment_receipt_$receiptDate.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (path == null) return;

      await File(path).writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt downloaded successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt download failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF(
    BuildContext context,
    List<PaymentRecordRow> records,
  ) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final now = DateTime.now();
    final document = PdfDocument();
    document.pageSettings.orientation = PdfPageOrientation.landscape;
    document.pageSettings.margins.all = 20;

    PdfPage page = document.pages.add();
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      16,
      style: PdfFontStyle.bold,
    );
    final subFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      8,
      style: PdfFontStyle.bold,
    );
    final cellFont = PdfStandardFont(PdfFontFamily.helvetica, 7);

    void drawTableHeader(PdfPage targetPage, double yPos) {
      const headers = [
        'Consumer Name',
        'KW',
        'Mobile',
        'Amount',
        'Receipt Date',
        'Mode',
        'Transaction No.',
        'Collected By',
      ];
      const colWidths = [105.0, 35.0, 75.0, 50.0, 62.0, 48.0, 90.0, 90.0];

      double xPos = 0;
      for (var i = 0; i < headers.length; i++) {
        targetPage.graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(30, 64, 175)),
          bounds: Rect.fromLTWH(xPos, yPos, colWidths[i], 18),
        );
        targetPage.graphics.drawString(
          headers[i],
          headerFont,
          brush: PdfSolidBrush(PdfColor(255, 255, 255)),
          bounds: Rect.fromLTWH(xPos + 2, yPos + 3, colWidths[i] - 4, 14),
        );
        xPos += colWidths[i];
      }
    }

    final pageWidth = page.getClientSize().width;
    double yPos = 0;

    page.graphics.drawString(
      AppConstants.companyName,
      titleFont,
      brush: PdfSolidBrush(PdfColor(30, 64, 175)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 22),
    );
    yPos += 24;

    page.graphics.drawString(
      'MIS Report - Payment Records',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 16),
    );
    yPos += 18;

    page.graphics.drawString(
      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}   |   Total Records: ${records.length}',
      subFont,
      brush: PdfSolidBrush(PdfColor(100, 100, 100)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 12),
    );
    yPos += 20;

    page.graphics.drawLine(
      PdfPen(PdfColor(30, 64, 175), width: 1.5),
      Offset(0, yPos),
      Offset(pageWidth, yPos),
    );
    yPos += 10;

    final totalAmount = records.fold<double>(
      0,
      (sum, row) => sum + row.payment.amount,
    );
    final statsData = [
      ['Total Records', '${records.length}'],
      ['Total Amount', 'Rs.${NumberFormat('#,##,###', 'en_IN').format(totalAmount)}'],
    ];

    final statWidth = pageWidth / statsData.length;
    for (var i = 0; i < statsData.length; i++) {
      final x = i * statWidth;
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(
          i == 0 ? PdfColor(30, 64, 175) : PdfColor(243, 244, 246),
        ),
        bounds: Rect.fromLTWH(x, yPos, statWidth - 4, 32),
      );
      page.graphics.drawString(
        statsData[i][1],
        PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(
          i == 0 ? PdfColor(255, 255, 255) : PdfColor(30, 64, 175),
        ),
        bounds: Rect.fromLTWH(x + 6, yPos + 2, statWidth - 8, 16),
      );
      page.graphics.drawString(
        statsData[i][0],
        PdfStandardFont(PdfFontFamily.helvetica, 7),
        brush: PdfSolidBrush(
          i == 0 ? PdfColor(200, 220, 255) : PdfColor(100, 100, 100),
        ),
        bounds: Rect.fromLTWH(x + 6, yPos + 18, statWidth - 8, 10),
      );
    }
    yPos += 44;

    drawTableHeader(page, yPos);
    yPos += 18;

    const colWidths = [105.0, 35.0, 75.0, 50.0, 62.0, 48.0, 90.0, 90.0];

    for (var rowIdx = 0; rowIdx < records.length; rowIdx++) {
      final record = records[rowIdx];
      final payment = record.payment;
      final app = record.application;
      final rowData = [
        app?.fullName ?? '-',
        app?.proposedCapacity.toStringAsFixed(1) ?? '-',
        app?.mobile ?? '-',
        NumberFormat('#,##,###', 'en_IN').format(payment.amount),
        DateFormat('dd MMM yyyy').format(payment.paymentDate),
        payment.paymentMode.name.toUpperCase(),
        (payment.transactionNumber?.trim().isNotEmpty ?? false)
            ? payment.transactionNumber!
            : '-',
        payment.collectedBy ?? '-',
      ];

      const rowH = 16.0;
      if (rowIdx % 2 == 0) {
        page.graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(239, 246, 255)),
          bounds: Rect.fromLTWH(0, yPos, pageWidth, rowH),
        );
      }

      double xPos = 0;
      for (var col = 0; col < rowData.length; col++) {
        page.graphics.drawString(
          rowData[col],
          cellFont,
          bounds: Rect.fromLTWH(xPos + 2, yPos + 2, colWidths[col] - 4, 12),
        );
        xPos += colWidths[col];
      }

      page.graphics.drawLine(
        PdfPen(PdfColor(220, 220, 220)),
        Offset(0, yPos + rowH),
        Offset(pageWidth, yPos + rowH),
      );
      yPos += rowH;

      if (yPos > page.getClientSize().height - 30 &&
          rowIdx < records.length - 1) {
        page = document.pages.add();
        yPos = 0;
        drawTableHeader(page, yPos);
        yPos += 18;
      }
    }

    final lastPage = document.pages[document.pages.count - 1];
    lastPage.graphics.drawString(
      '© ${now.year} ${AppConstants.companyName} | Confidential MIS Report',
      PdfStandardFont(PdfFontFamily.helvetica, 7),
      brush: PdfSolidBrush(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(
        0,
        lastPage.getClientSize().height - 14,
        pageWidth,
        12,
      ),
    );

    final bytes = document.saveSync();
    document.dispose();

    final fileName =
        'payment_records_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Payment PDF Report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = File(result);
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment PDF exported: $fileName'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
