import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_snackbar.dart';
import 'supplier_form_page.dart';

class SupplierDetailPage extends StatefulWidget {
  final int supplierId;

  const SupplierDetailPage({super.key, required this.supplierId});

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage>
    with SingleTickerProviderStateMixin {
  final SupplierService _service = SupplierService();
  SupplierModel? _supplier;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _fetch();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getSupplier(widget.supplierId);
      if (!mounted) return;
      setState(() {
        _supplier = data;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Supplier?',
      content: 'Supplier "${_supplier?.name}" akan dihapus permanen.',
      confirmText: 'Hapus',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.deleteSupplier(widget.supplierId);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Supplier berhasil dihapus.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormPage(supplier: _supplier)),
    );
    if (result == true) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _buildContent(colorScheme, theme),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, ThemeData theme) {
    final s = _supplier!;
    final imageUrl = s.image != null && s.image!.isNotEmpty
        ? _buildImageUrl(s.image!)
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: imageUrl != null ? 240 : 120,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: _openEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              onPressed: _delete,
              tooltip: 'Hapus',
              color: colorScheme.error,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              s.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            background: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildHeaderPlaceholder(colorScheme, s),
                  )
                : _buildHeaderPlaceholder(colorScheme, s),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      StatusBadge(
                        label: s.statusText,
                        type: s.status == 2
                            ? StatusType.success
                            : s.status == 3
                                ? StatusType.error
                                : StatusType.warning,
                        size: BadgeSize.medium,
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalLG,

                  // Contact section
                  if (s.noTelp != null) ...[
                    _buildSectionTitle('Kontak', theme),
                    _buildInfoCard(
                      colorScheme: colorScheme,
                      theme: theme,
                      children: [
                        _buildDetailRow(
                          icon: Icons.phone_rounded,
                          label: 'Telepon',
                          value: s.noTelp!,
                          colorScheme: colorScheme,
                          theme: theme,
                          onTap: () => _copyToClipboard(s.noTelp!),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalMD,
                  ],

                  // Bank details
                  if (s.bankName != null ||
                      s.bankAccountName != null ||
                      s.bankAccountNo != null) ...[
                    _buildSectionTitle('Rekening Bank', theme),
                    _buildInfoCard(
                      colorScheme: colorScheme,
                      theme: theme,
                      children: [
                        if (s.bankName != null)
                          _buildDetailRow(
                            icon: Icons.account_balance_rounded,
                            label: 'Bank',
                            value: s.bankName!,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        if (s.bankAccountName != null)
                          _buildDetailRow(
                            icon: Icons.person_rounded,
                            label: 'Nama Rekening',
                            value: s.bankAccountName!,
                            colorScheme: colorScheme,
                            theme: theme,
                            onTap: () => _copyToClipboard(s.bankAccountName!),
                          ),
                        if (s.bankAccountNo != null)
                          _buildDetailRow(
                            icon: Icons.credit_card_rounded,
                            label: 'No. Rekening',
                            value: s.bankAccountNo!,
                            colorScheme: colorScheme,
                            theme: theme,
                            onTap: () => _copyToClipboard(s.bankAccountNo!),
                            isLast: true,
                          ),
                      ],
                    ),
                    AppSpacing.gapVerticalMD,
                  ],

                  // QRIS section
                  if (s.qris != null && s.qris!.isNotEmpty) ...[
                    _buildSectionTitle('QRIS', theme),
                    _buildInfoCard(
                      colorScheme: colorScheme,
                      theme: theme,
                      children: [
                        _buildDetailRow(
                          icon: Icons.qr_code_rounded,
                          label: 'QRIS',
                          value: 'Tersedia',
                          colorScheme: colorScheme,
                          theme: theme,
                          onTap: () => _copyToClipboard(s.qris!),
                          isLast: true,
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalMD,
                  ],

                  // Address section
                  if (s.address != null) ...[
                    _buildSectionTitle('Alamat', theme),
                    _buildInfoCard(
                      colorScheme: colorScheme,
                      theme: theme,
                      children: [
                        _buildDetailRow(
                          icon: Icons.home_rounded,
                          label: 'Alamat',
                          value: s.address!,
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                        if (s.subdistrictName != null)
                          _buildDetailRow(
                            icon: Icons.location_city_rounded,
                            label: 'Kelurahan',
                            value: s.subdistrictName!,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        if (s.districtName != null)
                          _buildDetailRow(
                            icon: Icons.map_rounded,
                            label: 'Kecamatan',
                            value: s.districtName!,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        if (s.cityName != null)
                          _buildDetailRow(
                            icon: Icons.location_on_rounded,
                            label: 'Kota',
                            value: s.cityName!,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        if (s.provinceName != null)
                          _buildDetailRow(
                            icon: Icons.flag_rounded,
                            label: 'Provinsi',
                            value: s.provinceName!,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        if (s.postalCode != null)
                          _buildDetailRow(
                            icon: Icons.markunread_mailbox_rounded,
                            label: 'Kode Pos',
                            value: s.postalCode!,
                            colorScheme: colorScheme,
                            theme: theme,
                            isLast: true,
                          ),
                      ],
                    ),
                    AppSpacing.gapVerticalMD,
                  ],

                  // Meta info
                  _buildSectionTitle('Informasi', theme),
                  _buildInfoCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    children: [
                      if (s.userName != null)
                        _buildDetailRow(
                          icon: Icons.person_pin_rounded,
                          label: 'Dibuat oleh',
                          value: s.userName!,
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                      _buildDetailRow(
                        icon: Icons.tag_rounded,
                        label: 'ID Supplier',
                        value: '#${s.id}',
                        colorScheme: colorScheme,
                        theme: theme,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPlaceholder(ColorScheme colorScheme, SupplierModel s) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ColorScheme colorScheme,
    required ThemeData theme,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sectionGap),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.copy_rounded,
                      size: 14, color: colorScheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 0,
              indent: 46,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            AppSpacing.gapVerticalMD,
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
            AppSpacing.gapVerticalMD,
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showInfoSnackBar(context, '"$text" disalin ke clipboard.');
  }

  String _buildImageUrl(String imagePath) {
    return '${ApiConstants.baseUrl}/media/$imagePath';
  }
}
