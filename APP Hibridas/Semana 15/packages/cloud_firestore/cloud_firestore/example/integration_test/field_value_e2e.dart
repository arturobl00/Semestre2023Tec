// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void runFieldValueTests() {
  group('$FieldValue', () {
    late FirebaseFirestore firestore;

    setUpAll(() async {
      firestore = FirebaseFirestore.instance;
    });

    Future<DocumentReference<Map<String, dynamic>>> initializeTest(
      String path,
    ) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.doc(prefixedPath).delete();
      return firestore.doc(prefixedPath);
    }

    group('FieldValue.increment()', () {
      testWidgets('increments a number if it exists', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-increment-exists');
        await doc.set({'foo': 2});
        await doc.update({'foo': FieldValue.increment(1)});
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals(3));
      });

      testWidgets('decrements a number', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-decrement-exists');
        await doc.set({'foo': 2});
        await doc.update({'foo': FieldValue.increment(-1)});
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals(1));
      });

      testWidgets('sets an increment if it does not exist', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-increment-not-exists');
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.exists, isFalse);
        await doc.set({'foo': FieldValue.increment(1)});
        DocumentSnapshot<Map<String, dynamic>> snapshot2 = await doc.get();
        expect(snapshot2.data()!['foo'], equals(1));
      });
    });

    group('FieldValue.serverTimestamp()', () {
      testWidgets('sets a new server time value', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-server-timestamp-new');
        await doc.set({'foo': FieldValue.serverTimestamp()});
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], isA<Timestamp>());
      });

      testWidgets('updates a server time value', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-server-timestamp-update');
        await doc.set({'foo': FieldValue.serverTimestamp()});
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        Timestamp serverTime1 = snapshot.data()!['foo'];
        expect(serverTime1, isA<Timestamp>());
        await Future.delayed(const Duration(milliseconds: 100));
        await doc.update({'foo': FieldValue.serverTimestamp()});
        DocumentSnapshot<Map<String, dynamic>> snapshot2 = await doc.get();
        Timestamp serverTime2 = snapshot2.data()!['foo'];
        expect(serverTime2, isA<Timestamp>());
        expect(
          serverTime2.microsecondsSinceEpoch >
              serverTime1.microsecondsSinceEpoch,
          isTrue,
        );
      });
    });

    group('FieldValue.delete()', () {
      testWidgets('removes a value', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-delete');
        await doc.set({'foo': 'bar', 'bar': 'baz'});
        await doc.update({'bar': FieldValue.delete()});
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data(), equals(<String, dynamic>{'foo': 'bar'}));
      });
    });

    group('FieldValue.arrayUnion()', () {
      testWidgets('updates an existing array', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-array-union-update-array');
        await doc.set({
          'foo': [1, 2]
        });
        await doc.update({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals([1, 2, 3, 4]));
      });

      testWidgets('updates an array if current value is not an array',
          (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-array-union-replace');
        await doc.set({'foo': 'bar'});
        await doc.update({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals([3, 4]));
      });

      testWidgets('sets an array if current value is not an array', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-array-union-replace');
        await doc.set({'foo': 'bar'});
        await doc.set({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals([3, 4]));
      });
    });

    group('FieldValue.arrayRemove()', () {
      testWidgets('removes items in an array', (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-array-remove-existing');
        await doc.set({
          'foo': [1, 2, 3, 4]
        });
        await doc.update({
          'foo': FieldValue.arrayRemove([3, 4])
        });
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals([1, 2]));
      });

      testWidgets('removes & updates an array if existing item is not an array',
          (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-array-remove-replace');
        await doc.set({'foo': 'bar'});
        await doc.update({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals([3, 4]));
      });

      testWidgets('removes & sets an array if existing item is not an array',
          (_) async {
        DocumentReference<Map<String, dynamic>> doc =
            await initializeTest('field-value-array-remove-replace');
        await doc.set({'foo': 'bar'});
        await doc.set({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
        expect(snapshot.data()!['foo'], equals([3, 4]));
      });

      // ignore: todo
      // TODO(salakar): test is currently failing on CI but unable to reproduce locally
      testWidgets(
        'updates with nested types',
        (_) async {
          DocumentReference<Map<String, dynamic>> doc =
              await initializeTest('field-value-nested-types');

          DocumentReference<Map<String, dynamic>> ref =
              FirebaseFirestore.instance.doc('foo/bar');

          await doc.set({
            'foo': [1]
          });
          await doc.update({
            'foo': FieldValue.arrayUnion([2, ref])
          });
          DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
          expect(snapshot.data()!['foo'], equals([1, 2, ref]));
        },
        skip: true,
      );
    });
  });
}
