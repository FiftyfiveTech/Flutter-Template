import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../files/document_compressor.dart';

part 'document_compressor_providers.g.dart';

@Riverpod(keepAlive: true)
DocumentCompressor documentCompressor(Ref ref) =>
    const ImageDocumentCompressor();
