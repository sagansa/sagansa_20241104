import 'package:flutter/material.dart';

import '../models/utility_model.dart';
import '../services/utility_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_container.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dropdown.dart';
import '../widgets/modern_text_form_field.dart';
import '../widgets/section_card.dart';

/// Form create/edit Utility (khusus admin/super_admin).
/// Edit bila [utility] diberikan; create bila null.
class UtilityFormPage extends StatefulWidget {
  final UtilityModel? utility;

  const UtilityFormPage({super.key, this.utility});

  @override
  State<UtilityFormPage> createState() => _UtilityFormPageState();
}

class _UtilityFormPageState extends State<UtilityFormPage> {
  final UtilityService _service = UtilityService();
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingLookups = true;
  String? _errorMessage;

  // Lookup data
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _providers = [];

  // Selections
  Map<String, dynamic>? _store;
  Map<String, dynamic>? _unit;
  Map<String, dynamic>? _provider;
  int? _prePost;
  int? _category;
  int _status = 1;

  bool get _isEditing => widget.utility != null;

  @override
  void initState() {
    super.initState();
    final u = widget.utility;
    if (u != null) {
      _numberController.text = u.number ?? '';
      _nameController.text = u.name ?? '';
      _prePost = u.prePost;
      _category = u.category;
      _status = u.status ?? 1;
    }
    _loadLookups();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final lookups = await _service.getLookups();
      if (!mounted) return;
      setState(() {
        _stores = lookups['stores'] ?? [];
        _units = lookups['units'] ?? [];
        _providers = lookups['utility_providers'] ?? [];

        // Prefill relasi saat edit (match by id).
        final u = widget.utility;
        if (u != null) {
          _store = _stores
              .where((s) => s['id'].toString() == u.storeId.toString())
              .firstOrNull;
          _unit = u.unit != null
              ? _units
                  .where((n) =>
                      n['unit'].toString() == u.unit.toString())
                  .firstOrNull
              : null;
          _provider = _providers
              .where((p) =>
                  p['id'].toString() == u.utilityProviderId.toString())
              .firstOrNull;
        }
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingLookups = false;
      });
    }
  }

  int _id(Map<String, dynamic> m) =>
      m['id'] is int ? m['id'] as int : int.parse(m['id'].toString());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_store == null || _unit == null || _provider == null ||
        _prePost == null || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lengkapi semua field yang wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'number': _numberController.text.trim(),
        'name': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'store_id': _id(_store!),
        'unit_id': _id(_unit!),
        'utility_provider_id': _id(_provider!),
        'pre_post': _prePost,
        'category': _category,
        'status': _status,
      };
      if (_isEditing) {
        await _service.updateUtility(widget.utility!.id, payload);
      } else {
        await _service.createUtility(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Utility' : 'Tambah Utility'),
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isLoadingLookups = true;
                            });
                            _loadLookups();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppSpacing.paddingMD,
                    children: [
                      SectionCard(
                        title: 'Informasi Utility',
                        icon: Icons.electrical_services_rounded,
                        child: Column(
                          children: [
                            ModernTextFormField(
                              labelText: 'Nomor Utility (Wajib)',
                              controller: _numberController,
                              prefixIcon:
                                  const Icon(Icons.numbers_rounded, size: 20),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Nomor wajib diisi'
                                      : null,
                            ),
                            AppSpacing.gapVerticalSM,
                            ModernTextFormField(
                              labelText: 'Nama (opsional)',
                              controller: _nameController,
                              prefixIcon:
                                  const Icon(Icons.label_outline_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                      SectionCard(
                        title: 'Relasi',
                        icon: Icons.link_rounded,
                        child: Column(
                          children: [
                            ModernDropdown<Map<String, dynamic>>(
                              labelText: 'Toko',
                              hint: 'Pilih toko...',
                              isRequired: true,
                              prefixIcon: const Icon(Icons.storefront_rounded,
                                  size: 20),
                              value: _store,
                              items: _stores,
                              getLabel: (s) =>
                                  s['nickname']?.toString() ??
                                  'Toko #${s['id']}',
                              onChanged: (v) => setState(() => _store = v),
                            ),
                            AppSpacing.gapVerticalSM,
                            ModernDropdown<Map<String, dynamic>>(
                              labelText: 'Provider',
                              hint: 'Pilih provider...',
                              isRequired: true,
                              prefixIcon:
                                  const Icon(Icons.cable_rounded, size: 20),
                              value: _provider,
                              items: _providers,
                              getLabel: (p) =>
                                  p['name']?.toString() ?? 'Provider #${p['id']}',
                              onChanged: (v) => setState(() => _provider = v),
                            ),
                            AppSpacing.gapVerticalSM,
                            ModernDropdown<Map<String, dynamic>>(
                              labelText: 'Satuan',
                              hint: 'Pilih satuan...',
                              isRequired: true,
                              prefixIcon: const Icon(Icons.straighten_rounded,
                                  size: 20),
                              value: _unit,
                              items: _units,
                              getLabel: (n) =>
                                  n['unit']?.toString() ?? 'Satuan #${n['id']}',
                              onChanged: (v) => setState(() => _unit = v),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                      SectionCard(
                        title: 'Klasifikasi',
                        icon: Icons.category_rounded,
                        child: Column(
                          children: [
                            ModernDropdown<int>(
                              labelText: 'Jenis',
                              hint: 'Listrik / Air / Internet',
                              isRequired: true,
                              prefixIcon: const Icon(Icons.bolt_rounded,
                                  size: 20),
                              value: _category,
                              items: const [1, 2, 3],
                              getLabel: (c) => c == 1
                                  ? 'Listrik'
                                  : c == 2
                                      ? 'Air'
                                      : 'Internet',
                              onChanged: (v) => setState(() => _category = v),
                            ),
                            AppSpacing.gapVerticalSM,
                            ModernDropdown<int>(
                              labelText: 'Pembayaran',
                              hint: 'Prabayar / Pascabayar',
                              isRequired: true,
                              prefixIcon: const Icon(Icons.payments_rounded,
                                  size: 20),
                              value: _prePost,
                              items: const [1, 2],
                              getLabel: (p) => p == 1 ? 'Prabayar' : 'Pascabayar',
                              onChanged: (v) => setState(() => _prePost = v),
                            ),
                            AppSpacing.gapVerticalSM,
                            ModernDropdown<int>(
                              labelText: 'Status',
                              hint: 'Aktif / Nonaktif',
                              isRequired: true,
                              prefixIcon: const Icon(Icons.toggle_on_rounded,
                                  size: 20),
                              value: _status,
                              items: const [1, 2],
                              getLabel: (s) => s == 1 ? 'Aktif' : 'Nonaktif',
                              onChanged: (v) =>
                                  setState(() => _status = v ?? 1),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalXL,
                    ],
                  ),
                ),
      bottomSheet: GlassContainer.bottomBar(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ModernButton(
          text: _isEditing ? 'Simpan Perubahan' : 'Buat Utility',
          onPressed: _isSaving ? null : _submit,
          isLoading: _isSaving,
          fullWidth: true,
        ),
      ),
    );
  }
}
