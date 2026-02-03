/// Model class for restaurant sales data
class RestaurantSalesData {
  final String restaurantName;
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
  final String dataSynced;

  const RestaurantSalesData({
    required this.restaurantName,
    required this.invoiceNumbers,
    required this.totalBills,
    this.myAmount = 0.0,
    this.totalDiscount = 0.0,
    this.netSales = 0.0,
    this.deliveryCharge = 0.0,
    this.containerCharge = 0.0,
    this.serviceCharge = 0.0,
    this.additionalCharge = 0.0,
    this.totalTax = 0.0,
    this.roundOff = 0.0,
    this.waivedOff = 0.0,
    this.totalSales = 0.0,
    this.onlineTaxCalculated = 0.0,
    this.gstPaidByMerchant = 0.0,
    this.gstPaidByEcommerce = 0.0,
    this.cash = 0.0,
    this.card = 0.0,
    this.duePayment = 0.0,
    this.other = 0.0,
    this.wallet = 0.0,
    this.online = 0.0,
    this.pax = 0,
    this.dataSynced = '',
  });
}

/// Summary statistics for sales report
class SalesReportSummary {
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

  const SalesReportSummary({
    required this.total,
    required this.min,
    required this.max,
    required this.avg,
    this.myAmount = 0.0,
    this.totalDiscount = 0.0,
    this.netSales = 0.0,
    this.deliveryCharge = 0.0,
    this.containerCharge = 0.0,
    this.serviceCharge = 0.0,
    this.additionalCharge = 0.0,
    this.totalTax = 0.0,
    this.roundOff = 0.0,
    this.waivedOff = 0.0,
    this.totalSales = 0.0,
    this.onlineTaxCalculated = 0.0,
    this.gstPaidByMerchant = 0.0,
    this.gstPaidByEcommerce = 0.0,
    this.cash = 0.0,
    this.card = 0.0,
    this.duePayment = 0.0,
    this.other = 0.0,
    this.wallet = 0.0,
    this.online = 0.0,
    this.pax = 0,
  });
}

/// Order status options
enum OrderStatus {
  success('Success'),
  cancelled('Cancelled'),
  complimentary('Complimentary'),
  salesReturn('Sales Return'),
  all('All');

  final String displayName;
  const OrderStatus(this.displayName);
}

/// Restaurant filter model
class RestaurantFilter {
  final String id;
  final String name;
  final bool isSelected;

  const RestaurantFilter({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  RestaurantFilter copyWith({String? id, String? name, bool? isSelected}) {
    return RestaurantFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Column visibility option
class ColumnOption {
  final String id;
  final String displayName;
  final bool isVisible;

  const ColumnOption({
    required this.id,
    required this.displayName,
    this.isVisible = true,
  });

  ColumnOption copyWith({String? id, String? displayName, bool? isVisible}) {
    return ColumnOption(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  static List<ColumnOption> getDefaultColumns() {
    return [
      const ColumnOption(id: 'invoice_nos', displayName: 'Invoice Nos.'),
      const ColumnOption(id: 'total_bills', displayName: 'Total no. of bills'),
      const ColumnOption(id: 'my_amount', displayName: 'My Amount'),
      const ColumnOption(id: 'total_discount', displayName: 'Total Discount'),
      const ColumnOption(
        id: 'net_sales',
        displayName: 'Net Sales\n(M.A - T.D)',
      ),
      const ColumnOption(id: 'delivery_charge', displayName: 'Delivery Charge'),
      const ColumnOption(
        id: 'container_charge',
        displayName: 'Container Charge',
      ),
      const ColumnOption(id: 'service_charge', displayName: 'Service Charge'),
      const ColumnOption(
        id: 'additional_charge',
        displayName: 'Additional Charge',
      ),
      const ColumnOption(id: 'total_tax', displayName: 'Total Tax'),
      const ColumnOption(id: 'round_off', displayName: 'Round Off'),
      const ColumnOption(id: 'waived_off', displayName: 'Waived off'),
      const ColumnOption(id: 'total_sales', displayName: 'Total Sales'),
      const ColumnOption(
        id: 'online_tax',
        displayName: 'Online Tax Calculated',
      ),
      const ColumnOption(
        id: 'gst_merchant',
        displayName: 'GST Paid by Merchant',
      ),
      const ColumnOption(
        id: 'gst_ecommerce',
        displayName: 'GST Paid by Ecommerce',
      ),
      const ColumnOption(id: 'cash', displayName: 'Cash'),
      const ColumnOption(id: 'card', displayName: 'Card'),
      const ColumnOption(id: 'due_payment', displayName: 'Due Payment'),
      const ColumnOption(id: 'other', displayName: 'Other'),
      const ColumnOption(id: 'wallet', displayName: 'Wallet'),
      const ColumnOption(id: 'online', displayName: 'Online'),
      const ColumnOption(id: 'pax', displayName: 'Pax'),
      const ColumnOption(id: 'data_synced', displayName: 'Data Synced'),
    ];
  }
}
