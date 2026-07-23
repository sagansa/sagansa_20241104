enum OrderMode {
  direct('1'),
  online('3');

  final String apiValue;
  const OrderMode(this.apiValue);

  static OrderMode fromApi(String? value) {
    return switch (value) {
      '1' => OrderMode.direct,
      '3' => OrderMode.online,
      _ => OrderMode.online,
    };
  }

  bool get isDirect => this == OrderMode.direct;
  bool get isOnline => this == OrderMode.online;

  String get label => switch (this) {
        OrderMode.direct => 'DIRECT',
        OrderMode.online => 'ONLINE',
      };

  String get title => switch (this) {
        OrderMode.direct => 'PENGIRIMAN DIRECT',
        OrderMode.online => 'PENGIRIMAN ONLINE',
      };

  String get detailTitle => switch (this) {
        OrderMode.direct => 'DETAIL PENGIRIMAN DIRECT',
        OrderMode.online => 'DETAIL PENGIRIMAN ONLINE',
      };
}
