import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'services/storage_service.dart';

/// StorageService Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
