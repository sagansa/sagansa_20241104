import 'dart:io';
import 'package:flutter/material.dart';
import '../models/procurement_model.dart';
import '../services/closing_store_service.dart';
import '../services/fuel_service_service.dart';
import '../services/image_service.dart';
import '../services/procurement_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/safe_bottom_bar.dart';
import '../widgets/ticket_card_container.dart' show DashedDivider;

/// Item generik untuk daftar item receipt yang bisa diedit (fuel/service
/// maupun daily salary) — halaman ini bekerja mode-agnostik di atas tipe ini.
class _EditableItem {
  final int id;
  final int amount;
  final String title;
  final String subtitle;
  final String? badge;

  const _EditableItem({
    required this.id,
    required this.amount,
    required this.title,
    required this.subtitle,
    this.badge,
  });
}

/// Halaman edit payment receipt (fuel & service ATAU daily salary).
///
/// Edit: daftar item (add/remove), transfer_amount, notes, image.
/// total_amount computed (read-only). Item add/remove sinkron status
/// dua arah saat save (backend). Dipanggil dari PaymentReceiptDetailPage.
class EditPaymentReceiptPage extends StatefulWidget {
  final PaymentReceipt receipt;

  const EditPaymentReceiptPage({super.key, required this.receipt});

  @override
  State<EditPaymentReceiptPage> createState() => _EditPaymentReceiptPageState();
}

class _EditPaymentReceiptPageState extends State<EditPaymentReceiptPage> {
  final _procurementService = ProcurementService();
  final _fuelServiceService = FuelServiceService();
  final _closingStoreService = ClosingStoreService();
  final _transferAmountController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isDailySalary => widget.receipt.paymentFor == '2';

  /// Snapshot item ter-attach (editable: bisa di-remove / ditambah).
  late List<_EditableItem> _items;

  /// Receipt gaji selalu milik satu karyawan — simpan id-nya untuk
  /// menyaring kandidat item tambahan (aturan "satu karyawan").
  int? _salaryEmployeeId;
  String? _salaryEmployeeName;

  File? _imageFile;
  bool _isSaving = false;
  List<Map<String, dynamic>> _users = [];
  int? _userFilter;

