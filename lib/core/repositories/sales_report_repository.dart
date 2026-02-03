import 'dart:developer' as developer;
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_app/core/error/failure.dart';

/// Sales report data model
class SalesReportData {
  final String storeName;
  final String storeId;
  final String invoiceNumbers;
  final int totalBills;
  final double myAmount;
  final double totalDiscount;
  final double netSales;
  final double deliveryCharge;
  final double containerCharge;
  final double serviceCharge;
  final double additionalCharge;
  final double totalTax;
  final double roundOff;
  final double waivedOff;
  final double totalSales;
  final double onlineTaxCalculated;
  final double gstPaidByMerchant;
  final double gstPaidByEcommerce;
  final double cash;
  final double card;
  final double duePayment;
  final double other;
  final double wallet;
  final double online;
  final int pax;
  final String? dataSynced;

  const SalesReportData({
    required this.storeName,
    required this.storeId,
    this.invoiceNumbers = '',
    this.totalBills = 0,
    this.myAmount = 0,
    this.totalDiscount = 0,
    this.netSales = 0,
    this.deliveryCharge = 0,
    this.containerCharge = 0,
    this.serviceCharge = 0,
    this.additionalCharge = 0,
    this.totalTax = 0,
    this.roundOff = 0,
    this.waivedOff = 0,
    this.totalSales = 0,
    this.onlineTaxCalculated = 0,
    this.gstPaidByMerchant = 0,
    this.gstPaidByEcommerce = 0,
    this.cash = 0,
    this.card = 0,
    this.duePayment = 0,
    this.other = 0,
    this.wallet = 0,
    this.online = 0,
    this.pax = 0,
    this.dataSynced,
  });

