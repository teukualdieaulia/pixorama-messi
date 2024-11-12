// lib/src/pixorama.dart

import 'package:flutter/material.dart';
import 'package:pixels/pixels.dart';
import 'package:pixorama_client/pixorama_client.dart';

import '../../main.dart';

class Pixorama extends StatefulWidget {
  const Pixorama({super.key});

  @override
  State<Pixorama> createState() => _PixoramaState();
}

class _PixoramaState extends State<Pixorama> {
  // Controller yang menyimpan data gambar piksel dan menangani pembaruan.
  PixelImageController? _imageController;

  @override
  void initState() {
    super.initState();

    // Mulai mendengarkan pembaruan dari server.
    _listenToUpdates();
  }

  /// Metode untuk mendengarkan pembaruan gambar dari server secara terus-menerus.
  Future<void> _listenToUpdates() async {
    // Terus mencoba untuk terhubung dan mendengarkan pembaruan dari server.
    while (true) {
      try {
        // Mendapatkan aliran pembaruan dari server.
        final imageUpdates = client.pixorama.imageUpdates();

        // Mendengarkan pembaruan dari aliran.
        await for (final update in imageUpdates) {
          // Memeriksa jenis pembaruan yang diterima.
          if (update is ImageData) {
            // Jika pembaruan lengkap gambar, buat PixelImageController baru.
            setState(() {
              _imageController = PixelImageController(
                pixels: update.pixels,
                palette: PixelPalette.rPlace(),
                width: update.width,
                height: update.height,
              );
            });
          } else if (update is ImageUpdate) {
            // Jika pembaruan satu piksel, perbarui piksel tunggal.
            _imageController?.setPixelIndex(
              pixelIndex: update.pixelIndex,
              colorIndex: update.colorIndex,
            );
          }
        }
      } on MethodStreamException catch (_) {
        // Jika koneksi ke server terputus atau gagal.
        setState(() {
          _imageController = null;
        });
      }

      // Tunggu 5 detik sebelum mencoba terhubung lagi.
      await Future.delayed(Duration(seconds: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _imageController == null
          ? const CircularProgressIndicator()
          : PixelEditor(
              controller: _imageController!,
              onSetPixel: (details) {
                // Ketika pengguna menggambar, kirim pembaruan ke server.
                client.pixorama.setPixel(
                  pixelIndex: details.tapDetails.index,
                  colorIndex: details.colorIndex,
                );
              },
            ),
    );
  }
}
