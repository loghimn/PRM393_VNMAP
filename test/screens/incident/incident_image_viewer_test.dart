import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_image_viewer.dart';

void main() {
  group('IncidentImageViewer - Rendering', () {
    testWidgets('should display page indicator with correct count', (
      tester,
    ) async {
      final imageUrls = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
        'https://example.com/image3.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(home: IncidentImageViewer(imageUrls: imageUrls)),
      );

      // Page indicator shows "1 / 3"
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('should start at initial index when specified', (tester) async {
      final imageUrls = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
        'https://example.com/image3.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: IncidentImageViewer(imageUrls: imageUrls, initialIndex: 2),
        ),
      );

      // Should show "3 / 3"
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('should display close button in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentImageViewer(
            imageUrls: ['https://example.com/image1.jpg'],
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('should display download button in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentImageViewer(
            imageUrls: ['https://example.com/image1.jpg'],
          ),
        ),
      );

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
  });

  group('IncidentImageViewer - Interactions', () {
    testWidgets('should close when close button is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _ImageViewerWrapper())),
      );

      // Pump again to allow Navigator.push from postFrameCallback to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Should have popped - the ImageViewer should no longer be in tree
      expect(find.byType(IncidentImageViewer), findsNothing);
    });

    testWidgets('should show snackbar when download button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncidentImageViewer(
            imageUrls: ['https://example.com/image1.jpg'],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Đã lưu ảnh vào thiết bị'), findsOneWidget);
    });
  });
}

/// Helper widget that opens IncidentImageViewer via Navigator.push for testing pop behavior.
class _ImageViewerWrapper extends StatefulWidget {
  const _ImageViewerWrapper();

  @override
  State<_ImageViewerWrapper> createState() => _ImageViewerWrapperState();
}

class _ImageViewerWrapperState extends State<_ImageViewerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IncidentImageViewer(
            imageUrls: ['https://example.com/image1.jpg'],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Wrapper')));
  }
}
