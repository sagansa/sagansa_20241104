import 'package:flutter/material.dart';
import '../models/applicant_detail_model.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AdminProfileDetailPage extends StatefulWidget {
  final int profileId;
  const AdminProfileDetailPage({super.key, required this.profileId});

  @override
  State<AdminProfileDetailPage> createState() =>
      _AdminProfileDetailPageState();
}

class _AdminProfileDetailPageState extends State<AdminProfileDetailPage> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _detail;
  Map<String, dynamic>? _user;
  bool _locked = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await _userService.getAdminProfileDetail(widget.profileId);
      if (!mounted) return;
      setState(() {
        _detail = res['details'];
        _user = res['user'];
        _locked = res['locked'] == true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLock() async {
    setState(() => _isSaving = true);
    try {
      final newStatus = _locked ? 'draft' : 'submitted';
      final res =
          await _userService.setProfileStatus(widget.profileId, newStatus);
      if (!mounted) return;
      setState(() {
        _locked = res['locked'] == true;
        if (res['details'] is Map<String, dynamic>) {
          _detail = res['details'];
        }
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Berhasil.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _row(String label, String? value, TextTheme textTheme,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Profil')),
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                AppSpacing.gapVerticalMD,
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _detail ?? {};
    final detail = ApplicantDetail.fromJson(
        d);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Profil')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: _locked
                    ? colorScheme.error.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Row(
                children: [
                  Icon(
                    _locked ? Icons.lock : Icons.lock_open,
                    color: _locked
                        ? colorScheme.error
                        : AppColors.success,
                  ),
                  AppSpacing.gapHorizontalSM,
                  Expanded(
                    child: Text(
                      _locked
                          ? 'Profil TERKUNCI — hanya rekening yang dapat diubah user.'
                          : 'Profil TERBUKA — user dapat mengubah semua data.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _locked
                            ? colorScheme.error
                            : AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVerticalMD,
            Text('Data User',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            _row('Nama', _user?['name'], textTheme, colorScheme),
            _row('Email', _user?['email'], textTheme, colorScheme),
            _row('Status', detail.status ?? 'draft', textTheme, colorScheme),
            AppSpacing.gapVerticalMD,
            Text('Data Pribadi',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            _row('Nama Panggilan', detail.nickname, textTheme, colorScheme),
            _row('No. Telepon', detail.phone, textTheme, colorScheme),
            _row('NIK', detail.nik, textTheme, colorScheme),
            _row('Tempat Lahir', detail.birthPlace, textTheme, colorScheme),
            _row('Tanggal Lahir', detail.birthDate, textTheme, colorScheme),
            _row('Agama', detail.religion, textTheme, colorScheme),
            _row('Status Pernikahan', detail.maritalStatus, textTheme, colorScheme),
            _row('Pendidikan', detail.educationLevel, textTheme, colorScheme),
            _row('Alamat', detail.address, textTheme, colorScheme),
            _row('Kontak Darurat', detail.emergencyName, textTheme, colorScheme),
            _row('Telepon Darurat', detail.emergencyPhone, textTheme, colorScheme),
            AppSpacing.gapVerticalMD,
            Text('Data Rekening',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            _row('Nama Bank', detail.bankName, textTheme, colorScheme),
            _row('Pemilik Rekening', detail.bankAccountName, textTheme, colorScheme),
            _row('No. Rekening', detail.bankAccountNumber, textTheme, colorScheme),
            AppSpacing.gapVerticalLG,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _toggleLock,
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(_locked ? Icons.lock_open : Icons.lock),
                label: Text(_isSaving
                    ? 'Memproses...'
                    : (_locked ? 'Buka Kunci Profil' : 'Kunci Profil')),
              ),
            ),
            AppSpacing.gapVerticalLG,
          ],
        ),
      ),
    );
  }
}
