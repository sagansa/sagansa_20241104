import 'package:intl/intl.dart';

class SalaryModel {
  final DateTime month;
  final int amount;
  final String paymentStatus;
  final DateTime? paymentDate;

  SalaryModel({
    required this.month,
    required this.amount,
    required this.paymentStatus,
    this.paymentDate,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      month: DateTime.parse(json['month']),
      amount: json['amount'],
      paymentStatus: json['payment_status'],
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
    );
  }

  String get formattedMonth {
    return DateFormat('MMMM yyyy').format(month);
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'amount': amount,
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }
}
