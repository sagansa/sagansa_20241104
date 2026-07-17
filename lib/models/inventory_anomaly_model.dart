import 'package:flutter/material.dart';

enum AnomalyStatus {
  cocok,
  selisih,
  noSoData,
  noStockData;

  static AnomalyStatus fromString(String? s) {
    return switch (s) {
      'cocok' => AnomalyStatus.cocok,
      'selisih' => AnomalyStatus.selisih,
      'no_so_data' => AnomalyStatus.noSoData,
      'no_stock_data' => AnomalyStatus.noStockData,
      _ => AnomalyStatus.selisih,
    };
  }

  String get label => switch (this) {
        AnomalyStatus.cocok => 'Cocok',
        AnomalyStatus.selisih => 'Selisih',
        AnomalyStatus.noSoData => 'No Data SO',
        AnomalyStatus.noStockData => 'No Data Stok',
      };

  Color get color => switch (this) {
        AnomalyStatus.cocok => const Color(0xFF2E7D32),
        AnomalyStatus.selisih => const Color(0xFFC62828),
        AnomalyStatus.noSoData => const Color(0xFF616161),
        AnomalyStatus.noStockData => const Color(0xFFF9A825),
      };
}

class InventoryAnomalyItem {
  final int productId;
  final String? productName;
  final String? unit;
  final int soldQty;
  final int? stockBefore;
  final int? stockAfter;
  final int? stockDiff;
  final int? delta;
  final AnomalyStatus status;

  const InventoryAnomalyItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.soldQty,
    required this.stockBefore,
    required this.stockAfter,
    required this.stockDiff,
    required this.delta,
    required this.status,
  });

  factory InventoryAnomalyItem.fromJson(Map<String, dynamic> j) {
    return InventoryAnomalyItem(
      productId: (j['product_id'] as num).toInt(),
      productName: j['product_name'] as String?,
      unit: j['unit'] as String?,
      soldQty: (j['sold_qty'] as num? ?? 0).toInt(),
      stockBefore: (j['stock_before'] as num?)?.toInt(),
      stockAfter: (j['stock_after'] as num?)?.toInt(),
      stockDiff: (j['stock_diff'] as num?)?.toInt(),
      delta: (j['delta'] as num?)?.toInt(),
      status: AnomalyStatus.fromString(j['status'] as String?),
    );
  }

  int? get stockOut =>
      stockDiff != null ? (stockDiff! < 0 ? stockDiff!.abs() : 0) : null;
}

class InventoryAnomalySummary {
  final int productsCompared;
  final int matchCount;
  final int mismatchCount;
  final int noSoDataCount;
  final int noStockDataCount;
  final int totalSoldQty;
  final int totalStockOutQty;

  const InventoryAnomalySummary({
    required this.productsCompared,
    required this.matchCount,
    required this.mismatchCount,
    required this.noSoDataCount,
    required this.noStockDataCount,
    required this.totalSoldQty,
    required this.totalStockOutQty,
  });

  factory InventoryAnomalySummary.fromJson(Map<String, dynamic> j) {
    return InventoryAnomalySummary(
      productsCompared: (j['products_compared'] as num? ?? 0).toInt(),
      matchCount: (j['match_count'] as num? ?? 0).toInt(),
      mismatchCount: (j['mismatch_count'] as num? ?? 0).toInt(),
      noSoDataCount: (j['no_so_data_count'] as num? ?? 0).toInt(),
      noStockDataCount: (j['no_stock_data_count'] as num? ?? 0).toInt(),
      totalSoldQty: (j['total_sold_qty'] as num? ?? 0).toInt(),
      totalStockOutQty: (j['total_stock_out_qty'] as num? ?? 0).toInt(),
    );
  }
}

class InventoryAnomalyPeriod {
  final String dateFrom;
  final String dateTo;
  final List<int> storeIds;

  const InventoryAnomalyPeriod({
    required this.dateFrom,
    required this.dateTo,
    required this.storeIds,
  });

  factory InventoryAnomalyPeriod.fromJson(Map<String, dynamic> j) {
    return InventoryAnomalyPeriod(
      dateFrom: j['date_from'] as String? ?? '',
      dateTo: j['date_to'] as String? ?? '',
      storeIds: (j['store_ids'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

class InventoryAnomalyMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const InventoryAnomalyMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory InventoryAnomalyMeta.fromJson(Map<String, dynamic> j) {
    return InventoryAnomalyMeta(
      currentPage: (j['current_page'] as num? ?? 1).toInt(),
      lastPage: (j['last_page'] as num? ?? 1).toInt(),
      perPage: (j['per_page'] as num? ?? 50).toInt(),
      total: (j['total'] as num? ?? 0).toInt(),
    );
  }

  bool get hasMore => currentPage < lastPage;
}

class InventoryAnomalyResponse {
  final InventoryAnomalyPeriod period;
  final InventoryAnomalySummary summary;
  final List<InventoryAnomalyItem> items;
  final InventoryAnomalyMeta meta;

  const InventoryAnomalyResponse({
    required this.period,
    required this.summary,
    required this.items,
    required this.meta,
  });

  factory InventoryAnomalyResponse.fromJson(Map<String, dynamic> body) {
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return InventoryAnomalyResponse(
      period: InventoryAnomalyPeriod.fromJson(
          (data['period'] as Map<String, dynamic>?) ?? const {}),
      summary: InventoryAnomalySummary.fromJson(
          (data['summary'] as Map<String, dynamic>?) ?? const {}),
      items: ((data['items'] as List<dynamic>?) ?? const [])
          .map((e) => InventoryAnomalyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: InventoryAnomalyMeta.fromJson(
          (body['meta'] as Map<String, dynamic>?) ?? const {}),
    );
  }
}
