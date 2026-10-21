import 'dart:async';
import 'package:flutter/foundation.dart';

class _OperationToken {
  bool active = true;
}

/// Drains work that already owns data before replacing the application's store.
class DataOperations extends ChangeNotifier {
  DataOperations._();
  static final instance = DataOperations._();
  final _zoneKey = Object();
  final _pending = <Future<void>>{};
  Completer<void>? _reopened;
  bool _replacing = false;
  int _revision = 0;
  int get revision => _revision;

  void recordReplacement() {
    if (!_replacing || !ownsOperation) {
      throw StateError('Replacement owner required.');
    }
    _revision++;
  }

  bool get isReplacing => _replacing;
  bool get ownsOperation =>
      (Zone.current[_zoneKey] as _OperationToken?)?.active ?? false;

  Future<T> run<T>(Future<T> Function() action, {bool readOnly = false}) async {
    if (_replacing && !ownsOperation) {
      if (!readOnly) throw StateError('Data is being replaced. Please wait.');
      await _reopened!.future;
    }
    final token = _OperationToken();
    final future = Future<T>.sync(
      () => runZoned(action, zoneValues: {_zoneKey: token}),
    );
    late final Future<void> settled;
    settled = future
        .then<void>((_) {}, onError: (Object error, StackTrace stack) {})
        .whenComplete(() {
          token.active = false;
          _pending.remove(settled);
        });
    _pending.add(settled);
    return future;
  }

  Future<T> replace<T>({
    required Future<void> Function() quiesce,
    required Future<T> Function() change,
  }) async {
    if (_replacing) {
      throw StateError('Another data replacement is in progress.');
    }
    _replacing = true;
    _reopened = Completer<void>();
    notifyListeners();
    final token = _OperationToken();
    try {
      await runZoned(quiesce, zoneValues: {_zoneKey: token});
      while (_pending.isNotEmpty) {
        await Future.wait(_pending.toList(growable: false));
      }
      // An old asynchronous load may have started playback while draining.
      await runZoned(quiesce, zoneValues: {_zoneKey: token});
      return await runZoned(change, zoneValues: {_zoneKey: token});
    } finally {
      token.active = false;
      _replacing = false;
      _reopened!.complete();
      _reopened = null;
      notifyListeners();
    }
  }
}
