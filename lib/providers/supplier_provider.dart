import 'dart:io';

import 'package:flutter/material.dart';

import '../models/supplier_model.dart';
import '../services/supplier_service.dart';

@immutable
class SupplierListState {
  final List<SupplierModel> suppliers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final int? selectedStatus;
  final String searchQuery;
  final bool hasSearched;
  final bool isSearchVisible;

  const SupplierListState({
    this.suppliers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.errorMessage,
    this.selectedStatus,
    this.searchQuery = '',
    this.hasSearched = false,
    this.isSearchVisible = false,
  });

  SupplierListState copyWith({
    List<SupplierModel>? suppliers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    int? selectedStatus,
    bool clearStatus = false,
    String? searchQuery,
    bool? hasSearched,
    bool? isSearchVisible,
  }) {
    return SupplierListState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      hasSearched: hasSearched ?? this.hasSearched,
      isSearchVisible: isSearchVisible ?? this.isSearchVisible,
    );
  }

  int get activeFilterCount => selectedStatus != null ? 1 : 0;
}

@immutable
class SupplierDetailState {
  final SupplierModel? supplier;
  final bool isLoading;
  final String? errorMessage;

  const SupplierDetailState({
    this.supplier,
    this.isLoading = false,
    this.errorMessage,
  });

