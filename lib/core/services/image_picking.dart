
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// An image chosen by the user, ready to upload.
class PickedImage {
  const PickedImage({required this.bytes, required this.ext});
  final Uint8List bytes;
  final String ext;
}

/// Where an image came from.
enum ImagePickSource { camera, gallery }

/// Raised when picking fails for a reason worth telling the user about.
class ImagePickException implements Exception {
  const ImagePickException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Picks and decodes one image from the camera or the photo library.
///
/// Returns null when the user backs out. Throws [ImagePickException] with a
/// user-facing message when the OS refuses — a denied permission is the common
/// case and needs different wording from a generic failure, since the user has
/// to fix it in Settings rather than by retrying.
Future<PickedImage?> pickImage(
  ImagePickSource source, {
  double maxWidth = 1600,
  int quality = 80,
}) async {
  try {
    final file = await ImagePicker().pickImage(
      source: source == ImagePickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: quality,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImagePickException('That image could not be read.');
    }
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    return PickedImage(bytes: bytes, ext: ext);
  } on PlatformException catch (e) {
    throw ImagePickException(switch (e.code) {
      'camera_access_denied' =>
        'Camera access is off. Enable it for CampusConnect in Settings.',
      'photo_access_denied' =>
        'Photo access is off. Enable it for CampusConnect in Settings.',
      'no_available_camera' => 'This device has no camera available.',
      _ => 'Could not open that image. Please try again.',
    });
  } on ImagePickException {
    rethrow;
  } catch (_) {
    throw const ImagePickException('Could not open that image.');
  }
}
