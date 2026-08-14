/// Konstanta & perhitungan Berat Jenis (Specific Gravity) untuk storage-staff.
///
/// Rumus dihitung memakai integer "deci-gram" (1/10 gram) supaya tidak ada
/// float drift. Semua konstanta produksi ditetapkan di satu tempat ini.
library;

/// Volume tetap per perhitungan produksi, dalam liter.
const double kSpecificGravityVolumeLiters = 19;

/// Berat baseline tetap, dalam kg.
const double kSpecificGravityBaselineKg = 17;

/// Hasil perhitungan berat jenis.
class SpecificGravityResult {
  final double gramPerLiter;
  final double totalKg;
  final double additionalGram;
  final String totalKgFormatted;
  final String additionalGramFormatted;

  const SpecificGravityResult({
    required this.gramPerLiter,
    required this.totalKg,
    required this.additionalGram,
    required this.totalKgFormatted,
    required this.additionalGramFormatted,
  });
}

/// Menghitung berat jenis dari input gram/liter tunggal.
///
/// [gramPerLiter] adalah angka desimal (cth `906.5`). Mengembalikan hasil
/// dengan presisi exact via integer deci-gram.
SpecificGravityResult calculateSpecificGravity(double gramPerLiter) {
  final int inputDecig = (gramPerLiter * 10).round();
  final int totalDecig = (kSpecificGravityVolumeLiters * inputDecig).round();
  final double totalKg = totalDecig / 10000.0;

  final int baselineDecig =
      (kSpecificGravityBaselineKg * 1000 * 10).round(); // 17 kg = 170000 decig
  final int addDecig = totalDecig - baselineDecig;
  final double additionalGram = addDecig / 10.0;

  return SpecificGravityResult(
    gramPerLiter: gramPerLiter,
    totalKg: totalKg,
    additionalGram: additionalGram,
    totalKgFormatted: totalKg.toStringAsFixed(4),
    additionalGramFormatted: additionalGram.toStringAsFixed(1),
  );
}
