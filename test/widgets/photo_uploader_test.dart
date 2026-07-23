import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagansa/widgets/photo_uploader.dart';

/// Helper: buat file dummy untuk simulasi photo.
File _dummyImageFile() => File('test_assets/dummy_image.png');

void main() {
  group('PhotoUploader — grid layout', () {
    testWidgets('shows label + add icon when no photos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: const [],
              onChanged: (_) {},
              label: 'Unggah Foto Bukti',
              maxPhotos: 3,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
      expect(find.text('Unggah Foto Bukti'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided and no photos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: const [],
              onChanged: (_) {},
              label: 'Unggah Foto',
              subtitle: 'Ketuk untuk kamera',
              maxPhotos: 3,
            ),
          ),
        ),
      );

      expect(find.text('Ketuk untuk kamera'), findsOneWidget);
    });

    testWidgets('hides add button when maxPhotos reached (grid)', (tester) async {
      // maxPhotos=1, sudah 1 photo → add button hilang.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: [_dummyImageFile()],
              onChanged: (_) {},
              maxPhotos: 1,
              layout: PhotoUploaderLayout.grid,
            ),
          ),
        ),
      );

      // Tidak ada tombol "Tambah Foto Lagi" karena sudah full.
      expect(find.text('Tambah Foto Lagi'), findsNothing);
    });

    testWidgets('shows "Tambah Foto Lagi" when photos exist but not full',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: [_dummyImageFile()],
              onChanged: (_) {},
              maxPhotos: 3,
              layout: PhotoUploaderLayout.grid,
            ),
          ),
        ),
      );

      expect(find.text('Tambah Foto Lagi'), findsOneWidget);
    });
  });

  group('PhotoUploader — singleCard layout', () {
    testWidgets('shows OutlinedButton when no photo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: const [],
              onChanged: (_) {},
              maxPhotos: 1,
              layout: PhotoUploaderLayout.singleCard,
              label: 'Ambil Foto',
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
    });

    testWidgets('shows remove button when photo present (singleCard)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: [_dummyImageFile()],
              onChanged: (_) {},
              maxPhotos: 1,
              layout: PhotoUploaderLayout.singleCard,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });

  group('PhotoUploader — onChanged callback', () {
    testWidgets('remove button calls onChanged with reduced list',
        (tester) async {
      List<File>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploader(
              photos: [_dummyImageFile()],
              onChanged: (updated) => result = updated,
              maxPhotos: 3,
              layout: PhotoUploaderLayout.singleCard,
            ),
          ),
        ),
      );

      // Tap remove button.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.length, 0);
    });
  });
}
