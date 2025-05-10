import 'transaction_history_model.dart';
import 'dart:convert';

class TransactionDetailResponse {
  final String status;
  final TransactionDetail data;

  TransactionDetailResponse({
    required this.status,
    required this.data,
  });

  factory TransactionDetailResponse.fromJson(Map<String, dynamic> json) {
    return TransactionDetailResponse(
      status: json['status'],
      data: TransactionDetail.fromJson(json['data']),
    );
  }
}

class TransactionDetail {
  final int id;
  final String transactionNumber;
  final CustomerInfo? customer;
  final StoreInfo? store;
  final List<TransactionItem> items;
  final int totalAmount;
  final int paidAmount;
  final int changeAmount;
  final int discount;
  final String paymentMethod;
  final String paymentStatus;
  final String createdAt;

  TransactionDetail({
    required this.id,
    required this.transactionNumber,
    this.customer,
    this.store,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.discount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'],
      transactionNumber: json['transaction_number'],
      customer: json['customer'] != null
          ? CustomerInfo.fromJson(json['customer'])
          : null,
      store: json['store'] != null ? StoreInfo.fromJson(json['store']) : null,
      items: (json['items'] as List)
          .map((item) => TransactionItem.fromJson(item))
          .toList(),
      totalAmount: json['total_amount'],
      paidAmount: json['paid_amount'],
      changeAmount: json['change_amount'],
      discount: json['discount'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      createdAt: json['created_at'],
    );
  }

  factory TransactionDetail.fromTransactionHistory(
      TransactionHistoryModel history) {
    return TransactionDetail(
      id: history.id,
      transactionNumber: history.transactionNumber,
      createdAt: history.createdAt,
      totalAmount: history.totalAmount,
      paymentMethod: history.paymentMethod,
      paymentStatus: history.status,
      items: [],
      paidAmount: history.totalAmount,
      changeAmount: 0,
      discount: 0,
    );
  }

  // Getter untuk format payment method
  String get formattedPaymentMethod => paymentMethod;

  // Getter untuk menghitung subtotal (total sebelum diskon)
  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  // Getter untuk menghitung total item
  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class CustomerInfo {
  final int id;
  final String name;
  final String noTelp;

  CustomerInfo({
    required this.id,
    required this.name,
    required this.noTelp,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'],
      name: json['name'],
      noTelp: json['no_telp'],
    );
  }
}

class StoreInfo {
  final int id;
  final String name;

  StoreInfo({
    required this.id,
    required this.name,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'],
      name: json['name'],
    );
  }
}

class TransactionItem {
  final int id;
  final String productName;
  final VariantInfo? variant;
  final List<ModifierInfo>? modifier;
  final String? notes;
  final int quantity;
  final int price;
  final int subtotal;

  TransactionItem({
    required this.id,
    required this.productName,
    this.variant,
    this.modifier,
    this.notes,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      productName: json['product_name'],
      variant: json['variant'] != null
          ? VariantInfo.fromJson(jsonDecode(json['variant']))
          : null,
      modifier: json['modifier'] != null
          ? (jsonDecode(json['modifier']) as List)
              .map((m) => ModifierInfo.fromJson(m))
              .toList()
          : null,
      notes: json['notes'],
      quantity: json['quantity'],
      price: json['price'],
      subtotal: json['subtotal'],
    );
  }
}

class VariantInfo {
  final int id;
  final String name;
  final int price;

  VariantInfo({
    required this.id,
    required this.name,
    required this.price,
  });

  factory VariantInfo.fromJson(Map<String, dynamic> json) {
    return VariantInfo(
      id: json['id'],
      name: json['name'],
      price: json['price'],
    );
  }
}

class ModifierInfo {
  final int id;
  final String name;
  final ModifierDetail detail;

  ModifierInfo({
    required this.id,
    required this.name,
    required this.detail,
  });

  factory ModifierInfo.fromJson(Map<String, dynamic> json) {
    return ModifierInfo(
      id: json['id'],
      name: json['name'],
      detail: ModifierDetail.fromJson(json['detail']),
    );
  }
}

class ModifierDetail {
  final int id;
  final String name;
  final int price;

  ModifierDetail({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ModifierDetail.fromJson(Map<String, dynamic> json) {
    return ModifierDetail(
      id: json['id'],
      name: json['name'],
      price: json['price'],
    );
  }
}
