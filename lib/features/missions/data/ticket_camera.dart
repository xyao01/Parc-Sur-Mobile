import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/uuid.dart';

/// Takes the photo of a fuel receipt (Mob-C13) and keeps it in the app's own folder,
/// so that it can still be sent after a restart without network.
abstract interface class TicketCamera {
  /// Path of the saved JPEG, or `null` when the driver cancels.
  Future<String?> take();

  /// Removes photos the server has received.
  Future<void> discard(List<String> paths);
}

final ticketCameraProvider = Provider<TicketCamera>((ref) => DeviceTicketCamera());

class DeviceTicketCamera implements TicketCamera {
  final _picker = ImagePicker();

  /// Readable receipt, well under the 10 MB limit of the storage.
  static const maxSide = 1600.0;
  static const quality = 70;

  @override
  Future<String?> take() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    if (shot == null) return null;
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/tickets');
    await dir.create(recursive: true);
    final saved = await File(shot.path).copy('${dir.path}/${uuidV4()}.jpg');
    return saved.path;
  }

  @override
  Future<void> discard(List<String> paths) async {
    for (final p in paths) {
      try {
        await File(p).delete();
      } catch (_) {}
    }
  }
}
