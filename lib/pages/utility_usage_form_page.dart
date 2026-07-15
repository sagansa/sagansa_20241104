import 'package:flutter/material.dart';
import '../models/utility_usage_model.dart';
import '../services/utility_usage_service.dart';
import '../services/presence_service.dart';
import '../theme/app_spacing.dart';

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
  // Store is taken from the active clock-in (no dropdown)
  Map<String, dynamic>? _selectedStore;

  List<Map<String, dynamic>> _filteredUtilities = [];
  Map<String, dynamic>? _selectedUtility;

  bool _isLoadingLookups = true;
  bool _isSaving = false;

  // For showing previous reading
  String? _previousReading;

  bool get isEditing => widget.usage != null;

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
    super.dispose();
  }

  void _initForm() {
    final u = widget.usage;
    if (u != null) {
      _resultCtrl.text = u.result;
      _notesCtrl.text = u.notes ?? '';
      _previousReading = u.result;
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

      final stores = results[0] as List<Map<String, dynamic>>;
      final utilities = results[1] as List<Map<String, dynamic>>;

      Map<String, dynamic>? resolvedStore;
      Map<String, dynamic>? resolvedUtility;

      final u = widget.usage;
      if (u != null) {
        // Editing: store/utility from the existing usage
        resolvedStore = stores.where((s) => s['id'] == u.storeId).firstOrNull;
        resolvedUtility =
            utilities.where((ut) => ut['id'] == u.utilityId).firstOrNull;
      } else {
        // Creating: resolve the store from the active clock-in
        try {
          final presence = await PresenceService.getUserPresence();
          final presenceData = presence['data'] as Map<String, dynamic>?;
          final today = presenceData?['today'] as Map<String, dynamic>?;
          final clockInStoreId = today?['store_id'];
          if (clockInStoreId != null) {
            resolvedStore = stores
                .where((s) => s['id'].toString() == clockInStoreId.toString())
                .firstOrNull;
          }
          // Fallback: match by nickname
          if (resolvedStore == null) {
            final clockInName = today?['store']?.toString();
            if (clockInName != null && clockInName.isNotEmpty) {
              resolvedStore = stores
                  .where((s) => s['nickname']?.toString() == clockInName)
                  .firstOrNull;
            }
          }
        } catch (_) {
          // Clock-in info unavailable; user must be clocked in.
        }
      }

      setState(() {
        _stores = stores;
        _utilities = utilities;
        _selectedStore = resolvedStore;
        _selectedUtility = resolvedUtility;
      });

      if (_selectedStore != null) {
        final storeId = _storeId(_selectedStore!);
        _updateFilteredUtilities(storeId);
        if (resolvedUtility != null) {
          _loadPreviousReadingForUtility(_storeId(resolvedUtility!));
        } else {
          _loadPreviousReading(storeId);
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

  void _onUtilityChanged(Map<String, dynamic>? utility) {
    setState(() {
      _selectedUtility = utility;
      _previousReading = null;
    });
    if (utility != null) {
      _loadPreviousReadingForUtility(_storeId(utility));
    }
  }

  Future<void> _loadPreviousReading(int storeId) async {
    try {
      final data = await _service.getUtilityUsages(storeId: storeId);
      if (!mounted) return;
      if (data.isNotEmpty) {
        setState(() => _previousReading = data.first.result);
      } else {
        setState(() => _previousReading = null);
      }
    } catch (_) {
      if (mounted) setState(() => _previousReading = null);
    }
  }

  Future<void> _loadPreviousReadingForUtility(int utilityId) async {
    try {
      final data = await _service.getUtilityUsages(utilityId: utilityId);
      if (!mounted) return;
      if (data.isNotEmpty) {
        setState(() => _previousReading = data.first.result);
      } else {
        setState(() => _previousReading = null);
      }
    } catch (_) {
      if (mounted) setState(() => _previousReading = null);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Anda belum melakukan clock-in untuk toko ini.')),
      );
      return;
    }
    if (_selectedUtility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utility wajib dipilih.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'utility_id': _selectedUtility!['id'],
      'result': _resultCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      if (isEditing) {
        await _service.updateUtilityUsage(widget.usage!.id, data);
      } else {
        await _service.createUtilityUsage(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Pemakaian utility berhasil diperbarui.'
              : 'Pemakaian utility berhasil ditambahkan.'),
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
        title: Text(isEditing ? 'Edit Pemakaian' : 'Tambah Pemakaian'),
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.paddingMD,
                children: [
                  _buildSectionTitle('Informasi Pemakaian', theme),
                  _buildCard(
                    colorScheme: colorScheme,
                    children: [
                      // Store info (taken from clock-in, no dropdown)
                      Row(
                        children: [
                          Icon(Icons.store_rounded,
                              size: 20, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Toko',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant)),
                                Text(
                                  _selectedStore?['nickname']?.toString() ??
                                      'Belum clock-in',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _buildDivider(colorScheme),
                      // Utility dropdown (filtered by the clock-in store)
                      _buildDropdown<Map<String, dynamic>>(
                        label: 'Utility *',
                        hint: _selectedStore == null
                            ? 'Clock-in dulu untuk memilih toko'
                            : (_filteredUtilities.isEmpty
                                ? 'Tidak ada utility'
                                : 'Pilih utility'),
                        icon: Icons.electrical_services_rounded,
                        value: _selectedUtility,
                        items: _filteredUtilities,
                        itemLabel: (m) =>
                            '${m['utility_name'] ?? 'Utility #${m['id']}'}${m['unit'] != null ? ' (${m['unit']})' : ''}',
                        onChanged: _selectedStore == null
                            ? null
                            : (val) => _onUtilityChanged(val),
                        colorScheme: colorScheme,
                        theme: theme,
                        isRequired: true,
                      ),
                      _buildDivider(colorScheme),
                      // Result input with previous reading hint
                      _buildTextField(
                        controller: _resultCtrl,
                        label: 'Hasil Pemakaian *',
                        hint: 'Masukkan angka meter',
                        icon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Hasil wajib diisi' : null,
                        suffixText: _selectedUtility?['unit']?.toString(),
                        helperText: _previousReading != null
                            ? 'Laporan sebelumnya: $_formatPrevious(_previousReading!)'
                            : 'Belum ada laporan sebelumnya',
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalMD,
                  _buildSectionTitle('Catatan', theme),
                  _buildCard(
                    colorScheme: colorScheme,
                    children: [
                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Catatan',
                        hint: 'Catatan tambahan (opsional)',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalXL,
                  // Bottom Save Button (only one)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(
                              isEditing ? 'Simpan Perubahan' : 'Tambah Pemakaian',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                  AppSpacing.gapVerticalXL,
                ],
              ),
            ),
    );
  }

  String _formatPrevious(String value) {
    final num = int.tryParse(value.replaceAll('.', '')) ?? 0;
    return num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
    String? suffixText,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixText: suffixText,
          helperText: helperText,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        hint: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(hint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 14)),
            ),
          ],
        ),
        decoration: const InputDecoration(isDense: true),
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