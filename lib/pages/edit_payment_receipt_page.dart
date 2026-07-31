import 'dart:io';
import 'package:flutter/material.dart';
import '../models/procurement_model.dart';
import '../services/fuel_service_service.dart';
import '../services/image_service.dart';
import '../services/procurement_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../widgets/ticket_card_container.dart' show DashedDivider;

/// Halaman edit payment receipt fuel & service.
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
  final _transferAmountController = TextEditingController();
  final _notesController = TextEditingController();

  /// Snapshot item ter-attach (editable: bisa di-remove / ditambah).
  late List<FuelServiceItem> _fuelServices;
  File? _imageFile;
  bool _isSaving = false;
  List<Map<String, dynamic>> _users = [];
  int? _userFilter;

  @override
  void initState() {
    super.initState();
    _fuelServices = List.from(widget.receipt.fuelServices);
    _transferAmountController.text = widget.receipt.transferAmount.toString();
    _notesController.text = widget.receipt.notes ?? '';
    _loadUsers();
  }

  @override
  void dispose() {
    _transferAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalAmount => _fuelServices.fold(0, (sum, fs) => sum + fs.amount);

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
      final candidates = await _fuelServiceService.getFuelServicesForPayment(
        createdById: _userFilter,
      );
      final candidateItems = candidates
          .map((c) => FuelServiceItem.fromJson(c as Map<String, dynamic>))
          .toList();
      // Skip yang sudah ada di _fuelServices.
      final existingIds = _fuelServices.map((fs) => fs.id).toSet();
      final available =
          candidateItems.where((fs) => !existingIds.contains(fs.id)).toList();

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
                padding:
                    EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                    // Filter user (admin).
                    if (_users.isNotEmpty)
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
                            final fs = available[i];
                            final checked = selected.contains(fs.id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (v) => setSheetState(() {
                                if (v == true) {
                                  selected.add(fs.id);
                                } else {
                                  selected.remove(fs.id);
                                }
                              }),
                              title: Text(
                                  '${fs.vehicleRegister ?? "Kendaraan"} (KM: ${fs.km})'),
                              subtitle: Text(
                                  '${fs.typeLabel} • ${fs.date} • ${FormatUtils.formatCurrency(fs.amount)}'),
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
                                      .where((fs) => selected.contains(fs.id))
                                      .toList();
                                  setState(() => _fuelServices.addAll(toAdd));
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
    if (_fuelServices.isEmpty) {
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
      await _procurementService.updateFuelServicePaymentReceipt(
        receiptId: widget.receipt.id,
        fuelServiceIds: _fuelServices.map((fs) => fs.id).toList(),
        transferAmount: transferAmount,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        image: _imageFile,
      );
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
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
            tooltip: 'Simpan',
          ),
        ],
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
                Text('Item Bensin & Servis (${_fuelServices.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _openAddItemSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_fuelServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: Text('Tidak ada item.')),
              )
            else
              ..._fuelServices.asMap().entries.map((entry) {
                final idx = entry.key;
                final fs = entry.value;
                return _buildItemCard(fs, idx, theme);
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
    );
  }

  Widget _buildItemCard(FuelServiceItem fs, int idx, ThemeData theme) {
    final isFuel = fs.fuelService == 1;
    final typeColor = isFuel ? AppColors.success : AppColors.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          ),
          child: Text(fs.typeLabel,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: typeColor, fontWeight: FontWeight.bold)),
        ),
        title: Text('${fs.vehicleRegister ?? "Kendaraan"} (KM: ${fs.km})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${fs.date} • ${FormatUtils.formatCurrency(fs.amount)}',
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          tooltip: 'Hapus item (kembali ke pending)',
          onPressed: () => setState(() => _fuelServices.removeAt(idx)),
        ),
      ),
    );
  }
}
