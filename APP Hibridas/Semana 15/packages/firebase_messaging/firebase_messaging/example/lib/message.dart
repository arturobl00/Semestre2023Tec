// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Message route arguments.
class MessageArguments {
  /// The RemoteMessage
  final RemoteMessage message;

  /// Whether this message caused the application to open.
  final bool openedApplication;

  // ignore: public_member_api_docs
  MessageArguments(this.message, this.openedApplication);
}

/// Displays information about a [RemoteMessage].
class MessageView extends StatelessWidget {
  /// A single data row.
  Widget row(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: '),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MessageArguments args =
        ModalRoute.of(context)!.settings.arguments! as MessageArguments;
    RemoteMessage message = args.message;
    RemoteNotification? notification = message.notification;

    return Scaffold(
      appBar: AppBar(
        title: Text(message.messageId ?? 'N/A'),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            row('Triggered application open',
                args.openedApplication.toString()),
            row('Message ID', message.messageId),
            row('Sender ID', message.senderId),
            row('Category', message.category),
            row('Collapse Key', message.collapseKey),
            row('Content Available', message.contentAvailable.toString()),
            row('Data', message.data.toString()),
            row('From', message.from),
            row('Message ID', message.messageId),
            row('Sent Time', message.sentTime?.toString()),
            row('Thread ID', message.threadId),
            row('Time to Live (TTL)', message.ttl?.toString()),
            if (notification != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remote Notification',
                      style: TextStyle(fontSize: 18),
                    ),
                    row(
                      'Title',
                      notification.title,
                    ),
                    row(
                      'Body',
                      notification.body,
                    ),
                    if (notification.android != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Android Properties',
                        style: TextStyle(fontSize: 18),
                      ),
                      row(
                        'Channel ID',
                        notification.android!.channelId,
                      ),
                      row(
                        'Click Action',
                        notification.android!.clickAction,
                      ),
                      row(
                        'Color',
                        notification.android!.color,
                      ),
                      row(
                        'Count',
                        notification.android!.count?.toString(),
                      ),
                      row(
                        'Image URL',
                        notification.android!.imageUrl,
                      ),
                      row(
                        'Link',
                        notification.android!.link,
                      ),
                      row(
                        'Priority',
                        notification.android!.priority.toString(),
                      ),
                      row(
                        'Small Icon',
                        notification.android!.smallIcon,
                      ),
                      row(
                        'Sound',
                        notification.android!.sound,
                      ),
                      row(
                        'Ticker',
                        notification.android!.ticker,
                      ),
                      row(
                        'Visibility',
                        notification.android!.visibility.toString(),
                      ),
                    ],
                    if (notification.apple != null) ...[
                      const Text(
                        'Apple Properties',
                        style: TextStyle(fontSize: 18),
                      ),
                      row(
                        'Subtitle',
                        notification.apple!.subtitle,
                      ),
                      row(
                        'Badge',
                        notification.apple!.badge,
                      ),
                      row(
                        'Sound',
                        notification.apple!.sound?.name,
                      ),
                    ]
                  ],
                ),
              )
            ]
          ],
        ),
      )),
    );
  }
}
