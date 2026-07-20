import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/utility_usage_model.dart';
import '../services/image_upload_service.dart';
import '../services/presence_service.dart';
import '../services/utility_usage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/image_utils.dart';
import '../widgets/modern_dropdown.dart';

class UtilityUsageFormPage extends StatefulWidget {
  final UtilityUsageModel? usage;

  const UtilityUsageFormPage({super.key, this.usage});

  @override
  State<UtilityUsageFormPage> createState() => _UtilityUsageFormPageState();
}

class _UtilityUsageFormPageState extends State<UtilityUsageFormPage> {
  final _formKey = GlobalKey<FormState>();
  final UtilityUsageService _service = UtilityUsageService();

  final _resultCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _utilities = [];
  Map<String, dynamic>? _selectedStore;

  List<Map<String, dynamic>> _filteredUtilities = [];
  Map<String, dynamic>? _selectedUtility;

  Map<int, TextEditingController> _resultControllers = {};
  Map<int, String?> _previousReadings = {};
  Map<int, File?> _meterPhotos = {};
  Map<int, String?> _uploadedPhotoPaths = {};

  bool _isLoadingLookups = true;
  bool _isSaving = false;

  bool get isEditing => widget.usage != null;

  static const _categories = [
    {'id': 1, 'label': 'Listrik', 'icon': Icons.bolt_rounded},
    {'id': 2, 'label': 'Air', 'icon': Icons.water_drop_rounded},
    {'id': 3, 'label': 'Internet', 'icon': Icons.wifi_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _initForm();
    _loadLookups();
  }

  @override
  void dispose() {
    _resultCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _resultControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initForm() {
    final u = widget.usage;
    if (u != null) {
      _resultCtrl.text = u.result;
      _notesCtrl.text = u.notes ?? '';
    }
  }

  int _storeId(Map<String, dynamic> store) =>
      store['id'] is int ? store['id'] : int.parse(store['id'].toString());

  Future<void> _loadLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final results = await Future.wait([
        _service.getStores(),
        _service.getUtilities(),
      ]);

      if (!mounted) return;

      final stores = (results[0] as List).cast<Map<String, dynamic>>();
      final utilities = (results[1] as List).cast<Map<String, dynamic>>();

      Map<String, dynamic>? resolvedStore;
      Map<String, dynamic>? resolvedUtility;

      final u = widget.usage;
      if (u != null) {
        resolvedStore = stores.where((s) => s['id'] == u.storeId).firstOrNull;
        resolvedUtility =
            utilities.where((ut) => ut['id'] == u.utilityId).firstOrNull;
      } else {
        try {
          final presence = await PresenceService().getUserPresence();
          final presenceData = presence['data'] as Map<String, dynamic>?;
          final today = presenceData?['today'] as Map<String, dynamic>?;
          final clockInStoreId = today?['store_id'];
          if (clockInStoreId != null) {
            resolvedStore = stores
                .where((s) => s['id'].toString() == clockInStoreId.toString())
                .firstOrNull;
          }
          if (resolvedStore == null) {
            final clockInName = today?['store']?.toString();
            if (clockInName != null && clockInName.isNotEmpty) {
              resolvedStore = stores
                  .where((s) => s['nickname']?.toString() == clockInName)
                  .firstOrNull;
            }
          }
        } catch (_) {}
      }

      setState(() {
        _stores = stores;
        _utilities = utilities;
        _selectedStore = resolvedStore;
        _selectedUtility = resolvedUtility;
      });

      if (_selectedStore != null) {
        final storeId = _storeId(_selectedStore!);
        if (isEditing) {
          _updateFilteredUtilities(storeId);
        } else {
          await _initMultiUtilityFields(storeId);
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

  void _updateFilteredUtilities(int storeId) {
    setState(() {
      _filteredUtilities =
          _utilities.where((u) => u['store_id'] == storeId).toList();
    });
  }

  void _onStoreChanged(Map<String, dynamic>? store) {
    setState(() {
      _selectedStore = store;
      _selectedUtility = null;
    });
    if (store != null) {
      final storeId = _storeId(store);
      if (isEditing) {
        _updateFilteredUtilities(storeId);
      } else {
        _initMultiUtilityFields(storeId);
      }
    } else {
      setState(() => _filteredUtilities = []);
    }
  }

  Future<void> _initMultiUtilityFields(int storeId) async {
    _updateFilteredUtilities(storeId);

    for (final c in _resultControllers.values) {
      c.dispose();
    }
    final newControllers = <int, TextEditingController>{};
    for (final u in _filteredUtilities) {
      final id = _storeId(u);
      newControllers[id] = TextEditingController();
    }

    setState(() {
      _resultControllers = newControllers;
      _previousReadings = {};
      _meterPhotos = {};
      _uploadedPhotoPaths = {};
    });

    final futures = _filteredUtilities.map((u) async {
      final id = _storeId(u);
      final reading = await _fetchPreviousReading(utilityId: id);
      return MapEntry(id, reading);
    });
    final entries = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _previousReadings = Map.fromEntries(entries);
    });
  }

  Future<String?> _fetchPreviousReading({int? utilityId, int? storeId}) async {
    try {
      final data =
          await _service.getUtilityUsages(utilityId: utilityId, storeId: storeId);
      if (data.isNotEmpty) return data.first.result;
    } catch (_) {}
    return null;
  }

  Future<void> _pickPhoto(int utilityId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (picked == null) return;

      final compressed = await ImageUtils.compressImage(picked.path);
      setState(() {
        _meterPhotos[utilityId] = compressed;
        _uploadedPhotoPaths.remove(utilityId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _removePhoto(int utilityId) {
    setState(() {
      _meterPhotos.remove(utilityId);
      _uploadedPhotoPaths.remove(utilityId);
    });
  }

  int get _filledCount =>
      _resultControllers.values.where((c) => c.text.trim().isNotEmpty).length;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toko wajib dipilih.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    try {
      if (isEditing) {
        if (_selectedUtility == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utility wajib dipilih.')),
          );
          return;
        }
        final data = <String, dynamic>{
          'utility_id': _selectedUtility!['id'],
          'result': _resultCtrlValue(_storeId(_selectedUtility!)),
          'notes': notes,
        };
        await _service.updateUtilityUsage(widget.usage!.id, data);
      } else {
        final utilitiesWithResults =
            _filteredUtilities.where((u) {
          final controller = _resultControllers[_storeId(u)];
          return controller != null && controller.text.trim().isNotEmpty;
        }).toList();

        if (utilitiesWithResults.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Isi minimal satu pemakaian utility.')),
          );
          return;
        }

        for (final u in utilitiesWithResults) {
          final utId = _storeId(u);
          final controller = _resultControllers[utId]!;
          final data = <String, dynamic>{
            'utility_id': u['id'],
            'result': controller.text.trim(),
            'notes': notes,
          };
          final photoFile = _meterPhotos[utId];
          if (photoFile != null) {
            final uploadedPath = await ImageUploadService.upload(
              photoFile,
              directory: 'images/UtilityUsage',
            );
            if (uploadedPath != null) {
              data['image'] = uploadedPath;
            }
          }
          await _service.createUtilityUsage(data);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Pemakaian utility berhasil diperbarui.'
              : 'Pemakaian utility berhasil ditambahkan.'),
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

  String _resultCtrlValue(int utilityId) {
    return _resultControllers[utilityId]?.text.trim() ?? '';
  }

  String _formatNumber(String value) {
    final num = int.tryParse(value.replaceAll('.', '')) ?? 0;
    return num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  List<Map<String, dynamic>> _getCategory(int categoryId) =>
      _filteredUtilities.where((u) => u['category'] == categoryId).toList();

  bool _hasCategory(int categoryId) =>
      _filteredUtilities.any((u) => u['category'] == categoryId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pemakaian' : 'Tambah Pemakaian'),
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
                children: [
                  _buildStoreSection(theme, colorScheme),
                  if (!isEditing && _selectedStore != null) ...[
                    AppSpacing.gapVerticalMD,
                    _buildProgressTracker(colorScheme),
                    if (_hasCategory(1)) ...[
                      AppSpacing.gapVerticalLG,
                      _buildCategorySection(1, theme, colorScheme),
                    ],
                    if (_hasCategory(2)) ...[
                      AppSpacing.gapVerticalLG,
                      _buildCategorySection(2, theme, colorScheme),
                    ],
                    if (_hasCategory(3)) ...[
                      AppSpacing.gapVerticalLG,
                      _buildCategorySection(3, theme, colorScheme),
                    ],
                    if (_filteredUtilities.isEmpty)
                      _buildEmptyUtilities(colorScheme),
                  ],
                  if (isEditing) ...[
                    AppSpacing.gapVerticalMD,
                    _buildEditModeFields(theme, colorScheme),
                  ],
                  AppSpacing.gapVerticalLG,
                  _buildNotesSection(theme, colorScheme),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(colorScheme),
    );
  }

  Widget _buildStoreSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Toko', Icons.store_rounded, colorScheme),
        AppSpacing.gapVerticalSM,
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLG,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: ModernDropdown<Map<String, dynamic>>(
            value: _selectedStore,
            labelText: 'Toko',
            hint: 'Pilih toko...',
            isRequired: true,
            prefixIcon: const Icon(Icons.storefront, size: 20),
            items: _stores,
            getLabel: (s) => s['nickname']?.toString() ?? 'Toko #${s['id']}',
            getSubtitle: (s) => s['address']?.toString() ?? '',
            onChanged: (val) => _onStoreChanged(val),
            validator: (v) => v == null ? 'Toko wajib dipilih' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker(ColorScheme colorScheme) {
    final total = _filteredUtilities.length;
    final filled = _filledCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _buildProgressDot(1, filled >= 1, colorScheme),
          _buildProgressConnector(colorScheme),
          _buildProgressDot(2, filled >= 2, colorScheme),
          _buildProgressConnector(colorScheme),
          _buildProgressDot(3, filled >= 3, colorScheme),
          const Spacer(),
          Text(
            '$filled dari $total terisi',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int index, bool filled, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: filled ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: filled
            ? Icon(Icons.check, size: 18, color: colorScheme.onPrimary)
            : Text(
                '$index',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressConnector(ColorScheme colorScheme) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCategorySection(
      int categoryId, ThemeData theme, ColorScheme colorScheme) {
    final cat = _categories.firstWhere((c) => c['id'] == categoryId);
    final items = _getCategory(categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          cat['label'] as String,
          cat['icon'] as IconData,
          colorScheme,
        ),
        AppSpacing.gapVerticalSM,
        ...items.map((u) {
          final id = _storeId(u);
          final controller = _resultControllers[id]!;
          final prevReading = _previousReadings[id];
          final hasPhoto = _meterPhotos.containsKey(id);

          return Padding(
            padding: EdgeInsets.only(bottom: items.last == u ? 0 : AppSpacing.sm),
            child: _buildMeterCard(
              utility: u,
              controller: controller,
              prevReading: prevReading,
              hasPhoto: hasPhoto,
              utilityId: id,
              colorScheme: colorScheme,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMeterCard({
    required Map<String, dynamic> utility,
    required TextEditingController controller,
    required String? prevReading,
    required bool hasPhoto,
    required int utilityId,
    required ColorScheme colorScheme,
  }) {
    final name = utility['utility_name']?.toString() ?? 'Utility #${utility['id']}';
    final unit = utility['unit']?.toString() ?? '';
    final category = utility['category'];

    IconData catIcon;
    switch (category) {
      case 1:
        catIcon = Icons.bolt_rounded;
        break;
      case 2:
        catIcon = Icons.water_drop_rounded;
        break;
      case 3:
        catIcon = Icons.wifi_rounded;
        break;
      default:
        catIcon = Icons.speed_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: Icon(catIcon, size: 22, color: AppColors.info),
                ),
                AppSpacing.gapHorizontalSM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Text(
                          'Satuan: $unit',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (prevReading != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              color: colorScheme.surfaceContainerLow,
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 14, color: AppColors.info),
                  AppSpacing.gapHorizontalXS,
                  Text(
                    'Lalu: ${_formatNumber(prevReading)} $unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      labelText: 'Angka meter',
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixText: unit.isNotEmpty ? unit : null,
                      suffixStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSM,
                        borderSide: BorderSide(
                            color: colorScheme.outlineVariant, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSM,
                        borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSM,
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 4,
                          vertical: AppSpacing.sm + 4),
                      isDense: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                AppSpacing.gapHorizontalSM,
                _buildPhotoButton(utilityId, hasPhoto, colorScheme),
              ],
            ),
          ),
          if (hasPhoto)
            _buildPhotoPreview(utilityId, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPhotoButton(
      int utilityId, bool hasPhoto, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: hasPhoto
          ? () => _removePhoto(utilityId)
          : () => _pickPhoto(utilityId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.success.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.borderRadiusSM,
          border: Border.all(
            color: hasPhoto
                ? AppColors.success.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          hasPhoto ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
          size: 22,
          color: hasPhoto ? AppColors.success : AppColors.info,
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(int utilityId, ColorScheme colorScheme) {
    final file = _meterPhotos[utilityId];
    if (file == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusSM,
        child: Stack(
          children: [
            Image.file(
              file,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removePhoto(utilityId),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUtilities(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.electrical_services_rounded,
              size: 48, color: AppColors.info),
          AppSpacing.gapVerticalSM,
          Text(
            'Tidak ada utility terdaftar',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Toko ini belum memiliki utility yang aktif',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeFields(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Utility', Icons.electrical_services_rounded, colorScheme),
        AppSpacing.gapVerticalSM,
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLG,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              ModernDropdown<Map<String, dynamic>>(
                value: _selectedUtility,
                labelText: 'Utility',
                hint: _selectedStore == null ? 'Pilih toko dulu' : 'Pilih utility...',
                isRequired: true,
                enabled: _selectedStore != null,
                prefixIcon: const Icon(Icons.electrical_services, size: 20),
                items: _filteredUtilities,
                getLabel: (u) => '${u['utility_name'] ?? 'Utility #${u['id']}'}${u['unit'] != null ? ' (${u['unit']})' : ''}',
                onChanged: (val) => setState(() => _selectedUtility = val),
                validator: (v) => v == null ? 'Utility wajib dipilih' : null,
              ),
            ],
          ),
        ),
        if (_selectedUtility != null) ...[
          AppSpacing.gapVerticalMD,
          _buildMeterCard(
            utility: _selectedUtility!,
            controller: _resultCtrl,
            prevReading: null,
            hasPhoto: false,
            utilityId: _storeId(_selectedUtility!),
            colorScheme: colorScheme,
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Catatan', Icons.notes_rounded, colorScheme),
        AppSpacing.gapVerticalSM,
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLG,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Catatan tambahan (opsional)',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.info),
        AppSpacing.gapHorizontalXS,
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSM,
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing
                            ? Icons.save_rounded
                            : Icons.add_circle_rounded,
                        size: 20,
                      ),
                      AppSpacing.gapHorizontalSM,
                      Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambah Pemakaian',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
