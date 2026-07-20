import 'dart:io';
import 'dart:typed_data';

import '../models/sales_order_online_model.dart';
import '../models/store_model.dart';
import 'api_client.dart';
import 'image_upload_service.dart';

class SalesOrderService {
  final ApiClient _api = ApiClient();

  /// Daftar produk yang bisa dijual online.
  Future<List<SalesOrderOnlineProduct>> getOnlineProducts() async {
    final data = await _api.get('sales-orders/online-products');
    final list = data as List;
    return list.map((e) => SalesOrderOnlineProduct.fromJson(e)).toList();
  }

  /// Daftar online shop provider (Shopee, Tokopedia, dll).
  Future<List<OnlineShopProvider>> getOnlineShopProviders() async {
    final data = await _api.get('sales-orders/online-shop-providers');
    final list = data as List;
    return list.map((e) => OnlineShopProvider.fromJson(e)).toList();
  }

  /// Daftar delivery service (JNE, SiCepat, dll).
  Future<List<DeliveryServiceOption>> getDeliveryServices() async {
    final data = await _api.get('sales-orders/delivery-services');
    final list = data as List;
    return list.map((e) => DeliveryServiceOption.fromJson(e)).toList();
  }

  /// Buat sales order online.
  /// [items] sebagai JSON string (karena multipart form tidak support nested array
  /// secara native — dikirim sebagai field string lalu di-decode backend).
  Future<void> createOnlineOrder({
    required Store selectedStore,
    required String deliveryDate,
    required int onlineShopProviderId,
    required int deliveryServiceId,
    required String receiptNo,
    required List<SalesOrderItemRequest> items,
    File? imagePayment,
    Uint8List? imagePaymentBytes,
  }) async {
    final fields = <String, String>{
      'store_id': selectedStore.id.toString(),
      'delivery_date': deliveryDate,
      'online_shop_provider_id': onlineShopProviderId.toString(),
      'delivery_service_id': deliveryServiceId.toString(),
      'receipt_no': receiptNo,
    };

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      fields['items[$i][product_id]'] = item.productId.toString();
      fields['items[$i][quantity]'] = item.quantity.toString();
      fields['items[$i][unit_price]'] = item.unitPrice.toString();
    }

    if (imagePayment != null) {
      final path =
          await ImageUploadService.upload(imagePayment, directory: 'images/SalesOrder');
      if (path == null) throw Exception('Gagal upload bukti pembayaran.');
      fields['image_payment'] = path;
    } else if (imagePaymentBytes != null) {
      final path = await ImageUploadService.uploadBytes(
        imagePaymentBytes,
        'payment.jpg',
        directory: 'images/SalesOrder',
      );
      if (path == null) throw Exception('Gagal upload bukti pembayaran.');
      fields['image_payment'] = path;
    }

    await _api.multipart(
      method: 'POST',
      path: 'sales-orders/online',
      fields: fields,
    );
  }
}
