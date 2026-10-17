import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'profile_avatar_widget.dart';

typedef AvatarImagePicker = Future<XFile?> Function();

Future<void> showAvatarActionSheet(
  BuildContext context, {
  AvatarImagePicker? pickImage,
}) async {
  final auth = context.read<AuthProvider>();
  final action = await showModalBottomSheet<_AvatarAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        _AvatarActions(showRemove: auth.user?.avatarType != 'initial'),
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case _AvatarAction.upload:
      await _uploadAvatar(context, pickImage);
    case _AvatarAction.preset:
      await _choosePreset(context);
    case _AvatarAction.remove:
      final error = await auth.removeAvatar();
      if (context.mounted) {
        _showResult(context, error, 'Profile picture removed.');
      }
  }
}

Future<void> _uploadAvatar(
  BuildContext context,
  AvatarImagePicker? picker,
) async {
  final selected =
      await (picker?.call() ??
          ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            imageQuality: 85,
          ));
  if (selected == null || !context.mounted) return;
  final bytes = await selected.readAsBytes();
  if (!context.mounted) return;
  final mimeType = _supportedMime(selected, bytes);
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024 || mimeType == null) {
    _showResult(
      context,
      'Choose a JPEG, PNG or WebP picture smaller than 5 MB.',
      null,
    );
    return;
  }
  final error = await context.read<AuthProvider>().uploadAvatar(
    Uint8List.fromList(bytes),
    filename: selected.name,
    mimeType: mimeType,
  );
  if (context.mounted) _showResult(context, error, 'Profile picture updated.');
}

String? _supportedMime(XFile file, Uint8List bytes) {
  final claimed = file.mimeType?.toLowerCase();
  final extension = file.name.toLowerCase().split('.').last;
  final signature = bytes.length >= 12 ? bytes : Uint8List(0);
  if (signature.length >= 3 &&
      signature[0] == 0xff &&
      signature[1] == 0xd8 &&
      signature[2] == 0xff) {
    return claimed == null ||
            claimed == 'image/jpeg' ||
            extension == 'jpg' ||
            extension == 'jpeg'
        ? 'image/jpeg'
        : null;
  }
  if (signature.length >= 8 &&
      signature[0] == 0x89 &&
      signature[1] == 0x50 &&
      signature[2] == 0x4e &&
      signature[3] == 0x47) {
    return claimed == null || claimed == 'image/png' || extension == 'png'
        ? 'image/png'
        : null;
  }
  if (signature.length >= 12 &&
      String.fromCharCodes(signature.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(signature.sublist(8, 12)) == 'WEBP') {
    return claimed == null || claimed == 'image/webp' || extension == 'webp'
        ? 'image/webp'
        : null;
  }
  return null;
}

Future<void> _choosePreset(BuildContext context) async {
  var selectedId = context.read<AuthProvider>().user?.avatarType == 'preset'
      ? context.read<AuthProvider>().user?.avatarValue
      : null;
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose an avatar',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: avatarPresets.length,
              itemBuilder: (_, index) {
                final preset = avatarPresets[index];
                final selected = preset.id == selectedId;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Select ${preset.id.replaceAll('_', ' ')} avatar',
                  child: InkWell(
                    onTap: () => setState(() => selectedId = preset.id),
                    customBorder: const CircleBorder(),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: preset.background,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Icon(preset.icon, color: preset.foreground),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.pop(sheetContext, selectedId),
              child: const Text('Save avatar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  final error = await context.read<AuthProvider>().selectAvatarPreset(result);
  if (context.mounted) _showResult(context, error, 'Avatar updated.');
}

void _showResult(BuildContext context, String? error, String? success) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error ?? success ?? 'Done.')));
}

enum _AvatarAction { upload, preset, remove }

class _AvatarActions extends StatelessWidget {
  const _AvatarActions({required this.showRemove});

  final bool showRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.upload_rounded),
          title: const Text('Upload from device'),
          onTap: () => Navigator.pop(context, _AvatarAction.upload),
        ),
        ListTile(
          leading: const Icon(Icons.face_retouching_natural_rounded),
          title: const Text('Choose built-in avatar'),
          onTap: () => Navigator.pop(context, _AvatarAction.preset),
        ),
        if (showRemove)
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Remove current picture'),
            onTap: () => Navigator.pop(context, _AvatarAction.remove),
          ),
        ListTile(
          leading: const Icon(Icons.close_rounded),
          title: const Text('Cancel'),
          onTap: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