  @override
  void initState() {
    super.initState();
    if (_isDailySalary) {
      final first = widget.receipt.dailySalaries.firstOrNull;
      _salaryEmployeeId = first?.createdById;
      _salaryEmployeeName = first?.createdByName;
      _items = widget.receipt.dailySalaries
          .map((ds) => _EditableItem(
                id: ds.id,
                amount: ds.amount,
                title: ds.date.isEmpty ? 'Gaji #${ds.id}' : ds.date,
                subtitle: FormatUtils.formatCurrency(ds.amount),
                badge: 'Gaji',
              ))
          .toList();
    } else {
      _items = widget.receipt.fuelServices
          .map((fs) => _EditableItem(
                id: fs.id,
                amount: fs.amount,
                title:
                    '${fs.vehicleRegister ?? "Kendaraan"} (KM: ${fs.km})',
                subtitle:
                    '${fs.typeLabel} • ${fs.date} • ${FormatUtils.formatCurrency(fs.amount)}',
                badge: fs.typeLabel,
              ))
          .toList();
    }
    _transferAmountController.text = widget.receipt.transferAmount.toString();
    _notesController.text = widget.receipt.notes ?? '';
    if (!_isDailySalary) {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _transferAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalAmount => _items.fold(0, (sum, item) => sum + item.amount);

  Future<void> _loadUsers() async {
    try {
      final data = await _fuelServiceService.getUsersForFuelServicePayment();
      if (!mounted) return;
      setState(() {
        _users = data.cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _openAddItemSheet() async {
    try {
      final List<_EditableItem> available;
      if (_isDailySalary) {
        // Kandidat hanya milik karyawan yang sama (aturan satu karyawan).
        final candidates = await _closingStoreService.getDailySalariesForPayment(
          userId: _salaryEmployeeId,
        );
        final candidateItems = candidates
            .map((c) => c as Map<String, dynamic>)
            .map((c) => _EditableItem(
                  id: (c['id'] as int).toInt(),
                  amount:
                      double.tryParse('${c['amount'] ?? 0}')?.toInt() ?? 0,
                  title: c['date']?.toString() ?? '',
                  subtitle: FormatUtils.formatCurrency(
                      double.tryParse('${c['amount'] ?? 0}')?.toInt() ?? 0),
                  badge: 'Gaji',
                ))
            .toList();
        final existingIds = _items.map((i) => i.id).toSet();
        available =
            candidateItems.where((i) => !existingIds.contains(i.id)).toList();
      } else {
        final candidates = await _fuelServiceService.getFuelServicesForPayment(
          createdById: _userFilter,
        );
        final candidateItems = candidates
            .map((c) => FuelServiceItem.fromJson(c as Map<String, dynamic>))
            .map((fs) => _EditableItem(
                  id: fs.id,
                  amount: fs.amount,
                  title:
                      '${fs.vehicleRegister ?? "Kendaraan"} (KM: ${fs.km})',
                  subtitle:
                      '${fs.typeLabel} • ${fs.date} • ${FormatUtils.formatCurrency(fs.amount)}',
                  badge: fs.typeLabel,
                ))
            .toList();
        // Skip yang sudah ada di _items.
        final existingIds = _items.map((i) => i.id).toSet();
        available =
            candidateItems.where((i) => !existingIds.contains(i.id)).toList();
      }

      final selected = <int>{};
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Padding(
                // Keyboard inset + system nav bar inset agar tombol "Tambah"
                // di bawah tidak pernah tertutup (pola fuel service sheet).
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom +
                      ctx.systemBottomInset,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: AppSpacing.paddingMD,
                      child: Row(
                        children: [
                          Text('Tambah Item',
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    // Filter user (admin) — hanya mode fuel & service.
                    if (!_isDailySalary && _users.isNotEmpty)
                      Padding(
                        padding: AppSpacing.paddingHorizontalMD,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Pengemudi',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _userFilter,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Semua Pengemudi')),
                            ..._users.map((u) => DropdownMenuItem(
                                  value: _toInt(u['id']),
                                  child: Text(u['name']?.toString() ?? ''),
                                )),
                          ],
                          onChanged: (v) async {
                            setState(() => _userFilter = v);
                            Navigator.pop(ctx);
                            await _openAddItemSheet();
                          },
                        ),
                      ),
                    // Mode gaji: kandidat terkunci pada satu karyawan.
                    if (_isDailySalary && _salaryEmployeeName != null)
                      Padding(
                        padding: AppSpacing.paddingHorizontalMD,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Karyawan: $_salaryEmployeeName',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    const Divider(),
                    if (available.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Tidak ada item yang bisa ditambahkan.'),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: available.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final item = available[i];
                            final checked = selected.contains(item.id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (v) => setSheetState(() {
                                if (v == true) {
                                  selected.add(item.id);
                                } else {
                                  selected.remove(item.id);
                                }
                              }),
                              title: Text(item.title),
                              subtitle: Text(item.subtitle),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: AppSpacing.paddingMD,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selected.isEmpty
                              ? null
                              : () {
                                  final toAdd = available
                                      .where((i) => selected.contains(i.id))
                                      .toList();
                                  setState(() => _items.addAll(toAdd));
                                  Navigator.pop(ctx);
                                },
                          icon: const Icon(Icons.add),
                          label: Text(selected.isEmpty
                              ? 'Pilih item untuk ditambah'
                              : 'Tambah ${selected.length} item'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat item: $e')),
      );
    }
  }

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  Future<void> _pickImage() async {
    try {
      final photo = await ImageService.selectAndPickImage(context);
      if (photo != null && mounted) {
        setState(() => _imageFile = photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 item.')),
      );
      return;
    }
    final transferAmount = int.tryParse(_transferAmountController.text) ?? 0;
    if (transferAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transfer harus lebih dari 0.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isDailySalary) {
        await _procurementService.updateDailySalaryPaymentReceipt(
          receiptId: widget.receipt.id,
          dailySalaryIds: _items.map((i) => i.id).toList(),
          transferAmount: transferAmount,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          image: _imageFile,
        );
      } else {
        await _procurementService.updateFuelServicePaymentReceipt(
          receiptId: widget.receipt.id,
          fuelServiceIds: _items.map((i) => i.id).toList(),
          transferAmount: transferAmount,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          image: _imageFile,
        );
      }
      // Refresh receipt lengkap untuk return ke detail page.
      final updated =
          await _procurementService.getPaymentReceiptDetail(widget.receipt.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment receipt berhasil diperbarui.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, updated);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Payment Receipt'),
      ),
      // Tombol simpan dipatok di bawah (tidak ikut scroll) — pola standar
      // SafeBottomBar + ModernButton seperti halaman create lainnya.
      bottomNavigationBar: SafeBottomBar(
        child: ModernButton(
          text: 'Simpan Perubahan',
          onPressed: _isSaving ? null : _save,
          isLoading: _isSaving,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total (computed) + Transfer amount.
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Tagihan (otomatis)',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.secondary)),
                      Text(FormatUtils.formatCurrency(_totalAmount),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const DashedDivider(),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _transferAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Transfer',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Daftar item.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      _isDailySalary
                          ? 'Item Gaji Harian (${_items.length})'
                          : 'Item Bensin & Servis (${_items.length})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: _openAddItemSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            if (_isDailySalary && _salaryEmployeeName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'Karyawan: $_salaryEmployeeName',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: Text('Tidak ada item.')),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _buildItemCard(item, idx, theme);
              }),

            const SizedBox(height: AppSpacing.lg),

            // Notes.
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Image.
            Text('Bukti Transfer (opsional)',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            if (_imageFile != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    child: Image.file(_imageFile!,
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.white),
                        onPressed: () => setState(() => _imageFile = null),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                          _imageFile == null
                              ? Icons.add_a_photo_rounded
                              : Icons.edit_rounded,
                          size: 18),
                      label: Text(_imageFile == null
                          ? 'Unggah Bukti Baru'
                          : 'Ganti Foto Bukti'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(_EditableItem item, int idx, ThemeData theme) {
    final badgeColor = _isDailySalary
        ? AppColors.info
        : (item.badge == 'Fuel' ? AppColors.success : AppColors.warning);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          ),
          child: Text(item.badge ?? '-',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: badgeColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          tooltip: 'Hapus item (kembali ke pending)',
          onPressed: () => setState(() => _items.removeAt(idx)),
        ),
      ),
    );
  }
}
