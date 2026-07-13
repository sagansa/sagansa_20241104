import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/hygiene_model.dart';
import '../services/hygiene_service.dart';
import '../utils/image_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_sheet.dart';

class HygienePage extends StatefulWidget {
  const HygienePage({super.key});

  @override
  State<HygienePage> createState() => _HygienePageState();
}

class _HygienePageState extends State<HygienePage> {
  final HygieneService _hygieneService = HygieneService();
  final ImagePicker _picker = ImagePicker();

  List<RoomModel> _rooms = [];
  final Map<int, File?> _roomPhotos = {};
  final Map<int, int> _roomConditions = {};
  final Map<int, String?> _roomNotes = {};
  int? _storeId;
  String? _storeName;

  bool _isLoading = true;
  bool _hasSubmittedToday = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _hygieneService.getRooms(),
        _hygieneService.checkTodayStatus(),
      ]);

      final rooms = results[0] as List<RoomModel>;
      final hasSubmitted = results[1] as bool;

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _hasSubmittedToday = hasSubmitted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  int get _completedCount {
    int count = 0;
    for (final room in _rooms) {
      if (_roomPhotos[room.id] != null || _roomConditions.containsKey(room.id)) {
        count++;
      }
    }
    return count;
  }

  bool get _isReadyToSubmit {
    return _completedCount >= _rooms.length;
  }

  Future<void> _pickImage(int roomId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (image != null && mounted) {
        final compressed = await ImageUtils.compressToWebP(image.path);
        if (mounted) {
          setState(() {
            _roomPhotos[roomId] = compressed;
            if (!_roomConditions.containsKey(roomId)) {
              _roomConditions[roomId] = 1;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e')),
        );
      }
    }
  }

  Future<void> _pickCondition(int roomId) async {
    final result = await ModernBottomSheet.show<int>(
      context: context,
      title: 'Kondisi Ruangan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _conditionOption(1, 'Bersih', AppColors.success, Icons.check_circle, roomId),
          AppSpacing.gapVerticalSM,
          _conditionOption(2, 'Perlu Perhatian', AppColors.warning, Icons.info, roomId),
          AppSpacing.gapVerticalSM,
          _conditionOption(3, 'Kotor', AppColors.error, Icons.warning, roomId),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _roomConditions[roomId] = result;
      });
    }
  }

  Widget _conditionOption(int value, String label, Color color, IconData icon, int roomId) {
    final isSelected = _roomConditions[roomId] == value;
    return ElevatedButton.icon(
      onPressed: () => Navigator.pop(context, value),
      icon: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.onPrimary : color),
      label: Text(label),
      style: ElevatedButton.styleFrom(),
    );
  }

  Future<void> _addNotes(int roomId) async {
    final controller = TextEditingController(text: _roomNotes[roomId] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tulis catatan kondisi ruangan...',

          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _roomNotes[roomId] = result.trim().isEmpty ? null : result.trim();
      });
    }
  }

  Future<void> _submit() async {
    if (!_isReadyToSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua ruangan terlebih dahulu!')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Laporan'),
        content: Text('Kirim laporan kebersihan untuk $_completedCount ruangan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final rooms = _rooms.map((room) {
        return {
          'room_id': room.id,
          'image_path': _roomPhotos[room.id]?.path,
          'condition': _roomConditions[room.id],
          'notes': _roomNotes[room.id],
        };
      }).toList();

      await _hygieneService.submitHygiene(
        storeId: _storeId ?? 0,
        rooms: rooms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan kebersihan berhasil dikirim!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebersihan Toko'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasSubmittedToday
              ? _buildSubmittedView()
              : _buildForm(),
    );
  }

  Widget _buildSubmittedView() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: AppColors.success),
          AppSpacing.gapVerticalMD,
          Text(
            'Anda sudah mengirim laporan kebersihan hari ini',
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
    );
  }

  Widget _buildForm() {
    final progress = _rooms.isEmpty ? 0.0 : _completedCount / _rooms.length;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_storeName != null)
                        Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha:0.1),
                            borderRadius: AppSpacing.borderRadiusSM,
                            border: Border.all(color: AppColors.info.withValues(alpha:0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, color: AppColors.info),
                              AppSpacing.gapHorizontalSM,
                              Text(
                                _storeName!,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (_storeName != null) AppSpacing.gapVerticalMD,
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppSpacing.borderRadiusSM,
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          AppSpacing.gapHorizontalMD,
                          Text(
                            '$_completedCount/${_rooms.length}',
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      AppSpacing.gapVerticalSM,
                      Text(
                        _isReadyToSubmit
                            ? 'Semua ruangan sudah diperiksa'
                            : '${_rooms.length - _completedCount} ruangan belum diperiksa',
                        style: TextStyle(
                          color: _isReadyToSubmit ? AppColors.success : AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                      AppSpacing.gapVerticalMD,
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: AppSpacing.paddingHorizontalMD,
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRoomCard(_rooms[index]),
                    childCount: _rooms.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ),
            ],
          ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final hasPhoto = _roomPhotos.containsKey(room.id);
    final condition = _roomConditions[room.id];
    final hasNotes = _roomNotes.containsKey(room.id) && _roomNotes[room.id] != null;
    final isComplete = hasPhoto || condition != null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color? conditionColor;
    String conditionLabel = '';
    if (condition == 1) { conditionColor = AppColors.success; conditionLabel = 'Bersih'; }
    else if (condition == 2) { conditionColor = AppColors.warning; conditionLabel = 'Perlu Perhatian'; }
    else if (condition == 3) { conditionColor = AppColors.error; conditionLabel = 'Kotor'; }

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isComplete)
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
              ],
            ),
            AppSpacing.gapVerticalSM,
            Expanded(
              child: GestureDetector(
                onTap: () => _pickImage(room.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                    borderRadius: AppSpacing.borderRadiusSM,
                    border: Border.all(
                      color: hasPhoto
                          ? AppColors.success
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: AppSpacing.borderRadiusSM,
                          child: Image.file(
                            _roomPhotos[room.id]!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 28,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            AppSpacing.gapVerticalXS,
                            Text(
                              'Foto',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            AppSpacing.gapVerticalSM,
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickCondition(room.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: conditionColor?.withValues(alpha:0.1) ?? Colors.transparent,
                        borderRadius: AppSpacing.borderRadiusSM,
                        border: Border.all(
                          color: conditionColor ?? colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        conditionLabel.isEmpty ? 'Kondisi' : conditionLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: conditionLabel.isEmpty ? FontWeight.normal : FontWeight.bold,
                          color: conditionColor ?? colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapHorizontalXS,
                GestureDetector(
                  onTap: () => _addNotes(room.id),
                  child: Container(
                    padding: AppSpacing.paddingXS,
                    decoration: BoxDecoration(
                      color: hasNotes ? AppColors.info.withValues(alpha:0.1) : Colors.transparent,
                      borderRadius: AppSpacing.borderRadiusSM,
                      border: Border.all(
                        color: hasNotes ? AppColors.info : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      hasNotes ? Icons.notes : Icons.notes_outlined,
                      size: 16,
                      color: hasNotes ? AppColors.info : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.cardPadding.left,
        bottom: AppSpacing.cardPadding.left + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(
            _isSubmitting ? 'Mengirim...' : 'KIRIM LAPORAN KEBERSIHAN',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