  SupplierDetailState copyWith({
    SupplierModel? supplier,
    bool clearSupplier = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupplierDetailState(
      supplier: clearSupplier ? null : (supplier ?? this.supplier),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@immutable
class SupplierFormState {
  final List<ProvinceModel> provinces;
  final List<CityModel> cities;
  final List<DistrictModel> districts;
  final List<SubdistrictModel> subdistricts;
  final List<PostalCodeModel> postalCodes;
  final List<BankModel> banks;

  final ProvinceModel? selectedProvince;
  final CityModel? selectedCity;
  final DistrictModel? selectedDistrict;
  final SubdistrictModel? selectedSubdistrict;
  final PostalCodeModel? selectedPostalCode;
  final BankModel? selectedBank;

  final bool isLoadingLookups;
  final bool isLoadingCities;
  final bool isLoadingDistricts;
  final bool isLoadingSubdistricts;
  final bool isLoadingPostalCodes;
  final bool isSaving;

  final String? lookupErrorMessage;

  final bool qrisValidating;
  final String? qrisMerchantName;
  final String? qrisNmid;

  final File? pickedImage;

  const SupplierFormState({
    this.provinces = const [],
    this.cities = const [],
    this.districts = const [],
    this.subdistricts = const [],
    this.postalCodes = const [],
    this.banks = const [],
    this.selectedProvince,
    this.selectedCity,
    this.selectedDistrict,
    this.selectedSubdistrict,
    this.selectedPostalCode,
    this.selectedBank,
    this.isLoadingLookups = true,
    this.isLoadingCities = false,
    this.isLoadingDistricts = false,
    this.isLoadingSubdistricts = false,
    this.isLoadingPostalCodes = false,
    this.isSaving = false,
    this.lookupErrorMessage,
    this.qrisValidating = false,
    this.qrisMerchantName,
    this.qrisNmid,
    this.pickedImage,
  });

  SupplierFormState copyWith({
    List<ProvinceModel>? provinces,
    List<CityModel>? cities,
    List<DistrictModel>? districts,
    List<SubdistrictModel>? subdistricts,
    List<PostalCodeModel>? postalCodes,
    List<BankModel>? banks,
    ProvinceModel? selectedProvince,
    bool clearProvince = false,
    CityModel? selectedCity,
    bool clearCity = false,
    DistrictModel? selectedDistrict,
    bool clearDistrict = false,
    SubdistrictModel? selectedSubdistrict,
    bool clearSubdistrict = false,
    PostalCodeModel? selectedPostalCode,
    bool clearPostalCode = false,
    BankModel? selectedBank,
    bool clearBank = false,
    bool? isLoadingLookups,
    bool? isLoadingCities,
    bool? isLoadingDistricts,
    bool? isLoadingSubdistricts,
    bool? isLoadingPostalCodes,
    bool? isSaving,
    String? lookupErrorMessage,
    bool clearLookupError = false,
    bool? qrisValidating,
    String? qrisMerchantName,
    bool clearQrisMerchant = false,
    String? qrisNmid,
    bool clearQrisNmid = false,
    File? pickedImage,
    bool clearImage = false,
  }) {
    return SupplierFormState(
      provinces: provinces ?? this.provinces,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      subdistricts: subdistricts ?? this.subdistricts,
      postalCodes: postalCodes ?? this.postalCodes,
      banks: banks ?? this.banks,
      selectedProvince: clearProvince
          ? null
          : (selectedProvince ?? this.selectedProvince),
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      selectedDistrict: clearDistrict
          ? null
          : (selectedDistrict ?? this.selectedDistrict),
      selectedSubdistrict: clearSubdistrict
          ? null
          : (selectedSubdistrict ?? this.selectedSubdistrict),
      selectedPostalCode: clearPostalCode
          ? null
          : (selectedPostalCode ?? this.selectedPostalCode),
      selectedBank: clearBank ? null : (selectedBank ?? this.selectedBank),
      isLoadingLookups: isLoadingLookups ?? this.isLoadingLookups,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingDistricts: isLoadingDistricts ?? this.isLoadingDistricts,
      isLoadingSubdistricts: isLoadingSubdistricts ?? this.isLoadingSubdistricts,
      isLoadingPostalCodes: isLoadingPostalCodes ?? this.isLoadingPostalCodes,
      isSaving: isSaving ?? this.isSaving,
      lookupErrorMessage: clearLookupError
          ? null
          : (lookupErrorMessage ?? this.lookupErrorMessage),
      qrisValidating: qrisValidating ?? this.qrisValidating,
      qrisMerchantName: clearQrisMerchant
          ? null
          : (qrisMerchantName ?? this.qrisMerchantName),
      qrisNmid: clearQrisNmid ? null : (qrisNmid ?? this.qrisNmid),
      pickedImage: clearImage ? null : (pickedImage ?? this.pickedImage),
    );
  }
}

class SupplierProvider extends ChangeNotifier {
  final SupplierService _service = SupplierService();

  /// Supplier yang sedang diedit (mode edit form) — null saat mode tambah.
  final SupplierModel? editingSupplier;

  final ScrollController scrollController = ScrollController();

  // Text controllers untuk form.
  final nameController = TextEditingController();
  final noTelpController = TextEditingController();
  final addressController = TextEditingController();
  final bankAccountNameController = TextEditingController();
  final bankAccountNoController = TextEditingController();
  final qrisController = TextEditingController();

  SupplierListState _list = const SupplierListState();
  SupplierDetailState _detail = const SupplierDetailState();
  SupplierFormState _form = const SupplierFormState();

  SupplierProvider({this.editingSupplier}) {
    scrollController.addListener(_onScroll);
    if (editingSupplier != null) {
      _initControllers(editingSupplier!);
    }
  }

  SupplierListState get list => _list;
  SupplierDetailState get detail => _detail;
  SupplierFormState get form => _form;

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    nameController.dispose();
    noTelpController.dispose();
    addressController.dispose();
    bankAccountNameController.dispose();
    bankAccountNoController.dispose();
    qrisController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !_list.isLoadingMore &&
        _list.hasMore) {
      loadMore();
    }
  }

  // -------------------------------------------------------------------------
  // List actions
  // -------------------------------------------------------------------------

  Future<void> loadInitialSuppliers() async {
    if (_list.searchQuery.isEmpty && _list.selectedStatus == null) {
      _list = _list.copyWith(
        suppliers: const [],
        hasSearched: false,
        clearError: true,
        page: 1,
      );
      notifyListeners();
      return;
    }

    _list = _list.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      suppliers: const [],
      hasMore: true,
    );
    notifyListeners();

    try {
      final result = await _service.getSuppliersPaged(
        page: 1,
        search: _list.searchQuery.isEmpty ? null : _list.searchQuery,
        status: _list.selectedStatus,
      );
      _list = _list.copyWith(
        suppliers: result['data'] as List<SupplierModel>,
        hasMore: result['has_more'] as bool,
        isLoading: false,
        hasSearched: true,
      );
    } catch (e) {
      _list = _list.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        hasSearched: true,
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_list.isLoadingMore || !_list.hasMore) return;
    _list = _list.copyWith(isLoadingMore: true);
    notifyListeners();

    try {
      final result = await _service.getSuppliersPaged(
        page: _list.page + 1,
        search: _list.searchQuery.isEmpty ? null : _list.searchQuery,
        status: _list.selectedStatus,
      );
      _list = _list.copyWith(
        page: _list.page + 1,
        suppliers: [
          ..._list.suppliers,
          ...(result['data'] as List<SupplierModel>),
        ],
        hasMore: result['has_more'] as bool,
        isLoadingMore: false,
      );
    } catch (_) {
      _list = _list.copyWith(isLoadingMore: false);
    }
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _list = _list.copyWith(searchQuery: query);
    notifyListeners();
    if (query.length >= 3 || query.isEmpty) {
      await loadInitialSuppliers();
    }
  }

  Future<void> clearSearch() async {
    _list = _list.copyWith(
      searchQuery: '',
      suppliers: const [],
      hasSearched: false,
      page: 1,
    );
    notifyListeners();
  }

  void setSearchVisible(bool visible) {
    _list = _list.copyWith(isSearchVisible: visible);
    notifyListeners();
  }

  void closeSearch() {
    _list = _list.copyWith(
      isSearchVisible: false,
      searchQuery: '',
      suppliers: const [],
      hasSearched: false,
      page: 1,
    );
    notifyListeners();
  }

  Future<void> setStatusFilter(int? status) async {
    _list = _list.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    notifyListeners();
    await loadInitialSuppliers();
  }

  // -------------------------------------------------------------------------
  // Detail actions
  // -------------------------------------------------------------------------

  Future<void> fetchDetail(int id) async {
    _detail = _detail.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final data = await _service.getSupplier(id);
      _detail = _detail.copyWith(supplier: data, isLoading: false);
    } catch (e) {
      _detail = _detail.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
    }
    notifyListeners();
  }

