import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../files/document_picker.dart';

part 'document_picker_providers.g.dart';

@Riverpod(keepAlive: true)
DocumentPicker documentPicker(Ref ref) => const FilePickerDocumentPicker();
