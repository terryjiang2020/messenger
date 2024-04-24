// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:messenger/src/presentations/pages/chat_page/chat_page.dart';
import 'package:screenshot/screenshot.dart';

void main() {

  setUpAll(() {
    HttpOverrides.global = null;
  });
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // await tester.pumpWidget(const ChatPage());
    runApp(const MaterialApp(home: ChatPage()));
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('Athalia Putri'), findsAtLeastNWidgets(1));

    // // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);


  });
}

Future<List<Widget>> scrollEachItem(WidgetTester tester, ScreenshotController screenshotController) async {
  print('scrollEachItem is triggered');
  // First approach: get a single scrollable widget and drag it
  final scrollableElements = <Widget>[];

  // This will only contain the widgets that have been loaded.
  // By default, this means the widgets that are in the current viewport, due to lazy loading.
  // Which means that this would need to be re-run after each scroll to get the next set of widgets.
  final allWidgets = tester.allWidgets;

  for (final widget in allWidgets) {
    if (widget is ListView ||
        widget is ScrollView ||
        widget is SingleChildScrollView ||
        widget is CustomScrollView ||
        widget is NestedScrollView) {
      scrollableElements.add(widget);
    }
  }

  // If no scrollable element found, abort.
  if (scrollableElements.isEmpty) {
    print('scrollableElements is empty, abort');
    return scrollableElements;
  }
  else {
    print('scrollableElements is not empty, proceed');

    // Otherwise, start screenshoting.
    // The following tasks should be done:
    // 1. If no element exists in the current viewport, take screenshot and then scroll down.
    // 2. If any element exists in the current viewport, adjust the viewport to contain the whole element, take screenshot and then scroll down on that element until reach its bottom.
    // 3. Repeat the above steps until the bottom of the page is reached.

    for (final scrollable in scrollableElements) {

      print('Discovered scrollable type: ${scrollable.runtimeType.toString()}');

      // print('find.byWidget(scrollable): ${find.byWidget(scrollable)}');

      final scrollableFinder = find.byWidget(scrollable);

      try {
        tester.firstWidget<Widget>(scrollableFinder);
        print('Element found. Proceed.');

        final screenSize = tester.getSize(find.byWidget(scrollable));

        print('Checkpoint 1');

        final scrollableSize = screenSize.height;

        print('Checkpoint 2');

        final offset = Offset(0.0, -scrollableSize);

        print('Checkpoint 3');

        var i = 0;

        // Repeat 5 times
        while (i < 5) {
          print('Dragging: ${i}');
          // Drag from top to bottom with a slight offset to ensure enough movement
          await tester.dragFrom(screenSize.center(Offset.zero), offset);

          print('Checkpoint W 1');

          await delayed();
          
          print('Checkpoint W 2');

          await tester.pump(); // Wait for UI to rebuild after scroll

          await delayed();
          
          print('Checkpoint W 3');

          print('Dragging ${i} completed, proceed to screenshot taking.');

          screenshotController
              .capture(delay: const Duration(milliseconds: 10))
              .then((capturedImage) async {
            if (capturedImage != null) {
              final base64Value = uint8ListToBase64(capturedImage);
              await Dio().post('https://testserver.pretjob.com/api/designcomp/figma/screenshot/base64', data: {
                'items': [
                  {
                    'name': 'scrollable_${i}.png',
                    'base64': 'data:image/png;base64,' + base64Value,
                  }
                ]
              })
              .then((res) => {
                print('Screenshot uploaded successfully.')
              });
            }
            // final File file = File('screenshots/scrollable_${i}.png');
            // file.writeAsBytesSync(capturedImage!);
          }).catchError((onError) {
            print(onError);
          });

          print('Checkpoint W 4');

          print('Screenshot completed, proceed to next iteration.');

          i++;
          
          print('Checkpoint W 5');
        }
      }
      catch(err) {
        print('Element not found. Skip.');
      }

    }

    return scrollableElements;
  }
}

String uint8ListToBase64(Uint8List uint8List) {
  // Encode the uint8List to Base64
  String base64String = base64Encode(uint8List);
  return base64String;
}

Future<dynamic> delayed ({int milliseconds = 666}) async {
  /// 适当延时，让操作节奏慢下来
  return Future<dynamic>.delayed(Duration(milliseconds: milliseconds));
}

const Duration scrollDuration = Duration(milliseconds: 300);
