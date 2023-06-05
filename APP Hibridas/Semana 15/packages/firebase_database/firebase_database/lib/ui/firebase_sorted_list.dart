// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:firebase_core/firebase_core.dart';

import '../firebase_database.dart' show DataSnapshot, DatabaseEvent, Query;
import 'firebase_list.dart' show ChildCallback, ErrorCallback, ValueCallback;
import 'utils/stream_subscriber_mixin.dart';

/// Sorts the results of `query` on the client side using to the `comparator`.
// We can be smarter about how we handle insertion and keep the list always
// sorted. See example here:
// https://github.com/firebase/FirebaseUI-iOS/blob/master/FirebaseDatabaseUI/FUISortedArray.m
class FirebaseSortedList extends ListBase<DataSnapshot>
    with
        // ignore: prefer_mixin
        StreamSubscriberMixin<DatabaseEvent> {
  FirebaseSortedList({
    required this.query,
    required this.comparator,
    this.onChildAdded,
    this.onChildRemoved,
    this.onChildChanged,
    this.onValue,
    this.onError,
  }) {
    if (onChildAdded != null) {
      listen(query.onChildAdded, _onChildAdded, onError: _onError);
    }
    if (onChildRemoved != null) {
      listen(query.onChildRemoved, _onChildRemoved, onError: _onError);
    }
    if (onChildChanged != null) {
      listen(query.onChildChanged, _onChildChanged, onError: _onError);
    }
    if (onValue != null) {
      listen(query.onValue, _onValue, onError: _onError);
    }
  }

  /// Database query used to populate the list
  final Query query;

  /// The comparator used to sort the list on the client side
  final Comparator<DataSnapshot> comparator;

  /// Called when the child has been added
  final ChildCallback? onChildAdded;

  /// Called when the child has been removed
  final ChildCallback? onChildRemoved;

  /// Called when the child has changed
  final ChildCallback? onChildChanged;

  /// Called when the data of the list has finished loading
  final ValueCallback? onValue;

  /// Called when an error is reported (e.g. permission denied)
  final ErrorCallback? onError;

  // ListBase implementation
  final List<DataSnapshot> _snapshots = <DataSnapshot>[];

  @override
  int get length => _snapshots.length;

  @override
  set length(int value) {
    throw UnsupportedError('List cannot be modified.');
  }

  @override
  DataSnapshot operator [](int index) => _snapshots[index];

  @override
  void operator []=(int index, DataSnapshot value) {
    throw UnsupportedError('List cannot be modified.');
  }

  @override
  void clear() {
    cancelSubscriptions();

    // Do not call super.clear(), it will set the length, it's unsupported.
  }

  void _onChildAdded(DatabaseEvent event) {
    _snapshots.add(event.snapshot);
    _snapshots.sort(comparator);
    onChildAdded!(_snapshots.indexOf(event.snapshot), event.snapshot);
  }

  void _onChildRemoved(DatabaseEvent event) {
    final DataSnapshot snapshot =
        _snapshots.firstWhere((DataSnapshot snapshot) {
      return snapshot.key == event.snapshot.key;
    });
    final int index = _snapshots.indexOf(snapshot);
    _snapshots.removeAt(index);
    onChildRemoved!(index, snapshot);
  }

  void _onChildChanged(DatabaseEvent event) {
    final DataSnapshot snapshot =
        _snapshots.firstWhere((DataSnapshot snapshot) {
      return snapshot.key == event.snapshot.key;
    });
    final int index = _snapshots.indexOf(snapshot);
    _snapshots[index] = event.snapshot;
    onChildChanged!(index, event.snapshot);
  }

  void _onValue(DatabaseEvent event) {
    onValue!(event.snapshot);
  }

  void _onError(Object o) {
    onError?.call(o as FirebaseException);
  }
}
