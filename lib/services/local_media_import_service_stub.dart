import 'local_media_import_service_base.dart';

LocalMediaImportService createLocalMediaImportService({String? basePath}) {
  throw const LocalMediaImportException(
    'Local media import is not supported on this platform.',
  );
}
