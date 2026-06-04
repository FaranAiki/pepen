import 'dart:convert';
import 'dart:io';

class CompressionService {
  static List<int> compress(String data) {
    final bytes = utf8.encode(data);
    return gzip.encode(bytes);
  }

  static String decompress(List<int> bytes) {
    final decodedBytes = gzip.decode(bytes);
    return utf8.decode(decodedBytes);
  }
}
