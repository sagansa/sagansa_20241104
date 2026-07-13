import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/readiness_service.dart';
import '../utils/image_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ReadinessPage extends StatefulWidget {
  const ReadinessPage({super.key});

  @override
  State<ReadinessPage> createState() => _ReadinessPageState();
}

class _ReadinessPageState extends State<ReadinessPage> {
  final ReadinessService _readinessService = ReadinessService();
  final ImagePicker _picker = ImagePicker();

  File? _selfieImage;
  File? _leftHandImage;
  File? _rightHandImage;
  bool _isLoading = false;
  bool _hasSubmittedToday = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _readinessService.checkStatus();
      if (mounted) {
        setState(() {
          _hasSubmittedToday = status['data']['has_submitted_today'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengecek status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (image != null) {
        final compressed = await ImageUtils.compressToWebP(image.path);
        if (mounted) {
          setState(() {
            if (type == 'selfie') _selfieImage = compressed;
            if (type == 'left_hand') _leftHandImage = compressed;
            if (type == 'right_hand') _rightHandImage = compressed;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kamera: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_selfieImage == null || _leftHandImage == null || _rightHandImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua foto yang diperlukan!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _readinessService.submitReadiness(
        selfiePath: _selfieImage!.path,
        leftHandPath: _leftHandImage!.path,
        rightHandPath: _rightHandImage!.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengirim Kesiapan Diri!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePickerCard(String title, String description, File? image, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapVerticalXS,
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalMD,
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(type),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                    borderRadius: AppSpacing.borderRadiusSM,
                    border: Border.all(
                      color: image != null
                          ? AppColors.success
                          : colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: image != null
                      ? ClipRRect(
                          borderRadius: AppSpacing.borderRadiusSM,
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            AppSpacing.gapVerticalSM,
                            Text(
                              'Tap untuk mengambil foto',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesiapan Diri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasSubmittedToday
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: AppColors.success),
                      AppSpacing.gapVerticalMD,
                      Text(
                        'Anda sudah mengisi Kesiapan Diri hari ini',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapVerticalLG,
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: AppSpacing.paddingMD,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: AppSpacing.paddingMD,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha:0.1),
                          borderRadius: AppSpacing.borderRadiusSM,
                          border: Border.all(color: AppColors.info.withValues(alpha:0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.info),
                                AppSpacing.gapHorizontalSM,
                                Text(
                                  'Perhatian',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapVerticalSM,
                            const Text(
                              'Kesiapan Diri wajib diisi setiap hari Jumat sebelum Anda dapat melakukan Absen Masuk (Clock In).',
                            ),
                            AppSpacing.gapVerticalSM,
                            const Text('- Kuku harus bersih'),
                            const Text('- Rambut laki-laki harus pendek dan rapi'),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalLG,
                      _buildImagePickerCard(
                        'Foto Selfie',
                        'Tampilkan wajah dan rambut dengan jelas untuk melihat kerapihan.',
                        _selfieImage,
                        'selfie',
                      ),
                      _buildImagePickerCard(
                        'Foto Tangan Kiri',
                        'Tampilkan punggung jari dan kuku tangan kiri dengan jelas.',
                        _leftHandImage,
                        'left_hand',
                      ),
                      _buildImagePickerCard(
                        'Foto Tangan Kanan',
                        'Tampilkan punggung jari dan kuku tangan kanan dengan jelas.',
                        _rightHandImage,
                        'right_hand',
                      ),
                      AppSpacing.gapVerticalMD,
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(
                          'KIRIM KESIAPAN DIRI',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      AppSpacing.gapVerticalXL,
                    ],
                  ),
                ),
    );
  }
}
