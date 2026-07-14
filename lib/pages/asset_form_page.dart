import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_utils.dart';
import '../controllers/asset_controller.dart';
import '../models/asset_category_model.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Form catat aset manual (off-catalog). Penambahan aset dari produk
/// (recommended) dilakukan via AssetFromProductPage — halaman ini hanya untuk
/// aset yang tidak ada di katalog produk.
class AssetFormPage extends StatefulWidget {
  const AssetFormPage({super.key, this.assetId, this.initialStoreId});

  final int? assetId;
  final int? initialStoreId;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  late AssetController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  List<AssetCategoryModel> _categories = [];
  List<StoreModel> _stores = [];

  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedStoreId;
  int _selectedCondition = 1; // default: baik
  int _selectedStatus = 1; // default: aktif
  final ImagePicker _picker = ImagePicker();
  File? _photo;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.initialStoreId;
    _controller = AssetController(context);
    _loadLookups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final storeService = StoreService();
      final results = await Future.wait<dynamic>([
        _controller.loadCategories(),
        storeService.getStores(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<AssetCategoryModel>;
        _stores = results[1] as List<StoreModel>;
        if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
        if (_selectedStoreId == null && _stores.isNotEmpty) {
          _selectedStoreId = _stores.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked != null) {
      final compressed = await ImageUtils.compressImage(picked.path);
      if (mounted) setState(() => _photo = compressed);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showError('Pilih kategori aset terlebih dahulu.');
      return;
    }
    if (_selectedStoreId == null) {
      _showError('Pilih toko terlebih dahulu.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _controller.saveAsset(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        assetCategoryId: _selectedCategoryId!,
        storeId: _selectedStoreId!,
        condition: _selectedCondition,
        status: _selectedStatus,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        photo: _photo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aset berhasil disimpan.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
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
        title: Text(widget.assetId == null ? 'Catat Aset (Manual)' : 'Edit Aset'),

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    // Banner info: utamakan product-driven.
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha:0.1),
                        borderRadius: AppSpacing.borderRadiusSM,
                        border: Border.all(
                            color: AppColors.info.withValues(alpha:0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.info, size: 18),
                          AppSpacing.gapHorizontalSM,
                          Expanded(
                            child: Text(
                              'Form ini untuk aset di luar katalog produk. '
                              'Untuk aset standar, gunakan "Tambah dari Produk" '
                              'agar konsisten antar toko.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
                            borderRadius: AppSpacing.borderRadiusLG,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: _photo != null
                              ? ClipRRect(
                            borderRadius: AppSpacing.borderRadiusLG,
                                  child: Image.file(_photo!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt,
                                        color: colorScheme.primary, size: 32),
                                    AppSpacing.gapVerticalXS,
                                    Text('Tambah Foto',
                                        style: theme.textTheme.bodySmall),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Aset *',
                        hintText: 'mis. AC Split Ruang Server',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kode Aset',
                        hintText: 'Kosongkan untuk auto-generate (mis. A-0012)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                    '${c.name} (${c.frequencyLabel})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedStoreId,
                      decoration: const InputDecoration(
                        labelText: 'Toko *',
                      ),
                      items: _stores
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nickname.isNotEmpty ? s.nickname : 'Store #${s.id}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStoreId = v),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    // Condition & status stacked vertically to avoid overflow.
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Kondisi',
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Baik')),
                        DropdownMenuItem(
                            value: 2, child: Text('Rusak Ringan')),
                        DropdownMenuItem(
                            value: 3, child: Text('Rusak Berat')),
                        DropdownMenuItem(value: 4, child: Text('Hilang')),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedCondition = v ?? 1),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Aktif')),
                        DropdownMenuItem(value: 2, child: Text('Dipelihara')),
                        DropdownMenuItem(value: 3, child: Text('Non-Aktif')),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedStatus = v ?? 1),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                      ),
                      maxLines: 3,
                    ),
                    AppSpacing.gapVerticalLG,
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Aset'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
