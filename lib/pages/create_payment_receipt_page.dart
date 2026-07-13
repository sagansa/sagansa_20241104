import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/procurement_model.dart';
import '../../models/supplier_model.dart';
import '../../services/procurement_service.dart';
import '../../services/supplier_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';

class CreatePaymentReceiptPage extends StatefulWidget {
  final List<InvoicePurchase> invoices;

  const CreatePaymentReceiptPage({super.key, required this.invoices});

  @override
  State<CreatePaymentReceiptPage> createState() =>
      _CreatePaymentReceiptPageState();
}

class _CreatePaymentReceiptPageState extends State<CreatePaymentReceiptPage> {
  final ProcurementService _procurementService = ProcurementService();
  final SupplierService _supplierService = SupplierService();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  File? _imageFile;
  SupplierModel? _supplier;
  bool _loadingSupplier = false;

  List<InvoicePurchase> get _invoices => widget.invoices;

  int get _totalAmount {
    return _invoices.fold(0, (sum, inv) => sum + inv.totalPrice);
  }

  int? _supplierId;

  @override
  void initState() {
    super.initState();
    _amountController.text = _formatAmount(_totalAmount);
    _determineSupplier();
  }

  void _determineSupplier() {
    final ids = _invoices.map((inv) => inv.supplierId).toSet().toList();
    if (ids.length == 1 && ids.first != null) {
      _supplierId = ids.first!;
      _fetchSupplier(_supplierId!);
    }
  }

  Future<void> _fetchSupplier(int id) async {
    setState(() => _loadingSupplier = true);
    try {
      final supplier = await _supplierService.getSupplier(id);
      if (mounted) {
        setState(() {
          _supplier = supplier;
          _loadingSupplier = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSupplier = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.');
  }

  int _parseAmount(String text) {
    return int.tryParse(text.replaceAll('.', '')) ?? 0;
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    ModernBottomSheet.show(
      context: context,
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () {
              Navigator.pop(context);
              _pickFromGallery();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final receipt = await _procurementService.createPaymentReceipt(
        invoiceIds: _invoices.map((inv) => inv.id).toList(),
        transferAmount: _parseAmount(_amountController.text),
        totalAmount: _totalAmount,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        image: _imageFile,
      );
      if (!mounted) return;
      Navigator.pop(context, receipt);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Payment Receipt'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSupplierBankCard(theme, colorScheme),
              AppSpacing.gapVerticalMD,
              _buildInvoiceList(theme, colorScheme),
              AppSpacing.gapVerticalLG,
              _buildImagePicker(theme, colorScheme),
              AppSpacing.gapVerticalLG,
              _buildAmountField(theme, colorScheme),
              AppSpacing.gapVerticalMD,
              _buildNotesField(theme, colorScheme),
              AppSpacing.gapVerticalLG,
              _buildSubmitButton(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierBankCard(ThemeData theme, ColorScheme colorScheme) {
    if (_loadingSupplier) {
      return Card(
        child: const Padding(
          padding: AppSpacing.paddingMD,
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }

    if (_supplier == null) return const SizedBox.shrink();

    final bank = _supplier!;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, size: 20, color: colorScheme.primary),
                AppSpacing.gapHorizontalSM,
                Text(
                  'Informasi Bank Supplier',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,
            _bankInfoRow('Supplier', bank.name, theme),
            if (bank.bankName != null) ...[
              AppSpacing.gapVerticalXS,
              _bankInfoRow('Bank', bank.bankName!, theme),
            ],
            if (bank.bankAccountName != null) ...[
              AppSpacing.gapVerticalXS,
              _bankInfoRow('Atas Nama', bank.bankAccountName!, theme),
            ],
            if (bank.bankAccountNo != null) ...[
              AppSpacing.gapVerticalXS,
              _bankInfoRowWithCopy('No. Rekening', bank.bankAccountNo!, theme, colorScheme),
            ],
            if (bank.qris != null && bank.qris!.isNotEmpty) ...[
              AppSpacing.gapVerticalXS,
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'QRIS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Tersedia',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bankInfoRowWithCopy(String label, String value, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No. Rekening disalin'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Icon(Icons.copy, size: 16, color: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _bankInfoRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceList(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 20, color: colorScheme.primary),
                AppSpacing.gapHorizontalSM,
                Text(
                  'Invoice yang Dibayar (${_invoices.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,
            ..._invoices.asMap().entries.map((entry) {
              final idx = entry.key;
              final inv = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: idx < _invoices.length - 1 ? AppSpacing.sm + AppSpacing.xs : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.storeName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapVerticalXS,
                          Text(
                            '${inv.date} • ${inv.supplierName ?? ""}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      'Rp ${_formatAmount(inv.totalPrice)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Semua Invoice',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${_formatAmount(_totalAmount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, size: 20, color: colorScheme.primary),
                AppSpacing.gapHorizontalSM,
                Text(
                  'Bukti Pembayaran',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: AppSpacing.borderRadiusMD,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: AppSpacing.borderRadiusMD,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_imageFile!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageFile = null),
                                child: Container(
                                  padding: AppSpacing.paddingXS,
                                  decoration: BoxDecoration(
                                    color: colorScheme.scrim.withValues(alpha: 0.54),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          AppSpacing.gapVerticalSM,
                          Text(
                            'Ketuk untuk ambil foto bukti transfer',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments, size: 20, color: colorScheme.primary),
                AppSpacing.gapHorizontalSM,
                Text(
                  'Detail Pembayaran',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Transfer (Rp)',
                prefixText: 'Rp ',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Jumlah transfer wajib diisi';
                final num = int.tryParse(val.replaceAll('.', ''));
                if (num == null || num <= 0) return 'Jumlah harus lebih besar dari 0';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, size: 20, color: colorScheme.primary),
                AppSpacing.gapHorizontalSM,
                Text(
                  'Catatan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Keterangan pembayaran (opsional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.onSuccess,
        ),
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSuccess),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isSubmitting ? 'Memproses...' : 'Konfirmasi Pembayaran',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
