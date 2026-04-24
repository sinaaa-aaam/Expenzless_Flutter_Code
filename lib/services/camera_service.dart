// lib/services/camera_service.dart
// LOCAL RESOURCE 1: Camera
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'gemini_service.dart';

class ReceiptScanResult {
  final String? vendor;
  final double? amount;
  final DateTime? date;
  final String? category;
  final String? receiptImageUrl;
  final String? rawText;

  ReceiptScanResult({
    this.vendor, this.amount, this.date, this.category,
    this.receiptImageUrl, this.rawText,
  });
}

class CameraService {
  static final _picker = ImagePicker();

  static Future<ReceiptScanResult?> scanReceiptFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera, imageQuality: 85, maxWidth: 1920);
    if (image == null) return null;
    return _processImage(image);
  }

  static Future<ReceiptScanResult?> pickReceiptFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return null;
    return _processImage(image);
  }

  static Future<ReceiptScanResult> _processImage(XFile image) async {
    final bytes       = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final fileName   = 'receipts/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);
    await storageRef.putFile(File(image.path));
    final downloadUrl = await storageRef.getDownloadURL();

    final extracted = await GeminiService.extractReceiptData(base64Image);

    return ReceiptScanResult(
      vendor:          extracted['vendor'] as String?,
      amount:          (extracted['amount'] as num?)?.toDouble(),
      date:            extracted['date'] != null
                         ? DateTime.tryParse(extracted['date'].toString())
                         : null,
      category:        extracted['category'] as String?,
      receiptImageUrl: downloadUrl,
      rawText:         extracted['raw'] as String?,
    );
  }
}
