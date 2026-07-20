enum SalesPeriode {
  today,
  yesterday,
  month,
  year;

  String get apiValue => switch (this) {
        SalesPeriode.today => 'today',
        SalesPeriode.yesterday => 'yesterday',
        SalesPeriode.month => 'month',
        SalesPeriode.year => 'year',
      };

  String get label => switch (this) {
        SalesPeriode.today => 'Hari ini',
        SalesPeriode.yesterday => 'Kemarin',
        SalesPeriode.month => 'Bulan ini',
        SalesPeriode.year => 'Tahun ini',
      };

  String get expectedInterval => switch (this) {
        SalesPeriode.today => 'hour',
        SalesPeriode.yesterday => 'hour',
        SalesPeriode.month => 'day',
        SalesPeriode.year => 'month',
      };
}

enum SalesView { summary, trend, products, channels }

enum ProductSort { qty, revenue }

class SalesSummary {
  final String periodeLabel;
  final int omzet;
  final int orderCount;
  final int totalQty;
  // Pembanding periode natural (today↔kemarin, month↔bulan lalu paralel, dst).
  final int omzetPrev;
  final int orderCountPrev;
  final int totalQtyPrev;
  final String prevLabel;

  const SalesSummary({
    required this.periodeLabel,
    required this.omzet,
    required this.orderCount,
    required this.totalQty,
    required this.omzetPrev,
    required this.orderCountPrev,
    required this.totalQtyPrev,
    required this.prevLabel,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> j) => SalesSummary(
        periodeLabel: j['periode_label'] as String? ?? '',
        omzet: (j['omzet'] as num? ?? 0).toInt(),
        orderCount: (j['order_count'] as num? ?? 0).toInt(),
        totalQty: (j['total_qty'] as num? ?? 0).toInt(),
        omzetPrev: (j['omzet_prev'] as num? ?? 0).toInt(),
        orderCountPrev: (j['order_count_prev'] as num? ?? 0).toInt(),
        totalQtyPrev: (j['total_qty_prev'] as num? ?? 0).toInt(),
        prevLabel: j['prev_label'] as String? ?? '',
      );
}

class SalesTrendPoint {
  final String label;
  final int value;
  final int? valuePrev;

  const SalesTrendPoint({required this.label, required this.value, this.valuePrev});

  factory SalesTrendPoint.fromJson(Map<String, dynamic> j) => SalesTrendPoint(
        label: j['label'] as String? ?? '',
        value: (j['value'] as num? ?? 0).toInt(),
        valuePrev: (j['value_prev'] as num?)?.toInt(),
      );
}

class SalesProductItem {
  final int productId;
  final String? productName;
  final String? unit;
  final int qty;
  final int revenue;

  const SalesProductItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.revenue,
  });

  factory SalesProductItem.fromJson(Map<String, dynamic> j) => SalesProductItem(
        productId: (j['product_id'] as num).toInt(),
        productName: j['product_name'] as String?,
        unit: j['unit'] as String?,
        qty: (j['qty'] as num? ?? 0).toInt(),
        revenue: (j['revenue'] as num? ?? 0).toInt(),
      );
}

class SalesProductMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const SalesProductMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory SalesProductMeta.fromJson(Map<String, dynamic> j) => SalesProductMeta(
        currentPage: (j['current_page'] as num? ?? 1).toInt(),
        lastPage: (j['last_page'] as num? ?? 1).toInt(),
        perPage: (j['per_page'] as num? ?? 50).toInt(),
        total: (j['total'] as num? ?? 0).toInt(),
      );

  bool get hasMore => currentPage < lastPage;
}

class SalesChannelItem {
  final String channel;
  final String channelLabel;
  final int omzet;
  final int orderCount;
  final int qty;
  final double percentage;

  const SalesChannelItem({
    required this.channel,
    required this.channelLabel,
    required this.omzet,
    required this.orderCount,
    required this.qty,
    required this.percentage,
  });

  factory SalesChannelItem.fromJson(Map<String, dynamic> j) => SalesChannelItem(
        // `channel` bisa int (DB tinyint di production) atau string (test
        // factory). Normalisasi ke string agar switch _colorFor stabil.
        channel: (j['channel'] ?? '').toString(),
        channelLabel: j['channel_label'] as String? ?? '',
        omzet: (j['omzet'] as num? ?? 0).toInt(),
        orderCount: (j['order_count'] as num? ?? 0).toInt(),
        qty: (j['qty'] as num? ?? 0).toInt(),
        percentage: (j['percentage'] as num? ?? 0).toDouble(),
      );
}
