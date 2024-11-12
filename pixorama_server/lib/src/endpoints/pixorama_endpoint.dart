// lib/src/endpoints/pixorama_endpoint.dart

import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';
import 'package:pixorama_server/src/generated/protocol.dart';

class PixoramaEndpoint extends Endpoint {
  // Konstanta yang mendefinisikan ukuran gambar dan jumlah warna
  static const _imageWidth = 64;
  static const _imageHeight = 64;
  static const _numPixels = _imageWidth * _imageHeight;
  static const _numColorsInPalette = 16;
  static const _defaultPixelColor = 2;
  static const _channelPixelAdded = 'pixel-added';

  // Data piksel global yang merepresentasikan gambar
  final _pixelData = Uint8List(_numPixels)
    ..fillRange(
      0,
      _numPixels,
      _defaultPixelColor,
    );

  /// Mengatur satu piksel dan memberi tahu semua klien yang terhubung
  /// tentang perubahan tersebut.
  Future<void> setPixel(
    Session session, {
    required int colorIndex,
    required int pixelIndex,
  }) async {
    // Memeriksa apakah parameter input valid
    if (colorIndex < 0 || colorIndex >= _numColorsInPalette) {
      throw FormatException('colorIndex is out of range: $colorIndex');
    }
    if (pixelIndex < 0 || pixelIndex >= _numPixels) {
      throw FormatException('pixelIndex is out of range: $pixelIndex');
    }

    // Memperbarui data piksel dengan warna yang baru
    _pixelData[pixelIndex] = colorIndex;

    // Mengirimkan pesan ke semua klien yang terhubung tentang pembaruan piksel
    session.messages.postMessage(
      _channelPixelAdded,
      ImageUpdate(
        pixelIndex: pixelIndex,
        colorIndex: colorIndex,
      ),
    );
  }

  /// Mengembalikan aliran pembaruan gambar. Pesan pertama adalah
  /// `ImageData` yang berisi gambar penuh. Pembaruan berikutnya adalah
  /// `ImageUpdate` yang berisi piksel yang diperbarui.
  Stream imageUpdates(Session session) async* {
    // Mendapatkan aliran pembaruan dari saluran pixel-added
    var updateStream =
        session.messages.createStream<ImageUpdate>(_channelPixelAdded);

    // Mengirimkan gambar penuh pertama kali ke klien
    yield ImageData(
      pixels: _pixelData.buffer.asByteData(),
      width: _imageWidth,
      height: _imageHeight,
    );

    // Meneruskan semua pembaruan piksel individual ke klien
    await for (var imageUpdate in updateStream) {
      yield imageUpdate;
    }
  }
}
