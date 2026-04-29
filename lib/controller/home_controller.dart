import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class HomeController extends ChangeNotifier {
  XFile? selectedImage;
  final _picker = ImagePicker();

  bool get hasImage => selectedImage != null;

  Future<void> pickImage(BuildContext context, ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    if (!context.mounted) return;

    final primaryColor = Theme.of(context).colorScheme.primary;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Gambar',
          toolbarColor: primaryColor,
          toolbarWidgetColor: Colors.white,
          statusBarColor: primaryColor,
          backgroundColor: Colors.black,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
        ),
      ],
    );

    selectedImage = cropped != null ? XFile(cropped.path) : picked;
    notifyListeners();
  }

  void clearImage() {
    selectedImage = null;
    notifyListeners();
  }
}