  factory SalesReportData.fromJson(Map<String, dynamic> json) {
    return SalesReportData(
      storeName: json['store_name'] as String? ?? 'Unknown',
      storeId: json['store_id'] as String? ?? '',
      invoiceNumbers: json['invoice_numbers'] as String? ?? '',
      totalBills: json['total_bills'] as int? ?? 0,
      myAmount: (json['my_amount'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0,
      netSales: (json['net_sales'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
      containerCharge: (json['container_charge'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['service_charge'] as num?)?.toDouble() ?? 0,
      additionalCharge: (json['additional_charge'] as num?)?.toDouble() ?? 0,
      totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0,
      roundOff: (json['round_off'] as num?)?.toDouble() ?? 0,
      waivedOff: (json['waived_off'] as num?)?.toDouble() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      onlineTaxCalculated:
          (json['online_tax_calculated'] as num?)?.toDouble() ?? 0,
      gstPaidByMerchant:
          (json['gst_paid_by_merchant'] as num?)?.toDouble() ?? 0,
      gstPaidByEcommerce:
          (json['gst_paid_by_ecommerce'] as num?)?.toDouble() ?? 0,
      cash: (json['cash'] as num?)?.toDouble() ?? 0,
      card: (json['card'] as num?)?.toDouble() ?? 0,
      duePayment: (json['due_payment'] as num?)?.toDouble() ?? 0,
      other: (json['other'] as num?)?.toDouble() ?? 0,
      wallet: (json['wallet'] as num?)?.toDouble() ?? 0,
      online: (json['online'] as num?)?.toDouble() ?? 0,
      pax: json['pax'] as int? ?? 0,
      dataSynced: json['data_synced'] as String?,
    );
  }
}

/// Sales report summary
class SalesReportSummaryData {
  final int total;
  final int min;
  final int max;
  final int avg;
  final double myAmount;
  final double totalDiscount;
  final double netSales;
  final double deliveryCharge;
  final double containerCharge;
  final double serviceCharge;
  final double additionalCharge;
  final double totalTax;
  final double roundOff;
  final double waivedOff;
  final double totalSales;
  final double onlineTaxCalculated;
  final double gstPaidByMerchant;
  final double gstPaidByEcommerce;
  final double cash;
  final double card;
  final double duePayment;
  final double other;
  final double wallet;
  final double online;
  final int pax;

  const SalesReportSummaryData({
    this.total = 0,
    this.min = 0,
    this.max = 0,
    this.avg = 0,
    this.myAmount = 0,
    this.totalDiscount = 0,
    this.netSales = 0,
    this.deliveryCharge = 0,
    this.containerCharge = 0,
    this.serviceCharge = 0,
    this.additionalCharge = 0,
    this.totalTax = 0,
    this.roundOff = 0,
    this.waivedOff = 0,
    this.totalSales = 0,
    this.onlineTaxCalculated = 0,
    this.gstPaidByMerchant = 0,
    this.gstPaidByEcommerce = 0,
    this.cash = 0,
    this.card = 0,
    this.duePayment = 0,
    this.other = 0,
    this.wallet = 0,
    this.online = 0,
    this.pax = 0,
  });

  factory SalesReportSummaryData.fromReportData(List<SalesReportData> data) {
    if (data.isEmpty) {
      return const SalesReportSummaryData();
    }

    final bills = data.map((d) => d.totalBills).toList();
    final totalBills = bills.fold(0, (sum, b) => sum + b);
    final minBills = bills.reduce((a, b) => a < b ? a : b);
    final maxBills = bills.reduce((a, b) => a > b ? a : b);

    return SalesReportSummaryData(
      total: totalBills,
      min: minBills,
      max: maxBills,
      avg: data.isNotEmpty ? totalBills ~/ data.length : 0,
      myAmount: data.fold(0.0, (sum, d) => sum + d.myAmount),
      totalDiscount: data.fold(0.0, (sum, d) => sum + d.totalDiscount),
      netSales: data.fold(0.0, (sum, d) => sum + d.netSales),
      deliveryCharge: data.fold(0.0, (sum, d) => sum + d.deliveryCharge),
      containerCharge: data.fold(0.0, (sum, d) => sum + d.containerCharge),
      serviceCharge: data.fold(0.0, (sum, d) => sum + d.serviceCharge),
      additionalCharge: data.fold(0.0, (sum, d) => sum + d.additionalCharge),
      totalTax: data.fold(0.0, (sum, d) => sum + d.totalTax),
      roundOff: data.fold(0.0, (sum, d) => sum + d.roundOff),
      waivedOff: data.fold(0.0, (sum, d) => sum + d.waivedOff),
      totalSales: data.fold(0.0, (sum, d) => sum + d.totalSales),
      onlineTaxCalculated: data.fold(
        0.0,
        (sum, d) => sum + d.onlineTaxCalculated,
      ),
      gstPaidByMerchant: data.fold(0.0, (sum, d) => sum + d.gstPaidByMerchant),
      gstPaidByEcommerce: data.fold(
        0.0,
        (sum, d) => sum + d.gstPaidByEcommerce,
      ),
      cash: data.fold(0.0, (sum, d) => sum + d.cash),
      card: data.fold(0.0, (sum, d) => sum + d.card),
      duePayment: data.fold(0.0, (sum, d) => sum + d.duePayment),
      other: data.fold(0.0, (sum, d) => sum + d.other),
      wallet: data.fold(0.0, (sum, d) => sum + d.wallet),
      online: data.fold(0.0, (sum, d) => sum + d.online),
      pax: data.fold(0, (sum, d) => sum + d.pax),
    );
  }
}

/// Repository for sales reports
abstract class SalesReportRepository {
  Future<Either<Failure, List<SalesReportData>>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    String? storeId,
    String? status,
  });
}

/// Supabase implementation of SalesReportRepository
class SalesReportRepositoryImpl implements SalesReportRepository {
  final SupabaseClient _client;

  SalesReportRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<SalesReportData>>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    String? storeId,
    String? status,
  }) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      developer.log(
        'SalesReportRepo: Fetching sales report from $startDateStr to $endDateStr, storeId=$storeId',
        name: 'SalesReportRepo',
      );

      // Query orders grouped by store
      var query = _client
          .from('orders')
          .select('''
            store_id,
            stores!inner(name),
            order_number,
            total_amount,
            tax_amount,
            discount_amount,
            payment_method,
            status,
            created_at
          ''')
          .gte('created_at', '${startDateStr}T00:00:00')
          .lte('created_at', '${endDateStr}T23:59:59');

      if (storeId != null && storeId.isNotEmpty) {
        query = query.eq('store_id', storeId);
      }

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at');

      developer.log(
        'SalesReportRepo: Got ${(response as List).length} orders',
        name: 'SalesReportRepo',
      );

      // Group orders by store
      final storeOrders = <String, List<Map<String, dynamic>>>{};
      for (final order in response) {
        final sid = order['store_id'] as String;
        storeOrders.putIfAbsent(sid, () => []).add(order);
      }

      // Calculate sales data per store
      final salesData = <SalesReportData>[];
      for (final entry in storeOrders.entries) {
        final orders = entry.value;
        if (orders.isEmpty) continue;

        final storeName =
            orders.first['stores']['name'] as String? ?? 'Unknown';

        // Get invoice number range
        final orderNumbers = orders
            .map((o) => o['order_number'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        final invoiceRange = orderNumbers.isNotEmpty
            ? '${orderNumbers.first}-${orderNumbers.last}'
            : '';

        // Calculate totals
        double totalSales = 0;
        double totalTax = 0;
        double totalDiscount = 0;
        double cash = 0;
        double card = 0;
        double upi = 0;
        double online = 0;

        for (final order in orders) {
          final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
          final tax = (order['tax_amount'] as num?)?.toDouble() ?? 0;
          final discount = (order['discount_amount'] as num?)?.toDouble() ?? 0;
          final paymentMethod = order['payment_method'] as String? ?? '';

          totalSales += amount;
          totalTax += tax;
          totalDiscount += discount;

          switch (paymentMethod.toLowerCase()) {
            case 'cash':
              cash += amount;
              break;
            case 'card':
              card += amount;
              break;
            case 'upi':
              upi += amount;
              break;
            case 'online':
              online += amount;
              break;
          }
        }

        final lastSynced = orders.isNotEmpty
            ? orders.last['created_at'] as String?
            : null;

        salesData.add(
          SalesReportData(
            storeName: storeName,
            storeId: entry.key,
            invoiceNumbers: invoiceRange,
            totalBills: orders.length,
            myAmount: totalSales - totalTax,
            totalDiscount: totalDiscount,
            netSales: totalSales - totalTax - totalDiscount,
            totalTax: totalTax,
            totalSales: totalSales,
            cash: cash,
            card: card,
            online: online + upi,
            dataSynced: lastSynced,
          ),
        );
      }

      developer.log(
        'SalesReportRepo: Returning ${salesData.length} store reports',
        name: 'SalesReportRepo',
      );

      return right(salesData);
    } on PostgrestException catch (e) {
      developer.log(
        'SalesReportRepo: PostgrestException - ${e.message}',
        name: 'SalesReportRepo',
      );
      return left(DatabaseFailure(message: e.message, code: e.code));
    } catch (e) {
      developer.log('SalesReportRepo: Exception - $e', name: 'SalesReportRepo');
      return left(Failure(message: 'Failed to fetch sales report: $e'));
    }
  }
}
