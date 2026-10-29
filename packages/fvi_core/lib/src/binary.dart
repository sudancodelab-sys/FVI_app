import 'dart:convert';
import 'dart:typed_data';

import 'errors.dart';

/// Minimal big-endian writer for the compact wire formats used in requests
/// and activation codes. Every variable-length field is length-prefixed so the
/// reader never has to guess where a field ends.
class ByteWriter {
  final BytesBuilder _out = BytesBuilder(copy: false);

  void u8(int value) {
    RangeError.checkValueInInterval(value, 0, 0xFF, 'value');
    _out.addByte(value);
  }

  void u16(int value) {
    RangeError.checkValueInInterval(value, 0, 0xFFFF, 'value');
    _out
      ..addByte(value >> 8)
      ..addByte(value & 0xFF);
  }

  void u32(int value) {
    RangeError.checkValueInInterval(value, 0, 0xFFFFFFFF, 'value');
    _out
      ..addByte(value >> 24)
      ..addByte((value >> 16) & 0xFF)
      ..addByte((value >> 8) & 0xFF)
      ..addByte(value & 0xFF);
  }

  /// Writes exactly [length] bytes, with no prefix.
  void fixed(List<int> bytes, int length) {
    if (bytes.length != length) {
      throw ArgumentError('expected $length bytes, got ${bytes.length}');
    }
    _out.add(bytes);
  }

  /// Writes a u16 length prefix followed by the bytes.
  void bytes16(List<int> bytes) {
    u16(bytes.length);
    _out.add(bytes);
  }

  /// Writes a UTF-8 string with a u16 byte-length prefix.
  void string(String value) => bytes16(utf8.encode(value));

  Uint8List toBytes() => _out.toBytes();
}

class ByteReader {
  ByteReader(List<int> data)
    : _data = data is Uint8List ? data : Uint8List.fromList(data);

  final Uint8List _data;
  int _offset = 0;

  int get offset => _offset;
  bool get isDone => _offset == _data.length;

  Uint8List _take(int length) {
    if (_offset + length > _data.length) {
      throw const FviFormatException('unexpected end of data');
    }
    final view = Uint8List.sublistView(_data, _offset, _offset + length);
    _offset += length;
    return view;
  }

  int u8() => _take(1)[0];

  int u16() {
    final b = _take(2);
    return (b[0] << 8) | b[1];
  }

  int u32() {
    final b = _take(4);
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  }

  Uint8List fixed(int length) => Uint8List.fromList(_take(length));

  Uint8List bytes16() => fixed(u16());

  String string() {
    try {
      return utf8.decode(_take(u16()));
    } on FormatException {
      throw const FviFormatException('invalid UTF-8 text');
    }
  }

  /// The bytes from [start] up to the current position. Used to recover the
  /// exact encoded header for signature and AAD checks.
  Uint8List consumedSince(int start) =>
      Uint8List.fromList(Uint8List.sublistView(_data, start, _offset));

  void expectDone() {
    if (!isDone) throw const FviFormatException('unexpected trailing data');
  }
}
