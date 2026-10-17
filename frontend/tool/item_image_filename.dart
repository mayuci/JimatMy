import 'dart:io';

import 'package:jimatmy/utils/item_image_key.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.join(' ').trim().isEmpty) {
    stderr.writeln('Usage: dart run tool/item_image_filename.dart "ITEM NAME"');
    exitCode = 64;
    return;
  }
  stdout.writeln(itemImageFilename(arguments.join(' ')));
}
