import 'package:flutter/material.dart';

import '../models/production_model.dart';
import '../models/store_model.dart';
import '../services/presence_service.dart';
import '../services/production_service.dart';
import '../services/recipe_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dropdown.dart';
import '../widgets/safe_bottom_bar.dart';

/// Form create produksi.
///
/// Workflow:
///   1. User pilih toko + tanggal + (opsional) resep dari master.
///   2. Submit → backend create production + auto-prefill items dari resep.
///   3. Setelah create, user lanjut ke ProductionDetailPage untuk atur qty
///      item (override default resep) & apply stok.
///
/// Pilih resep opsional — produksi tanpa resep berarti user akan input
/// ingredient manual di detail page.
class ProductionFormPage extends StatefulWidget {
  const ProductionFormPage({super.key});

  @override
  State<ProductionFormPage> createState() => _ProductionFormPageState();
}

class _ProductionFormPageState extends State<ProductionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductionService _prodService = ProductionService();
  final RecipeService _recipeService = RecipeService();

  final List<StoreModel> _stores = [];
  final List<Recipe> _recipes = [];

  int? _storeId;
  DateTime _date = DateTime.now();
  Recipe? _selectedRecipe;
  final _notesCtrl = TextEditingController();
  final String _status = '1';

  bool _loadingStores = true;
  bool _loadingRecipes = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
    _loadRecipes();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await PresenceService().getStores();
      if (!mounted) return;
      setState(() {
        _stores
          ..clear()
          ..addAll(stores);
        _loadingStores = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar toko: $e';
        _loadingStores = false;
      });
    }
  }

  Future<void> _loadRecipes() async {
    try {
      final result = await _recipeService.list(perPage: 100);
      if (!mounted) return;
      setState(() {
        _recipes
          ..clear()
          ..addAll(result.items);
        _loadingRecipes = false;
      });
    } catch (_) {
      // Resep opsional — abaikan kalau gagal load.
      if (mounted) setState(() => _loadingRecipes = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_storeId == null) {
      setState(() => _error = 'Pilih toko terlebih dahulu.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _prodService.create(
        storeId: _storeId!,
        date: _date,
        recipeId: _selectedRecipe?.id,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: _status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produksi dibuat.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Produksi')),
      body: _loadingStores
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + context.systemBottomInset,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: AppSpacing.paddingSM,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: Text(_error!,
                            style: TextStyle(color: AppColors.error)),
                      ),
                      AppSpacing.gapVerticalMD,
                    ],
                    // Store picker.
                    ModernDropdown<int>(
                      value: _storeId,
                      labelText: 'Toko',
                      hint: 'Pilih toko...',
                      isRequired: true,
                      prefixIcon: const Icon(Icons.storefront, size: 20),
                      items: _stores.map((s) => s.id).toList(),
                      getLabel: (v) {
                        final s = _stores.firstWhere((e) => e.id == v,
                            orElse: () => StoreModel(
                                id: 0,
                                nickname: '',
                                latitude: 0,
                                longitude: 0));
                        return s.nickname;
                      },
                      onChanged: (v) => setState(() => _storeId = v),
                      validator: (v) => v == null ? 'Pilih toko' : null,
                    ),
                    AppSpacing.gapVerticalMD,
                    // Date picker.
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_date.day}/${_date.month}/${_date.year}'),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    // Recipe picker (opsional).
                    if (_loadingRecipes)
                      const Padding(
                        padding: AppSpacing.paddingSM,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else ...[
                      Text('Resep (opsional)',
                          style: theme.textTheme.bodySmall),
                      AppSpacing.gapVerticalXS,
                      ModernDropdown<Recipe?>(
                        value: _selectedRecipe,
                        labelText: 'Resep (opsional)',
                        hint: 'Pilih resep untuk auto-prefill ingredient',
                        items: [null, ..._recipes],
                        getLabel: (r) {
                          if (r == null) return '— Tanpa resep (manual) —';
                          return '${r.product.name} (out: ${_fmtQty(r.outputQty)}${r.outputUnit != null ? ' ${r.outputUnit!.name}' : ''})';
                        },
                        onChanged: (v) => setState(() => _selectedRecipe = v),
                      ),
                      if (_selectedRecipe != null) ...[
                        AppSpacing.gapVerticalSM,
                        _recipePreview(_selectedRecipe!),
                      ],
                    ],
                    AppSpacing.gapVerticalMD,
                    // Notes.
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    AppSpacing.gapVerticalLG,
                    ModernButton(
                      text: _submitting ? 'Menyimpan...' : 'Simpan',
                      onPressed: _submitting ? null : _submit,
                      isLoading: _submitting,
                      icon: Icons.save,
                    ),
                    AppSpacing.gapVerticalSM,
                    Text(
                      'Setelah simpan, lanjut atur qty ingredient & apply stok di halaman detail.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _recipePreview(Recipe r) {
    return Container(
      padding: AppSpacing.paddingSM,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bahan dari resep (akan di-prefill):',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          ...r.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• ${ing.product.name}'
                        '${ing.isOptional ? ' (opsional)' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${_fmtQty(ing.quantity)}'
                      '${ing.unit != null ? ' ${ing.unit!.name}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _fmtQty(double q) {
    // Trim trailing zeros untuk tampilan cantik.
    return q
        .toStringAsFixed(q == q.roundToDouble() ? 0 : 3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
