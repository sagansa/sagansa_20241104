/// Semua endpoint API Sagansa, terpusat di satu tempat.
///
/// **Penggunaan:**
/// ```dart
/// final data = await _api.get(Endpoints.procurementRequests);
/// final detail = await _api.get(Endpoints.procurementRequestDetail(id));
/// ```
///
/// Konvensi:
/// - Static const untuk path tetap.
/// - Static method untuk path dengan parameter (mengembalikan String).
/// - Naming: camelCase, grouped by domain via komentar.
class Endpoints {
  Endpoints._();

  // === Auth ===
  static const String login = 'login';
  static const String logout = 'logout';
  static const String profile = 'profile';

  // === Admin ===
  static const String adminProfile = 'admin/profile';
  static String adminProfileDetail(int id) => 'admin/profile/$id';
  static const String adminLeaves = 'admin/leaves';

  // === Users & Roles ===
  static const String users = 'users';

  // === Presence ===
  static const String userPresence = 'user-presence';
  static const String presencesToday = 'presences/today';
  static const String presencesMonthly = 'presences/monthly';
  static const String presencesHistory = 'presences/history';
  static const String checkIn = 'check-in';
  static const String checkOut = 'check-out';

  // === Leaves ===
  static const String leaves = 'leaves';

  // === Salaries ===
  static const String salaries = 'salaries';
  static String salaryDetail(int id) => 'salaries/$id';
  static const String salaryEmployees = 'salaries/employees';

  // === Daily Salaries ===
  static const String dailySalaries = 'daily-salaries';
  static const String dailySalariesEmployees = 'daily-salaries/employees';
  static const String dailySalariesBulkUpdateStatus =
      'daily-salaries/bulk-update-status';

  // === Stores ===
  static const String stores = 'stores';
  static const String shiftStores = 'shift-stores';

  // === Calendar ===
  static const String calendar = 'calendar';

  // === Location & Device Tokens ===
  static const String locationPing = 'location';
  static const String deviceTokens = 'device-tokens';

  // === Storage Stocks ===
  static const String storageStocksTodayStatus = 'storage-stocks/today-status';
  static const String storageStocksMonitoring = 'storage-stocks/monitoring';
  static const String storageStocksProducts = 'storage-stocks/products';
  static String storageStockDetail(int id) => 'storage-stocks/$id';
  static const String storageStockCreate = 'storage-stocks';

  // === Transfer Stocks ===
  static String transferStockDetail(int id) => 'transfer-stocks/$id';
  static const String transferStockProducts = 'transfer-stocks/products';
  static const String transferStockCreate = 'transfer-stocks';

  // === Closing Stores ===
  static const String closingStores = 'closing-stores';
  static String closingStoreDetail(int id) => 'closing-stores/$id';
  static const String closingStoresActiveDraft = 'closing-stores/active-draft';
  static const String closingStoresSave = 'closing-stores/save';
  static const String closingStoresUnpaidTransactions =
      'closing-stores/unpaid-transactions';
  static const String closingStoresVehicles = 'closing-stores/vehicles';
  static const String closingStoresSuppliers = 'closing-stores/suppliers';
  static const String closingStoresFuelServices = 'closing-stores/fuel-services';
  static const String closingStoresFuelServicesForPayment =
      'closing-stores/fuel-services-for-payment';
  static const String closingStoresFuelServicesUsers =
      'closing-stores/fuel-services/users';

  // === Procurement ===
  static const String procurementProducts = 'procurement/products';
  static const String procurementRequests = 'procurement/requests';
  static String procurementRequestDetail(int id) => 'procurement/requests/$id';
  static String procurementRequestSave(int id) => 'procurement/requests/$id';
  static const String procurementDetailRequests = 'procurement/detail-requests';
  static String procurementApproveItem(int itemId) =>
      'procurement/requests/items/$itemId/approve';
  static String procurementRejectItem(int itemId) =>
      'procurement/requests/items/$itemId/reject';
  static const String procurementInvoices = 'procurement/invoices';
  static String procurementInvoiceDetail(int id) => 'procurement/invoices/$id';
  static const String procurementPaymentReceipts =
      'procurement/payment-receipts';
  static String procurementPaymentReceiptDetail(int id) =>
      'procurement/payment-receipts/$id';

  // === Recipes & Productions ===
  static const String recipes = 'recipes';
  static String recipeDetail(int id) => 'recipes/$id';
  static String recipesByProduct(int productId) => 'recipes/by-product/$productId';
  static const String productions = 'productions';

  // === Sales Orders (general) ===
  static const String salesOrderSearch = 'sales-orders/search';
  static const String salesOrderReadyToShip = 'sales-orders/ready-to-ship';
  static const String salesOrderMarkPrinted =
      'sales-orders/payment-proofs/printed';
  static const String salesOrderDeliveryUpdate = 'sales-orders/delivery-update';
  static const String salesOrderUpdatePaymentStatus =
      'sales-orders/update-payment-status';
  static const String salesOrderUpdateItems = 'sales-orders/update-items';

  // === Sales Orders Online (admin) ===
  static const String onlineShopProviders = 'sales-orders/online-shop-providers';
  static const String deliveryServices = 'sales-orders/delivery-services';
  static const String onlineProducts = 'sales-orders/online-products';
  static const String createSalesOrderOnline = 'sales-orders/online';

  // === Sales Orders Employee ===
  static const String salesOrderEmployee = 'sales-orders/employee';
  static String salesOrderEmployeeDetail(int id) => 'sales-orders/employee/$id';
  static const String salesOrderEmployeeSupportingData =
      'sales-orders/employee/supporting-data';

  // === Sales Dashboard ===
  static const String salesDashboard = 'sales-dashboard';

  // === Inventory Anomalies ===
  static const String compareInventoryAnomaly = 'inventory-anomalies/compare';

  // === Hygiene ===
  static const String hygiene = 'hygiene';
  static const String hygieneRooms = 'hygiene/rooms';
  static const String hygieneTodayStatus = 'hygiene/today-status';
  static const String hygieneOfRooms = 'hygiene/of-rooms';
  static String hygieneRoomUpdate(int id) => 'hygiene/of-rooms/$id';

  // === Assets ===
  static const String assetCategories = 'asset-categories';
  static const String assets = 'assets';
  static String assetDetail(int id) => 'assets/$id';
  static const String assetDashboard = 'assets/dashboard';
  static const String assetCurrentStore = 'assets/current-store';
  static const String assetFromProduct = 'assets/from-product';
  static const String assetProducts = 'asset-products';
  static const String assetIssues = 'asset-issues';
  static String assetIssueDetail(int id) => 'asset-issues/$id';

  // === Suppliers ===
  static const String suppliers = 'suppliers';
  static String supplierDetail(int id) => 'suppliers/$id';

  // === Utility Usages ===
  static const String utilities = 'utilities';
  static const String utilityUsages = 'utility-usages';
  static String utilityUsageDetail(int id) => 'utility-usages/$id';

  // === Regional (address) ===
  static const String provinces = 'provinces';
  static const String cities = 'cities';
  static const String districts = 'districts';
  static const String subdistricts = 'subdistricts';
  static const String postalCodes = 'postal-codes';

  // === Banks ===
  static const String banks = 'banks';

  // === App version ===
  static const String appVersion = 'app-version';
}
