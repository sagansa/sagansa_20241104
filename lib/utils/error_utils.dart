/// Utilitas untuk membersihkan pesan error sebelum ditampilkan ke user.
///
/// Beberapa exception jaringan (mis. SocketException, ClientException) menyertakan
/// URL lengkap (https://...) di dalam pesan. URL ini tidak perlu dan tidak boleh
/// ditampilkan ke user, sehingga kita buang di satu tempat terpusat.
class ErrorUtils {
  // Cocok untuk http:// maupun https:// beserta path/query-nya.
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/[^\s]+',
    caseSensitive: false,
  );

  /// Hilangkan URL dari pesan error dan bersihkan prefix "Exception: ".
  ///
  /// Jika setelah dibersihkan pesan kosong (mis. error murni jaringan tanpa
  /// teks bermakna), kembalikan [fallback].
  static String sanitize(dynamic error, {String fallback = 'Terjadi kesalahan. Coba lagi.'}) {
    var msg = error?.toString() ?? fallback;
    msg = msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
    msg = msg.replaceAll(_urlRegex, '').trim();
    // Bersihkan spasi/format sisa akibat penghapusan URL.
    msg = msg.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (msg.isEmpty) return fallback;
    return msg;
  }
}
