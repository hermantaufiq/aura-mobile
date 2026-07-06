import 'dart:typed_data';

class AvatarImageData {
  final Uint8List bytes;
  final String filename;

  const AvatarImageData({
    required this.bytes,
    required this.filename,
  });
}
