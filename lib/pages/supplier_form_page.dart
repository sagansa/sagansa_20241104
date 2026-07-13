import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/image_utils.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';

class SupplierFormPage extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _service = SupplierService();

  // Text controllers
  final _nameCtrl = TextEditingController();
  final _noTelpCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  final _bankAccountNoCtrl = TextEditingController();
  final _qrisCtrl = TextEditingController();

  // Address dropdowns
  List<ProvinceModel> _provinces = [];
  List<CityModel> _cities = [];
  List<DistrictModel> _districts = [];
  List<SubdistrictModel> _subdistricts = [];
  List<PostalCodeModel> _postalCodes = [];
  List<BankModel> _banks = [];

  ProvinceModel? _selectedProvince;
  CityModel? _selectedCity;
  DistrictModel? _selectedDistrict;
  SubdistrictModel? _selectedSubdistrict;
  PostalCodeModel? _selectedPostalCode;
  BankModel? _selectedBank;

  bool _isLoadingLookups = true;
  bool _isLoadingCities = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingSubdistricts = false;
  bool _isLoadingPostalCodes = false;
  bool _isSaving = false;

  File? _pickedImage;
  final _imagePicker = ImagePicker();

  bool get isEditing => widget.supplier != null;

  // QRIS state
  bool _qrisValidating = false;
  String? _qrisMerchantName;
  String? _qrisNmid;

  @override
  void initState() {
    super.initState();
    _initForm();
    _loadLookups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noTelpCtrl.dispose();
    _addressCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _bankAccountNoCtrl.dispose();
    _qrisCtrl.dispose();
    super.dispose();
  }

  void _initForm() {
    final s = widget.supplier;
    if (s != null) {
      _nameCtrl.text = s.name;
      _noTelpCtrl.text = s.noTelp ?? '';
      _addressCtrl.text = s.address ?? '';
      _bankAccountNameCtrl.text = s.bankAccountName ?? '';
      _bankAccountNoCtrl.text = s.bankAccountNo ?? '';
      _qrisCtrl.text = s.qris ?? '';
    }
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final results = await Future.wait([
        _service.getProvinces(),
        _service.getBanks(),
      ]);
      _provinces = results[0] as List<ProvinceModel>;
      _banks = results[1] as List<BankModel>;

      final s = widget.supplier;
      if (s != null) {
        // Restore selected bank
        if (s.bankId != null) {
          _selectedBank = _banks.where((b) => b.id == s.bankId).firstOrNull;
        }
        // Restore province and cascade
        if (s.provinceId != null) {
          _selectedProvince = _provinces.where((p) => p.id == s.provinceId).firstOrNull;
          if (_selectedProvince != null) await _loadCities(s.provinceId!, preselect: s.cityId);
          if (_selectedCity != null && s.districtId != null) {
            await _loadDistricts(s.cityId!, preselect: s.districtId);
          }
          if (_selectedDistrict != null && s.subdistrictId != null) {
            await _loadSubdistricts(s.districtId!, preselect: s.subdistrictId);
          }
          if (_selectedSubdistrict != null && s.postalCodeId != null) {
            await _loadPostalCodes(s.subdistrictId!, preselect: s.postalCodeId);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _loadCities(int provinceId, {int? preselect}) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
      _districts = [];
      _selectedDistrict = null;
      _subdistricts = [];
      _selectedSubdistrict = null;
      _postalCodes = [];
      _selectedPostalCode = null;
    });
    try {
      final cities = await _service.getCities(provinceId);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        if (preselect != null) {
          _selectedCity = cities.where((c) => c.id == preselect).firstOrNull;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _loadDistricts(int cityId, {int? preselect}) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _subdistricts = [];
      _selectedSubdistrict = null;
      _postalCodes = [];
      _selectedPostalCode = null;
    });
    try {
      final districts = await _service.getDistricts(cityId);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        if (preselect != null) {
          _selectedDistrict = districts.where((d) => d.id == preselect).firstOrNull;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _loadSubdistricts(int districtId, {int? preselect}) async {
    setState(() {
      _isLoadingSubdistricts = true;
      _subdistricts = [];
      _selectedSubdistrict = null;
      _postalCodes = [];
      _selectedPostalCode = null;
    });
    try {
      final subs = await _service.getSubdistricts(districtId);
      if (!mounted) return;
      setState(() {
        _subdistricts = subs;
        if (preselect != null) {
          _selectedSubdistrict = subs.where((s) => s.id == preselect).firstOrNull;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingSubdistricts = false);
    }
  }

  Future<void> _loadPostalCodes(int subdistrictId, {int? preselect}) async {
    setState(() {
      _isLoadingPostalCodes = true;
      _postalCodes = [];
      _selectedPostalCode = null;
    });
    try {
      final pcs = await _service.getPostalCodes(subdistrictId);
      if (!mounted) return;
      setState(() {
        _postalCodes = pcs;
        if (preselect != null) {
          _selectedPostalCode = pcs.where((p) => p.id == preselect).firstOrNull;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingPostalCodes = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked != null) {
      final compressed = await ImageUtils.compressToWebP(picked.path);
      if (mounted) setState(() => _pickedImage = compressed);
    }
  }

  Future<void> _validateQrisInput() async {
    final qrisText = _qrisCtrl.text.trim();
    if (qrisText.isEmpty) {
      setState(() {
        _qrisMerchantName = null;
        _qrisNmid = null;
      });
      return;
    }

    if (widget.supplier == null) return;

    setState(() {
      _qrisValidating = true;
      _qrisMerchantName = null;
      _qrisNmid = null;
    });

    try {
      final result = await _service.validateQris(widget.supplier!.id, qrisText);
      if (mounted) {
        setState(() {
          _qrisMerchantName = result['merchant_name'] as String?;
          _qrisNmid = result['merchant_nmid'] as String?;
          _qrisValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _qrisValidating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QRIS tidak valid: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provinsi dan Kota harus diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'no_telp': _noTelpCtrl.text.trim().isEmpty ? null : _noTelpCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'province_id': _selectedProvince!.id,
      'city_id': _selectedCity!.id,
      if (_selectedDistrict != null) 'district_id': _selectedDistrict!.id,
      if (_selectedSubdistrict != null) 'subdistrict_id': _selectedSubdistrict!.id,
      if (_selectedPostalCode != null) 'postal_code_id': _selectedPostalCode!.id,
      if (_selectedBank != null) 'bank_id': _selectedBank!.id,
      'bank_account_name': _bankAccountNameCtrl.text.trim().isEmpty
          ? null
          : _bankAccountNameCtrl.text.trim(),
      'bank_account_no': _bankAccountNoCtrl.text.trim().isEmpty
          ? null
          : _bankAccountNoCtrl.text.trim(),
      'qris': _qrisCtrl.text.trim().isEmpty ? null : _qrisCtrl.text.trim(),
    };

    try {
      if (isEditing) {
        await _service.updateSupplier(widget.supplier!.id, data, image: _pickedImage);
      } else {
        await _service.createSupplier(data, image: _pickedImage);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Supplier berhasil diperbarui.'
              : 'Supplier berhasil ditambahkan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Supplier' : 'Tambah Supplier'),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _submit,
              child: Text(
                'Simpan',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.paddingMD,
                children: [
                  // Image picker
                  _buildImagePicker(colorScheme),
                  AppSpacing.gapVerticalLG,

                  _buildSectionTitle('Informasi Dasar', theme),
                  _buildCard(
                    colorScheme: colorScheme,
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Nama Supplier *',
                        hint: 'Nama supplier',
                        icon: Icons.store_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      _buildDivider(colorScheme),
                      _buildTextField(
                        controller: _noTelpCtrl,
                        label: 'No. Telepon',
                        hint: '08xxxxxxxx',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalMD,

                  _buildSectionTitle('Rekening Bank', theme),
                  _buildCard(
                    colorScheme: colorScheme,
                    children: [
                      _buildDropdown<BankModel>(
                        label: 'Bank',
                        hint: 'Pilih bank (opsional)',
                        icon: Icons.account_balance_rounded,
                        value: _selectedBank,
                        items: _banks,
                        itemLabel: (b) => b.name,
                        onChanged: (val) => setState(() => _selectedBank = val),
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      _buildDivider(colorScheme),
                      _buildTextField(
                        controller: _bankAccountNameCtrl,
                        label: 'Nama Pemilik Rekening',
                        hint: 'Nama sesuai rekening bank',
                        icon: Icons.person_rounded,
                      ),
                      _buildDivider(colorScheme),
                      _buildTextField(
                        controller: _bankAccountNoCtrl,
                        label: 'Nomor Rekening',
                        hint: 'Nomor rekening',
                        icon: Icons.credit_card_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalMD,

                  _buildSectionTitle('QRIS', theme),
                  _buildCard(
                    colorScheme: colorScheme,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                              child: TextFormField(
                                controller: _qrisCtrl,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: 'QRIS Payload',
                                  hintText: 'Tempel hasil scan QRIS supplier',
                                  prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                                ),
                                onChanged: (_) => _validateQrisInput(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: IconButton(
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              tooltip: 'Scan QRIS',
                              onPressed: () async {
                                final scanned = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const _QrisScannerPage(),
                                  ),
                                );
                                if (scanned != null && mounted) {
                                  _qrisCtrl.text = scanned;
                                  _validateQrisInput();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_qrisValidating)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              AppSpacing.gapHorizontalSM,
                              Text('Memvalidasi QRIS...', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      if (_qrisMerchantName != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 0),
                              AppSpacing.gapVerticalSM,
                              Text(
                                'Merchant: $_qrisMerchantName',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (_qrisNmid != null)
                                Text(
                                  'NMID: $_qrisNmid',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.gapVerticalMD,

                  _buildSectionTitle('Alamat *', theme),
                  _buildCard(
                    colorScheme: colorScheme,
                    children: [
                      _buildTextField(
                        controller: _addressCtrl,
                        label: 'Alamat Lengkap *',
                        hint: 'Jalan, nomor, RT/RW, dll.',
                        icon: Icons.home_rounded,
                        maxLines: 3,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
                      ),
                      _buildDivider(colorScheme),
                      _buildDropdown<ProvinceModel>(
                        label: 'Provinsi *',
                        hint: 'Pilih provinsi',
                        icon: Icons.flag_rounded,
                        value: _selectedProvince,
                        items: _provinces,
                        itemLabel: (p) => p.name,
                        onChanged: (val) async {
                          setState(() => _selectedProvince = val);
                          if (val != null) await _loadCities(val.id);
                        },
                        colorScheme: colorScheme,
                        theme: theme,
                        isRequired: true,
                      ),
                      _buildDivider(colorScheme),
                      _buildDropdown<CityModel>(
                        label: 'Kota/Kabupaten *',
                        hint: _selectedProvince == null
                            ? 'Pilih provinsi dulu'
                            : (_isLoadingCities ? 'Memuat...' : 'Pilih kota'),
                        icon: Icons.location_on_rounded,
                        value: _selectedCity,
                        items: _cities,
                        itemLabel: (c) => c.name,
                        onChanged: _selectedProvince == null
                            ? null
                            : (val) async {
                                setState(() => _selectedCity = val);
                                if (val != null) await _loadDistricts(val.id);
                              },
                        colorScheme: colorScheme,
                        theme: theme,
                        isRequired: true,
                        isLoading: _isLoadingCities,
                      ),
                      _buildDivider(colorScheme),
                      _buildDropdown<DistrictModel>(
                        label: 'Kecamatan',
                        hint: _selectedCity == null
                            ? 'Pilih kota dulu'
                            : (_isLoadingDistricts ? 'Memuat...' : 'Pilih kecamatan'),
                        icon: Icons.map_rounded,
                        value: _selectedDistrict,
                        items: _districts,
                        itemLabel: (d) => d.name,
                        onChanged: _selectedCity == null
                            ? null
                            : (val) async {
                                setState(() => _selectedDistrict = val);
                                if (val != null) await _loadSubdistricts(val.id);
                              },
                        colorScheme: colorScheme,
                        theme: theme,
                        isLoading: _isLoadingDistricts,
                      ),
                      _buildDivider(colorScheme),
                      _buildDropdown<SubdistrictModel>(
                        label: 'Kelurahan',
                        hint: _selectedDistrict == null
                            ? 'Pilih kecamatan dulu'
                            : (_isLoadingSubdistricts ? 'Memuat...' : 'Pilih kelurahan'),
                        icon: Icons.location_city_rounded,
                        value: _selectedSubdistrict,
                        items: _subdistricts,
                        itemLabel: (s) => s.name,
                        onChanged: _selectedDistrict == null
                            ? null
                            : (val) async {
                                setState(() => _selectedSubdistrict = val);
                                if (val != null) await _loadPostalCodes(val.id);
                              },
                        colorScheme: colorScheme,
                        theme: theme,
                        isLoading: _isLoadingSubdistricts,
                      ),
                      _buildDivider(colorScheme),
                      _buildDropdown<PostalCodeModel>(
                        label: 'Kode Pos',
                        hint: _selectedSubdistrict == null
                            ? 'Pilih kelurahan dulu'
                            : (_isLoadingPostalCodes ? 'Memuat...' : 'Pilih kode pos'),
                        icon: Icons.markunread_mailbox_rounded,
                        value: _selectedPostalCode,
                        items: _postalCodes,
                        itemLabel: (p) => p.postalCode,
                        onChanged: _selectedSubdistrict == null
                            ? null
                            : (val) => setState(() => _selectedPostalCode = val),
                        colorScheme: colorScheme,
                        theme: theme,
                        isLoading: _isLoadingPostalCodes,
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalXL,

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5),
                            )
                          : Text(
                              isEditing ? 'Simpan Perubahan' : 'Tambah Supplier',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                  AppSpacing.gapVerticalXL,
                ],
              ),
            ),
    );
  }

  Widget _buildImagePicker(ColorScheme colorScheme) {
    final hasImage = _pickedImage != null;
    final existingImageUrl = widget.supplier?.image;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusLG,
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_pickedImage!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        borderRadius: AppSpacing.borderRadiusXL,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 13, color: colorScheme.surface),
                          AppSpacing.gapHorizontalXS,
                          Text('Ganti Foto',
                              style: TextStyle(
                                  color: colorScheme.surface, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : existingImageUrl != null && existingImageUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        '${ApiConstants.baseUrl}/media/$existingImageUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildImagePlaceholder(colorScheme),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                            borderRadius: AppSpacing.borderRadiusXL,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 13, color: colorScheme.surface),
                              AppSpacing.gapHorizontalXS,
                              Text('Ganti Foto',
                                  style: TextStyle(
                                      color: colorScheme.surface,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildImagePlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: colorScheme.primary,
        ),
        AppSpacing.gapVerticalSM,
        Text(
          'Tambah Foto Supplier',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.gapVerticalXS,
        Text(
          'Opsional',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCard({
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 0,
      indent: 48,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?>? onChanged,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isRequired = false,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: isLoading
          ? Row(
              children: [
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.md),
                Text(hint,
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14)),
              ],
            )
          : DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(hint,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14)),
                  ),
                ],
              ),
              decoration: InputDecoration(
                isDense: true,
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(itemLabel(item),
                            overflow: TextOverflow.ellipsis, maxLines: 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              validator: isRequired
                  ? (v) => v == null ? '$label wajib dipilih' : null
                  : null,
            ),
    );
  }
}

/// Full-screen QRIS scanner page.
class _QrisScannerPage extends StatefulWidget {
  const _QrisScannerPage();

  @override
  State<_QrisScannerPage> createState() => _QrisScannerPageState();
}

class _QrisScannerPageState extends State<_QrisScannerPage> {
  MobileScannerController? _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      _hasScanned = true;
      Navigator.pop(context, barcode.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QRIS Supplier'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller!,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => _controller!.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.surface, width: 2),
                borderRadius: AppSpacing.borderRadiusLG,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QRIS supplier',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.surface.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
