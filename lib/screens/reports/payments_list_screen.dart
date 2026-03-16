import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: paymentsAsync.when(
                  data: (payments) => payments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(64),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.payments_outlined, size: 48, color: Color(0xFFE2E8F0)),
                                SizedBox(height: 16),
                                Text('No payments recorded yet', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: const BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.cardRadius), topRight: Radius.circular(AppTheme.cardRadius)),
                                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 1, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                  Expanded(flex: 2, child: Text('APPLICATION #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                  Expanded(flex: 1, child: Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                  Expanded(flex: 1, child: Text('MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                  Expanded(flex: 2, child: Text('TRANSACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                  Expanded(flex: 1, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                  SizedBox(width: 48),
                                ],
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: payments.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                              itemBuilder: (context, index) {
                                final p = payments[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 1, child: Text(DateFormat('dd MMM yyyy').format(p.paymentDate), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                                      Expanded(flex: 2, child: Text(p.applicationId.substring(0, 8), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor))),
                                      Expanded(flex: 1, child: Text(p.paymentType.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 1, child: Text(p.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 2, child: Text(p.transactionNumber ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '₹${NumberFormat('#,##,###', 'en_IN').format(p.amount)}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                          onPressed: () => context.go('/applications/${p.applicationId}'),
                                          style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor.withOpacity(0.05), foregroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                  loading: () => const Padding(padding: EdgeInsets.all(64), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => const Padding(padding: EdgeInsets.all(64), child: Center(child: Text('Error loading payments'))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              SizedBox(height: 4),
              Text(
                'Manage and track all client transaction history',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => context.go('/reports'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 20),
            label: const Text('View Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
