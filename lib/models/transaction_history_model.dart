class TransactionHistory {
  final int id;
  final String transactionNumber;
  final int totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final int itemsCount;
  final String createdAt;

  TransactionHistory({
    required this.id,
    required this.transactionNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    return TransactionHistory(
      id: json['id'],
      transactionNumber: json['transaction_number'],
      totalAmount: json['total_amount'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      status: json['status'],
      itemsCount: json['items_count'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_number': transactionNumber,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': status,
      'items_count': itemsCount,
      'created_at': createdAt,
    };
  }

  String get formattedPaymentMethod {
    return paymentMethod
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
