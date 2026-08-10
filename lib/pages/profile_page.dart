import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../models/applicant_detail_model.dart';
import '../services/user_service.dart';
import '../theme/app_spacing.dart';
import '../utils/error_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final _nicknameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _maritalCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  final _bankAccountNumberCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    for (final c in [
      _nicknameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _nikCtrl,
      _birthPlaceCtrl,
      _birthDateCtrl,
      _religionCtrl,
      _maritalCtrl,
      _educationCtrl,
      _emergencyPhoneCtrl,
      _emergencyNameCtrl,
      _bankNameCtrl,
      _bankAccountNameCtrl,
      _bankAccountNumberCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detail = await _userService.getProfile();
      if (!mounted) return;
      _fillControllers(detail);
      setState(() {
        _isLocked = detail.isLocked;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorUtils.sanitize(e);
        _isLoading = false;
      });
    }
  }

  void _fillControllers(ApplicantDetail d) {
    _nicknameCtrl.text = d.nickname ?? '';
    _phoneCtrl.text = d.phone ?? '';
    _addressCtrl.text = d.address ?? '';
    _nikCtrl.text = d.nik ?? '';
    _birthPlaceCtrl.text = d.birthPlace ?? '';
    _birthDateCtrl.text = d.birthDate ?? '';
    _religionCtrl.text = d.religion ?? '';
    _maritalCtrl.text = d.maritalStatus ?? '';
    _educationCtrl.text = d.educationLevel ?? '';
    _emergencyPhoneCtrl.text = d.emergencyPhone ?? '';
    _emergencyNameCtrl.text = d.emergencyName ?? '';
    _bankNameCtrl.text = d.bankName ?? '';
    _bankAccountNameCtrl.text = d.bankAccountName ?? '';
    _bankAccountNumberCtrl.text = d.bankAccountNumber ?? '';
  }

  ApplicantDetail _collect() {
    return ApplicantDetail(
      nickname: _nicknameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      nik: _nikCtrl.text.trim(),
      birthPlace: _birthPlaceCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim(),
      religion: _religionCtrl.text.trim(),
      maritalStatus: _maritalCtrl.text.trim(),
      educationLevel: _educationCtrl.text.trim(),
      emergencyPhone: _emergencyPhoneCtrl.text.trim(),
      emergencyName: _emergencyNameCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      bankAccountName: _bankAccountNameCtrl.text.trim(),
      bankAccountNumber: _bankAccountNumberCtrl.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = await _userService.updateProfile(_collect());
      if (!mounted) return;
      _fillControllers(updated);
      setState(() {
        _isLocked = updated.isLocked;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
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

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _birthDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Saya')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Saya')),
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!,
                    style: TextStyle(color: colorScheme.error)),
                AppSpacing.gapVerticalMD,
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLocked)
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMD,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: AppSpacing.borderRadiusMD,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 18, color: AppColors.info),
                      AppSpacing.gapHorizontalSM,
                      Expanded(
                        child: Text(
                          'Data pribadi terkunci. Hanya rekening yang dapat diubah.',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              Text('Data Pribadi',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.gapVerticalSM,
              _field(_nicknameCtrl, 'Nama Panggilan', enabled: !_isLocked),
              _field(_phoneCtrl, 'No. Telepon',
                  enabled: !_isLocked, keyboard: TextInputType.phone),
              _field(_nikCtrl, 'NIK', enabled: !_isLocked),
              _field(_birthPlaceCtrl, 'Tempat Lahir', enabled: !_isLocked),
              if (_isLocked)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Lahir',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: Text(
                    _birthDateCtrl.text.trim().isNotEmpty
                        ? _birthDateCtrl.text.trim()
                        : '-',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                TextFormField(
                  controller: _birthDateCtrl,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              AppSpacing.gapVerticalSM,
              _field(_religionCtrl, 'Agama', enabled: !_isLocked),
              _field(_maritalCtrl, 'Status Pernikahan', enabled: !_isLocked),
              _field(_educationCtrl, 'Pendidikan Terakhir', enabled: !_isLocked),
              _field(_addressCtrl, 'Alamat', enabled: !_isLocked, maxLines: 2),
              _field(_emergencyNameCtrl, 'Kontak Darurat (Nama)',
                  enabled: !_isLocked),
              _field(_emergencyPhoneCtrl, 'Kontak Darurat (Telepon)',
                  enabled: !_isLocked, keyboard: TextInputType.phone),
              AppSpacing.gapVerticalMD,
              Text('Data Rekening',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.gapVerticalSM,
              _field(_bankNameCtrl, 'Nama Bank'),
              _field(_bankAccountNameCtrl, 'Nama Pemilik Rekening'),
              _field(_bankAccountNumberCtrl, 'No. Rekening',
                  keyboard: TextInputType.number),
              AppSpacing.gapVerticalLG,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                ),
              ),
              AppSpacing.gapVerticalLG,
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Saat terkunci: tampilkan sebagai teks statis (tanpa cursor/input).
    if (!enabled) {
      final value = ctrl.text.trim();
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Text(
            value.isNotEmpty ? value : '-',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
