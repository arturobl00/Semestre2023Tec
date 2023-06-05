// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import './utils/exception.dart';
import '../../firebase_storage_platform_interface.dart';
import 'method_channel_reference.dart';
import 'method_channel_task_snapshot.dart';

/// Method Channel delegate for [FirebaseStoragePlatform].
class MethodChannelFirebaseStorage extends FirebaseStoragePlatform {
  /// Creates a new [MethodChannelFirebaseStorage] instance with an [app] and/or
  /// [bucket].
  MethodChannelFirebaseStorage(
      {required FirebaseApp app, required String bucket})
      : super(appInstance: app, bucket: bucket) {
    // The channel setMethodCallHandler callback is not app specific, so there
    // is no need to register the caller more than once.
    if (_initialized) return;

    channel.setMethodCallHandler((MethodCall call) async {
      Map<dynamic, dynamic> arguments = call.arguments;

      switch (call.method) {
        case 'Task#onProgress':
          return _handleTaskStateChange(TaskState.running, arguments);
        case 'Task#onPaused':
          return _handleTaskStateChange(TaskState.paused, arguments);
        case 'Task#onSuccess':
          return _handleTaskStateChange(TaskState.success, arguments);
        case 'Task#onCanceled':
          return _sendTaskException(
              arguments['handle'],
              FirebaseException(
                plugin: 'firebase_storage',
                code: 'canceled',
                message: 'User canceled the upload/download.',
              ));
        case 'Task#onFailure':
          Map<String, dynamic> errorMap =
              Map<String, dynamic>.from(arguments['error']);
          return _sendTaskException(
              arguments['handle'],
              FirebaseException(
                plugin: 'firebase_storage',
                code: errorMap['code'],
                message: errorMap['message'],
              ));
      }
    });

    _initialized = true;
  }

  /// Internal stub class initializer.
  ///
  /// When the user code calls an storage method, the real instance is
  /// then initialized via the [delegateFor] method.
  MethodChannelFirebaseStorage._() : super(appInstance: null, bucket: '');

  /// Keep an internal reference to whether the [MethodChannelFirebaseStorage]
  /// class has already been initialized.
  static bool _initialized = false;

  /// Returns a unique key to identify the instance by [FirebaseApp] name and
  /// any custom storage buckets.
  static String _getInstanceKey(String /*!*/ appName, String bucket) {
    return '$appName|$bucket';
  }

  /// The [MethodChannelFirebaseStorage] method channel.
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_storage',
  );

  static Map<String, MethodChannelFirebaseStorage>
      _methodChannelFirebaseStorageInstances =
      <String, MethodChannelFirebaseStorage>{};

  /// Returns a stub instance to allow the platform interface to access
  /// the class instance statically.
  static MethodChannelFirebaseStorage get instance {
    return MethodChannelFirebaseStorage._();
  }

  static int _methodChannelHandleId = 0;

  /// Increments and returns the next channel ID handler for Storage.
  static int get nextMethodChannelHandleId => _methodChannelHandleId++;

  /// A map containing all Task stream observers, keyed by their handle.
  static final Map<int, StreamController<dynamic>> taskObservers =
      <int, StreamController<TaskSnapshotPlatform>>{};

  @override
  int maxOperationRetryTime = const Duration(minutes: 2).inMilliseconds;

  @override
  int maxUploadRetryTime = const Duration(minutes: 10).inMilliseconds;

  @override
  int maxDownloadRetryTime = const Duration(minutes: 10).inMilliseconds;

  Future<void> _handleTaskStateChange(
      TaskState taskState, Map<dynamic, dynamic> arguments) async {
    // Get & cast native snapshot data to a Map
    Map<String, dynamic> snapshotData =
        Map<String, dynamic>.from(arguments['snapshot']);

    // Get the cached Storage instance.
    FirebaseStoragePlatform storage = _methodChannelFirebaseStorageInstances[
        _getInstanceKey(arguments['appName'], arguments['bucket'])]!;

    // Create a snapshot.
    TaskSnapshotPlatform snapshot =
        MethodChannelTaskSnapshot(storage, taskState, snapshotData);

    // Fire a snapshot event.
    taskObservers[arguments['handle']]!.add(snapshot);
  }

  void _sendTaskException(int handle, FirebaseException exception) {
    taskObservers[handle]!.addError(exception);
  }

  @override
  FirebaseStoragePlatform delegateFor(
      {required FirebaseApp app, required String bucket}) {
    String key = _getInstanceKey(app.name, bucket);

    return _methodChannelFirebaseStorageInstances[key] ??=
        MethodChannelFirebaseStorage(app: app, bucket: bucket);
  }

  @override
  ReferencePlatform ref(String path) {
    return MethodChannelReference(this, path);
  }

  @override
  Future<void> useStorageEmulator(String host, int port) async {
    emulatorHost = host;
    emulatorPort = port;
    try {
      await MethodChannelFirebaseStorage.channel
          .invokeMethod('Storage#useEmulator', <String, dynamic>{
        'appName': app.name,
        'maxOperationRetryTime': maxOperationRetryTime,
        'maxUploadRetryTime': maxUploadRetryTime,
        'maxDownloadRetryTime': maxDownloadRetryTime,
        'bucket': bucket,
        'host': emulatorHost,
        'port': emulatorPort
      });
    } catch (e, s) {
      convertPlatformException(e, s);
    }
  }

  @override
  void setMaxOperationRetryTime(int time) {
    maxOperationRetryTime = time;
  }

  @override
  void setMaxUploadRetryTime(int time) {
    maxUploadRetryTime = time;
  }

  @override
  Future<void> setMaxDownloadRetryTime(int time) async {
    maxDownloadRetryTime = time;
  }
}