  Future<void> deleteSupplier(int id) async {
    await _service.deleteSupplier(id);
  }

  // -------------------------------------------------------------------------
  // Form actions
  // -------------------------------------------------------------------------

  void _initControllers(SupplierModel s) {
    nameController.text = s.name;
    noTelpController.text = s.noTelp ?? '';
    addressController.text = s.address ?? '';
    bankAccountNameController.text = s.bankAccountName ?? '';
    bankAccountNoController.text = s.bankAccountNo ?? '';
    qrisController.text = s.qris ?? '';
  }

  Future<void> loadLookups() async {
    _form = _form.copyWith(isLoadingLookups: true, clearLookupError: true);
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getProvinces(),
        _service.getBanks(),
      ]);
      _form = _form.copyWith(
        provinces: results[0] as List<ProvinceModel>,
        banks: results[1] as List<BankModel>,
      );
      notifyListeners();

      // Mode edit: restore pilihan yang sudah ada (bank + cascade alamat).
      final s = editingSupplier;
      if (s != null) {
        if (s.bankId != null) {
          setSelectedBank(
              _form.banks.where((b) => b.id == s.bankId).firstOrNull);
        }
        if (s.provinceId != null) {
          setSelectedProvince(
              _form.provinces.where((p) => p.id == s.provinceId).firstOrNull);
          if (_form.selectedCity != null && s.districtId != null) {
            await loadDistricts(_form.selectedCity!.id, preselect: s.districtId);
          }
          if (_form.selectedDistrict != null && s.subdistrictId != null) {
            await loadSubdistricts(_form.selectedDistrict!.id,
                preselect: s.subdistrictId);
          }
          if (_form.selectedSubdistrict != null && s.postalCodeId != null) {
            await loadPostalCodes(_form.selectedSubdistrict!.id,
                preselect: s.postalCodeId);
          }
        }
      }
    } catch (e) {
      _form = _form.copyWith(
        lookupErrorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      _form = _form.copyWith(isLoadingLookups: false);
      notifyListeners();
    }
  }

  Future<void> loadCities(int provinceId, {int? preselect}) async {
    _form = _form.copyWith(isLoadingCities: true);
    notifyListeners();

    try {
      final cities = await _service.getCities(provinceId);
      final next = preselect != null
          ? cities.where((c) => c.id == preselect).firstOrNull
          : _form.selectedCity;
      _form = _form.copyWith(
        cities: cities,
        selectedCity: next,
        clearCity: preselect != null && next == null,
        isLoadingCities: false,
      );
    } catch (_) {
      _form = _form.copyWith(isLoadingCities: false);
    }
    notifyListeners();
  }

  Future<void> loadDistricts(int cityId, {int? preselect}) async {
    _form = _form.copyWith(isLoadingDistricts: true);
    notifyListeners();

    try {
      final districts = await _service.getDistricts(cityId);
      final next = preselect != null
          ? districts.where((d) => d.id == preselect).firstOrNull
          : _form.selectedDistrict;
      _form = _form.copyWith(
        districts: districts,
        selectedDistrict: next,
        clearDistrict: preselect != null && next == null,
        isLoadingDistricts: false,
      );
    } catch (_) {
      _form = _form.copyWith(isLoadingDistricts: false);
    }
    notifyListeners();
  }

  Future<void> loadSubdistricts(int districtId, {int? preselect}) async {
    _form = _form.copyWith(isLoadingSubdistricts: true);
    notifyListeners();

    try {
      final subs = await _service.getSubdistricts(districtId);
      final next = preselect != null
          ? subs.where((s) => s.id == preselect).firstOrNull
          : _form.selectedSubdistrict;
      _form = _form.copyWith(
        subdistricts: subs,
        selectedSubdistrict: next,
        clearSubdistrict: preselect != null && next == null,
        isLoadingSubdistricts: false,
      );
    } catch (_) {
      _form = _form.copyWith(isLoadingSubdistricts: false);
    }
    notifyListeners();
  }

  Future<void> loadPostalCodes(int subdistrictId, {int? preselect}) async {
    _form = _form.copyWith(isLoadingPostalCodes: true);
    notifyListeners();

    try {
      final pcs = await _service.getPostalCodes(subdistrictId);
      final next = preselect != null
          ? pcs.where((p) => p.id == preselect).firstOrNull
          : _form.selectedPostalCode;
      _form = _form.copyWith(
        postalCodes: pcs,
        selectedPostalCode: next,
        clearPostalCode: preselect != null && next == null,
        isLoadingPostalCodes: false,
      );
    } catch (_) {
      _form = _form.copyWith(isLoadingPostalCodes: false);
    }
    notifyListeners();
  }

  void setSelectedBank(BankModel? bank) {
    _form = _form.copyWith(
      selectedBank: bank,
      clearBank: bank == null,
    );
    notifyListeners();
  }

  Future<void> setSelectedProvince(ProvinceModel? province) async {
    _form = _form.copyWith(
      selectedProvince: province,
      clearProvince: province == null,
      cities: const [],
      districts: const [],
      subdistricts: const [],
      postalCodes: const [],
      clearCity: true,
      clearDistrict: true,
      clearSubdistrict: true,
      clearPostalCode: true,
    );
    notifyListeners();
    if (province != null) {
      await loadCities(province.id);
    }
  }

  Future<void> setSelectedCity(CityModel? city) async {
    _form = _form.copyWith(
      selectedCity: city,
      clearCity: city == null,
      districts: const [],
      subdistricts: const [],
      postalCodes: const [],
      clearDistrict: true,
      clearSubdistrict: true,
      clearPostalCode: true,
    );
    notifyListeners();
    if (city != null) {
      await loadDistricts(city.id);
    }
  }

  Future<void> setSelectedDistrict(DistrictModel? district) async {
    _form = _form.copyWith(
      selectedDistrict: district,
      clearDistrict: district == null,
      subdistricts: const [],
      postalCodes: const [],
      clearSubdistrict: true,
      clearPostalCode: true,
    );
    notifyListeners();
    if (district != null) {
      await loadSubdistricts(district.id);
    }
  }

  Future<void> setSelectedSubdistrict(SubdistrictModel? subdistrict) async {
    _form = _form.copyWith(
      selectedSubdistrict: subdistrict,
      clearSubdistrict: subdistrict == null,
      postalCodes: const [],
      clearPostalCode: true,
    );
    notifyListeners();
    if (subdistrict != null) {
      await loadPostalCodes(subdistrict.id);
    }
  }

  void setSelectedPostalCode(PostalCodeModel? postalCode) {
    _form = _form.copyWith(
      selectedPostalCode: postalCode,
      clearPostalCode: postalCode == null,
    );
    notifyListeners();
  }

  void setPickedImage(File? file) {
    _form = _form.copyWith(
      pickedImage: file,
      clearImage: file == null,
    );
    notifyListeners();
  }

  Future<void> validateQris() async {
    final qrisText = qrisController.text.trim();
    if (qrisText.isEmpty) {
      _form = _form.copyWith(
        qrisValidating: false,
        clearQrisMerchant: true,
        clearQrisNmid: true,
      );
      notifyListeners();
      return;
    }

    if (editingSupplier == null) return;

    _form = _form.copyWith(
      qrisValidating: true,
      clearQrisMerchant: true,
      clearQrisNmid: true,
    );
    notifyListeners();

    try {
      final result = await _service.validateQris(editingSupplier!.id, qrisText);
      _form = _form.copyWith(
        qrisMerchantName: result['merchant_name'] as String?,
        qrisNmid: result['merchant_nmid'] as String?,
        qrisValidating: false,
      );
      notifyListeners();
    } catch (e) {
      _form = _form.copyWith(qrisValidating: false);
      notifyListeners();
      rethrow;
    }
  }

  Map<String, dynamic> buildPayload() {
    return {
      'name': nameController.text.trim(),
      'no_telp': noTelpController.text.trim().isEmpty
          ? null
          : noTelpController.text.trim(),
      'address': addressController.text.trim(),
      'province_id': _form.selectedProvince!.id,
      'city_id': _form.selectedCity!.id,
      if (_form.selectedDistrict != null)
        'district_id': _form.selectedDistrict!.id,
      if (_form.selectedSubdistrict != null)
        'subdistrict_id': _form.selectedSubdistrict!.id,
      if (_form.selectedPostalCode != null)
        'postal_code_id': _form.selectedPostalCode!.id,
      if (_form.selectedBank != null) 'bank_id': _form.selectedBank!.id,
      'bank_account_name': bankAccountNameController.text.trim().isEmpty
          ? null
          : bankAccountNameController.text.trim(),
      'bank_account_no': bankAccountNoController.text.trim().isEmpty
          ? null
          : bankAccountNoController.text.trim(),
      'qris': qrisController.text.trim().isEmpty
          ? null
          : qrisController.text.trim(),
    };
  }

  Future<void> submitCreate(Map<String, dynamic> data, {File? image}) async {
    _form = _form.copyWith(isSaving: true);
    notifyListeners();
    try {
      await _service.createSupplier(data, image: image);
    } finally {
      _form = _form.copyWith(isSaving: false);
      notifyListeners();
    }
  }

  Future<void> submitUpdate(int id, Map<String, dynamic> data,
      {File? image}) async {
    _form = _form.copyWith(isSaving: true);
    notifyListeners();
    try {
      await _service.updateSupplier(id, data, image: image);
    } finally {
      _form = _form.copyWith(isSaving: false);
      notifyListeners();
    }
  }
}
