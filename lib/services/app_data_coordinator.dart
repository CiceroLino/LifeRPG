import '../data/database/data_operations.dart';

class AppDataCoordinator {
  AppDataCoordinator({
    required this.quiesce,
    required this.reload,
    this.afterReplacement,
  });
  final Future<void> Function() quiesce;
  final List<Future<void> Function()> reload;
  final void Function()? afterReplacement;

  Future<T> replaceData<T>(
    Future<T> Function() change, {
    bool Function(T)? wasReplaced,
  }) => DataOperations.instance.replace(
    quiesce: quiesce,
    change: () async {
      try {
        final result = await change();
        if (wasReplaced?.call(result) ?? true) afterReplacement?.call();
        return result;
      } finally {
        await Future.wait(reload.map((load) => load()));
      }
    },
  );
}
