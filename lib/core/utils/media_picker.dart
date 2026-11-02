import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'feedback.dart';

/// A file chosen on the phone, ready to upload.
typedef PickedFile = ({List<int> bytes, String name});

/// Camera or gallery → a photo (resized, so uploads stay small).
Future<PickedFile?> pickPhoto(BuildContext context) async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  try {
    final XFile? image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image == null) return null;
    return (bytes: await image.readAsBytes(), name: image.name);
  } catch (_) {
    if (context.mounted) {
      AppFeedback.toast(
        context,
        source == ImageSource.camera
            ? 'Allow camera access in Settings to take a photo.'
            : 'Allow photo access in Settings to choose a picture.',
      );
    }
    return null;
  }
}

/// A verification document: a PDF, or a photo of the certificate.
Future<PickedFile?> pickDocument(BuildContext context) async {
  final FilePickerResult? result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
    withData: true,
  );
  final PlatformFile? file = result?.files.single;
  final List<int>? bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  if (bytes.length > 10 * 1024 * 1024) {
    if (context.mounted) {
      AppFeedback.toast(context, 'Documents can be up to 10 MB.');
    }
    return null;
  }
  return (bytes: bytes, name: file.name);
}
